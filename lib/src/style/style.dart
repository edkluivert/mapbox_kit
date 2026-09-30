// StyleManager and the layer/source base classes.
// Ported from mapbox_maps_flutter 2.31.0 (BSD-3, Mapbox).

part of '../../mapbox_kit.dart';

/// Influences the y direction of the tile coordinates.
enum Scheme {
  /// Slippy map tilenames scheme.
  XYZ,

  /// OSGeo spec scheme.
  TMS,
}

/// The encoding used by this source. Mapbox Terrain RGB is used by default
enum Encoding {
  /// Terrarium format PNG tiles.
  TERRARIUM,

  /// Mapbox Terrain RGB tiles.
  MAPBOX,
}

/// The unit a cache budget should be measured in. Either Tiles or Megabytes.
enum TileCacheBudgetType {
  /// A tile cache budget measured in tile units
  TILES,

  /// A tile cache budget measured in megabyte units
  MEGABYTES
}

/// Defines a resource budget, either in tile units or in megabytes.
class TileCacheBudget {
  /// The type of TileCacheBudget, either in Tiles or in Megabytes
  TileCacheBudgetType type;

  /// The size of the budget.
  int size;

  /// Returns the TileCacheBudget formatted into an object
  Object toJson() {
    switch (type) {
      case TileCacheBudgetType.MEGABYTES:
        return {"megabytes": size};
      case TileCacheBudgetType.TILES:
        return {"tiles": size};
    }
  }

  /// Decodes the TileCacheBudget from and object
  static TileCacheBudget? decode(Object? budget) {
    if (budget is! Map || budget.isEmpty) return null;
    var budgetType = budget.keys.first;
    var budgetSize = _asInt(budget.values.first) ?? 0;

    if (budgetType == 'megabytes') {
      return TileCacheBudget.inMegabytes(
          TileCacheBudgetInMegabytes(size: budgetSize));
    } else if (budgetType == 'tiles') {
      return TileCacheBudget.inTiles(TileCacheBudgetInTiles(size: budgetSize));
    } else {
      return null;
    }
  }

  TileCacheBudget.inMegabytes(TileCacheBudgetInMegabytes budget)
      : type = TileCacheBudgetType.MEGABYTES,
        size = budget.size;

  TileCacheBudget.inTiles(TileCacheBudgetInTiles budget)
      : type = TileCacheBudgetType.TILES,
        size = budget.size;

  TileCacheBudget(this.type, this.size);
}

/// Define the duration and delay for a style transition.
class StyleTransition {
  StyleTransition({this.duration, this.delay});

  /// Duration of the transition.
  int? duration;

  /// Delay of the transition.
  int? delay;

  String encode() {
    final properties = <String, dynamic>{"duration": duration, "delay": delay};
    return json.encode(properties);
  }

  static StyleTransition decode(String properties) {
    final map = json.decode(properties);
    return StyleTransition(duration: map["duration"], delay: map["delay"]);
  }
}

/// Super class for all different types of layers.
abstract class Layer {
  /// The ID of the Layer.
  String id;

  /// The visibility of the layer.
  Visibility? visibility;

  /// The visibility of the layer.
  List<Object>? visibilityExpression;

  /// An expression specifying conditions on source features.
  /// Only features that match the filter are displayed.
  List<Object>? filter;

  /// The minimum zoom level for the layer. At zoom levels less than the minzoom, the layer will be hidden.
  double? minZoom;

  /// The maximum zoom level for the layer. At zoom levels equal to or greater than the maxzoom, the layer will be hidden.
  double? maxZoom;

  /// The slot this layer is assigned to. If specified, and a slot with that name exists, it will be placed at that position in the layer order.
  String? slot;

  /// Get the type of current layer as a String.
  String getType();

  Future<String> _encode();

  Layer(
      {required String this.id,
      Visibility? this.visibility,
      List<Object>? this.visibilityExpression,
      List<Object>? this.filter,
      double? this.maxZoom,
      double? this.minZoom,
      String? this.slot});
}

/// Super class for all different types of sources.
abstract class Source {
  /// The ID of the Source.
  String id;

