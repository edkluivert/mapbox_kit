// options#... calls: process-wide Mapbox settings.

import Foundation
import MapboxMaps
import MapboxCommon

enum MapboxKitOptions {
    private static let settings = SettingsServiceFactory.getInstanceFor(.persistent)

    static func invoke(method: String, arguments a: JSON, reply: Reply) -> Int32 {
        switch method {
        case "getAccessToken":
            reply.run { MapboxOptions.accessToken }
        case "setAccessToken":
            reply.run { MapboxOptions.accessToken = str(a["token"]) ?? ""; return nil }
        case "getBaseUrl":
            reply.run { MapboxMapsOptions.baseURL.absoluteString }
        case "setBaseUrl":
            reply.run {
                guard let url = URL(string: str(a["url"]) ?? "") else { throw MapboxKitError("Invalid url") }
                MapboxMapsOptions.baseURL = url
                return nil
            }
        case "getDataPath":
            reply.run { MapboxMapsOptions.dataPath.absoluteString }
        case "setDataPath":
            reply.run {
                guard let url = URL(string: str(a["path"]) ?? "") else { throw MapboxKitError("Invalid url") }
                MapboxMapsOptions.dataPath = url
                return nil
            }
        case "getAssetPath":
            reply.run { MapboxMapsOptions.assetPath.absoluteString }
        case "setAssetPath":
            reply.run {
                guard let url = URL(string: str(a["path"]) ?? "") else { throw MapboxKitError("Invalid url") }
                MapboxMapsOptions.assetPath = url
                return nil
            }
        case "getTileStoreUsageMode":
            reply.run { MapboxMapsOptions.tileStoreUsageMode.rawValue }
        case "setTileStoreUsageMode":
            reply.run {
                guard let mode = TileStoreUsageMode(rawValue: int(a["mode"]) ?? 1) else { throw MapboxKitError("Invalid mode") }
                MapboxMapsOptions.tileStoreUsageMode = mode
                return nil
            }
        case "getWorldview":
            reply.run { try? settings.get(key: MapboxCommonSettings.worldview, type: String.self).get() }
        case "setWorldview":
            reply.run { _ = settings.set(key: MapboxCommonSettings.worldview, value: str(a["worldview"])); return nil }
        case "getLanguage":
            reply.run { try? settings.get(key: MapboxCommonSettings.language, type: String.self).get() }
        case "setLanguage":
            reply.run { _ = settings.set(key: MapboxCommonSettings.language, value: str(a["language"])); return nil }
        case "perfReport":
            reply.run { MapboxKitPerf.report() }
        case "clearData":
            MapboxMap.clearData { error in
                if let error { reply.error(error) } else { reply.success(nil) }
            }
        default:
            return 2
        }
        return 0
    }
}
