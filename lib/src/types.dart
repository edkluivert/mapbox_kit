// Data types of the map, camera and style APIs.
// Ported from mapbox_maps_flutter 2.31.0 (pigeon-generated; BSD-3, Mapbox),
// with JSON codecs in place of the pigeon message codec.

part of '../mapbox_kit.dart';

/// Describes the glyphs rasterization option values.
enum GlyphsRasterizationMode {
  /// No glyphs are rasterized locally. All glyphs are loaded from the server.
  NO_GLYPHS_RASTERIZED_LOCALLY,

  /// Ideographs are rasterized locally, and they are not loaded from the server.
  IDEOGRAPHS_RASTERIZED_LOCALLY,

  /// All glyphs are rasterized locally. No glyphs are loaded from the server.
  ALL_GLYPHS_RASTERIZED_LOCALLY,
}

/// Describes the map context mode.
enum ContextMode {
  /// Unique context mode: the GL context is not shared.
  UNIQUE,

  /// Shared context mode: the GL context is shared with other renderers.
  SHARED,
}

/// Describes whether to constrain the map in both axes or only vertically e.g. while panning.
enum ConstrainMode {
  /// No constrains.
  NONE,

  /// Constrain to height only
  HEIGHT_ONLY,

  /// Constrain both width and height axes.
  WIDTH_AND_HEIGHT,
}

/// Satisfies embedding platforms that requires the viewport coordinate systems to be set according to its standards.
enum ViewportMode {
  /// Default viewport
  DEFAULT,

  /// Viewport flipped on the y-axis.
  FLIPPED_Y,
}

/// Describes the map orientation.
enum NorthOrientation {
  /// Default, map oriented upwards
  UPWARDS,

  /// Map oriented rightwards
  RIGHTWARDS,

  /// Map oriented downwards
  DOWNWARDS,

  /// Map oriented leftwards
  LEFTWARDS,
}

enum _MapWidgetDebugOptions {
  tileBorders,
  parseStatus,
  timestamps,
  collision,
  overdraw,
  stencilClip,
  depthBuffer,
  modelBounds,
  terrainWireframe,
  layers2DWireframe,
  layers3DWireframe,
  light,
  camera,
  padding,
}

/// Options for enabling debugging features in a map.
enum MapDebugOptionsData {
  /// Edges of tile boundaries are shown as thick, red lines.
  TILE_BORDERS,

  /// Each tile shows its tile coordinate (x/y/z) in the upper-left corner.
  PARSE_STATUS,

  /// Each tile shows a timestamp indicating when it was loaded.
  TIMESTAMPS,

  /// Edges of glyphs and symbols are shown as faint, green lines.
  COLLISION,

  /// Each drawing operation is replaced by a translucent fill.
  OVERDRAW,

  /// The stencil buffer is shown instead of the color buffer.
  STENCIL_CLIP,

  /// The depth buffer is shown instead of the color buffer.
  DEPTH_BUFFER,

  /// Visualize residency of tiles in the render cache.
  RENDER_CACHE,

  /// Show 3D model bounding boxes.
  MODEL_BOUNDS,

  /// Show a wireframe for terrain.
  TERRAIN_WIREFRAME,
}

/// Type information of the variant's content
enum Type {
  SCREEN_BOX,
  SCREEN_COORDINATE,
  LIST,
}

/// Describes tile store usage modes.
enum TileStoreUsageMode {
  /// Tile store usage is disabled.
  DISABLED,

  /// Tile store enabled for accessing loaded tile packs.
  READ_ONLY,

  /// Tile store enabled for accessing local tile packs and for loading new tile packs from server.
  READ_AND_UPDATE,
}

/// Describes the reason for an offline request response error.
enum ResponseErrorReason {
  /// No error occurred during the resource request.
  SUCCESS,

  /// The resource is not found.
  NOT_FOUND,

  /// The server error.
  SERVER,

  /// The connection error.
  CONNECTION,

  /// The error happened because of a rate limit.
  RATE_LIMIT,

  /// The resource cannot be loaded because the device is in offline mode.
  IN_OFFLINE_MODE,

  /// Other reason.
  OTHER,
}

enum StyleProjectionName {
  mercator,
  globe,
}

/// Whether extruded geometries are lit relative to the map or viewport.
enum Anchor {
  /// The position of the light source is aligned to the rotation of the map.
  MAP,

  /// The position of the light source is aligned to the rotation of the viewport.
  VIEWPORT,
}

enum _MapEvent {
  mapLoaded,
  mapLoadingError,
  styleLoaded,
  styleDataLoaded,
  cameraChanged,
  mapIdle,
  sourceAdded,
  sourceRemoved,
  sourceDataLoaded,
  styleImageMissing,
  styleImageRemoveUnused,
  renderFrameStarted,
  renderFrameFinished,
  resourceRequest,
}