  /// Get the type of the current source as a String.
  String getType();

  String _encode(bool volatile);

  Source({required this.id});

  StyleManager? _style;

  void bind(StyleManager style) => _style = style;
}

/// Extension for StyleManager to add/update/get layers from the current style.
extension StyleLayer on StyleManager {
  /// Add a layer the the current style.
  Future<void> addLayer(Layer layer) async {
    var encode = await layer._encode();
    return addStyleLayer(encode, null);
  }

  /// Add a layer to the current style in a specific position.
  Future<void> addLayerAt(Layer layer, LayerPosition position) async {
    var encode = await layer._encode();
    return addStyleLayer(encode, position);
  }

  /// Update an existing layer in the style.
  Future<void> updateLayer(Layer layer) async {
    var encode = await layer._encode();
    return setStyleLayerProperties(layer.id, encode);
  }

  /// Get a previously added layer from the current style.
  ///
  /// Circle, fill, fill-extrusion, line and symbol layers are decoded; other
  /// layer types return `null`.
  Future<Layer?> getLayer(String layerId) async {
    var properties = await getStyleLayerProperties(layerId);

    Layer? layer;
    var map = json.decode(properties);

    var type = map["type"];
    switch (type) {
      case "circle":
        layer = CircleLayer.decode(properties);
        break;
      case "fill-extrusion":
        layer = FillExtrusionLayer.decode(properties);
        break;
      case "fill":
        layer = FillLayer.decode(properties);
        break;
      case "line":
        layer = LineLayer.decode(properties);
        break;
      case "symbol":
        layer = SymbolLayer.decode(properties);
        break;
      default:
        mapboxKitLog("Layer type: $type is not decoded by mapbox_kit.");
    }

    return Future.value(layer);
  }
}

/// Extension for StyleManager to add/get sources from the current style.
extension StyleSource on StyleManager {
  Future<void> addSource(Source source) async {
    if (source is GeoJsonSource && source._data != null) {
      final internalData = source._data!;

      // Add empty data initially so that the source is added and
      // volatile properties can be set. Then add the data.
      source._data = "";
      await _addSourceInternal(source);
      return source.updateGeoJSON(internalData);
    } else {
      return _addSourceInternal(source);
    }
  }

  Future<void> _addSourceInternal(Source source) {
    final nonVolatileProperties = source._encode(false);
    final volatileProperties = source._encode(true);
    source.bind(this);
    return addStyleSource(source.id, nonVolatileProperties).then((value) {
      // volatile properties have to be set after the source has been added to the style
      setStyleSourceProperties(source.id, volatileProperties);
    });
  }

  /// Get the source with sourceId from the current style.
  ///
  /// GeoJSON and raster-dem sources are decoded; other source types return
  /// `null`.
  Future<Source?> getSource(String sourceId) async {
    final properties = await getStyleSourceProperties(sourceId);

    Source? source;

    final map = json.decode(properties);

    final type = map["type"];
    switch (type) {
      case "geojson":
        source = GeoJsonSource(id: sourceId);
        break;
      case "raster-dem":
        source = RasterDemSource(id: sourceId);
        break;
      default:
        mapboxKitLog("Source type: $type is not decoded by mapbox_kit.");
    }

    source?.bind(this);
    return Future.value(source);
  }
}

/// Extension to convert color format
extension StyleColorInt on int {
  /// Convert the color from int format to a string with format "rgba(red, green, blue, alpha)".
  String toRGBA() {
    final alpha = (this >> 24) & 0xFF;
    final red = (this >> 16) & 0xFF;
    final green = (this >> 8) & 0xFF;
    final blue = this & 0xFF;
    return "rgba($red, $green, $blue, ${alpha / 255})";
  }
}

int _argb(int alpha, int red, int green, int blue) =>
    ((alpha & 0xFF) << 24) |
    ((red & 0xFF) << 16) |
    ((green & 0xFF) << 8) |
    (blue & 0xFF);

