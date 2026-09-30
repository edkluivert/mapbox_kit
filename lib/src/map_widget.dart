part of '../mapbox_kit.dart';

/// Registers the plugin with the framework: the [MapWidget] element factory
/// and the native FFI symbols. Called by the generated
/// `DartNativePluginRegistrant.registerAll()`; safe to call more than once.
abstract final class MapboxKit {
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    DartNativeReconciler.registerElementFactory<MapWidget>(
      (widget) => _MapWidgetElement(widget),
    );
    MapboxKitFFIBindings.loadSymbols();
  }
}

/// The view type key shared with the native providers.
abstract final class _MapboxKitViewType {
  static final int map = ViewType.claim('com.kluivert.mapbox_kit/map');
}

/// Plugin mutation tags, matched by the native providers.
abstract final class _MapMutation {
  static const int init = 1;
}

/// A MapWidget provides an embeddable map interface.
/// You use this class to display map information and to manipulate the map contents from your application.
/// You can center the map on a given coordinate, specify the size of the area you want to display,
/// and style the features of the map to fit your application's use case.
///
/// Use of MapWidget requires a Mapbox API access token, set with
/// [MapboxOptions.setAccessToken] before the widget is built.
/// Obtain an access token on the [Mapbox account page](https://www.mapbox.com/studio/account/tokens/).
///
/// The widget is a native leaf: it fills the space its parent gives it
/// (`grow: 1` in a flex parent, or the size of a `SizedBox`).
class MapWidget extends StatelessWidget {
  const MapWidget({
    super.key,
    this.mapOptions,
    this.cameraOptions,
    this.textureView = true,
    this.styleUri = MapboxStyles.STANDARD,
    this.onMapCreated,
    this.onStyleLoadedListener,
    this.onCameraChangeListener,
    this.onMapIdleListener,
    this.onMapLoadedListener,
    this.onMapLoadErrorListener,
    this.onRenderFrameStartedListener,
    this.onRenderFrameFinishedListener,
    this.onSourceAddedListener,
    this.onSourceDataLoadedListener,
    this.onSourceRemovedListener,
    this.onStyleDataLoadedListener,
    this.onStyleImageMissingListener,
    this.onStyleImageUnusedListener,
    this.onResourceRequestListener,
    this.onTapListener,
    this.onLongTapListener,
    this.onScrollListener,
    this.onZoomListener,
    this.isOpaque = true,
  });

  /// Describes the map options value when using a MapWidget.
  final MapOptions? mapOptions;

  /// The initial camera options when creating a MapWidget.
  final CameraOptions? cameraOptions;

  /// Flag indicating to use a TextureView as render surface for the MapWidget.
  /// Only works for Android.
  final bool? textureView;

  /// The styleUri applied when the map is created. Default is [MapboxStyles.STANDARD].
  final String styleUri;

  /// Invoked when a new Map is created and return a MapboxMap instance to handle the Map.
  final MapCreatedCallback? onMapCreated;

  /// Invoked when the requested style has been fully loaded, including the style, specified sprite and sources' metadata.
  final OnStyleLoadedListener? onStyleLoadedListener;

  /// Invoked whenever camera position changes.
  final OnCameraChangeListener? onCameraChangeListener;

  /// Invoked when the Map has entered the idle state.
  final OnMapIdleListener? onMapIdleListener;

  /// Invoked when the Map's style has been fully loaded, and the Map has rendered all visible tiles.
  final OnMapLoadedListener? onMapLoadedListener;

  /// Invoked whenever the map load errors out.
  final OnMapLoadErrorListener? onMapLoadErrorListener;

  /// Invoked whenever the Map finished rendering a frame.
  final OnRenderFrameFinishedListener? onRenderFrameFinishedListener;

  /// Invoked whenever the Map started rendering a frame.
  final OnRenderFrameStartedListener? onRenderFrameStartedListener;

  /// Invoked whenever the Source has been added with StyleManager#addStyleSource runtime API.
  final OnSourceAddedListener? onSourceAddedListener;

  /// Invoked when the requested source data has been loaded.
  final OnSourceDataLoadedListener? onSourceDataLoadedListener;

  /// Invoked whenever the Source has been removed with StyleManager#removeStyleSource runtime API.
  final OnSourceRemovedListener? onSourceRemovedListener;

  /// Invoked when the requested style data has been loaded.
  final OnStyleDataLoadedListener? onStyleDataLoadedListener;

  /// Invoked whenever a style has a missing image.
  final OnStyleImageMissingListener? onStyleImageMissingListener;

  /// Invoked whenever an image added to the Style is no longer needed.
  final OnStyleImageUnusedListener? onStyleImageUnusedListener;

  /// Invoked when map makes a request to load required resources.
  final OnResourceRequestListener? onResourceRequestListener;

  /// Whether the map is rendered as opaque. Only has an effect on iOS.
  final bool? isOpaque;

  /// Gesture listener called on map tap.
  final OnMapTapListener? onTapListener;

  /// Gesture listener called on map long tap.
  final OnMapLongTapListener? onLongTapListener;