/// Describes the glyphs rasterization option values.
class GlyphsRasterizationOptions {
  GlyphsRasterizationOptions({
    required this.rasterizationMode,
    this.fontFamily,
  });

  /// Glyphs rasterization mode for client-side text rendering.
  GlyphsRasterizationMode rasterizationMode;

  /// Font family to use as font fallback for client-side text renderings.
  String? fontFamily;

  Map<String, dynamic> toJson() => {
        'rasterizationMode': rasterizationMode.index,
        'fontFamily': fontFamily,
      };

  static GlyphsRasterizationOptions fromJson(Map<String, dynamic> json) =>
      GlyphsRasterizationOptions(
        rasterizationMode: _enumFromIndex(
                GlyphsRasterizationMode.values, json['rasterizationMode']) ??
            GlyphsRasterizationMode.NO_GLYPHS_RASTERIZED_LOCALLY,
        fontFamily: json['fontFamily'] as String?,
      );
}

class TileCoverOptions {
  TileCoverOptions({
    this.tileSize,
    this.minZoom,
    this.maxZoom,
    this.roundZoom,
  });

  /// Tile size of the source. Defaults to 512.
  int? tileSize;

  /// Min zoom defined in the source between range [0, 22].
  int? minZoom;

  /// Max zoom defined in the source between range [0, 22].
  int? maxZoom;

  /// Whether to round zoom values when calculating tilecover.
  bool? roundZoom;

  Map<String, dynamic> toJson() => {
        'tileSize': tileSize,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'roundZoom': roundZoom,
      };
}

/// Padding around the interior of the view, in logical pixels.
class MbxEdgeInsets {
  MbxEdgeInsets({
    required this.top,
    required this.left,
    required this.bottom,
    required this.right,
  });

  /// Padding from the top.
  double top;

  /// Padding from the left.
  double left;

  /// Padding from the bottom.
  double bottom;

  /// Padding from the right.
  double right;

  Map<String, dynamic> toJson() =>
      {'top': top, 'left': left, 'bottom': bottom, 'right': right};

  static MbxEdgeInsets fromJson(Map<String, dynamic> json) => MbxEdgeInsets(
        top: _asDouble(json['top']) ?? 0,
        left: _asDouble(json['left']) ?? 0,
        bottom: _asDouble(json['bottom']) ?? 0,
        right: _asDouble(json['right']) ?? 0,
      );
}

/// Various options for describing the viewpoint of a camera.
class CameraOptions {
  CameraOptions({
    this.center,
    this.padding,
    this.anchor,
    this.zoom,
    this.bearing,
    this.pitch,
  });

  /// Coordinate at the center of the camera.
  Point? center;

  /// Padding around the interior of the view that affects the frame of
  /// reference for `center`.
  MbxEdgeInsets? padding;

  /// Point of reference for `zoom` and `angle`, assuming an origin at the
  /// top-left corner of the view.
  ScreenCoordinate? anchor;

  /// Zero-based zoom level. Constrained to the minimum and maximum zoom
  /// levels.
  double? zoom;

  /// Bearing, measured in degrees from true north. Wrapped to [0, 360).
  double? bearing;

  /// Pitch toward the horizon measured in degrees.
  double? pitch;

  Map<String, dynamic> toJson() => {
        'center': center?.toJson(),
        'padding': padding?.toJson(),
        'anchor': anchor?.toJson(),
        'zoom': zoom,
        'bearing': bearing,
        'pitch': pitch,
      };

  static CameraOptions fromJson(Map<String, dynamic> json) => CameraOptions(
        center: _asMap(json['center']) == null
            ? null
            : Point.fromJson(_asMap(json['center'])!),
        padding: _asMap(json['padding']) == null
            ? null
            : MbxEdgeInsets.fromJson(_asMap(json['padding'])!),
        anchor: _asMap(json['anchor']) == null
            ? null
            : ScreenCoordinate.fromJson(_asMap(json['anchor'])!),
        zoom: _asDouble(json['zoom']),
        bearing: _asDouble(json['bearing']),
        pitch: _asDouble(json['pitch']),
      );
}

/// Describes the viewpoint of a camera.
class CameraState {
  CameraState({
    required this.center,
    required this.padding,
    required this.zoom,
    required this.bearing,
    required this.pitch,
  });

  /// Coordinate at the center of the camera.
  Point center;

  /// Padding around the interior of the view that affects the frame of
  /// reference for `center`.
  MbxEdgeInsets padding;

  /// Zero-based zoom level. Constrained to the minimum and maximum zoom
  /// levels.
  double zoom;

  /// Bearing, measured in degrees from true north. Wrapped to [0, 360).
  double bearing;

  /// Pitch toward the horizon measured in degrees.
  double pitch;

  Map<String, dynamic> toJson() => {
        'center': center.toJson(),
        'padding': padding.toJson(),
        'zoom': zoom,
        'bearing': bearing,
        'pitch': pitch,
      };
}