/// HSL (hue 0..360, saturation 0..1, lightness 0..1) to packed ARGB.
int _hslToArgb(double alpha, double hue, double saturation, double lightness) {
  final chroma = (1 - (2 * lightness - 1).abs()) * saturation;
  final h = (hue % 360) / 60;
  final x = chroma * (1 - ((h % 2) - 1).abs());
  double r = 0, g = 0, b = 0;
  if (h < 1) {
    r = chroma;
    g = x;
  } else if (h < 2) {
    r = x;
    g = chroma;
  } else if (h < 3) {
    g = chroma;
    b = x;
  } else if (h < 4) {
    g = x;
    b = chroma;
  } else if (h < 5) {
    r = x;
    b = chroma;
  } else {
    r = chroma;
    b = x;
  }
  final m = lightness - chroma / 2;
  return _argb(
    (alpha * 255).round(),
    ((r + m) * 255).round(),
    ((g + m) * 255).round(),
    ((b + m) * 255).round(),
  );
}

extension StyleColorString on String {
  /// Convert the color from a CSS-style `"rgba(r,g,b,a)"` string, as returned
  /// for plain (non-expression) color properties, to int.
  int toRGBAInt() {
    final match =
        RegExp(r'^rgba\(([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\)$')
            .firstMatch(this);
    if (match == null) {
      return 0;
    }
    final red = double.parse(match.group(1)!).round();
    final green = double.parse(match.group(2)!).round();
    final blue = double.parse(match.group(3)!).round();
    final alpha = (double.parse(match.group(4)!) * 255).round();
    return _argb(alpha, red, green, blue);
  }
}

extension StyleColorList on List {
  /// Convert the color from a color expression to int.
  /// `rgb`, `rgba`, `hsl` and `hsla` formats are supported.
  /// Example input: `[rgba, $R, $G, $B, $A]`.
  int toRGBAInt() {
    num? n(int i) => this[i] is num ? this[i] as num : null;
    switch ((firstOrNull, length)) {
      case ("rgb", 4):
        final r = n(1), g = n(2), b = n(3);
        if (r == null || g == null || b == null) return 0;
        return _argb(1, r.toInt(), g.toInt(), b.toInt());
      case ("rgba", 5):
        final r = n(1), g = n(2), b = n(3), a = n(4);
        if (r == null || g == null || b == null || a == null) return 0;
        return _argb((a * 255).toInt(), r.toInt(), g.toInt(), b.toInt());
      case ("hsl", 4):
        final h = n(1), s = n(2), l = n(3);
        if (h == null || s == null || l == null) return 0;
        return _hslToArgb(1, h.toDouble(), s.toDouble(), l.toDouble());
      case ("hsla", 5):
        final h = n(1), s = n(2), l = n(3), a = n(4);
        if (h == null || s == null || l == null || a == null) return 0;
        return _hslToArgb(
            a.toDouble(), h.toDouble(), s.toDouble(), l.toDouble());
      default:
        return 0;
    }
  }
}

/// Interface for managing style of the `map`.
class StyleManager {
  StyleManager._(this._channel);

  final _MapChannel _channel;

  Future<T> _call<T>(String method, [Map<String, dynamic>? args]) async =>
      await _channel.invoke('style#$method', args) as T;

  StylePropertyValue _property(dynamic value) =>
      StylePropertyValue.fromJson(_requireMap(value));

  List<StyleObjectInfo?> _infos(dynamic value) => ((value as List?) ?? const [])
      .map((e) => e == null ? null : StyleObjectInfo.fromJson(_requireMap(e)))
      .toList();

  /// Get the URI of the current style in use.
  Future<String> getStyleURI() => _call('getStyleURI');

  /// Load style from provided URI.
  Future<void> setStyleURI(String uri) => _call('setStyleURI', {'uri': uri});

  /// Get the JSON serialization string of the current style in use.
  Future<String> getStyleJSON() => _call('getStyleJSON');

  /// Load the style from a provided JSON string.
  Future<void> setStyleJSON(String json) =>
      _call('setStyleJSON', {'json': json});

  /// Returns the map style's default camera, if any, or a default camera otherwise.
  Future<CameraOptions> getStyleDefaultCamera() async =>
      CameraOptions.fromJson(_requireMap(await _call('getStyleDefaultCamera')));

