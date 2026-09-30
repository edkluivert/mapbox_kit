part of '../mapbox_kit.dart';

/// Controller for a single MapboxMap instance running on the host platform.
class MapboxMap {
  MapboxMap._({
    required _MapChannel channel,
    this.onMapTapListener,
    this.onMapLongTapListener,
    this.onMapScrollListener,
    this.onMapZoomListener,
  }) : _channel = channel {
    annotations = AnnotationManager._(_channel);
    _setupGestures();
  }

  final _MapChannel _channel;
  bool _disposed = false;

  /// The id of the hosted native view this controller drives.
  int get viewId => _channel.viewId;

  /// The currently loaded Style object.
  late final StyleManager style = StyleManager._(_channel);

  /// The interface to set the location puck.
  late final LocationSettings location =
      LocationSettings._(_LocationComponentSettingsInterface(_channel));

  /// The interface to create and set annotations.
  late final AnnotationManager annotations;

  /// The interface to access the gesture settings.
  late final GesturesSettingsInterface gestures =
      GesturesSettingsInterface._(_channel);

  /// The interface to set the logo settings.
  late final LogoSettingsInterface logo = LogoSettingsInterface._(_channel);

  /// The interface to access the compass settings.
  late final CompassSettingsInterface compass =
      CompassSettingsInterface._(_channel);

  /// The interface to access the scale bar settings.
  late final ScaleBarSettingsInterface scaleBar =
      ScaleBarSettingsInterface._(_channel);

  /// The interface to access the attribution settings.
  late final AttributionSettingsInterface attribution =
      AttributionSettingsInterface._(_channel);

  OnMapTapListener? onMapTapListener;
  OnMapLongTapListener? onMapLongTapListener;
  OnMapScrollListener? onMapScrollListener;
  OnMapZoomListener? onMapZoomListener;

  StreamSubscription<dynamic>? _gestures;

  /// Releases the native subscriptions. Called by the widget on unmount.
  void dispose() {
    _disposed = true;
    _gestures?.cancel();
    _gestures = null;
  }

  Future<T> _call<T>(String method, [Map<String, dynamic>? args]) async =>
      await _channel.invoke('map#$method', args) as T;

  // ── Camera ─────────────────────────────────────────────────────────────

  /// Convenience method that returns the `camera options` object for given parameters.
  Future<CameraOptions> cameraForCoordinatesPadding(
    List<Point> coordinates,
    CameraOptions camera,
    MbxEdgeInsets? coordinatesPadding,
    double? maxZoom,
    ScreenCoordinate? offset,
  ) async =>
      CameraOptions.fromJson(_requireMap(await _call('cameraForCoordinatesPadding', {
        'coordinates': coordinates.map((e) => e.toJson()).toList(),
        'camera': camera.toJson(),
        'coordinatesPadding': coordinatesPadding?.toJson(),
        'maxZoom': maxZoom,
        'offset': offset?.toJson(),
      })));

  /// Convenience method that returns the `camera options` object for given parameters.
  Future<CameraOptions> cameraForCoordinateBounds(
          CoordinateBounds bounds,
          MbxEdgeInsets padding,
          double? bearing,
          double? pitch,
          double? maxZoom,
          ScreenCoordinate? offset) async =>
      CameraOptions.fromJson(_requireMap(await _call('cameraForCoordinateBounds', {
        'bounds': bounds.toJson(),
        'padding': padding.toJson(),
        'bearing': bearing,
        'pitch': pitch,
        'maxZoom': maxZoom,
        'offset': offset?.toJson(),
      })));

  /// Convenience method that returns the `camera options` object for given parameters.
  Future<CameraOptions> cameraForCoordinates(List<Point> coordinates,
          MbxEdgeInsets padding, double? bearing, double? pitch) async =>
      CameraOptions.fromJson(_requireMap(await _call('cameraForCoordinates', {
        'coordinates': coordinates.map((e) => e.toJson()).toList(),
        'padding': padding.toJson(),
        'bearing': bearing,
        'pitch': pitch,
      })));

  /// Convenience method that adjusts the provided `camera options` object for given parameters.
  Future<CameraOptions> cameraForCoordinatesCameraOptions(
          List<Point> coordinates, CameraOptions camera, ScreenBox box) async =>
      CameraOptions.fromJson(
          _requireMap(await _call('cameraForCoordinatesCameraOptions', {
        'coordinates': coordinates.map((e) => e.toJson()).toList(),
        'camera': camera.toJson(),
        'box': box.toJson(),
      })));