  /// Gesture listener called on map scroll.
  final OnMapScrollListener? onScrollListener;

  /// Gesture listener called on map zoom.
  final OnMapZoomListener? onZoomListener;

  @override
  Widget build(BuildContext context) => throw UnimplementedError(
        'MapWidget is a native leaf widget; build() is never called. '
        'Is MapboxKit.initialize() in the plugin registrant?',
      );
}

/// Hosts the native map view and owns the [MapboxMap] handed to the app.
class _MapWidgetElement extends NativeElement {
  _MapWidgetElement(MapWidget super.widget);

  MapWidget get _widget => widget as MapWidget;

  final _MapEvents _events = _MapEvents();
  MapboxMap? _map;
  int? _readyToken;
  bool _unmounted = false;

  @override
  int get viewType => _MapboxKitViewType.map;

  @override
  ViewProps buildProps() => const FlexProps(direction: 0, grow: 1);

  @override
  void mount(Element? parent, UIKitReconciler reconciler) {
    super.mount(parent, reconciler); // creates the native container view
    final id = viewId!;
    // Stretch across the parent's cross axis; without this the view collapses
    // to width 0 in a Column on Android.
    emitMutation(SetAlignSelf(id, 1));

    _events.update(_widget);
    final readyToken = MapboxKitFFIBindings.registerHandler(_onReady,
        oneShot: true);
    _readyToken = readyToken;
    final params = <String, dynamic>{
      'readyToken': readyToken,
      'mapOptions': _widget.mapOptions?.toJson(),
      'cameraOptions': _widget.cameraOptions?.toJson(),
      'textureView': _widget.textureView,
      'styleUri': _widget.styleUri,
      'isOpaque': _widget.isOpaque,
      // Subscribed natively at creation so nothing fired while the map was
      // loading (styleLoaded, mapLoaded, ...) is lost before the Dart
      // stream attaches; the native side buffers and replays them.
      'eventTypes': _events.eventTypes.map((e) => e.index).toList(),
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(params)));
    emitMutation(PluginMutation(id, _MapMutation.init, bytes));
    mapboxKitLog('MapWidget mount viewId=$id readyToken=$readyToken');
  }

  void _onReady(int type, String payload) {
    _readyToken = null;
    if (_unmounted) return;
    if (type == MapboxKitEventType.error) {
      mapboxKitLog('map view failed to initialise: $payload');
      return;
    }
    final channel = _MapChannel(viewId!);
    final map = MapboxMap._(
      channel: channel,
      onMapTapListener: _widget.onTapListener,
      onMapLongTapListener: _widget.onLongTapListener,
      onMapScrollListener: _widget.onScrollListener,
      onMapZoomListener: _widget.onZoomListener,
    );
    _map = map;
    _events.attach(channel);
    _widget.onMapCreated?.call(map);
  }

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    _events.update(_widget);
    final map = _map;
    if (map != null) {
      map.onMapTapListener = _widget.onTapListener;
      map.onMapLongTapListener = _widget.onLongTapListener;
      map.onMapScrollListener = _widget.onScrollListener;
      map.onMapZoomListener = _widget.onZoomListener;
      map._setupGestures();
    }
  }

  @override
  void unmount() {
    _unmounted = true;
    final token = _readyToken;
    if (token != null) MapboxKitFFIBindings.removeHandler(token);
    _map?.dispose();
    _map = null;
    _events.detach();
    super.unmount();
  }
}

/// The map event listeners of one widget and their native subscription.
final class _MapEvents {
  OnStyleLoadedListener? _onStyleLoadedListener;
  OnCameraChangeListener? _onCameraChangeListener;
  OnMapIdleListener? _onMapIdleListener;
  OnMapLoadedListener? _onMapLoadedListener;
  OnMapLoadErrorListener? _onMapLoadErrorListener;
  OnRenderFrameFinishedListener? _onRenderFrameFinishedListener;
  OnRenderFrameStartedListener? _onRenderFrameStartedListener;
  OnSourceAddedListener? _onSourceAddedListener;
  OnSourceDataLoadedListener? _onSourceDataLoadedListener;
  OnSourceRemovedListener? _onSourceRemovedListener;
  OnStyleDataLoadedListener? _onStyleDataLoadedListener;
  OnStyleImageMissingListener? _onStyleImageMissingListener;
  OnStyleImageUnusedListener? _onStyleImageUnusedListener;
  OnResourceRequestListener? _onResourceRequestListener;

  _MapChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  List<_MapEvent> _subscribedEventTypes = const [];

