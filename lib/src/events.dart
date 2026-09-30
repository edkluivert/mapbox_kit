// Map event payloads. Ported from mapbox_maps_flutter 2.31.0 (BSD-3, Mapbox).

part of '../mapbox_kit.dart';

/// The time interval of an event. The `begin` property represents the time
/// origin of an event, and the `end` property represents the time when the particular
/// operation is complete.
class EventTimeInterval {
  /// Representing timestamp taken at the time of an event creation; in microseconds; since the epoch.
  final DateTime begin;

  /// Timestamp taken at the time of an event completion.
  final DateTime end;

  EventTimeInterval.fromJson(Map<String, dynamic> json)
      : begin = DateTime.fromMicrosecondsSinceEpoch(_asInt(json['begin']) ?? 0),
        end = DateTime.fromMicrosecondsSinceEpoch(_asInt(json['end']) ?? 0);

  @override
  String toString() {
    return "EventTimeInterval begin: $begin, end: $end";
  }
}

/// The class for camera-changed event in Observer
class CameraChangedEventData {
  /// The time when the camera was changed.
  final int timestamp;

  /// The current state of the camera.
  final CameraState cameraState;

  CameraChangedEventData.fromJson(Map<String, dynamic> json)
      : timestamp = _asInt(json['timestamp']) ?? 0,
        cameraState = Conversion.fromJson(_requireMap(json['cameraState']));
}

/// The class for map-idle event in Observer
class MapIdleEventData {
  /// The timestamp of the `MapIdle` event.
  final int timestamp;

  MapIdleEventData.fromJson(Map<String, dynamic> json)
      : timestamp = _asInt(json['timestamp']) ?? 0;
}

/// The class for map-loaded event in Observer
class MapLoadedEventData {
  /// The `timeInterval.begin` represents the time when a style is set, and the
  /// `timeInterval.end` is taken when the `map` is fully loaded.
  final EventTimeInterval timeInterval;

  MapLoadedEventData.fromJson(Map<String, dynamic> json)
      : timeInterval = EventTimeInterval.fromJson(_requireMap(json['timeInterval']));
}

/// The class for map-loading-error event in Observer
class MapLoadingErrorEventData {
  /// Defines what resource could not be loaded.
  final MapLoadErrorType type;

  /// The descriptive error message of the error.
  final String message;

  /// In case of `source` or `tile` loading errors; `source-id` will contain the id of the source failing.
  final String? sourceId;

  /// In case of `tile` loading errors; `tile-id` will contain the id of the tile.
  final TileID? tileId;

  /// The timestamp of the `MapLoadingError` event.
  final int timestamp;

  MapLoadingErrorEventData.fromJson(Map<String, dynamic> json)
      : type = _enumFromIndex(MapLoadErrorType.values, json['type']) ??
            MapLoadErrorType.STYLE,
        message = json['message']?.toString() ?? '',
        sourceId = json['sourceId'] as String?,
        tileId = json['tileId'] != null
            ? TileID.fromJson(_requireMap(json['tileId']))
            : null,
        timestamp = _asInt(json['timestamp']) ?? 0;
}

/// The class for render-frame-finished event in Observer
class RenderFrameFinishedEventData {
  /// The `timeInterval.begin` is when the `map` started rendering the frame, and
  /// `timeInterval.end` is when the frame was rendered.
  final EventTimeInterval timeInterval;

  /// The render-mode value tells whether the Map has all {"full"} required to render the visible viewport.
  final RenderMode renderMode;

  /// The needs-repaint value provides information about ongoing transitions that trigger Map repaint.
  final bool needsRepaint;

  /// The placement-changed value tells if the symbol placement has been changed in the visible viewport.
  final bool placementChanged;

  RenderFrameFinishedEventData.fromJson(Map<String, dynamic> json)
      : timeInterval = EventTimeInterval.fromJson(_requireMap(json['timeInterval'])),
        renderMode = _enumFromIndex(RenderMode.values, json['renderMode']) ??
            RenderMode.PARTIAL,
        placementChanged = json['placementChanged'] == true,
        needsRepaint = json['needsRepaint'] == true;
}

/// Describes whether a map or frame has been fully rendered or not.
enum RenderMode {
  /// The map is partially rendered.
  PARTIAL,

  /// The map is fully rendered.
  FULL
}

/// The class for render-frame-started event in Observer
class RenderFrameStartedEventData {
  /// The timestamp of an event when the `map` started rendering the frame.
  final int timestamp;

  RenderFrameStartedEventData.fromJson(Map<String, dynamic> json)
      : timestamp = _asInt(json['timestamp']) ?? 0;
}

///The class for event in Observer
class ResourceEventData {
  /// The timestamps of the resource request event.
  final EventTimeInterval timeInterval;

  /// The type of data source from which the resource is requested.
  final DataSourceType dataSource;

  /// "request" property
  final Request request;

  /// "response" property
  final Response? response;

