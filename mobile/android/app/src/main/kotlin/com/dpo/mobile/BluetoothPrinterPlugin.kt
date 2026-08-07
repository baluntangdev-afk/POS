package com.dpo.mobile

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

private const val METHOD_CHANNEL_NAME = "com.dpo.mobile/bt_printer"
private const val TAG = "BluetoothPrinterPlugin"
private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

// Classic (SPP) Bluetooth connect/write/disconnect for thermal printers, replacing the
// equivalent calls from `print_bluetooth_thermal` (that package's `pairedBluetooths` and
// `bluetoothEnabled` are still used elsewhere and are unaffected by the issue below).
//
// print_bluetooth_thermal opens its socket via createRfcommSocketToServiceRecord(SPP_UUID),
// which depends on an SDP lookup finding a correct service record on the printer for that
// UUID. Plenty of cheap ESC/POS printers don't expose one properly, and on some
// Android/Bluetooth-stack combinations the socket-level connect can still report
// isConnected == true (a phantom success) without the printer's print service ever binding
// to it -- the app reports "connected" and nothing prints. This plugin bypasses SDP
// entirely and connects directly on RFCOMM channel 1 via reflection, which is the channel
// most classic-Bluetooth thermal printers actually listen on regardless of their SDP
// records, falling back to the SDP-based method if reflection is unavailable.
class BluetoothPrinterPlugin : FlutterPlugin {
    private lateinit var appContext: Context
    private lateinit var channel: MethodChannel
    private val scope = CoroutineScope(Dispatchers.IO + Job())

    private var socket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null

    private val adapter: BluetoothAdapter?
        get() = (appContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
        channel.setMethodCallHandler { call, result -> handleCall(call, result) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        closeQuietly()
    }

    private fun handleCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> {
                val mac = call.argument<String>("mac")
                if (mac == null) {
                    result.success(false)
                    return
                }
                scope.launch {
                    val ok = connect(mac)
                    withContext(Dispatchers.Main) { result.success(ok) }
                }
            }
            "writeBytes" -> {
                @Suppress("UNCHECKED_CAST")
                val ints = call.arguments as? List<Int>
                if (ints == null) {
                    result.success(false)
                    return
                }
                val bytes = ByteArray(ints.size) { i -> ints[i].toByte() }
                scope.launch {
                    val ok = writeBytes(bytes)
                    withContext(Dispatchers.Main) { result.success(ok) }
                }
            }
            "disconnect" -> {
                scope.launch {
                    closeQuietly()
                    withContext(Dispatchers.Main) { result.success(true) }
                }
            }
            "connectionStatus" -> result.success(socket?.isConnected == true)
            else -> result.notImplemented()
        }
    }

    private fun connect(mac: String): Boolean {
        closeQuietly()
        val bt = adapter ?: return false
        val device =
            try {
                bt.getRemoteDevice(mac)
            } catch (e: Exception) {
                Log.w(TAG, "invalid mac $mac", e)
                return false
            }
        try {
            bt.cancelDiscovery()
        } catch (e: SecurityException) {
            Log.w(TAG, "cancelDiscovery missing permission", e)
        }

        if (tryConnect { openChannel1(device) }) return true
        return tryConnect { device.createRfcommSocketToServiceRecord(SPP_UUID) }
    }

    private fun tryConnect(openSocket: () -> BluetoothSocket?): Boolean {
        val sock =
            try {
                openSocket()
            } catch (e: Exception) {
                Log.w(TAG, "failed to open socket", e)
                null
            } ?: return false
        return try {
            sock.connect()
            socket = sock
            outputStream = sock.outputStream
            true
        } catch (e: Exception) {
            Log.w(TAG, "connect attempt failed", e)
            try {
                sock.close()
            } catch (closeError: Exception) {
                // already closed / never opened
            }
            false
        }
    }

    private fun openChannel1(device: BluetoothDevice): BluetoothSocket? {
        return try {
            val method = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
            method.invoke(device, 1) as BluetoothSocket
        } catch (e: Exception) {
            Log.w(TAG, "channel 1 reflection unavailable, falling back to SDP lookup", e)
            null
        }
    }

    private fun writeBytes(bytes: ByteArray): Boolean {
        val stream = outputStream ?: return false
        return try {
            val chunkSize = 16 * 1024
            var offset = 0
            while (offset < bytes.size) {
                val end = minOf(offset + chunkSize, bytes.size)
                stream.write(bytes, offset, end - offset)
                stream.flush()
                offset = end
            }
            true
        } catch (e: Exception) {
            Log.w(TAG, "write failed", e)
            closeQuietly()
            false
        }
    }

    private fun closeQuietly() {
        try {
            outputStream?.close()
        } catch (e: Exception) {
            // already closed
        }
        try {
            socket?.close()
        } catch (e: Exception) {
            // already closed
        }
        outputStream = null
        socket = null
    }
}
