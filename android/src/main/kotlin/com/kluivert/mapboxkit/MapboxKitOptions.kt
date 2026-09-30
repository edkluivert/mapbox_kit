package com.kluivert.mapboxkit

import com.mapbox.bindgen.Value
import com.mapbox.common.MapboxCommonSettings
import com.mapbox.common.MapboxOptions
import com.mapbox.common.SettingsServiceFactory
import com.mapbox.common.SettingsServiceStorageType
import com.mapbox.maps.MapboxMap
import com.mapbox.maps.MapboxMapsOptions
import com.mapbox.maps.TileStoreUsageMode
import org.json.JSONObject

/** options#... calls: process-wide Mapbox settings. */
object MapboxKitOptions {
    private val settings by lazy { SettingsServiceFactory.getInstance(SettingsServiceStorageType.PERSISTENT) }

    fun invoke(method: String, a: JSONObject, reply: Reply): Int {
        when (method) {
            "getAccessToken" -> reply.run { MapboxOptions.accessToken }
            "setAccessToken" -> reply.run { MapboxOptions.accessToken = a.optString("token"); null }
            "getBaseUrl" -> reply.run { MapboxMapsOptions.baseUrl }
            "setBaseUrl" -> reply.run { MapboxMapsOptions.baseUrl = a.optString("url"); null }
            "getDataPath" -> reply.run { MapboxMapsOptions.dataPath }
            "setDataPath" -> reply.run { MapboxMapsOptions.dataPath = a.optString("path"); null }
            "getAssetPath" -> reply.run { "" }
            "setAssetPath" -> reply.run { null } // ignored on Android
            "getTileStoreUsageMode" -> reply.run { MapboxMapsOptions.tileStoreUsageMode.ordinal }
            "setTileStoreUsageMode" -> reply.run {
                MapboxMapsOptions.tileStoreUsageMode = TileStoreUsageMode.values()[a.optInt("mode", 1).coerceIn(0, 2)]
                null
            }
            "getWorldview" -> reply.run { settings.get(MapboxCommonSettings.WORLDVIEW).value?.contents as? String }
            "setWorldview" -> reply.run {
                val v = a.optStringOrNull("worldview")
                if (v != null) settings.set(MapboxCommonSettings.WORLDVIEW, Value.valueOf(v)) else settings.erase(MapboxCommonSettings.WORLDVIEW)
                null
            }
            "getLanguage" -> reply.run { settings.get(MapboxCommonSettings.LANGUAGE).value?.contents as? String }
            "setLanguage" -> reply.run {
                val v = a.optStringOrNull("language")
                if (v != null) settings.set(MapboxCommonSettings.LANGUAGE, Value.valueOf(v)) else settings.erase(MapboxCommonSettings.LANGUAGE)
                null
            }
            "clearData" -> MapboxMap.clearData { expected ->
                if (expected.isError) reply.error("clearDataError", expected.error, null) else reply.success(null)
            }
            else -> return 2
        }
        return 0
    }
}