  /// "cancelled" property
  final bool cancelled;

  ResourceEventData.fromJson(Map<String, dynamic> json)
      : timeInterval = EventTimeInterval.fromJson(_requireMap(json['timeInterval'])),
        dataSource = _enumFromIndex(DataSourceType.values, json['source']) ??
            DataSourceType.NETWORK,
        request = Request.fromJson(_requireMap(json['request'])),
        response = json['response'] != null
            ? Response.fromJson(_requireMap(json['response']))
            : null,
        cancelled = json['cancelled'] == true;
}

/// Describes data source of request for resource-request event.
enum DataSourceType {
  /// data source as asset.
  ASSET,

  /// data source as database.
  DATABASE,

  /// data source as file-system.
  FILE_SYSTEM,

  /// data source as network.
  NETWORK,

  /// data source as resource-loader.
  RESOURCE_LOADER,
}

/// The class for source-added event in Observer
class SourceAddedEventData {
  /// The timestamp of source addition.
  final int timestamp;

  /// The ID of the added source.
  final String id;

  SourceAddedEventData.fromJson(Map<String, dynamic> json)
      : id = json['sourceId']?.toString() ?? '',
        timestamp = _asInt(json['timestamp']) ?? 0;
}

/// The class for source-data-loaded event in Observer
class SourceDataLoadedEventData {
  /// The 'id' property defines the source id.
  final String id;

  /// The 'type' property defines if source's meta{e.g.; TileJSON} or tile has been loaded.
  final SourceDataType type;

  /// The 'loaded' property will be set to 'true' if all source's required for Map's visible viewport; are loaded.
  final bool? loaded;

  /// The 'tile-id' property defines the tile id if the 'type' field equals 'tile'.
  final TileID? tileID;

  /// The data identifier provided to `setStyleGeoJSONSourceData`, when any.
  final String? dataId;

  /// The `timeInterval.begin` is when source data begins loading, and the `timeInterval.end` is when source data is loaded.
  final EventTimeInterval timeInterval;

  SourceDataLoadedEventData.fromJson(Map<String, dynamic> json)
      : id = json['sourceId']?.toString() ?? '',
        type = _enumFromIndex(SourceDataType.values, json['type']) ??
            SourceDataType.METADATA,
        loaded = json['loaded'] as bool?,
        tileID = json['tileId'] != null
            ? TileID.fromJson(_requireMap(json['tileId']))
            : null,
        dataId = json['dataId'] as String?,
        timeInterval = EventTimeInterval.fromJson(_requireMap(json['timeInterval']));
}

/// The class for source-removed event in Observer
class SourceRemovedEventData {
  /// The timestamp of source removal.
  final int timestamp;

  /// The ID of the removal source.
  final String id;

  SourceRemovedEventData.fromJson(Map<String, dynamic> json)
      : id = json['sourceId']?.toString() ?? '',
        timestamp = _asInt(json['timestamp']) ?? 0;
}

/// The class for style-data-loaded event in Observer
class StyleDataLoadedEventData {
  /// The `timeInterval.begin` is when style data begins loading, and the `timeInterval.end` is when style data is loaded.
  final EventTimeInterval timeInterval;

  /// The 'type' property defines what kind of style has been loaded.
  final StyleDataType type;

  StyleDataLoadedEventData.fromJson(Map<String, dynamic> json)
      : type = _enumFromIndex(StyleDataType.values, json['type']) ??
            StyleDataType.STYLE,
        timeInterval = EventTimeInterval.fromJson(_requireMap(json['timeInterval']));
}

/// The class for style-image-missing event in Observer
class StyleImageMissingEventData {
  /// The timestamp of an event when the `map` requested a missing image.
  final int timestamp;

  /// The ID of the missing image.
  final String id;

  StyleImageMissingEventData.fromJson(Map<String, dynamic> json)
      : timestamp = _asInt(json['timestamp']) ?? 0,
        id = json['imageId']?.toString() ?? '';
}

/// The class for style-image-remove-unused event in Observer
class StyleImageUnusedEventData {
  /// The timestamp of an event when the `map` no longer needs a previously added image.
  final int timestamp;

  /// The identifier of an image that is not used by the `map`.
  final String id;

  StyleImageUnusedEventData.fromJson(Map<String, dynamic> json)
      : timestamp = _asInt(json['timestamp']) ?? 0,
        id = json['imageId']?.toString() ?? '';
}

/// The class for style-loaded event in Observer
class StyleLoadedEventData {
  /// The `timeInterval.begin` is when the style begins loading, and the `timeInterval.end` is when the style is loaded.
  final EventTimeInterval timeInterval;

  StyleLoadedEventData.fromJson(Map<String, dynamic> json)
      : timeInterval = EventTimeInterval.fromJson(_requireMap(json['timeInterval']));
}

/// Describes an error type while loading the map.
enum MapLoadErrorType {
  /// An error related to style.
  STYLE,