  /// Convenience method that returns the `camera options` object for given parameters.
  Future<CameraOptions> cameraForGeometry(Map<String?, Object?> geometry,
          MbxEdgeInsets padding, double? bearing, double? pitch) async =>
      CameraOptions.fromJson(_requireMap(await _call('cameraForGeometry', {
        'geometry': geometry,
        'padding': padding.toJson(),
        'bearing': bearing,
        'pitch': pitch,
      })));

  /// Returns the `coordinate bounds` for a given camera.
  Future<CoordinateBounds> coordinateBoundsForCamera(
          CameraOptions camera) async =>
      CoordinateBounds.fromJson(_requireMap(
          await _call('coordinateBoundsForCamera', {'camera': camera.toJson()})));

  /// Returns the `coordinate bounds` for a given camera.
  Future<CoordinateBounds> coordinateBoundsForCameraUnwrapped(
          CameraOptions camera) async =>
      CoordinateBounds.fromJson(_requireMap(await _call(
          'coordinateBoundsForCameraUnwrapped', {'camera': camera.toJson()})));

  /// Returns the `coordinate bounds` and the `zoom` for a given `camera`.
  Future<CoordinateBoundsZoom> coordinateBoundsZoomForCamera(
          CameraOptions camera) async =>
      CoordinateBoundsZoom.fromJson(_requireMap(await _call(
          'coordinateBoundsZoomForCamera', {'camera': camera.toJson()})));

  /// Returns the unwrapped `coordinate bounds` and `zoom` for a given `camera`.
  Future<CoordinateBoundsZoom> coordinateBoundsZoomForCameraUnwrapped(
          CameraOptions camera) async =>
      CoordinateBoundsZoom.fromJson(_requireMap(await _call(
          'coordinateBoundsZoomForCameraUnwrapped',
          {'camera': camera.toJson()})));

  /// Calculates a `screen coordinate` that corresponds to a geographical coordinate.
  ///
  /// The `screen coordinate` is in `logical pixels` relative to the top left corner
  /// of the map (not of the whole screen).
  Future<ScreenCoordinate> pixelForCoordinate(Point coordinate) async =>
      ScreenCoordinate.fromJson(_requireMap(await _call(
          'pixelForCoordinate', {'coordinate': coordinate.toJson()})));

  /// Calculates a geographical `coordinate` that corresponds to a `screen coordinate`.
  Future<Point> coordinateForPixel(ScreenCoordinate pixel) async =>
      Point.fromJson(_requireMap(
          await _call('coordinateForPixel', {'pixel': pixel.toJson()})));

  /// Calculates `screen coordinates` that correspond to geographical `coordinates`.
  Future<List<ScreenCoordinate?>> pixelsForCoordinates(
          List<Point> coordinates) async =>
      ((await _call('pixelsForCoordinates', {
        'coordinates': coordinates.map((e) => e.toJson()).toList()
      })) as List)
          .map((e) => e == null ? null : ScreenCoordinate.fromJson(_requireMap(e)))
          .toList();

  /// Calculates geographical `coordinates` that correspond to `screen coordinates`.
  Future<List<Point?>> coordinatesForPixels(
          List<ScreenCoordinate?> pixels) async =>
      ((await _call('coordinatesForPixels',
              {'pixels': pixels.map((e) => e?.toJson()).toList()})) as List)
          .map((e) => e == null ? null : Point.fromJson(_requireMap(e)))
          .toList();

  /// Changes the map view by any combination of center, zoom, bearing, and pitch, without an animated transition.
  /// The map will retain its current values for any details not passed via the camera options argument.
  Future<void> setCamera(CameraOptions cameraOptions) =>
      _call('setCamera', {'cameraOptions': cameraOptions.toJson()});

  /// Returns the current `camera state`.
  Future<CameraState> getCameraState() async =>
      Conversion.fromJson(_requireMap(await _call('getCameraState')));

  /// Sets the `camera bounds options` of the map.
  Future<void> setBounds(CameraBoundsOptions options) =>
      _call('setBounds', {'options': options.toJson()});