  /// Returns the map style's transition options.
  Future<TransitionOptions> getStyleTransition() async =>
      TransitionOptions.fromJson(_requireMap(await _call('getStyleTransition')));

  /// Adds new import to current style, loaded from a JSON string.
  Future<void> addStyleImportFromJSON(String importId, String json,
          Map<String, Object>? config, ImportPosition? importPosition) =>
      _call('addStyleImportFromJSON', {
        'importId': importId,
        'json': json,
        'config': config,
        'importPosition': importPosition?.toJson(),
      });

  /// Adds new import to current style, loaded from an URI.
  Future<void> addStyleImportFromURI(String importId, String uri,
          Map<String, Object>? config, ImportPosition? importPosition) =>
      _call('addStyleImportFromURI', {
        'importId': importId,
        'uri': uri,
        'config': config,
        'importPosition': importPosition?.toJson(),
      });

  /// Updates an existing import in the style, loaded from a JSON string.
  Future<void> updateStyleImportWithJSON(
          String importId, String json, Map<String, Object>? config) =>
      _call('updateStyleImportWithJSON',
          {'importId': importId, 'json': json, 'config': config});

  /// Updates an existing import in the style, loaded from an URI.
  Future<void> updateStyleImportWithURI(
          String importId, String uri, Map<String, Object>? config) =>
      _call('updateStyleImportWithURI',
          {'importId': importId, 'uri': uri, 'config': config});

  /// Moves import to position before another import, specified with `importPosition`.
  Future<void> moveStyleImport(String importId, ImportPosition? importPosition) =>
      _call('moveStyleImport',
          {'importId': importId, 'importPosition': importPosition?.toJson()});

  /// Returns the existing style imports.
  Future<List<StyleObjectInfo?>> getStyleImports() async =>
      _infos(await _call('getStyleImports'));

  /// Removes an existing style import.
  Future<void> removeStyleImport(String importId) =>
      _call('removeStyleImport', {'importId': importId});

  /// Gets style import schema.
  Future<Object> getStyleImportSchema(String importId) =>
      _call('getStyleImportSchema', {'importId': importId});

  /// Gets style import config.
  Future<Map<String, StylePropertyValue>> getStyleImportConfigProperties(
      String importId) async {
    final map = _requireMap(
        await _call('getStyleImportConfigProperties', {'importId': importId}));
    return map.map((key, value) => MapEntry(key, _property(value)));
  }

  /// Gets the value of style import config.
  Future<StylePropertyValue> getStyleImportConfigProperty(
          String importId, String config) async =>
      _property(await _call('getStyleImportConfigProperty',
          {'importId': importId, 'config': config}));

  /// Sets style import config.
  Future<void> setStyleImportConfigProperties(
          String importId, Map<String, Object> configs) =>
      _call('setStyleImportConfigProperties',
          {'importId': importId, 'configs': configs});

  /// Sets a value to a style import config.
  ///
  /// The Standard style import is named `basemap`; its configs include
  /// `lightPreset` (dawn, day, dusk, night), `theme` (default, faded,
  /// monochrome), `showPointOfInterestLabels`, `show3dObjects` and more.
  Future<void> setStyleImportConfigProperty(
          String importId, String config, Object value) =>
      _call('setStyleImportConfigProperty',
          {'importId': importId, 'config': config, 'value': value});

  /// Overrides the map style's transition options with user-provided options.
  Future<void> setStyleTransition(TransitionOptions transitionOptions) =>
      _call('setStyleTransition',
          {'transitionOptions': transitionOptions.toJson()});

  /// Adds a new style layer given its JSON properties
  Future<void> addStyleLayer(String properties, LayerPosition? layerPosition) =>
      _call('addStyleLayer',
          {'properties': properties, 'layerPosition': layerPosition?.toJson()});

  /// Adds a new persistent style layer given its JSON properties
  Future<void> addPersistentStyleLayer(
          String properties, LayerPosition? layerPosition) =>
      _call('addPersistentStyleLayer',
          {'properties': properties, 'layerPosition': layerPosition?.toJson()});