/// Holds options to be used for setting `camera bounds`.
class CameraBoundsOptions {
  CameraBoundsOptions({
    this.bounds,
    this.maxZoom,
    this.minZoom,
    this.maxPitch,
    this.minPitch,
  });

  /// The latitude and longitude bounds to which the camera center are constrained.
  CoordinateBounds? bounds;

  /// The maximum zoom level, in Mapbox zoom levels 0-25.5.
  double? maxZoom;

  /// The minimum zoom level, in Mapbox zoom levels 0-25.5.
  double? minZoom;

  /// The maximum allowed pitch value in degrees.
  double? maxPitch;

  /// The minimum allowed pitch value in degrees.
  double? minPitch;

  Map<String, dynamic> toJson() => {
        'bounds': bounds?.toJson(),
        'maxZoom': maxZoom,
        'minZoom': minZoom,
        'maxPitch': maxPitch,
        'minPitch': minPitch,
      };
}

/// Holds information about `camera bounds`.
class CameraBounds {
  CameraBounds({
    required this.bounds,
    required this.maxZoom,
    required this.minZoom,
    required this.maxPitch,
    required this.minPitch,
  });

  /// The latitude and longitude bounds to which the camera center are constrained.
  CoordinateBounds bounds;

  /// The maximum zoom level, in Mapbox zoom levels 0-25.5.
  double maxZoom;

  /// The minimum zoom level, in Mapbox zoom levels 0-25.5.
  double minZoom;

  /// The maximum allowed pitch value in degrees.
  double maxPitch;

  /// The minimum allowed pitch value in degrees.
  double minPitch;

  static CameraBounds fromJson(Map<String, dynamic> json) => CameraBounds(
        bounds: CoordinateBounds.fromJson(_requireMap(json['bounds'])),
        maxZoom: _asDouble(json['maxZoom']) ?? 22,
        minZoom: _asDouble(json['minZoom']) ?? 0,
        maxPitch: _asDouble(json['maxPitch']) ?? 85,
        minPitch: _asDouble(json['minPitch']) ?? 0,
      );
}

/// Options for a camera animation.
class MapAnimationOptions {
  MapAnimationOptions({
    this.duration,
    this.startDelay,
  });

  /// The duration of the animation in milliseconds.
  /// If not set explicitly default duration will be taken 300ms
  int? duration;

  /// The amount of time, in milliseconds, to delay starting the animation after animation start.
  /// If not set explicitly default startDelay will be taken 0ms. This only works for Android.
  int? startDelay;

  Map<String, dynamic> toJson() =>
      {'duration': duration, 'startDelay': startDelay};
}

/// A rectangular area as measured on a two-dimensional map projection.
class CoordinateBounds {
  CoordinateBounds({
    required this.southwest,
    required this.northeast,
    required this.infiniteBounds,
  });

  /// Coordinate at the southwest corner.
  Point southwest;

  /// Coordinate at the northeast corner.
  Point northeast;

  /// If set to `true`, an infinite (unconstrained) bounds covering the world coordinates would be used.
  bool infiniteBounds;

  Map<String, dynamic> toJson() => {
        'southwest': southwest.toJson(),
        'northeast': northeast.toJson(),
        'infiniteBounds': infiniteBounds,
      };

  static CoordinateBounds fromJson(Map<String, dynamic> json) =>
      CoordinateBounds(
        southwest: Point.fromJson(_requireMap(json['southwest'])),
        northeast: Point.fromJson(_requireMap(json['northeast'])),
        infiniteBounds: json['infiniteBounds'] == true,
      );
}

/// Options for enabling debugging features in a map.
class MapDebugOptions {
  MapDebugOptions({required this.data});

  MapDebugOptionsData data;

  Map<String, dynamic> toJson() => {'data': data.index};
}

class TileCacheBudgetInMegabytes {
  TileCacheBudgetInMegabytes({required this.size});

  int size;

  Map<String, dynamic> toJson() => {'size': size};
}

class TileCacheBudgetInTiles {
  TileCacheBudgetInTiles({required this.size});

  int size;

  Map<String, dynamic> toJson() => {'size': size};
}

/// Describes the map option values.
class MapOptions {
  MapOptions({
    this.contextMode,
    this.constrainMode,
    this.viewportMode,
    this.orientation,
    this.crossSourceCollisions,
    this.size,
    required this.pixelRatio,
    this.glyphsRasterizationOptions,
  });

  /// The map context mode.
  ContextMode? contextMode;

  /// The map constrain mode. By default, it is set to `HeightOnly`.
  ConstrainMode? constrainMode;

  /// The viewport mode.
  ViewportMode? viewportMode;

  /// The orientation of the Map. By default, it is set to `Upwards`.
  NorthOrientation? orientation;