  /// An error related to sprite.
  SPRITE,

  /// An error related to source.
  SOURCE,

  /// An error related to glyphs.
  GLYPHS,

  /// An error related to tile.
  TILE
}

/// Defines what kind of style data has been loaded in a style-data-loaded event.
enum StyleDataType {
  /// The style data loaded event is associated with style.
  STYLE,

  /// The style data loaded event is associated with sprite.
  SPRITE,

  /// The style data loaded event is associated with sources.
  SOURCES
}

/// Defines what kind of source data has been loaded in a source-data-loaded event.
enum SourceDataType {
  /// The source data loaded event is associated with source metadata.
  METADATA,

  /// The source data loaded event is associated with source tile.
  TILE
}

/// Defines the tile id in a source-data-loaded event.
class TileID {
  /// The zoom level.
  final int z;

  /// The x coordinate of the tile
  final int x;

  /// The y coordinate of the tile
  final int y;

  TileID.fromJson(Map<String, dynamic> json)
      : x = _asInt(json['x']) ?? 0,
        y = _asInt(json['y']) ?? 0,
        z = _asInt(json['z']) ?? 0;

  dynamic toMap() => <String, dynamic>{'x': x, 'y': y, 'z': z};
}

///The data class for error in Observer
class Error {
  /// "reason" property
  final ResponseErrorReason reason;

  /// "message" property
  final String message;

  Error.fromJson(Map<String, dynamic> json)
      : reason = _enumFromIndex(ResponseErrorReason.values, json['reason']) ??
            ResponseErrorReason.OTHER,
        message = json['message']?.toString() ?? '';
}

/// The response data class that included in EventData
class Response {
  /// "etag" property
  final String? eTag;

  /// "must-revalidate" property
  final bool mustRevalidate;

  /// "no-content" property
  final bool noContent;

  /// "modified" property
  final DateTime? modified;

  /// "source" property
  final ResponseSourceType source;

  /// "notModified" property
  final bool notModified;

  /// "expires" property
  final DateTime? expires;

  /// "size" property
  final int size;

  /// "error" property
  final Error? error;

  Response.fromJson(Map<String, dynamic> json)
      : eTag = json['etag'] as String?,
        mustRevalidate = json['mustRevalidate'] == true,
        noContent = json['noContent'] == true,
        modified = json['modified'] != null
            ? DateTime.fromMicrosecondsSinceEpoch(_asInt(json['modified'])!)
            : null,
        source = _enumFromIndex(ResponseSourceType.values, json['source']) ??
            ResponseSourceType.NETWORK,
        notModified = json['notModified'] == true,
        expires = json['expires'] != null
            ? DateTime.fromMicrosecondsSinceEpoch(_asInt(json['expires'])!)
            : null,
        size = _asInt(json['size']) ?? 0,
        error = json['error'] != null
            ? Error.fromJson(_requireMap(json['error']))
            : null;
}

/// Describes source data type for response in resource-request event.
enum ResponseSourceType {
  /// source type as network.
  NETWORK,

  /// source type as cache.
  CACHE,

  /// source type as tile-store.
  TILE_STORE,

  /// source type as local-file.
  LOCAL_FILE,
}

/// The enumeration defines the method used to make a resource request.
enum RequestLoadingMethodType {
  /// The engine should try loading a resource from the network.
  NETWORK,

  /// The engine should try loading a resource from the cache.
  CACHE
}

/// The request data class that included in EventData
class Request {
  /// "loading-method" property
  final List<RequestLoadingMethodType> loadingMethod;

  /// "url" property
  final String url;

  /// The type of a requested resource
  final RequestType kind;

  /// "priority" property
  final RequestPriority priority;

  Request.fromJson(Map<String, dynamic> json)
      : loadingMethod = ((json['loadingMethod'] as List?) ?? const [])
            .map((e) => _enumFromIndex(RequestLoadingMethodType.values, e))
            .whereType<RequestLoadingMethodType>()
            .toList(),
        url = json['url']?.toString() ?? '',
        kind = _enumFromIndex(RequestType.values, json['resource']) ??
            RequestType.UNKNOWN,
        priority = _enumFromIndex(RequestPriority.values, json['priority']) ??
            RequestPriority.REGULAR;
}

/// Describes type for request object.
enum RequestType {
  /// Request type unknown.
  UNKNOWN,

  /// Request type style.
  STYLE,

  /// Request type source.
  SOURCE,

  /// Request type tile.
  TILE,

  /// Request type glyphs.
  GLYPHS,

  /// Request type sprite-image.
  SPRITE_IMAGE,

  /// Request type sprite-json.
  SPRITE_JSON,

  /// Request type image.
  IMAGE,

  /// The resource type is a 3D model.
  MODEL
}

/// Describes priority for request object.
enum RequestPriority {
  /// Regular priority.
  REGULAR,

  /// low priority.
  LOW
}