  /// Checks if a style layer is persistent.
  Future<bool> isStyleLayerPersistent(String layerId) =>
      _call('isStyleLayerPersistent', {'layerId': layerId});

  /// Removes an existing style layer
  Future<void> removeStyleLayer(String layerId) =>
      _call('removeStyleLayer', {'layerId': layerId});

  /// Moves an existing style layer
  Future<void> moveStyleLayer(String layerId, LayerPosition? layerPosition) =>
      _call('moveStyleLayer',
          {'layerId': layerId, 'layerPosition': layerPosition?.toJson()});

  /// Checks whether a given style layer exists.
  Future<bool> styleLayerExists(String layerId) =>
      _call('styleLayerExists', {'layerId': layerId});

  /// Returns the existing style layers.
  Future<List<StyleObjectInfo?>> getStyleLayers() async =>
      _infos(await _call('getStyleLayers'));

  /// Gets the value of style layer property.
  Future<StylePropertyValue> getStyleLayerProperty(
          String layerId, String property) async =>
      _property(await _call(
          'getStyleLayerProperty', {'layerId': layerId, 'property': property}));

  /// Sets a value to a style layer property.
  Future<void> setStyleLayerProperty(
          String layerId, String property, Object value) =>
      _call('setStyleLayerProperty',
          {'layerId': layerId, 'property': property, 'value': value});

  /// Gets style layer properties.
  Future<String> getStyleLayerProperties(String layerId) =>
      _call('getStyleLayerProperties', {'layerId': layerId});

  /// Sets style layer properties.
  Future<void> setStyleLayerProperties(String layerId, String properties) =>
      _call('setStyleLayerProperties',
          {'layerId': layerId, 'properties': properties});

  /// Adds a new style source.
  Future<void> addStyleSource(String sourceId, String properties) =>
      _call('addStyleSource', {'sourceId': sourceId, 'properties': properties});

  /// Gets the value of style source property.
  Future<StylePropertyValue> getStyleSourceProperty(
          String sourceId, String property) async =>
      _property(await _call('getStyleSourceProperty',
          {'sourceId': sourceId, 'property': property}));

  /// Sets a value to a style source property.
  Future<void> setStyleSourceProperty(
          String sourceId, String property, Object value) =>
      _call('setStyleSourceProperty',
          {'sourceId': sourceId, 'property': property, 'value': value});

  /// Gets style source properties.
  Future<String> getStyleSourceProperties(String sourceId) =>
      _call('getStyleSourceProperties', {'sourceId': sourceId});

  /// Sets style source properties.
  Future<void> setStyleSourceProperties(String sourceId, String properties) =>
      _call('setStyleSourceProperties',
          {'sourceId': sourceId, 'properties': properties});

  /// Add additional features to a GeoJSON style source.
  Future<void> addGeoJSONSourceFeatures(
          String sourceId, String dataId, List<Feature> features) =>
      _call('addGeoJSONSourceFeatures', {
        'sourceId': sourceId,
        'dataId': dataId,
        'features': features.map((e) => e.toJson()).toList(),
      });

  /// Update existing features in a GeoJSON style source.
  Future<void> updateGeoJSONSourceFeatures(
          String sourceId, String dataId, List<Feature> features) =>
      _call('updateGeoJSONSourceFeatures', {
        'sourceId': sourceId,
        'dataId': dataId,
        'features': features.map((e) => e.toJson()).toList(),
      });

  /// Remove features from a GeoJSON style source.
  Future<void> removeGeoJSONSourceFeatures(
          String sourceId, String dataId, List<String> featureIds) =>
      _call('removeGeoJSONSourceFeatures',
          {'sourceId': sourceId, 'dataId': dataId, 'featureIds': featureIds});

  /// Updates the image of an image style source.
  Future<void> updateStyleImageSourceImage(String sourceId, MbxImage image) =>
      _call('updateStyleImageSourceImage',
          {'sourceId': sourceId, 'image': image.toJson()});

  /// Removes an existing style source.
  Future<void> removeStyleSource(String sourceId) =>
      _call('removeStyleSource', {'sourceId': sourceId});

