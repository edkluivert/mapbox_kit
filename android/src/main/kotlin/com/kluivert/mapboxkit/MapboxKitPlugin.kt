package com.kluivert.mapboxkit

import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Plugin entry point, registered automatically through the pubspec
 * `pluginClass`. Loads libmapbox_kit.so (the one call site that fires
 * JNI_OnLoad) and registers the map view provider with the framework.
 */
class MapboxKitPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        try {
            System.loadLibrary("mapbox_kit")
        } catch (e: UnsatisfiedLinkError) {
            Log.e("MapboxKit", "Failed to load libmapbox_kit.so: ${e.message}")
        }
        MapboxKitBridge.register()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        MapboxKitBridge.resetAll()
    }
}
