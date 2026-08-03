package com.dpo.mobile

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import net.nyx.printerservice.print.IPrinterService
import net.nyx.printerservice.print.PrintTextFormat
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

private const val CHANNEL_NAME = "com.dpo.mobile/nyx_printer"
private const val NYX_PACKAGE = "net.nyx.printerservice"
private const val NYX_ACTION = "net.nyx.printerservice.IPrinterService"
private const val BIND_TIMEOUT_SECONDS = 3L
private const val LINE_HEIGHT_PX = 24

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
                    result.success(false)
                    return
                }
                Thread {
                    val success = printDocument(instructions)
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
        val serviceRef = AtomicReference<IPrinterService?>()
        val latch = CountDownLatch(1)
        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
                serviceRef.set(binder?.let { IPrinterService.Stub.asInterface(it) })
                latch.countDown()
            }

            override fun onServiceDisconnected(name: ComponentName?) {
                serviceRef.set(null)
                latch.countDown()
            }
        }

        val intent = Intent(NYX_ACTION).apply { setPackage(NYX_PACKAGE) }
        val bound =
            try {
                appContext.bindService(intent, connection, Context.BIND_AUTO_CREATE)
            } catch (e: Exception) {
                false
            }
        if (!bound) return false

        return try {
            latch.await(BIND_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            val service = serviceRef.get() ?: return false
            for (instruction in instructions) {
                writeInstruction(service, instruction)
            }
            true
        } catch (e: Exception) {
            false
        } finally {
            try {
                appContext.unbindService(connection)
            } catch (e: Exception) {
                // already unbound
            }
        }
    }

    private fun writeInstruction(service: IPrinterService, instruction: Map<String, Any?>) {
        when (instruction["type"] as? String) {
            "text" -> service.printText(instruction["text"] as? String ?: "", textFormatFor(instruction))
            "row" -> {
                @Suppress("UNCHECKED_CAST")
                val columns = (instruction["columns"] as? List<String>)?.toTypedArray() ?: emptyArray()
                @Suppress("UNCHECKED_CAST")
                val weightsList = instruction["weights"] as? List<Int> ?: emptyList()
                val weights = IntArray(columns.size) { i -> weightsList.getOrElse(i) { 1 } }
                val bold = instruction["bold"] as? Boolean ?: false
                val lastAlign = instruction["lastColumnAlign"] as? String ?: "left"
                val formats =
                    Array(columns.size) { i ->
                        PrintTextFormat().apply {
                            textSize = 24
                            style = if (bold) 1 else 0
                            ali = if (i == columns.lastIndex) alignToInt(lastAlign) else 0
                        }
                    }
                service.printTableText(columns, weights, formats)
            }
            "divider" -> {
                val char = instruction["char"] as? String ?: "-"
                service.printText(char.repeat(32), PrintTextFormat())
            }
            "feed" -> {
                val lines = (instruction["lines"] as? Int) ?: 1
                service.paperOut(lines * LINE_HEIGHT_PX)
            }
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