  /// Checks whether a given style source exists.
  Future<bool> styleSourceExists(String sourceId) =>
      _call('styleSourceExists', {'sourceId': sourceId});

  /// Returns the existing style sources.
  Future<List<StyleObjectInfo?>> getStyleSources() async =>
      _infos(await _call('getStyleSources'));

  /// Returns an ordered list of the current style lights.
  Future<List<StyleObjectInfo?>> getStyleLights() async =>
      _infos(await _call('getStyleLights'));

  /// Set global directional lightning.
  Future<void> setLight(FlatLight flatLight) =>
      _call('setLight', {'flatLight': flatLight.toJson()});

  /// Set dynamic lightning.
  Future<void> setLights(
          AmbientLight ambientLight, DirectionalLight directionalLight) =>
      _call('setLights', {
        'ambientLight': ambientLight.toJson(),
        'directionalLight': directionalLight.toJson(),
      });

  /// Gets the value of a style light property.
  Future<StylePropertyValue> getStyleLightProperty(
          String id, String property) async =>
      _property(
          await _call('getStyleLightProperty', {'id': id, 'property': property}));

  /// Sets a value to the the style light property.
  Future<void> setStyleLightProperty(String id, String property, Object value) =>
      _call('setStyleLightProperty',
          {'id': id, 'property': property, 'value': value});

  /// Sets the style global terrain source properties.
  Future<void> setStyleTerrain(String properties) =>
      _call('setStyleTerrain', {'properties': properties});

  /// Get the value of a style terrain property.
  Future<StylePropertyValue> getStyleTerrainProperty(String property) async =>
      _property(await _call('getStyleTerrainProperty', {'property': property}));

  /// Sets a value to the named style terrain property.
  Future<void> setStyleTerrainProperty(String property, Object value) =>
      _call('setStyleTerrainProperty', {'property': property, 'value': value});

  /// Get an image from the style.
  Future<MbxImage?> getStyleImage(String imageId) async {
    final value = await _call('getStyleImage', {'imageId': imageId});
    return value == null ? null : MbxImage.fromJson(_requireMap(value));
  }

  /// Adds an image to be used in the style. [image] carries the PNG (or JPEG)
  /// encoded bytes; [scale] is the pixel ratio they were rendered at.
  Future<void> addStyleImage(
          String imageId,
          double scale,
          MbxImage image,
          bool sdf,
          List<ImageStretches?> stretchX,
          List<ImageStretches?> stretchY,
          ImageContent? content) =>
      _call('addStyleImage', {
        'imageId': imageId,
        'scale': scale,
        'image': image.toJson(),
        'sdf': sdf,
        'stretchX': stretchX.map((e) => e?.toJson()).toList(),
        'stretchY': stretchY.map((e) => e?.toJson()).toList(),
        'content': content?.toJson(),
      });

  /// Removes an image from the style.
  Future<void> removeStyleImage(String imageId) =>
      _call('removeStyleImage', {'imageId': imageId});

  /// Checks whether an image exists.
  Future<bool> hasStyleImage(String imageId) =>
      _call('hasStyleImage', {'imageId': imageId});

  /// Adds a model to be used in the style.
  Future<void> addStyleModel(String modelId, String modelUri) =>
      _call('addStyleModel', {'modelId': modelId, 'modelUri': modelUri});

  /// Removes a model from the style.
  Future<void> removeStyleModel(String modelId) =>
      _call('removeStyleModel', {'modelId': modelId});

  /// Check if the style is completely loaded.
  Future<bool> isStyleLoaded() => _call('isStyleLoaded');

  /// Returns the map style's projection, if any.
  Future<StyleProjection?> getProjection() async =>
      StyleProjection.fromJson(_asMap(await _call('getProjection')));

  /// Sets the projection of the style.
  Future<void> setProjection(StyleProjection projection) =>
      _call('setProjection', {'projection': projection.toJson()});

  /// Localizes the labels of the style, or of the given [layerIds] only.
  Future<void> localizeLabels(String locale, List<String>? layerIds) =>
      _call('localizeLabels', {'locale': locale, 'layerIds': layerIds});
}