  /// Specify whether to enable cross-source symbol collision detection
  /// or not. By default, it is set to `true`.
  bool? crossSourceCollisions;

  /// The size to resize the map object and renderer backend, in logical pixels.
  Size? size;

  /// The custom pixel ratio. By default, it is set to 1.0
  double pixelRatio;

  /// Glyphs rasterization options to use for client-side text rendering.
  GlyphsRasterizationOptions? glyphsRasterizationOptions;

  Map<String, dynamic> toJson() => {
        'contextMode': contextMode?.index,
        'constrainMode': constrainMode?.index,
        'viewportMode': viewportMode?.index,
        'orientation': orientation?.index,
        'crossSourceCollisions': crossSourceCollisions,
        'size': size?.toJson(),
        'pixelRatio': pixelRatio,
        'glyphsRasterizationOptions': glyphsRasterizationOptions?.toJson(),
      };

  static MapOptions fromJson(Map<String, dynamic> json) => MapOptions(
        contextMode: _enumFromIndex(ContextMode.values, json['contextMode']),
        constrainMode:
            _enumFromIndex(ConstrainMode.values, json['constrainMode']),
        viewportMode: _enumFromIndex(ViewportMode.values, json['viewportMode']),
        orientation:
            _enumFromIndex(NorthOrientation.values, json['orientation']),
        crossSourceCollisions: json['crossSourceCollisions'] as bool?,
        size: _asMap(json['size']) == null
            ? null
            : Size.fromJson(_asMap(json['size'])!),
        pixelRatio: _asDouble(json['pixelRatio']) ?? 1.0,
        glyphsRasterizationOptions:
            _asMap(json['glyphsRasterizationOptions']) == null
                ? null
                : GlyphsRasterizationOptions.fromJson(
                    _asMap(json['glyphsRasterizationOptions'])!),
      );
}

/// Describes the coordinate on the screen, measured from top to bottom and from left to right.
/// Note: the `map` uses screen coordinate units measured in `logical pixels`.
class ScreenCoordinate {
  ScreenCoordinate({required this.x, required this.y});

  /// A value representing the x position of this coordinate.
  double x;

  /// A value representing the y position of this coordinate.
  double y;

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  static ScreenCoordinate fromJson(Map<String, dynamic> json) =>
      ScreenCoordinate(
        x: _asDouble(json['x']) ?? 0,
        y: _asDouble(json['y']) ?? 0,
      );
}

/// Describes the coordinate box on the screen, measured in `logical pixels`
/// from top to bottom and from left to right.
class ScreenBox {
  ScreenBox({required this.min, required this.max});

  /// The screen coordinate close to the top left corner of the screen.
  ScreenCoordinate min;

  /// The screen coordinate close to the bottom right corner of the screen.
  ScreenCoordinate max;

  Map<String, dynamic> toJson() => {'min': min.toJson(), 'max': max.toJson()};
}

/// A coordinate bounds and zoom.
class CoordinateBoundsZoom {
  CoordinateBoundsZoom({required this.bounds, required this.zoom});

  /// The latitude and longitude bounds.
  CoordinateBounds bounds;

  /// Zoom.
  double zoom;

  static CoordinateBoundsZoom fromJson(Map<String, dynamic> json) =>
      CoordinateBoundsZoom(
        bounds: CoordinateBounds.fromJson(_requireMap(json['bounds'])),
        zoom: _asDouble(json['zoom']) ?? 0,
      );
}

/// Size type.
class Size {
  Size({required this.width, required this.height});

  /// Width of the size.
  double width;

  /// Height of the size.
  double height;

  Map<String, dynamic> toJson() => {'width': width, 'height': height};

  static Size fromJson(Map<String, dynamic> json) => Size(
        width: _asDouble(json['width']) ?? 0,
        height: _asDouble(json['height']) ?? 0,
      );
}

/// Options for querying rendered features.
class RenderedQueryOptions {
  RenderedQueryOptions({this.layerIds, this.filter});

  /// Layer IDs to include in the query.
  List<String?>? layerIds;

  /// Filters the returned features with an expression
  String? filter;

  Map<String, dynamic> toJson() => {'layerIds': layerIds, 'filter': filter};
}

/// Options for querying source features.
class SourceQueryOptions {
  SourceQueryOptions({this.sourceLayerIds, required this.filter});

  /// Source layer IDs to include in the query.
  List<String?>? sourceLayerIds;

  /// Filters the returned features with an expression
  String filter;

  Map<String, dynamic> toJson() =>
      {'sourceLayerIds': sourceLayerIds, 'filter': filter};
}

/// A value or a collection of features returned by a feature extension query.
class FeatureExtensionValue {
  FeatureExtensionValue({this.value, this.featureCollection});

  /// An optional value of a feature extension
  String? value;

  /// An optional array of features from a feature extension.
  List<Map<String?, Object?>?>? featureCollection;

