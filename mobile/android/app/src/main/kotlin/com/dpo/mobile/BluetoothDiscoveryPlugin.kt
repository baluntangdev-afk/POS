package com.dpo.mobile

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

private const val METHOD_CHANNEL_NAME = "com.dpo.mobile/bt_discovery"
private const val EVENT_CHANNEL_NAME = "com.dpo.mobile/bt_discovery_events"
private const val TAG = "BluetoothDiscoveryPlugin"

// Live discovery/pairing for classic (SPP) Bluetooth thermal printers. Permission checks
// (BLUETOOTH_SCAN/BLUETOOTH_CONNECT on API 31+, ACCESS_FINE_LOCATION + Location Services
// below that) and the "turn Bluetooth on" prompt are handled Dart-side via permission_handler
// and android_intent_plus — this plugin only does the two things neither of those packages
// covers for classic Bluetooth: device discovery and pairing. Calls here assume the caller
// has already confirmed permissions are granted; a missing permission surfaces as a
// SecurityException, caught below and reported as a failed result rather than a crash.
class BluetoothDiscoveryPlugin : FlutterPlugin {
    private lateinit var appContext: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var receiver: BroadcastReceiver? = null

    private val adapter: BluetoothAdapter?
        get() = (appContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler { call, result -> handleCall(call, result) }

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    eventSink = sink
                    registerReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterReceiver()
                    eventSink = null
                }
            }
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        unregisterReceiver()
    }

    private fun handleCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startDiscovery" -> result.success(startDiscovery())
            "stopDiscovery" -> {
                cancelDiscoverySafely()
                result.success(true)
            }
            "pairDevice" -> {
                val mac = call.argument<String>("mac")
                if (mac == null) {
                    result.success(false)
                } else {
                    result.success(pairDevice(mac))
                }
            }
            "sdkInt" -> result.success(android.os.Build.VERSION.SDK_INT)
            else -> result.notImplemented()
        }
    }

    private fun startDiscovery(): Boolean {
        val bt = adapter ?: return false
        return try {
            if (bt.isDiscovering) bt.cancelDiscovery()
            bt.startDiscovery()
        } catch (e: SecurityException) {
            Log.w(TAG, "startDiscovery missing permission", e)
            false
        }
    }

    private fun cancelDiscoverySafely() {
        try {
            if (adapter?.isDiscovering == true) adapter?.cancelDiscovery()
        } catch (e: SecurityException) {
            Log.w(TAG, "cancelDiscovery missing permission", e)
        }
    }

    private fun pairDevice(mac: String): Boolean {
        val bt = adapter ?: return false
        return try {
            val device = bt.getRemoteDevice(mac)
            if (device.bondState == BluetoothDevice.BOND_BONDED) {
                true
            } else {
                device.createBond()
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "createBond missing permission", e)
            false
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "invalid mac address: $mac", e)
            false
        }
    }

    private fun registerReceiver() {
        if (receiver != null) return
        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
        }
        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    BluetoothDevice.ACTION_FOUND -> onDeviceFound(intent)
                    BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                        eventSink?.success(mapOf("type" to "discoveryFinished"))
                    }
                    BluetoothDevice.ACTION_BOND_STATE_CHANGED -> onBondStateChanged(intent)
                }
            }
        }
        appContext.registerReceiver(receiver, filter)
    }

    private fun unregisterReceiver() {
        cancelDiscoverySafely()
        receiver?.let {
            try {
                appContext.unregisterReceiver(it)
            } catch (e: IllegalArgumentException) {
                // already unregistered
            }
        }
        receiver = null
    }

    private fun onDeviceFound(intent: Intent) {
        @Suppress("DEPRECATION")
        val device =
            intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE) ?: return
        val name =
            try {
                device.name
            } catch (e: SecurityException) {
                null
            } ?: return
        eventSink?.success(
            mapOf("type" to "deviceFound", "name" to name, "mac" to device.address)
        )
    }

    private fun onBondStateChanged(intent: Intent) {
        @Suppress("DEPRECATION")
        val device =
            intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE) ?: return
        val newState = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, -1)
        // Only report terminal states — BOND_BONDING is a transient step, not an outcome.
        val bonded =
            when (newState) {
                BluetoothDevice.BOND_BONDED -> true
                BluetoothDevice.BOND_NONE -> false
                else -> return
            }
        eventSink?.success(
            mapOf("type" to "bondStateChanged", "mac" to device.address, "bonded" to bonded)
        )
    }
}
