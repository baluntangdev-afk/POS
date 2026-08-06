package com.dpo.mobile

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Parcel
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import net.nyx.printerservice.print.PrintTextFormat
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

private const val CHANNEL_NAME = "com.dpo.mobile/nyx_printer"
private const val NYX_PACKAGE = "net.nyx.printerservice"
private const val NYX_ACTION = "net.nyx.printerservice.IPrinterService"
private const val BIND_TIMEOUT_SECONDS = 3L
private const val PRINTER_STATUS_SUCCESS = 0
private const val TAG = "NyxPrinterPlugin"

// The Bluetooth print path targets PaperSize.mm80. 32 chars/line (a 58mm-paper
// assumption) left the right-hand column short of the actual page width, but
// never wrapped; 48 overshot the printer's actual physical capacity and
// caused it to auto-wrap rows onto a second line, breaking the padding-based
// alignment. 42 was tried as an untested middle ground and still overshot in
// practice (a 26-char item label + amount wrapped). 36 was also tried and
// still overshot (e.g. the 19-char "VATable Sales" + amount row, padded to
// the full 36 chars, wrapped). 32 is the last value confirmed not to
// overshoot — every single-line row is padded out to exactly this many
// characters, so it must stay at or under the printer's real physical
// capacity for ALL rows, not just long ones.
private const val LINE_WIDTH_CHARS = 32
private const val LINE_HEIGHT_PX = 24

// The net.nyx.printerservice.print.IPrinterService.aidl this plugin used to ship with
// (4 methods: printText/printTableText/paperOut/getPrinterStatus) does NOT match the
// real interface. Confirmed by dexdumping the installed service APK and the
// manufacturer's own postest diagnostic app: the real interface has ~17 methods, and
// AIDL assigns Binder transaction codes by original declaration order, not by whatever
// subset we guess at — every call under the old AIDL landed on a different, wrong real
// method (explaining the "success" results that never actually printed anything).
// postest's own compiled Proxy class was disassembled to recover the real transaction
// codes and wire formats used here:
//   code 7   int printText(String text, PrintTextFormat format)
//   code 5   int paperOut(int px)
// There is no real "printTableText"; postest itself builds aligned rows by manually
// padding a single string before calling printText, which is what writeRow() does below.
private const val INTERFACE_DESCRIPTOR = "net.nyx.printerservice.print.IPrinterService"
private const val TRANSACTION_PRINT_TEXT = 7
private const val TRANSACTION_PAPER_OUT = 5