  static FeatureExtensionValue fromJson(Map<String, dynamic> json) =>
      FeatureExtensionValue(
        value: json['value']?.toString(),
        featureCollection: (json['featureCollection'] as List?)
            ?.map((e) => e is Map ? e.cast<String?, Object?>() : null)
            .toList(),
      );
}

/// Specifies the position at which a layer will be added when using `addStyleLayer`.
class LayerPosition {
  LayerPosition({this.above, this.below, this.at});

  /// Layer should be positioned above specified layer id.
  String? above;

  /// Layer should be positioned below specified layer id.
  String? below;

  /// Layer should be positioned at specified index in a layers stack.
  int? at;

  Map<String, dynamic> toJson() => {'above': above, 'below': below, 'at': at};
}

/// Specifies the position at which an import will be added when using `addStyleImport`.
class ImportPosition {
  ImportPosition({this.above, this.below, this.at});

  /// Import should be positioned above the specified import id.
  String? above;

  /// Import should be positioned below the specified import id.
  String? below;

  /// Import should be positioned at the specified index in the imports stack.
  int? at;

  Map<String, dynamic> toJson() => {'above': above, 'below': below, 'at': at};
}

/// Represents query result that is returned in QueryRenderedFeaturesCallback.
class QueriedRenderedFeature {
  QueriedRenderedFeature({required this.queriedFeature, required this.layers});

  /// Feature returned by the query.
  QueriedFeature queriedFeature;

  /// An array of layer Ids for the queried feature.
  List<String?> layers;

  static QueriedRenderedFeature fromJson(Map<String, dynamic> json) =>
      QueriedRenderedFeature(
        queriedFeature: QueriedFeature.fromJson(_requireMap(json['queriedFeature'])),
        layers: _asStringList(json['layers']) ?? const [],
      );
}

/// Represents query result that is returned in QuerySourceFeaturesCallback.
class QueriedSourceFeature {
  QueriedSourceFeature({required this.queriedFeature});

  /// Feature returned by the query.
  QueriedFeature queriedFeature;

  static QueriedSourceFeature fromJson(Map<String, dynamic> json) =>
      QueriedSourceFeature(
        queriedFeature: QueriedFeature.fromJson(_requireMap(json['queriedFeature'])),
      );
}

/// Represents query result that is returned in QueryFeaturesCallback.
class QueriedFeature {
  QueriedFeature({
    required this.feature,
    required this.source,
    this.sourceLayer,
    required this.state,
  });

  /// Feature returned by the query.
  Map<String?, Object?> feature;

  /// Source id for a queried feature.
  String source;

  /// Source layer id for a queried feature.
  String? sourceLayer;

  /// Feature state for a queried feature, as a JSON string.
  String state;

  static QueriedFeature fromJson(Map<String, dynamic> json) => QueriedFeature(
        feature: _requireMap(json['feature']).cast<String?, Object?>(),
        source: json['source'] as String? ?? '',
        sourceLayer: json['sourceLayer'] as String?,
        state: json['state'] is String
            ? json['state'] as String
            : jsonEncode(json['state'] ?? {}),
      );
}

/// Identifies a feature in a featureset.
class FeaturesetFeatureId {
  FeaturesetFeatureId({required this.id, this.namespace});

  /// A feature id coming from the feature itself.
  String id;

  /// A namespace of the feature
  String? namespace;

  Map<String, dynamic> toJson() => {'id': id, 'namespace': namespace};

  static FeaturesetFeatureId fromJson(Map<String, dynamic> json) =>
      FeaturesetFeatureId(
        id: json['id']?.toString() ?? '',
        namespace: json['namespace'] as String?,
      );
}

/// A feature state map.
class FeatureState {
  FeatureState({required this.map});

  Map<String, Object?> map;
}

/// Identifies a featureset within the style.
class FeaturesetDescriptor {
  FeaturesetDescriptor({this.featuresetId, this.importId, this.layerId});

  /// An optional unique identifier for the featureset within the style.
  String? featuresetId;

  /// An optional import id that is required if the featureset is defined within an imported style.
  String? importId;

  /// An optional unique identifier for the layer within the current style.
  String? layerId;

  Map<String, dynamic> toJson() => {
        'featuresetId': featuresetId,
        'importId': importId,
        'layerId': layerId,
      };

  static FeaturesetDescriptor fromJson(Map<String, dynamic> json) =>
      FeaturesetDescriptor(
        featuresetId: json['featuresetId'] as String?,
        importId: json['importId'] as String?,
        layerId: json['layerId'] as String?,
      );
}

/// A basic feature of a featureset.
class FeaturesetFeature {
  FeaturesetFeature({
    this.id,
    required this.featureset,
    required this.geometry,
    required this.properties,
    required this.state,
  });

  /// An identifier of the feature.
  FeaturesetFeatureId? id;