  /// Returns the `camera bounds` of the map.
  Future<CameraBounds> getBounds() async =>
      CameraBounds.fromJson(_requireMap(await _call('getBounds')));

  // ── Map interface ──────────────────────────────────────────────────────

  /// Gets the size of the map, in logical pixels.
  Future<Size> getSize() async =>
      Size.fromJson(_requireMap(await _call('getSize')));

  /// Triggers a repaint of the map.
  Future<void> triggerRepaint() => _call('triggerRepaint');

  /// Tells the map rendering engine that there is currently a gesture in progress.
  Future<void> setGestureInProgress(bool inProgress) =>
      _call('setGestureInProgress', {'inProgress': inProgress});

  /// Returns `true` if a gesture is currently in progress.
  Future<bool> isGestureInProgress() => _call('isGestureInProgress');

  /// Tells the map rendering engine that the animation is currently performed by the user.
  Future<void> setUserAnimationInProgress(bool inProgress) =>
      _call('setUserAnimationInProgress', {'inProgress': inProgress});

  /// Returns `true` if user animation is currently in progress.
  Future<bool> isUserAnimationInProgress() =>
      _call('isUserAnimationInProgress');

  /// When loading a map, if prefetch zoom `delta` is set to any number greater than 0,
  /// the map will first request a tile at zoom level lower than `zoom - delta`.
  Future<void> setPrefetchZoomDelta(int delta) =>
      _call('setPrefetchZoomDelta', {'delta': delta});

  /// Returns the map's prefetch zoom delta.
  Future<int> getPrefetchZoomDelta() async =>
      (await _call<num>('getPrefetchZoomDelta')).toInt();

  /// Sets the north `orientation mode`.
  Future<void> setNorthOrientation(NorthOrientation orientation) =>
      _call('setNorthOrientation', {'orientation': orientation.index});

  /// Sets the map `constrain mode`.
  Future<void> setConstrainMode(ConstrainMode mode) =>
      _call('setConstrainMode', {'mode': mode.index});

  /// Sets the `viewport mode`.
  Future<void> setViewportMode(ViewportMode mode) =>
      _call('setViewportMode', {'mode': mode.index});

  /// Returns the `map options`.
  Future<MapOptions> getMapOptions() async =>
      MapOptions.fromJson(_requireMap(await _call('getMapOptions')));

  /// The URL that points to the glyphs used by the style for rendering text labels on the map.
  Future<String> styleGlyphURL() => _call('styleGlyphURL');

  /// Sets a custom glyph URL at runtime.
  Future<void> setStyleGlyphURL(String glyphURL) =>
      _call('setStyleGlyphURL', {'glyphURL': glyphURL});

  /// Debug options for the widget associated with the map.
  Future<List<MapWidgetDebugOptions>> getDebugOptions() async =>
      ((await _call('getDebugOptions')) as List)
          .map((e) => _enumFromIndex(_MapWidgetDebugOptions.values, e))
          .whereType<_MapWidgetDebugOptions>()
          .map(MapWidgetDebugOptions._)
          .toList();

  /// Set debug options for the widget associated with the map.
  Future<void> setDebugOptions(List<MapWidgetDebugOptions> debugOptions) =>
      _call('setDebugOptions',
          {'debugOptions': debugOptions.map((e) => e._option.index).toList()});

  /// Queries the map for rendered features.
  Future<List<QueriedRenderedFeature?>> queryRenderedFeatures(
          RenderedQueryGeometry geometry, RenderedQueryOptions options) async =>
      ((await _call('queryRenderedFeatures',
              {'geometry': geometry.toJson(), 'options': options.toJson()}))
          as List)
          .map((e) =>
              e == null ? null : QueriedRenderedFeature.fromJson(_requireMap(e)))
          .toList();

  /// Queries the map for source features.
  Future<List<QueriedSourceFeature?>> querySourceFeatures(
          String sourceId, SourceQueryOptions options) async =>
      ((await _call('querySourceFeatures',
              {'sourceId': sourceId, 'options': options.toJson()})) as List)
          .map((e) =>
              e == null ? null : QueriedSourceFeature.fromJson(_requireMap(e)))
          .toList();

