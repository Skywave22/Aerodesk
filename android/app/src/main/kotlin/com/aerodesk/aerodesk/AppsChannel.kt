package com.aerodesk.aerodesk

import android.app.ActivityManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.storage.StorageManager
import android.provider.Settings
import android.util.Base64
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

/**
 * Native bridge for AeroDesk.
 *
 * Every method uses public Android APIs only. Anything that is not available on
 * the current device is reported back as unavailable so the Dart side can show
 * "Unknown" instead of guessing.
 */
class AppsChannel(private val activity: MainActivity) : MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.aerodesk/apps"
        private const val ICON_SIZE_PX = 128
        private const val APK_MIME = "application/vnd.android.package-archive"
    }

    private val executor = Executors.newSingleThreadExecutor()

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        // Icon loading and filesystem walks are done off the platform thread.
        executor.execute {
            try {
                val value: Any? = when (call.method) {
                    "getInstalledApps" -> installedApps()
                    "launchApp" -> launchApp(call.argument<String>("packageName"))
                    "openAppInfo" -> openAppInfo(call.argument<String>("packageName"))
                    "openFile" -> openFile(call.argument<String>("path"))
                    "hasAllFilesAccess" -> hasAllFilesAccess()
                    "requestAllFilesAccess" -> requestAllFilesAccess()
                    "getStorageVolumes" -> storageVolumes()
                    "getDeviceExtras" -> deviceExtras()
                    "getDeviceProfile" -> deviceProfile()
                    "getAppVersion" -> appVersion()
                    else -> throw UnsupportedOperationException("Unknown method ${call.method}")
                }
                activity.runOnUiThread { result.success(value) }
            } catch (error: Throwable) {
                activity.runOnUiThread { result.error("apps_channel_error", error.message, null) }
            }
        }
    }

    // ---------------------------------------------------------------- apps

    /** Launchable applications, folders first in the Dart layer. */
    private fun installedApps(): List<Map<String, Any?>> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolved = activity.packageManager.queryIntentActivities(intent, 0)
        return resolved.mapNotNull { info ->
            val packageName = info.activityInfo?.packageName ?: return@mapNotNull null
            val label = try {
                info.loadLabel(activity.packageManager)?.toString()
            } catch (_: Throwable) {
                null
            } ?: packageName
            val category = try {
                info.activityInfo.applicationInfo?.category ?: ApplicationInfo.CATEGORY_UNDEFINED
            } catch (_: Throwable) {
                ApplicationInfo.CATEGORY_UNDEFINED
            }
            mapOf(
                "packageName" to packageName,
                "label" to label,
                "category" to category,
                "icon" to iconAsBase64(packageName),
            )
        }
    }

    private fun iconAsBase64(packageName: String): String? {
        return try {
            val drawable = activity.packageManager.getApplicationIcon(packageName)
            val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else ICON_SIZE_PX
            val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else ICON_SIZE_PX
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            val scaled = Bitmap.createScaledBitmap(bitmap, ICON_SIZE_PX, ICON_SIZE_PX, true)
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.PNG, 90, stream)
            Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
        } catch (_: Throwable) {
            null
        }
    }

    private fun launchApp(packageName: String?): Boolean {
        if (packageName.isNullOrBlank()) return false
        val intent = activity.packageManager.getLaunchIntentForPackage(packageName) ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            activity.startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    private fun openAppInfo(packageName: String?): Boolean {
        if (packageName.isNullOrBlank()) return false
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null),
        )
        return start(intent)
    }

    private fun openFile(path: String?): Boolean {
        if (path.isNullOrBlank()) return false
        val file = File(path)
        if (!file.exists()) return false
        return try {
            val uri = FileProvider.getUriForFile(
                activity,
                "${activity.packageName}.fileprovider",
                file,
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeTypeOf(file.name))
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(Intent.createChooser(intent, "Open with"))
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun mimeTypeOf(name: String): String {
        val extension = name.substringAfterLast('.', "").lowercase()
        val byExtension = when (extension) {
            "apk" -> APK_MIME
            "png", "jpg", "jpeg", "gif", "webp", "bmp" -> "image/*"
            "mp4", "mkv", "webm", "3gp" -> "video/*"
            "mp3", "wav", "ogg", "m4a", "flac", "aac" -> "audio/*"
            "pdf" -> "application/pdf"
            "txt", "md", "log", "csv", "json", "xml" -> "text/plain"
            "zip", "tar", "gz" -> "application/zip"
            else -> null
        }
        return byExtension ?: "*/*"
    }

    // ------------------------------------------------------------- storage

    private fun hasAllFilesAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            false
        }
    }

    private fun requestAllFilesAccess(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false
        val perApp = Intent(
            Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
            Uri.fromParts("package", activity.packageName, null),
        )
        if (start(perApp)) return true
        return start(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
    }

    /** Storage volumes, or an empty list when the platform hides them. */
    private fun storageVolumes(): List<Map<String, Any?>> {
        val volumes = mutableListOf<Map<String, Any?>>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val manager = activity.getSystemService(StorageManager::class.java)
                for (volume in manager.storageVolumes) {
                    val directory = volume.directory ?: continue
                    volumes.add(
                        mapOf(
                            "path" to directory.absolutePath,
                            "label" to labelFor(directory),
                            "primary" to !volume.isRemovable,
                            "removable" to volume.isRemovable,
                        ),
                    )
                }
            } catch (_: Throwable) {
                volumes.clear()
            }
        }
        if (volumes.isEmpty()) {
            for (candidate in fallbackStoragePaths()) {
                volumes.add(
                    mapOf(
                        "path" to candidate.absolutePath,
                        "label" to labelFor(candidate),
                        "primary" to (candidate.absolutePath == "/storage/emulated/0"),
                        "removable" to (candidate.absolutePath != "/storage/emulated/0"),
                    ),
                )
            }
        }
        return volumes
    }

    private fun fallbackStoragePaths(): List<File> {
        val candidates = mutableListOf<File>()
        val primary = File("/storage/emulated/0")
        if (primary.isDirectory) candidates.add(primary)
        val storageRoot = File("/storage")
        if (storageRoot.isDirectory) {
            storageRoot.listFiles()?.forEach { child ->
                if (child.isDirectory && candidates.none { it.absolutePath == child.absolutePath }) {
                    candidates.add(child)
                }
            }
        }
        return candidates
    }

    private fun labelFor(directory: File): String {
        return when (directory.absolutePath) {
            "/storage/emulated/0", "/sdcard" -> "Internal storage"
            else -> directory.name
        }
    }

    private fun deviceExtras(): Map<String, Any?> {
        val extras = mutableMapOf<String, Any?>()
        try {
            val battery = activity.registerReceiver(null, android.content.IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            if (battery != null) {
                val level = battery.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = battery.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                val status = battery.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                val temperature = battery.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE)
                if (level >= 0 && scale > 0) {
                    extras["batteryLevel"] = level * 100 / scale
                }
                extras["batteryCharging"] =
                    status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
                if (temperature != Int.MIN_VALUE) {
                    extras["batteryTemperatureC"] = temperature / 10.0
                }
            }
        } catch (_: Throwable) {
            // Battery details are optional.
        }

        try {
            val dataStat = StatFs(Environment.getDataDirectory().absolutePath)
            extras["storageTotalBytes"] = dataStat.blockCountLong * dataStat.blockSizeLong
            extras["storageAvailableBytes"] = dataStat.availableBlocksLong * dataStat.blockSizeLong
        } catch (_: Throwable) {
            // Storage details are optional.
        }

        try {
            val manager = activity.getSystemService(ActivityManager::class.java)
            val memory = ActivityManager.MemoryInfo()
            manager.getMemoryInfo(memory)
            extras["memoryTotalBytes"] = memory.totalMem
            extras["memoryAvailableBytes"] = memory.availMem
        } catch (_: Throwable) {
            // Memory details are optional.
        }

        try {
            val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                activity.display
            } else {
                @Suppress("DEPRECATION")
                activity.windowManager.defaultDisplay
            }
            extras["refreshRate"] = display?.refreshRate?.toDouble()
        } catch (_: Throwable) {
            // Refresh rate is optional.
        }
        return extras
    }

    // -------------------------------------------------------------- device

    private fun deviceProfile(): Map<String, Any?> {
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "board" to Build.BOARD,
            "hardware" to Build.HARDWARE,
            "product" to Build.PRODUCT,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "securityPatch" to securityPatch(),
            "cpuCores" to Runtime.getRuntime().availableProcessors(),
        )
    }

    private fun securityPatch(): String {
        return try {
            Build.VERSION.SECURITY_PATCH ?: ""
        } catch (_: Throwable) {
            ""
        }
    }

    private fun appVersion(): Map<String, Any?> {
        return try {
            val info = activity.packageManager.getPackageInfo(activity.packageName, 0)
            val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                info.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                info.versionCode.toLong()
            }
            mapOf("version" to (info.versionName ?: "Unknown"), "build" to code.toString())
        } catch (_: Throwable) {
            mapOf("version" to "Unknown", "build" to "0")
        }
    }

    // -------------------------------------------------------------- helper

    private fun start(intent: Intent): Boolean {
        return try {
            activity.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (_: Throwable) {
            false
        }
    }
}