  List<_MapEvent> get eventTypes {
    final listenersMap = {
      _onStyleLoadedListener: _MapEvent.styleLoaded,
      _onCameraChangeListener: _MapEvent.cameraChanged,
      _onMapIdleListener: _MapEvent.mapIdle,
      _onMapLoadedListener: _MapEvent.mapLoaded,
      _onMapLoadErrorListener: _MapEvent.mapLoadingError,
      _onRenderFrameFinishedListener: _MapEvent.renderFrameFinished,
      _onRenderFrameStartedListener: _MapEvent.renderFrameStarted,
      _onSourceAddedListener: _MapEvent.sourceAdded,
      _onSourceDataLoadedListener: _MapEvent.sourceDataLoaded,
      _onSourceRemovedListener: _MapEvent.sourceRemoved,
      _onStyleDataLoadedListener: _MapEvent.styleDataLoaded,
      _onStyleImageMissingListener: _MapEvent.styleImageMissing,
      _onStyleImageUnusedListener: _MapEvent.styleImageRemoveUnused,
      _onResourceRequestListener: _MapEvent.resourceRequest,
    };
    listenersMap.remove(null);
    return listenersMap.values.toList();
  }

  void update(MapWidget widget) {
    _onStyleLoadedListener = widget.onStyleLoadedListener;
    _onCameraChangeListener = widget.onCameraChangeListener;
    _onMapIdleListener = widget.onMapIdleListener;
    _onMapLoadedListener = widget.onMapLoadedListener;
    _onMapLoadErrorListener = widget.onMapLoadErrorListener;
    _onRenderFrameFinishedListener = widget.onRenderFrameFinishedListener;
    _onRenderFrameStartedListener = widget.onRenderFrameStartedListener;
    _onSourceAddedListener = widget.onSourceAddedListener;
    _onSourceDataLoadedListener = widget.onSourceDataLoadedListener;
    _onSourceRemovedListener = widget.onSourceRemovedListener;
    _onStyleDataLoadedListener = widget.onStyleDataLoadedListener;
    _onStyleImageMissingListener = widget.onStyleImageMissingListener;
    _onStyleImageUnusedListener = widget.onStyleImageUnusedListener;
    _onResourceRequestListener = widget.onResourceRequestListener;
    _updateSubscription();
  }

  void attach(_MapChannel channel) {
    _channel = channel;
    _updateSubscription();
  }

  void detach() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _subscribedEventTypes = const [];
  }

  void _updateSubscription() {
    final channel = _channel;
    if (channel == null) return;
    final newEventTypes = eventTypes;
    if (_subscription != null && _sameTypes(newEventTypes)) return;
    _subscription?.cancel();
    _subscription = null;
    _subscribedEventTypes = newEventTypes;
    if (newEventTypes.isEmpty) return;
    _subscription = channel.stream('map#events', {
      'eventTypes': newEventTypes.map((e) => e.index).toList(),
    }).listen(_handleEvent, onError: (Object error) {
      mapboxKitLog('map events stream error: $error');
    });
  }

  bool _sameTypes(List<_MapEvent> types) {
    if (types.length != _subscribedEventTypes.length) return false;
    for (var i = 0; i < types.length; i++) {
      if (types[i] != _subscribedEventTypes[i]) return false;
    }
    return true;
  }

  void _handleEvent(dynamic raw) {
    try {
      final event = _requireMap(raw);
      final type = _enumFromIndex(_MapEvent.values, event['type']);
      final data = _requireMap(event['data']);
      switch (type) {
        case _MapEvent.styleLoaded:
          _onStyleLoadedListener?.call(StyleLoadedEventData.fromJson(data));
        case _MapEvent.cameraChanged:
          _onCameraChangeListener
              ?.call(CameraChangedEventData.fromJson(data));
        case _MapEvent.mapIdle:
          _onMapIdleListener?.call(MapIdleEventData.fromJson(data));
        case _MapEvent.mapLoaded:
          _onMapLoadedListener?.call(MapLoadedEventData.fromJson(data));
        case _MapEvent.mapLoadingError:
          _onMapLoadErrorListener
              ?.call(MapLoadingErrorEventData.fromJson(data));
        case _MapEvent.renderFrameFinished:
          _onRenderFrameFinishedListener
              ?.call(RenderFrameFinishedEventData.fromJson(data));
        case _MapEvent.renderFrameStarted:
          _onRenderFrameStartedListener
              ?.call(RenderFrameStartedEventData.fromJson(data));
        case _MapEvent.sourceAdded:
          _onSourceAddedListener?.call(SourceAddedEventData.fromJson(data));
        case _MapEvent.sourceRemoved:
          _onSourceRemovedListener
              ?.call(SourceRemovedEventData.fromJson(data));
        case _MapEvent.sourceDataLoaded:
          _onSourceDataLoadedListener
              ?.call(SourceDataLoadedEventData.fromJson(data));
        case _MapEvent.styleDataLoaded:
          _onStyleDataLoadedListener
              ?.call(StyleDataLoadedEventData.fromJson(data));
        case _MapEvent.styleImageMissing:
          _onStyleImageMissingListener
              ?.call(StyleImageMissingEventData.fromJson(data));
        case _MapEvent.styleImageRemoveUnused:
          _onStyleImageUnusedListener
              ?.call(StyleImageUnusedEventData.fromJson(data));
        case _MapEvent.resourceRequest:
          _onResourceRequestListener?.call(ResourceEventData.fromJson(data));
        case null:
          mapboxKitLog('unknown map event: $raw');
      }
    } catch (error) {
      mapboxKitLog('map event $raw dropped: $error');
    }
  }
}
