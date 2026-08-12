package com.cyberguard.ai

import android.Manifest
import android.app.Activity
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.net.wifi.WifiInfo
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
    private val LINK_CHANNEL = "com.cyberguard.ai/link"
    private val LINK_EVENT_CHANNEL = "com.cyberguard.ai/link_stream"


    // ── Smart Link Interceptor plumbing ──────────────────────────────────
    // Links delivered while Flutter is alive go straight to this sink; a
    // cold-start link (no sink yet) is buffered for getInitialLink().
    private var linkEventSink: EventChannel.EventSink? = null
    private var pendingInitialLink: Map<String, Any?>? = null

    // Pending result for the ROLE_BROWSER request dialog (resolved in
    // onActivityResult once the user accepts/declines the system prompt).
    private val ROLE_BROWSER_REQUEST = 4711
    private var pendingBrowserRoleResult: MethodChannel.Result? = null

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
                            // Just a flag now. The manifest receiver is always
                            // registered; SmsGuard.handle() no-ops until this
                            // is set, so nothing is scanned without consent.
                            SmsGuard.setEnabled(applicationContext, true)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "stopSmsListener" -> {
                        try {
                            SmsGuard.setEnabled(applicationContext, false)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "isSmsGuardRunning" -> {
                        try {
                            result.success(SmsGuard.isEnabled(applicationContext))
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

        // ── Smart Link Interceptor channels ──────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LINK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> {
                        result.success(pendingInitialLink)
                        pendingInitialLink = null // consume once
                    }
                    "openInBrowser" -> {
                        try {
                            val url = call.argument<String>("url")!!
                            result.success(openInBrowser(url))
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "isDefaultBrowser" -> {
                        try {
                            result.success(isDefaultBrowser())
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    "requestDefaultBrowser" -> {
                        try {
                            requestDefaultBrowser(result)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LINK_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    linkEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    linkEventSink = null
                }
            })

        // Capture the intent that launched us (cold start). The sink isn't
        // attached yet, so this buffers into pendingInitialLink.
        handleLinkIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleLinkIntent(intent)
    }

    /// Pull a URL out of a VIEW (tapped link) or SEND (shared text) intent and
    /// route it to Flutter — live via the event sink, or buffered for cold start.
    private fun handleLinkIntent(intent: Intent?) {
        val url = extractUrl(intent) ?: return
        val payload: Map<String, Any?> = mapOf(
            "url" to url,
            "sourceApp" to referrerLabel(),
        )
        val sink = linkEventSink
        if (sink != null) {
            sink.success(payload)
        } else {
            pendingInitialLink = payload
        }
    }

    private fun extractUrl(intent: Intent?): String? {
        if (intent == null) return null
        return when (intent.action) {
            Intent.ACTION_VIEW -> {
                val data = intent.dataString
                if (data != null && (data.startsWith("http://") || data.startsWith("https://"))) data
                else null
            }
            Intent.ACTION_SEND -> {
                val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return null
                // Shared text may be "Check this out https://… 🔗" — grab the URL.
                Regex("""https?://\S+""").find(text)?.value
            }
            else -> null
        }
    }

    /// Friendly label for the app that handed us the link (best effort).
    private fun referrerLabel(): String? {
        val ref = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) referrer else null
        val pkg = ref?.host ?: return null
        return try {
            val ai = packageManager.getApplicationInfo(pkg, 0)
            packageManager.getApplicationLabel(ai).toString()
        } catch (_: Exception) {
            pkg
        }
    }

    /// Open [url] in a real browser, excluding CyberGuard from the chooser so
    /// "Continue Anyway" can never loop back into the interceptor.
    private fun openInBrowser(url: String): Boolean {
        return try {
            val view = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                .addCategory(Intent.CATEGORY_BROWSABLE)
            val chooser = Intent.createChooser(view, "Open with")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                chooser.putExtra(
                    Intent.EXTRA_EXCLUDE_COMPONENTS,
                    arrayOf(ComponentName(this, MainActivity::class.java)),
                )
            }
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(chooser)
            true
        } catch (e: Exception) {
            false
        }
    }

    /// True when CyberGuard is the system default browser. On Android 12+ this
    /// is the ONLY way a tapped http/https link is delivered to us before the
    /// browser opens it (a passive intent filter is bypassed for unverified
    /// domains). Uses RoleManager on Q+, falling back to intent resolution.
    private fun isDefaultBrowser(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val rm = getSystemService(Context.ROLE_SERVICE) as? RoleManager
            if (rm != null && rm.isRoleAvailable(RoleManager.ROLE_BROWSER)) {
                return rm.isRoleHeld(RoleManager.ROLE_BROWSER)
            }
        }
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.example.com"))
                .addCategory(Intent.CATEGORY_BROWSABLE)
            val resolved = packageManager.resolveActivity(
                intent, PackageManager.MATCH_DEFAULT_ONLY
            )
            resolved?.activityInfo?.packageName == packageName
        } catch (e: Exception) {
            false
        }
    }

    /// Ask the OS to make CyberGuard the default browser. On Q+ this pops the
    /// system ROLE_BROWSER dialog and the result is delivered via
    /// onActivityResult. On older devices we open the default-apps settings
    /// (no in-place dialog API), so we resolve immediately with the current
    /// state and rely on a re-check when the user returns.
    private fun requestDefaultBrowser(result: MethodChannel.Result) {
        if (isDefaultBrowser()) {
            result.success(true)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val rm = getSystemService(Context.ROLE_SERVICE) as? RoleManager
            if (rm != null && rm.isRoleAvailable(RoleManager.ROLE_BROWSER)) {
                pendingBrowserRoleResult = result
                startActivityForResult(
                    rm.createRequestRoleIntent(RoleManager.ROLE_BROWSER),
                    ROLE_BROWSER_REQUEST,
                )
                return
            }
        }
        // Pre-Q fallback: send the user to the default-apps settings screen.
        try {
            startActivity(Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS))
        } catch (e: Exception) {
            try { startActivity(Intent(Settings.ACTION_SETTINGS)) } catch (_: Exception) {}
        }
        result.success(false)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == ROLE_BROWSER_REQUEST) {
            // RESULT_OK means the role was granted to us; double-check by
            // querying current state to stay correct across OEM quirks.
            val granted = resultCode == Activity.RESULT_OK || isDefaultBrowser()
            pendingBrowserRoleResult?.success(granted)
            pendingBrowserRoleResult = null
        }
    }

    // SmsReceiver is declared in AndroidManifest.xml and must not also be
    // registered here — both registrations would fire and every message would
    // be scanned twice, raising duplicate notifications. The manifest receiver
    // runs in this same process, so SmsBus still reaches the EventChannel sink
    // for live in-app updates exactly as before.

    override fun onDestroy() {
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

            // Android 12 (S) deprecated WifiManager.getConnectionInfo(). The
            // supported path is the WifiInfo hanging off the active network's
            // NetworkCapabilities; it is also the only one that reliably
            // carries a real SSID on newer releases. Fall back to the old call
            // when transportInfo is absent (pre-S, or a redacted instance).
            val wifiInfo: WifiInfo? =
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    capabilities?.transportInfo as? WifiInfo
                } else {
                    null
                }) ?: @Suppress("DEPRECATION") wifiManager.connectionInfo

            val rawSsid = wifiInfo?.ssid ?: ""
            val cleanedSsid = rawSsid.trim().removePrefix("\"").removeSuffix("\"")
            val ssidHidden =
                cleanedSsid.isEmpty() ||
                cleanedSsid.equals(WifiManager.UNKNOWN_SSID, ignoreCase = true) ||
                cleanedSsid.equals("<unknown ssid>", ignoreCase = true) ||
                cleanedSsid == "0x"

            // The SSID is redacted rather than absent when the caller is not
            // allowed to see it. Two separate causes, and the user can only
            // act on them if we say which one it is: the runtime permission
            // may be missing, or the device-wide Location toggle may be off —
            // Android withholds the SSID for the latter even when the
            // permission itself is granted.
            if (ssidHidden) {
                if (!hasWifiNamePermission()) {
                    return wifiUnavailable(
                        "permission_required",
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                            "Allow the nearby-devices permission to read the Wi-Fi network name"
                        else
                            "Allow the location permission to read the Wi-Fi network name",
                    )
                }
                // The device-wide Location toggle only gates the SSID on the
                // legacy path. With NEARBY_WIFI_DEVICES granted on Android 13+
                // the name is readable regardless, so telling that user to
                // switch Location on would be asking for something that
                // changes nothing.
                if (!hasNearbyWifiPermission() && !isLocationServiceOn()) {
                    return wifiUnavailable(
                        "location_off",
                        "Turn on Location in system settings — Android hides the Wi-Fi name while it is off, even with the permission granted",
                    )
                }
            }

            val ssid = if (ssidHidden) "Unknown" else cleanedSsid

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

    /// Shared shape for every "we cannot report a network" outcome, so the
    /// Dart side only ever has to switch on `status`.
    private fun wifiUnavailable(status: String, message: String): Map<String, Any> =
        mapOf(
            "status" to status,
            "message" to message,
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

    /// True when at least one permission that unlocks the SSID is granted.
    /// NEARBY_WIFI_DEVICES is the Android 13+ route; ACCESS_FINE_LOCATION
    /// covers everything before it (and still works after).
    private fun hasWifiNamePermission(): Boolean {
        // Checked first: on Android 13+ this is the only permission the app
        // asks for, and ACCESS_FINE_LOCATION is capped at API 32 in the
        // manifest so it can never be granted there.
        if (hasNearbyWifiPermission()) return true
        return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    }

    /// The Android 13+ path. Declared with `neverForLocation`, so granting it
    /// reveals the network's identity without granting any location access
    /// and without requiring the device Location toggle.
    private fun hasNearbyWifiPermission(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.NEARBY_WIFI_DEVICES) ==
            PackageManager.PERMISSION_GRANTED

    /// The device-wide Location toggle, which is separate from the app's
    /// permission grant. Android returns "<unknown ssid>" while this is off.
    private fun isLocationServiceOn(): Boolean {
        val lm = getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            lm.isLocationEnabled
        } else {
            @Suppress("DEPRECATION")
            lm.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
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
