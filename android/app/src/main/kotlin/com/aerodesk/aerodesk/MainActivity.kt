package com.aerodesk.aerodesk

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Single activity host for AeroDesk.
 *
 * The activity is resizeable and handles configuration changes itself, so the
 * Flutter UI keeps running when the window moves to a tablet, an external
 * display or Android desktop mode.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppsChannel(this).register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
