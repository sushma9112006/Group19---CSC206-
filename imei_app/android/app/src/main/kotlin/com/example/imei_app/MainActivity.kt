package com.example.imei_app

import android.app.ActivityManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "imei_track/device_specs"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method == "getDeviceSpecs") {
                    try {
                        val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
                        val memInfo = ActivityManager.MemoryInfo()
                        activityManager.getMemoryInfo(memInfo)

                        val totalRamGb = memInfo.totalMem.toDouble() / (1024 * 1024 * 1024)

                        val stat = StatFs(Environment.getDataDirectory().path)
                        val totalStorageGb =
                            (stat.blockSizeLong * stat.blockCountLong).toDouble() / (1024 * 1024 * 1024)

                        val roundedStorageGb = kotlin.math.round(totalStorageGb).toInt()

                        val data = mapOf(
                            "brand" to Build.MANUFACTURER,
                            "model" to Build.MODEL,
                            "ram" to String.format("%.0f GB", totalRamGb),
                            "storage" to "$roundedStorageGb GB",
                            "rom" to "$roundedStorageGb GB"
                        )

                        result.success(data)

                    } catch (e: Exception) {
                        result.error("DEVICE_SPECS_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
