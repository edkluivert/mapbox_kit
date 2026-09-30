part of '../mapbox_kit.dart';

/// Class for Mapbox SDK settings management
final class MapboxOptions {
  /// The access token that is used to access resources provided by Mapbox services.
  static Future<String> getAccessToken() async =>
      await _NativeChannel.invoke('options#getAccessToken') as String;

  /// The access token that is used to access resources provided by Mapbox services.
  ///
  /// Set it before the first [MapWidget] is built.
  static void setAccessToken(String token) {
    _NativeChannel.invoke('options#setAccessToken', {'token': token})
        .catchError((Object e) => mapboxKitLog('setAccessToken failed: $e'));
  }
}

/// Configurations for the external resources that are used by Maps API object,
/// such as maps data directory and base URL.
///
/// The resource options changes are taken into consideration by the Maps API objects during their construction phase.
/// Any changes made to the resource options during runtime will not impact objects that have already been created.
final class MapboxMapsOptions {
  MapboxMapsOptions._();

  static Future<T> _get<T>(String method) async =>
      await _NativeChannel.invoke('options#$method') as T;

  static void _set(String method, Map<String, dynamic> args) {
    _NativeChannel.invoke('options#$method', args)
        .catchError((Object e) => mapboxKitLog('$method failed: $e'));
  }

  /// The base URL that would be used by the Maps engine to make HTTP requests.
  /// By default the engine uses the base URL `https://api.mapbox.com`
  static Future<String> getBaseUrl() => _get('getBaseUrl');

  /// The base URL that would be used by the Maps engine to make HTTP requests.
  static void setBaseUrl(String url) => _set('setBaseUrl', {'url': url});

  /// The path to the Maps data folder.
  static Future<String> getDataPath() => _get('getDataPath');

  /// The path to the Maps data folder.
  static void setDataPath(String path) => _set('setDataPath', {'path': path});

  /// The path to the Maps asset folder. Default is application's main bundle path.
  /// This option is ignored for Android platform.
  static Future<String> getAssetPath() => _get('getAssetPath');

  /// The path to the Maps asset folder. Ignored on Android.
  static void setAssetPath(String path) =>
      _set('setAssetPath', {'path': path});

  /// The tile store usage mode for the Maps API objects. Default is `readOnly`.
  static Future<TileStoreUsageMode> getTileStoreUsageMode() async =>
      _enumFromIndex(
          TileStoreUsageMode.values, await _get<int>('getTileStoreUsageMode')) ??
      TileStoreUsageMode.READ_ONLY;

  /// The tile store usage mode for the Maps API objects.
  static void setTileStoreUsageMode(TileStoreUsageMode mode) =>
      _set('setTileStoreUsageMode', {'mode': mode.index});

  /// Current worldview preference for Mapbox products, as a ISO 3166-1 alpha-2 country code.
  @experimental
  static Future<String?> getWorldview() => _get('getWorldview');

  /// Set preferred worldview for Mapbox products as a ISO 3166-1 alpha-2 country code.
  @experimental
  static void setWorldview(String? worldview) =>
      _set('setWorldview', {'worldview': worldview});

  /// Current language preference for Mapbox products, as a bcp-47 tag.
  @experimental
  static Future<String?> getLanguage() => _get('getLanguage');

  /// Set preferred language for Mapbox products with a bcp-47 tag.
  @experimental
  static void setLanguage(String? language) =>
      _set('setLanguage', {'language': language});

  /// Clears temporary map data from the data path.
  static Future<void> clearData() => _get('clearData');
}