  /// A featureset descriptor denoting the featureset this feature belongs to.
  FeaturesetDescriptor featureset;

  /// A feature geometry.
  Map<String?, Object?> geometry;

  /// Feature JSON properties.
  Map<String, Object?> properties;

  /// A feature state snapshot.
  Map<String, Object?> state;

  static FeaturesetFeature fromJson(Map<String, dynamic> json) =>
      FeaturesetFeature(
        id: _asMap(json['id']) == null
            ? null
            : FeaturesetFeatureId.fromJson(_asMap(json['id'])!),
        featureset: FeaturesetDescriptor.fromJson(_requireMap(json['featureset'])),
        geometry: _requireMap(json['geometry']).cast<String?, Object?>(),
        properties: _asMap(json['properties'])?.cast<String, Object?>() ?? {},
        state: _asMap(json['state'])?.cast<String, Object?>() ?? {},
      );
}

/// Projected meters in north and east directions.
class ProjectedMeters {
  ProjectedMeters({required this.northing, required this.easting});

  /// Projected meters in north direction.
  double northing;

  /// Projected meters in east direction.
  double easting;

  Map<String, dynamic> toJson() => {'northing': northing, 'easting': easting};

  static ProjectedMeters fromJson(Map<String, dynamic> json) => ProjectedMeters(
        northing: _asDouble(json['northing']) ?? 0,
        easting: _asDouble(json['easting']) ?? 0,
      );
}

/// A point in Mercator projection.
class MercatorCoordinate {
  MercatorCoordinate({required this.x, required this.y});

  /// A value representing the x position of this coordinate.
  double x;

  /// A value representing the y position of this coordinate.
  double y;

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  static MercatorCoordinate fromJson(Map<String, dynamic> json) =>
      MercatorCoordinate(
        x: _asDouble(json['x']) ?? 0,
        y: _asDouble(json['y']) ?? 0,
      );
}

/// Information about a style object.
class StyleObjectInfo {
  StyleObjectInfo({required this.id, required this.type});

  /// The object's identifier.
  String id;

  /// The object's type.
  String type;

  static StyleObjectInfo fromJson(Map<String, dynamic> json) => StyleObjectInfo(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
      );
}

/// The projection of the style.
class StyleProjection {
  StyleProjection({required this.name});

  StyleProjectionName name;

  Map<String, dynamic> toJson() => {'name': name.index};

  static StyleProjection? fromJson(Map<String, dynamic>? json) {
    final name = _enumFromIndex(StyleProjectionName.values, json?['name']);
    return name == null ? null : StyleProjection(name: name);
  }
}

/// A global directional light source which is only applied on 3D layers and hillshade layers.
class FlatLight {
  FlatLight({
    required this.id,
    this.anchor,
    this.color,
    this.colorTransition,
    this.intensity,
    this.intensityTransition,
    this.position,
    this.positionTransition,
  });

  /// Unique light name
  String id;

  /// Whether extruded geometries are lit relative to the map or viewport.
  Anchor? anchor;

  /// Color tint for lighting extruded geometries.
  int? color;

  /// Transition property for `color`
  TransitionOptions? colorTransition;

  /// Intensity of lighting (on a scale from 0 to 1).
  double? intensity;

  /// Transition property for `intensity`
  TransitionOptions? intensityTransition;

  /// Position of the light source relative to lit (extruded) geometries, in [r radial coordinate, a azimuthal angle, p polar angle].
  List<double?>? position;

  /// Transition property for `position`
  TransitionOptions? positionTransition;

  Map<String, dynamic> toJson() => {
        'id': id,
        'anchor': anchor?.index,
        'color': color,
        'colorTransition': colorTransition?.toJson(),
        'intensity': intensity,
        'intensityTransition': intensityTransition?.toJson(),
        'position': position,
        'positionTransition': positionTransition?.toJson(),
      };
}

/// A light that has a direction and is located at infinite distance.
class DirectionalLight {
  DirectionalLight({
    required this.id,
    this.castShadows,
    this.color,
    this.colorTransition,
    this.direction,
    this.directionTransition,
    this.intensity,
    this.intensityTransition,
    this.shadowIntensity,
    this.shadowIntensityTransition,
    this.shadowDrawBeforeLayer,
  });

  /// Unique light name
  String id;

  /// Enable/Disable shadow casting for this light
  bool? castShadows;

  /// Color of the directional light.
  int? color;

  /// Transition property for `color`
  TransitionOptions? colorTransition;

  /// Direction of the light source specified as [a azimuthal angle, p polar angle].
  List<double?>? direction;

  /// Transition property for `direction`
  TransitionOptions? directionTransition;

  /// A multiplier for the color of the directional light.
  double? intensity;

  /// Transition property for `intensity`
  TransitionOptions? intensityTransition;

  /// Determines the shadow strength.
  double? shadowIntensity;

  /// Transition property for `shadowIntensity`
  TransitionOptions? shadowIntensityTransition;

