part of '../mapbox_kit.dart';

/// Definition for listener invoked when the map is created.
typedef MapCreatedCallback = void Function(MapboxMap controller);

/// Definition for listener invoked when the style is fully loaded.
typedef OnStyleLoadedListener = void Function(
    StyleLoadedEventData styleLoadedEventData);

/// Definition for listener invoked whenever the camera position changes.
typedef OnCameraChangeListener = void Function(
    CameraChangedEventData cameraChangedEventData);

/// Definition for listener invoked whenever the Map has entered the idle state.
typedef OnMapIdleListener = void Function(MapIdleEventData mapIdleEventData);

/// Definition for listener invoked when the map loading finishes.
typedef OnMapLoadedListener = void Function(
    MapLoadedEventData mapLoadedEventData);

/// Definition for listener invoked whenever the map load errors out.
typedef OnMapLoadErrorListener = void Function(
    MapLoadingErrorEventData mapLoadingErrorEventData);

/// Definition for listener invoked whenever the Map started rendering a frame.
typedef OnRenderFrameStartedListener = void Function(
    RenderFrameStartedEventData renderFrameStartedEventData);

/// Definition for listener invoked whenever the Map finished rendering a frame.
typedef OnRenderFrameFinishedListener = void Function(
    RenderFrameFinishedEventData renderFrameFinishedEventData);

/// Definition for listener invoked whenever a source is added.
typedef OnSourceAddedListener = void Function(
    SourceAddedEventData sourceAddedEventData);

/// Definition for listener invoked when the requested source data has been loaded.
typedef OnSourceDataLoadedListener = void Function(
    SourceDataLoadedEventData sourceDataLoadedEventData);

/// Definition for listener invoked whenever a source is removed.
typedef OnSourceRemovedListener = void Function(
    SourceRemovedEventData sourceRemovedEventData);

/// Definition for listener invoked when the requested style data has been loaded.
typedef OnStyleDataLoadedListener = void Function(
    StyleDataLoadedEventData styleDataLoadedEventData);

/// Definition for listener invoked when the style has a missing image.
typedef OnStyleImageMissingListener = void Function(
    StyleImageMissingEventData styleImageMissingEventData);

/// Definition for listener invoked when an image added to the Style is no longer needed.
typedef OnStyleImageUnusedListener = void Function(
    StyleImageUnusedEventData styleImageUnusedEventData);

/// Definition for listener invoked when the map makes a resource request.
typedef OnResourceRequestListener = void Function(
    ResourceEventData resourceEventData);

/// Gesture listener called on map tap.
typedef OnMapTapListener = void Function(MapContentGestureContext context);

/// Gesture listener called on map long tap.
typedef OnMapLongTapListener = void Function(MapContentGestureContext context);

/// Gesture listener called on map scroll.
typedef OnMapScrollListener = void Function(MapContentGestureContext context);

/// Gesture listener called on map zoom.
typedef OnMapZoomListener = void Function(MapContentGestureContext context);
