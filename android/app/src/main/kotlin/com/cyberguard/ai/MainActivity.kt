package com.cyberguard.ai

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.cyberguard.ai/device"
    private val SMS_EVENT_CHANNEL = "com.cyberguard.ai/sms_stream"

    private val smsReceiver = SmsReceiver()
    private var smsReceiverRegistered = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledApps" -> {
                        try {
                            result.success(getInstalledApps())
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "getAppIcon" -> {
                        try {
                            val packageName = call.argument<String>("packageName")!!
                            result.success(getAppIcon(packageName))
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "getWifiDetails" -> {
                        try {
                            result.success(getWifiDetails())
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "getSmsMessages" -> {
                        try {
                            result.success(getRecentSms())
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "getBatteryInfo" -> {
                        try {
                            result.success(getBatteryInfo())
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "getDeviceInfo" -> {
                        try {
                            result.success(getDeviceInfo())
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "openAppSettings" -> {
                        try {
                            val packageName = call.argument<String>("packageName")!!
                            openAppSettings(packageName)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "uninstallApp" -> {
                        try {
                            val packageName = call.argument<String>("packageName")!!
                            uninstallApp(packageName)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "startSmsListener" -> {
                        try {
                            // Start the long-lived foreground service so
                            // scanning survives the activity being killed.
                            PhishingGuardService.start(applicationContext)
                            // Also keep the in-activity dynamic receiver
                            // alive for the same-process EventChannel.
                            registerSmsReceiver()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "stopSmsListener" -> {
                        try {
                            PhishingGuardService.stop(applicationContext)
                            unregisterSmsReceiver()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "isSmsGuardRunning" -> {
                        try {
                            result.success(
                                PhishingGuardService.isEnabled(applicationContext)
                            )
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    SmsBus.attach(events)
                }

                override fun onCancel(arguments: Any?) {
                    SmsBus.detach()
                }
            })
    }

    private fun registerSmsReceiver() {
        if (smsReceiverRegistered) return
        val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION).apply {
            priority = 999
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(smsReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(smsReceiver, filter)
        }
        smsReceiverRegistered = true
    }

    private fun unregisterSmsReceiver() {
        if (!smsReceiverRegistered) return
        try { unregisterReceiver(smsReceiver) } catch (_: Throwable) {}
        smsReceiverRegistered = false
    }

    override fun onDestroy() {
        unregisterSmsReceiver()
        super.onDestroy()
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledPackages(android.content.pm.PackageManager.PackageInfoFlags.of(
                android.content.pm.PackageManager.GET_PERMISSIONS.toLong()
            ))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledPackages(android.content.pm.PackageManager.GET_PERMISSIONS)
        }

        return packages
            .filter { pkg ->
                val appInfo = pkg.applicationInfo ?: return@filter false
                val isSystem = (appInfo.flags and
                        android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                !isSystem
            }
            .mapNotNull { pkg ->
                try {
                    val appInfo = pkg.applicationInfo ?: return@mapNotNull null
                    val permissions = pkg.requestedPermissions?.toList() ?: emptyList()
                    val apkFile = File(appInfo.sourceDir)
                    val installer = getInstallerPackage(pkg.packageName)
                    mapOf(
                        "packageName" to pkg.packageName,
                        "appName" to (pm.getApplicationLabel(appInfo).toString()),
                        "versionName" to (pkg.versionName ?: ""),
                        "targetSdk" to appInfo.targetSdkVersion,
                        "minSdk" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
                            appInfo.minSdkVersion else 0,
                        "installTime" to pkg.firstInstallTime,
                        "updateTime" to pkg.lastUpdateTime,
                        "permissions" to permissions,
                        "apkSize" to (if (apkFile.exists()) apkFile.length() else 0L),
                        "installerPackage" to installer,
                    )
                } catch (e: Exception) {
                    null
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun getInstallerPackage(packageName: String): String {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                packageManager.getInstallSourceInfo(packageName).installingPackageName ?: ""
            } else {
                packageManager.getInstallerPackageName(packageName) ?: ""
            }
        } catch (e: Exception) {
            ""
        }
    }

    private fun openAppSettings(packageName: String) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun uninstallApp(packageName: String) {
        // ACTION_DELETE pops the system uninstall dialog; user confirms.
        val intent = Intent(Intent.ACTION_DELETE).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun getAppIcon(packageName: String): ByteArray? {
        return try {
            val pm = packageManager
            val drawable = pm.getApplicationIcon(packageName)
            val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
            val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    @Suppress("DEPRECATION")
    private fun getWifiDetails(): Map<String, Any> {
        return try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            val network = connectivityManager?.activeNetwork
            val capabilities = connectivityManager?.getNetworkCapabilities(network)

            // Hard preconditions — surface a clear status if Wi-Fi is off
            // or we're not currently connected to a Wi-Fi network.
            val wifiEnabled = wifiManager?.isWifiEnabled == true
            val onWifi = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
            if (!wifiEnabled) {
                return mapOf(
                    "status" to "wifi_off",
                    "message" to "Wi-Fi is turned off on this device",
                    "ssid" to "",
                    "bssid" to "",
                    "rssi" to -100,
                    "linkSpeed" to 0,
                    "frequency" to 0,
                    "ipAddress" to "",
                    "isWifi" to false,
                    "hasInternet" to false,
                    "isSecured" to false,
                )
            }
            if (!onWifi) {
                return mapOf(
                    "status" to "not_connected",
                    "message" to "Not connected to any Wi-Fi network",
                    "ssid" to "",
                    "bssid" to "",
                    "rssi" to -100,
                    "linkSpeed" to 0,
                    "frequency" to 0,
                    "ipAddress" to "",
                    "isWifi" to false,
                    "hasInternet" to false,
                    "isSecured" to false,
                )
            }

            val wifiInfo = wifiManager.connectionInfo
            val rawSsid = wifiInfo?.ssid ?: ""
            val cleanedSsid = rawSsid.trim().removePrefix("\"").removeSuffix("\"")
            val ssid = if (
                cleanedSsid.isEmpty() ||
                cleanedSsid.equals("<unknown ssid>", ignoreCase = true) ||
                cleanedSsid == "0x"
            ) "Unknown" else cleanedSsid

            val bssid = (wifiInfo?.bssid ?: "").let {
                if (it == "02:00:00:00:00:00") "" else it
            }
            val rssi = wifiInfo?.rssi ?: -100
            val linkSpeed = wifiInfo?.linkSpeed ?: 0
            val frequency = wifiInfo?.frequency ?: 0
            val ipInt = wifiInfo?.ipAddress ?: 0
            val ipAddress = intToIp(ipInt)
            val isWifi = true
            val hasInternet = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) ?: false

            // Detect encryption via scanResults capabilities string for this BSSID.
            // Requires location permission to be granted; otherwise scanResults is empty.
            var isSecured = true
            try {
                val results = wifiManager?.scanResults ?: emptyList()
                val match = results.firstOrNull { it.BSSID.equals(bssid, ignoreCase = true) }
                val caps = match?.capabilities ?: ""
                if (caps.isNotEmpty()) {
                    val upper = caps.uppercase()
                    isSecured = upper.contains("WPA") || upper.contains("WEP") || upper.contains("SAE")
                }
            } catch (_: SecurityException) {
                // No location permission — leave isSecured as the safe default
            }

            mapOf(
                "status" to "connected",
                "ssid" to ssid,
                "bssid" to bssid,
                "rssi" to rssi,
                "linkSpeed" to linkSpeed,
                "frequency" to frequency,
                "ipAddress" to ipAddress,
                "isWifi" to isWifi,
                "hasInternet" to hasInternet,
                "isSecured" to isSecured,
            )
        } catch (e: Exception) {
            mapOf(
                "status" to "error",
                "message" to (e.message ?: "Unknown error"),
                "ssid" to "",
                "bssid" to "",
                "rssi" to -100,
                "linkSpeed" to 0,
                "frequency" to 0,
                "ipAddress" to "",
                "isWifi" to false,
                "hasInternet" to false,
                "isSecured" to false,
            )
        }
    }

    private fun intToIp(ip: Int): String {
        return "${ip and 0xFF}.${ip shr 8 and 0xFF}.${ip shr 16 and 0xFF}.${ip shr 24 and 0xFF}"
    }

    private fun getRecentSms(): List<Map<String, String>> {
        val messages = mutableListOf<Map<String, String>>()
        try {
            // Pull a large window of recent SMS — covers months of history.
            val cursor = contentResolver.query(
                Uri.parse("content://sms/inbox"),
                arrayOf("address", "body", "date"),
                null,
                null,
                "date DESC LIMIT 500"
            )
            cursor?.use {
                while (it.moveToNext()) {
                    messages.add(
                        mapOf(
                            "address" to (it.getString(0) ?: ""),
                            "body" to (it.getString(1) ?: ""),
                            "date" to (it.getString(2) ?: "")
                        )
                    )
                }
            }
        } catch (e: Exception) {
            // Permission denied or unavailable
        }
        return messages
    }

    private fun getBatteryInfo(): Map<String, Any> {
        return try {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as? android.os.BatteryManager
            val level = batteryManager?.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
            val isCharging = batteryManager?.isCharging ?: false
            mapOf(
                "level" to level,
                "isCharging" to isCharging,
            )
        } catch (e: Exception) {
            mapOf("level" to -1, "isCharging" to false)
        }
    }

    private fun getDeviceInfo(): Map<String, Any> {
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "brand" to Build.BRAND,
            "device" to Build.DEVICE,
            "fingerprint" to Build.FINGERPRINT,
        )
    }
}