  /// Specify a layer before which shadows are drawn on the ground.
  String? shadowDrawBeforeLayer;

  Map<String, dynamic> toJson() => {
        'id': id,
        'castShadows': castShadows,
        'color': color,
        'colorTransition': colorTransition?.toJson(),
        'direction': direction,
        'directionTransition': directionTransition?.toJson(),
        'intensity': intensity,
        'intensityTransition': intensityTransition?.toJson(),
        'shadowIntensity': shadowIntensity,
        'shadowIntensityTransition': shadowIntensityTransition?.toJson(),
        'shadowDrawBeforeLayer': shadowDrawBeforeLayer,
      };
}

/// An indirect light affecting all objects in the map adding a constant amount of light on them.
class AmbientLight {
  AmbientLight({
    required this.id,
    this.color,
    this.colorTransition,
    this.intensity,
    this.intensityTransition,
  });

  /// Unique light name
  String id;

  /// Color of the ambient light.
  int? color;

  /// Transition property for `color`
  TransitionOptions? colorTransition;

  /// A multiplier for the color of the ambient light.
  double? intensity;

  /// Transition property for `intensity`
  TransitionOptions? intensityTransition;

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color,
        'colorTransition': colorTransition?.toJson(),
        'intensity': intensity,
        'intensityTransition': intensityTransition?.toJson(),
      };
}

/// Describes an image, as PNG bytes.
class MbxImage {
  MbxImage({required this.width, required this.height, required this.data});

  /// The width of the image, in screen pixels.
  int width;

  /// The height of the image, in screen pixels.
  int height;

  /// The encoded image data (PNG).
  Uint8List data;

  Map<String, dynamic> toJson() =>
      {'width': width, 'height': height, 'data': base64Encode(data)};

  static MbxImage fromJson(Map<String, dynamic> json) => MbxImage(
        width: _asInt(json['width']) ?? 0,
        height: _asInt(json['height']) ?? 0,
        data: _bytesFromJson(json['data']) ?? Uint8List(0),
      );
}

/// Describes the image stretch areas.
class ImageStretches {
  ImageStretches({required this.first, required this.second});

  /// The first stretchable part in screen pixel units.
  double first;

  /// The second stretchable part in screen pixel units.
  double second;

  Map<String, dynamic> toJson() => {'first': first, 'second': second};
}

/// Describes the image content, e.g. where text can be fit into an image.
class ImageContent {
  ImageContent({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// Distance to the left, in screen pixels.
  double left;

  /// Distance to the top, in screen pixels.
  double top;

  /// Distance to the right, in screen pixels.
  double right;

  /// Distance to the bottom, in screen pixels.
  double bottom;

  Map<String, dynamic> toJson() =>
      {'left': left, 'top': top, 'right': right, 'bottom': bottom};
}

/// The `transition options` controls timing for the interpolation between a transitionable style
/// property's previous value and new value.
class TransitionOptions {
  TransitionOptions({this.duration, this.delay, this.enablePlacementTransitions});

  /// Time allotted for transitions to complete. Units in milliseconds. Defaults to `300.0`.
  int? duration;

  /// Length of time before a transition begins. Units in milliseconds. Defaults to `0.0`.
  int? delay;

  /// Whether the fade in/out symbol placement transition is enabled. Defaults to `true`.
  bool? enablePlacementTransitions;

  Map<String, dynamic> toJson() => {
        'duration': duration,
        'delay': delay,
        'enablePlacementTransitions': enablePlacementTransitions,
      };

  static TransitionOptions fromJson(Map<String, dynamic> json) =>
      TransitionOptions(
        duration: _asInt(json['duration']),
        delay: _asInt(json['delay']),
        enablePlacementTransitions: json['enablePlacementTransitions'] as bool?,
      );
}

/// Describes the canonical tile id.
class CanonicalTileID {
  CanonicalTileID({required this.z, required this.x, required this.y});

  /// The z value of the coordinate (zoom-level).
  int z;

  /// The x value of the coordinate.
  int x;

  /// The y value of the coordinate.
  int y;

  Map<String, dynamic> toJson() => {'z': z, 'x': x, 'y': y};

  static CanonicalTileID fromJson(Map<String, dynamic> json) => CanonicalTileID(
        z: _asInt(json['z']) ?? 0,
        x: _asInt(json['x']) ?? 0,
        y: _asInt(json['y']) ?? 0,
      );
}

/// Holds a style property value with meta data.
class StylePropertyValue {
  StylePropertyValue({this.value, required this.kind});

  /// The property value.
  Object? value;

  /// The kind of the property value.
  StylePropertyValueKind kind;

  static StylePropertyValue fromJson(Map<String, dynamic> json) =>
      StylePropertyValue(
        value: json['value'],
        kind: _enumFromIndex(StylePropertyValueKind.values, json['kind']) ??
            StylePropertyValueKind.UNDEFINED,
      );
}

/// Geometry for querying rendered features.
class RenderedQueryGeometry {
  RenderedQueryGeometry.fromList(List<ScreenCoordinate> points)
      : value = jsonEncode(points.map((e) => e.toJson()).toList()),
        type = Type.LIST;

  RenderedQueryGeometry.fromScreenBox(ScreenBox box)
      : value = jsonEncode(box.toJson()),
        type = Type.SCREEN_BOX;

  RenderedQueryGeometry.fromScreenCoordinate(ScreenCoordinate point)
      : value = jsonEncode(point.toJson()),
        type = Type.SCREEN_COORDINATE;

  /// ScreenCoordinate/List<ScreenCoordinate>/ScreenBox in Json mode.
  String value;

  /// Type of the geometry encoded in [value].
  Type type;

  Map<String, dynamic> toJson() => {'value': value, 'type': type.index};
}

/// Options for enabling debugging features in a map.
class MapWidgetDebugOptions {
  final _MapWidgetDebugOptions _option;

  const MapWidgetDebugOptions._(this._option);

  /// Edges of tile boundaries are shown as thick, red lines to help diagnose
  /// tile clipping issues.
  static const MapWidgetDebugOptions tileBorders =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.tileBorders);

  /// Each tile shows its tile coordinate (x/y/z) in the upper-left corner.
  static const MapWidgetDebugOptions parseStatus =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.parseStatus);

