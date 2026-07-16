package com.zephyrixel.kgmusic

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.BatteryManager
import android.os.Build
import android.os.StatFs
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

internal object DeviceProfileChannel {
    private const val CHANNEL = "com.zephyrixel.kgmusic/device_profile"

    fun register(context: Context, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "read") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            runCatching { collect(context.applicationContext) }
                .onSuccess(result::success)
                .onFailure { result.error("device_profile", it.message, null) }
        }
    }

    private fun collect(context: Context): Map<String, Any?> {
        val memory = ActivityManager.MemoryInfo().also {
            (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(it)
        }
        val battery = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val sensors = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val internalStorage = StatFs(context.filesDir.absolutePath).availableBytes
        val externalPath = context.getExternalFilesDir(null)?.absolutePath
        val externalStorage = externalPath?.let { StatFs(it).availableBytes } ?: internalStorage

        return mapOf(
            "androidId" to Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ANDROID_ID,
            ),
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "basebandVersion" to Build.getRadioVersion(),
            "availableRamBytes" to memory.availMem,
            "availableInternalStorageBytes" to internalStorage,
            "availableExternalStorageBytes" to externalStorage,
            "batteryLevel" to battery?.batteryPercentage(),
            "batteryStatus" to battery?.getIntExtra(
                BatteryManager.EXTRA_STATUS,
                BatteryManager.BATTERY_STATUS_UNKNOWN,
            ),
            "hasAccelerometer" to sensors.has(Sensor.TYPE_ACCELEROMETER),
            "hasGravity" to sensors.has(Sensor.TYPE_GRAVITY),
            "hasGyroscope" to sensors.has(Sensor.TYPE_GYROSCOPE),
            "hasLight" to sensors.has(Sensor.TYPE_LIGHT),
            "hasMagneticField" to sensors.has(Sensor.TYPE_MAGNETIC_FIELD),
            "hasOrientation" to sensors.has(Sensor.TYPE_ORIENTATION),
            "hasPressure" to sensors.has(Sensor.TYPE_PRESSURE),
            "hasStepCounter" to sensors.has(Sensor.TYPE_STEP_COUNTER),
            "hasAmbientTemperature" to sensors.has(Sensor.TYPE_AMBIENT_TEMPERATURE),
        )
    }

    private fun SensorManager.has(type: Int): Boolean = getDefaultSensor(type) != null

    private fun Intent.batteryPercentage(): Int? {
        val level = getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        if (level < 0 || scale <= 0) return null
        return (level * 100 / scale).coerceIn(0, 100)
    }
}