class NyxPrinterPlugin : FlutterPlugin {
    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler { call, result -> handleCall(call, result) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun handleCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(isNyxPrinterInstalled())
            "printDocument" -> {
                @Suppress("UNCHECKED_CAST")
                val instructions = call.arguments as? List<Map<String, Any?>>
                if (instructions == null) {
                    Log.w(
                        TAG,
                        "printDocument: arguments were not a List<Map<String, Any?>>: ${call.arguments}"
                    )
                    result.success(false)
                    return
                }
                Log.d(TAG, "printDocument: received ${instructions.size} instructions")
                Thread {
                    val success = printDocument(instructions)
                    Log.d(TAG, "printDocument: overall success=$success")
                    mainHandler.post { result.success(success) }
                }.start()
            }

            else -> result.notImplemented()
        }
    }

    private fun isNyxPrinterInstalled(): Boolean {
        return try {
            appContext.packageManager.getPackageInfo(NYX_PACKAGE, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun printDocument(instructions: List<Map<String, Any?>>): Boolean {
        return withPrinterBinder { binder ->
            var allSucceeded = true
            for (instruction in instructions) {
                val status =
                    try {
                        writeInstruction(binder, instruction)
                    } catch (e: Exception) {
                        Log.e(TAG, "writeInstruction threw for $instruction", e)
                        allSucceeded = false
                        continue
                    }
                Log.d(TAG, "instruction=$instruction status=$status")
                if (status != PRINTER_STATUS_SUCCESS) {
                    allSucceeded = false
                }
            }
            allSucceeded
        }
    }

    private fun withPrinterBinder(block: (IBinder) -> Boolean): Boolean {
        val binderRef = AtomicReference<IBinder?>()
        val latch = CountDownLatch(1)
        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
                binderRef.set(binder)
                latch.countDown()
            }

            override fun onServiceDisconnected(name: ComponentName?) {
                binderRef.set(null)
                latch.countDown()
            }
        }

        val intent = Intent(NYX_ACTION).apply { setPackage(NYX_PACKAGE) }
        val bound =
            try {
                appContext.bindService(intent, connection, Context.BIND_AUTO_CREATE)
            } catch (e: Exception) {
                Log.e(TAG, "bindService threw", e)
                false
            }
        Log.d(TAG, "bindService returned $bound")
        if (!bound) return false

        return try {
            val awaited = latch.await(BIND_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            Log.d(TAG, "latch.await returned $awaited")
            val binder = binderRef.get()
            if (binder == null) {
                Log.w(TAG, "binder was null after connect")
                return false
            }
            block(binder)
        } catch (e: Exception) {
            Log.e(TAG, "withPrinterBinder threw", e)
            false
        } finally {
            try {
                appContext.unbindService(connection)
            } catch (e: Exception) {
                // already unbound
            }
        }
    }

    private fun writeInstruction(binder: IBinder, instruction: Map<String, Any?>): Int {
        return when (instruction["type"] as? String) {
            "text" -> printText(
                binder,
                instruction["text"] as? String ?: "",
                textFormatFor(instruction)
            )

            "row" -> {
                @Suppress("UNCHECKED_CAST")
                val columns = (instruction["columns"] as? List<Map<String, Any?>>) ?: emptyList()
                val weights = (instruction["weights"] as? List<*>)
                    ?.map { (it as Number).toInt() } ?: emptyList()
                val minGap = (instruction["minGap"] as? Int) ?: 1
                writeRow(binder, columns, weights, minGap)
            }

            "divider" -> {
                val char = instruction["char"] as? String ?: "-"
                printText(binder, char.repeat(LINE_WIDTH_CHARS), PrintTextFormat())
            }

            "feed" -> {
                val lines = (instruction["lines"] as? Int) ?: 1
                paperOut(binder, lines * LINE_HEIGHT_PX)
            }

            else -> PRINTER_STATUS_SUCCESS
        }
    }

    // Columns are laid out in fixed-width slots sized proportionally to
    // [weights], spanning the full LINE_WIDTH_CHARS edge-to-edge — like a
    // real receipt table rather than a two-item spaceBetween row. Each
    // column is aligned per its own "align" within its slot, so a
    // right-aligned column lands flush against the right edge of that
    // slot. A row is only joined into one physical line when every column
    // shares the same "bold"; otherwise each column is printed with its
    // own style on its own line. Matches the Bluetooth ESC/POS path
    // (print_service.dart's _generateRowBytes).
    private fun writeRow(
        binder: IBinder,
        columns: List<Map<String, Any?>>,
        weights: List<Int>,
        minGap: Int,
    ): Int {
        val line = buildRowLine(columns, weights, LINE_WIDTH_CHARS, minGap)
        if (line != null) {
            return printText(binder, line, textFormatFor(columns.first()))
        }

        // Pad each column out to the full line width ourselves instead of
        // relying on PrintTextFormat.ali — the joined-line path above never
        // depends on native alignment (it space-pads the string directly),
        // and that's the only path confirmed to align correctly on-device.
        var status = PRINTER_STATUS_SUCCESS
        for (column in columns) {
            val text = column["text"] as? String ?: ""
            val align = column["align"] as? String ?: "left"
            val paddedText = alignWithin(text, LINE_WIDTH_CHARS, align)
            val columnStatus = printText(binder, paddedText, textFormatFor(column))
            if (status == PRINTER_STATUS_SUCCESS) status = columnStatus
        }
        return status
    }

    // Returns a single line spanning [lineWidth] chars, or null if a
    // column's text doesn't fit its weighted slot (with at least [minGap]
    // chars to spare before non-last columns), or if the columns don't all
    // share the same "bold" — either case signals the row should instead
    // be printed as one line per column.
    private fun buildRowLine(
        columns: List<Map<String, Any?>>,
        weights: List<Int>,
        lineWidth: Int,
        minGap: Int,
    ): String? {
        if (columns.size == 1) return columns[0]["text"] as? String
        if (columns.size != weights.size) return null

        val firstBold = columns.first()["bold"] as? Boolean ?: false
        if (columns.any { (it["bold"] as? Boolean ?: false) != firstBold }) return null

        val totalWeight = weights.sum()
        val widths = mutableListOf<Int>()
        var used = 0
        for (i in 0 until columns.size - 1) {
            val width = lineWidth * weights[i] / totalWeight
            widths.add(width)
            used += width
        }
        widths.add(lineWidth - used)

        val segments = mutableListOf<String>()
        for (i in columns.indices) {
            val text = columns[i]["text"] as? String ?: ""
            val align = columns[i]["align"] as? String ?: "left"
            val width = widths[i]
            val isLast = i == columns.size - 1

            if (text.length + (if (isLast) 0 else minGap) > width) return null

            segments.add(alignWithin(text, width, align))
        }
        return segments.joinToString("")
    }

    private fun alignWithin(text: String, width: Int, align: String): String {
        val pad = width - text.length
        if (pad <= 0) return text
        return when (align) {
            "left" -> text.padEnd(width)
            "right" -> text.padStart(width)
            "center" -> " ".repeat(pad / 2) + text + " ".repeat(pad - pad / 2)
            else -> text.padEnd(width)
        }
    }

    private fun printText(binder: IBinder, text: String, format: PrintTextFormat): Int {
        val data = Parcel.obtain()
        val reply = Parcel.obtain()
        return try {
            data.writeInterfaceToken(INTERFACE_DESCRIPTOR)
            data.writeString(text)
            data.writeInt(1)
            format.writeToParcel(data, 0)
            binder.transact(TRANSACTION_PRINT_TEXT, data, reply, 0)
            reply.readException()
            reply.readInt()
        } finally {
            data.recycle()
            reply.recycle()
        }
    }

    private fun paperOut(binder: IBinder, px: Int): Int {
        val data = Parcel.obtain()
        val reply = Parcel.obtain()
        return try {
            data.writeInterfaceToken(INTERFACE_DESCRIPTOR)
            data.writeInt(px)
            binder.transact(TRANSACTION_PAPER_OUT, data, reply, 0)
            reply.readException()
            reply.readInt()
        } finally {
            data.recycle()
            reply.recycle()
        }
    }

    private fun textFormatFor(instruction: Map<String, Any?>): PrintTextFormat {
        val align = instruction["align"] as? String ?: "left"
        val bold = instruction["bold"] as? Boolean ?: false
        val sizeMultiplier = (instruction["sizeMultiplier"] as? Int) ?: 1
        return PrintTextFormat().apply {
            ali = alignToInt(align)
            style = if (bold) 1 else 0
            textSize = if (sizeMultiplier >= 2) 48 else 24
        }
    }

    private fun alignToInt(align: String): Int =
        when (align) {
            "center" -> 1
            "right" -> 2
            else -> 0
        }
}