  /// Each tile shows a timestamps with modified and expires dates or n/a if
  /// timestamp is not available.
  static const MapWidgetDebugOptions timestamps =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.timestamps);

  /// Edges of glyphs and symbols are shown as faint, green lines to help
  /// diagnose collision and label placement issues.
  static const MapWidgetDebugOptions collision =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.collision);

  /// Each drawing operation is replaced by a translucent fill.
  static const MapWidgetDebugOptions overdraw =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.overdraw);

  /// The stencil buffer is shown instead of the color buffer.
  static const MapWidgetDebugOptions stencilClip =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.stencilClip);

  /// The depth buffer is shown instead of the color buffer.
  static const MapWidgetDebugOptions depthBuffer =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.depthBuffer);

  /// Show 3D model bounding boxes.
  static const MapWidgetDebugOptions modelBounds =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.modelBounds);

  /// Show a wireframe for terrain. Supported on Android only.
  static const MapWidgetDebugOptions terrainWireframe =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.terrainWireframe);

  /// Show a wireframe for 2D layers. Supported on Android only.
  static const MapWidgetDebugOptions layers2DWireframe =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.layers2DWireframe);

  /// Show a wireframe for 3D layers. Supported on Android only.
  static const MapWidgetDebugOptions layers3DWireframe =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.layers3DWireframe);

  /// Each tile shows its local lighting conditions in the upper-left corner.
  static const MapWidgetDebugOptions light =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.light);

  /// Show a debug overlay with information about the CameraState
  /// including lat, long, zoom, pitch, & bearing.
  static const MapWidgetDebugOptions camera =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.camera);

  /// Draws camera padding frame.
  static const MapWidgetDebugOptions padding =
      MapWidgetDebugOptions._(_MapWidgetDebugOptions.padding);

  @override
  bool operator ==(Object other) =>
      other is MapWidgetDebugOptions && other._option == _option;

  @override
  int get hashCode => _option.hashCode;
}

/// A structure that defines additional information about map content gesture.
class MapContentGestureContext {
  MapContentGestureContext({
    required this.touchPosition,
    required this.point,
    required this.gestureState,
  });

  /// The location of gesture in Map view bounds.
  ScreenCoordinate touchPosition;

  /// Geographical coordinate of the map gesture.
  Point point;

  /// The state of the gesture.
  GestureState gestureState;

  static MapContentGestureContext fromJson(Map<String, dynamic> json) =>
      MapContentGestureContext(
        touchPosition:
            ScreenCoordinate.fromJson(_requireMap(json['touchPosition'])),
        point: Point.fromJson(_requireMap(json['point'])),
        gestureState: _enumFromIndex(GestureState.values, json['gestureState']) ??
            GestureState.ended,
      );
}

extension Conversion on CameraState {
  CameraOptions toCameraOptions() {
    return CameraOptions(
      center: center,
      padding: padding,
      zoom: zoom,
      bearing: bearing,
      pitch: pitch,
    );
  }

  static CameraState fromJson(Map<String, dynamic> json) {
    return CameraState(
        center: Point.fromJson(_requireMap(json['center'])),
        padding: MbxEdgeInsets.fromJson(_requireMap(json['padding'])),
        zoom: _asDouble(json['zoom']) ?? 0,
        bearing: _asDouble(json['bearing']) ?? 0,
        pitch: _asDouble(json['pitch']) ?? 0);
  }
}