  /// Returns all the leaves (original points) of a cluster (given its cluster_id) from a GeoJsonSource.
  Future<FeatureExtensionValue> getGeoJsonClusterLeaves(String sourceIdentifier,
          Map<String?, Object?> cluster, int? limit, int? offset) async =>
      FeatureExtensionValue.fromJson(_requireMap(await _call(
          'getGeoJsonClusterLeaves', {
        'sourceIdentifier': sourceIdentifier,
        'cluster': cluster,
        'limit': limit,
        'offset': offset,
      })));

  /// Returns the children (original points or clusters) of a cluster (on the next zoom level).
  Future<FeatureExtensionValue> getGeoJsonClusterChildren(
          String sourceIdentifier, Map<String?, Object?> cluster) async =>
      FeatureExtensionValue.fromJson(_requireMap(await _call(
          'getGeoJsonClusterChildren',
          {'sourceIdentifier': sourceIdentifier, 'cluster': cluster})));

  /// Returns the zoom on which the cluster expands into several children.
  Future<FeatureExtensionValue> getGeoJsonClusterExpansionZoom(
          String sourceIdentifier, Map<String?, Object?> cluster) async =>
      FeatureExtensionValue.fromJson(_requireMap(await _call(
          'getGeoJsonClusterExpansionZoom',
          {'sourceIdentifier': sourceIdentifier, 'cluster': cluster})));

  /// Updates the state object of a feature within a style source.
  Future<void> setFeatureState(String sourceId, String? sourceLayerId,
          String featureId, String state) =>
      _call('setFeatureState', {
        'sourceId': sourceId,
        'sourceLayerId': sourceLayerId,
        'featureId': featureId,
        'state': state,
      });

  /// Gets the state map of a feature within a style source.
  Future<String> getFeatureState(
          String sourceId, String? sourceLayerId, String featureId) =>
      _call('getFeatureState', {
        'sourceId': sourceId,
        'sourceLayerId': sourceLayerId,
        'featureId': featureId,
      });

  /// Removes entries from a feature state object.
  Future<void> removeFeatureState(String sourceId, String? sourceLayerId,
          String featureId, String? stateKey) =>
      _call('removeFeatureState', {
        'sourceId': sourceId,
        'sourceLayerId': sourceLayerId,
        'featureId': featureId,
        'stateKey': stateKey,
      });

  /// Reduces memory use. Useful to call when the application gets paused or sent to background.
  Future<void> reduceMemoryUse() => _call('reduceMemoryUse');

  /// Gets elevation for the given coordinate.
  /// Note: Elevation is only available for the visible region on the screen and with terrain enabled.
  Future<double?> getElevation(Point coordinate) async =>
      _asDouble(await _call('getElevation', {'coordinate': coordinate.toJson()}));

  /// Returns tile ids covering the map.
  Future<List<CanonicalTileID>> tileCover(TileCoverOptions options) async =>
      ((await _call('tileCover', {'options': options.toJson()})) as List)
          .map((e) => CanonicalTileID.fromJson(_requireMap(e)))
          .toList();

  /// Will load a new map style asynchronous from the specified URI.
  ///
  /// URI can take the following forms:
  ///
  /// - **Constants**: load one of the bundled styles in [MapboxStyles].
  /// - **`mapbox://styles/<user>/<style>`**: loads the style from a Mapbox account.
  /// - **`http://...` or `https://...`**: loads the style over the Internet.
  /// - **`asset://...`** / **`file://...`**: loads a bundled or on-disk style.
  Future<void> loadStyleURI(String styleURI) =>
      _call('loadStyleURI', {'styleURI': styleURI});

  /// Loads a style from a JSON string.
  Future<void> loadStyleJson(String styleJson) =>
      _call('loadStyleJson', {'styleJson': styleJson});

  /// Clears temporary map data.
  Future<void> clearData() => _call('clearData');

  /// The memory budget hint to be used by the map. The budget can be given in
  /// tile units or in megabytes.
  Future<void> setTileCacheBudget(
          TileCacheBudgetInMegabytes? tileCacheBudgetInMegabytes,
          TileCacheBudgetInTiles? tileCacheBudgetInTiles) =>
      _call('setTileCacheBudget', {
        'tileCacheBudgetInMegabytes': tileCacheBudgetInMegabytes?.toJson(),
        'tileCacheBudgetInTiles': tileCacheBudgetInTiles?.toJson(),
      });

  // ── Animation ──────────────────────────────────────────────────────────

  /// Ease the map camera to a given camera options and animation options
  Future<void> easeTo(CameraOptions cameraOptions,
          MapAnimationOptions? mapAnimationOptions) =>
      _call('easeTo', {
        'cameraOptions': cameraOptions.toJson(),
        'mapAnimationOptions': mapAnimationOptions?.toJson(),
      });

  /// Fly the map camera to a given camera options.
  Future<void> flyTo(CameraOptions cameraOptions,
          MapAnimationOptions? mapAnimationOptions) =>
      _call('flyTo', {
        'cameraOptions': cameraOptions.toJson(),
        'mapAnimationOptions': mapAnimationOptions?.toJson(),
      });

  /// Pitch the map by with optional animation. Android only.
  Future<void> pitchBy(double pitch, MapAnimationOptions? mapAnimationOptions) =>
      _call('pitchBy',
          {'pitch': pitch, 'mapAnimationOptions': mapAnimationOptions?.toJson()});

  /// Scale the map by with optional animation. Android only.
  Future<void> scaleBy(double amount, ScreenCoordinate? screenCoordinate,
          MapAnimationOptions? mapAnimationOptions) =>
      _call('scaleBy', {
        'amount': amount,
        'screenCoordinate': screenCoordinate?.toJson(),
        'mapAnimationOptions': mapAnimationOptions?.toJson(),
      });

  /// Move the map by a given screen coordinate with optional animation. Android only.
  Future<void> moveBy(ScreenCoordinate screenCoordinate,
          MapAnimationOptions? mapAnimationOptions) =>
      _call('moveBy', {
        'screenCoordinate': screenCoordinate.toJson(),
        'mapAnimationOptions': mapAnimationOptions?.toJson(),
      });

  /// Rotate the map by with optional animation. Android only.
  Future<void> rotateBy(ScreenCoordinate first, ScreenCoordinate second,
          MapAnimationOptions? mapAnimationOptions) =>
      _call('rotateBy', {
        'first': first.toJson(),
        'second': second.toJson(),
        'mapAnimationOptions': mapAnimationOptions?.toJson(),
      });

  /// Cancel the ongoing camera animation if there is one.
  Future<void> cancelCameraAnimation() => _call('cancelCameraAnimation');

  // ── Gestures ───────────────────────────────────────────────────────────

  void _setupGestures() {
    if (_disposed) return;
    final wanted = onMapTapListener != null ||
        onMapLongTapListener != null ||
        onMapScrollListener != null ||
        onMapZoomListener != null;
    if (wanted && _gestures == null) {
      _gestures = _channel.stream('map#gestures').listen((raw) {
        try {
          final event = _requireMap(raw);
          final context =
              MapContentGestureContext.fromJson(_requireMap(event['context']));
          switch (event['type']) {
            case 'tap':
              onMapTapListener?.call(context);
            case 'longTap':
              onMapLongTapListener?.call(context);
            case 'scroll':
              onMapScrollListener?.call(context);
            case 'zoom':
              onMapZoomListener?.call(context);
          }
        } catch (error) {
          mapboxKitLog('gesture event $raw dropped: $error');
        }
      }, onError: (Object error) {
        mapboxKitLog('gesture stream error: $error');
      });
    } else if (!wanted && _gestures != null) {
      _gestures?.cancel();
      _gestures = null;
    }
  }

  void setOnMapTapListener(OnMapTapListener? onMapTapListener) {
    this.onMapTapListener = onMapTapListener;
    _setupGestures();
  }

  void setOnMapLongTapListener(OnMapLongTapListener? onMapLongTapListener) {
    this.onMapLongTapListener = onMapLongTapListener;
    _setupGestures();
  }

  void setOnMapMoveListener(OnMapScrollListener? onMapScrollListener) {
    this.onMapScrollListener = onMapScrollListener;
    _setupGestures();
  }

  void setOnMapZoomListener(OnMapZoomListener? onMapZoomListener) {
    this.onMapZoomListener = onMapZoomListener;
    _setupGestures();
  }

  /// Returns a snapshot of the map as PNG bytes.
  Future<Uint8List> snapshot() async =>
      base64Decode(await _call<String>('snapshot'));
}
