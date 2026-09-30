## 0.1.0

Initial release: the `mapbox_maps_flutter` 2.31.0 API for DartNative on
Mapbox Maps SDK 11.31.0, over FFI (no platform channels).

- `MapWidget` with `onMapCreated`, style / map / camera / idle / error
  listeners and tap / long-tap / scroll / zoom gesture listeners; `MapboxMap`
  with camera state, `setCamera`, `easeTo`, `flyTo`, `cameraForCoordinates*`,
  pixel ↔ coordinate conversion, `loadStyleURI` / `loadStyleJson`, feature
  queries, feature state, elevation, snapshots.
- `StyleManager` with sources, layers, layer / source properties, Standard
  style imports and config (`lightPreset`, `theme`, `show3dObjects`, …),
  terrain, lights, images, models, projection; `GeoJsonSource`,
  `RasterDemSource`, `LineLayer`, `SymbolLayer`, `CircleLayer`, `FillLayer`,
  `FillExtrusionLayer` ported from the plugin, any other type through JSON.
- Point and polyline annotation managers with tap, long-press and drag
  events, every layer-level property setter and getter, and `setSlot` /
  `getSlot` for Mapbox Standard slots.
- Location component settings with the default, custom 2D and 3D pucks;
  gestures, logo, compass, scale bar and attribution settings;
  `MapboxOptions.setAccessToken` and `MapboxMapsOptions`.
- iOS: manager-level annotation properties (`setIconAllowOverlap`,
  `setIconRotationAlignment`, …) are applied to the Mapbox manager object,
  since setting them on the layer was overridden by the manager's own sync;
  `setSymbolElevationReference` reaches the SDK's experimental property.
- Map events are subscribed natively when the map is created and replayed
  once the Dart stream attaches, so `onStyleLoadedListener` fires even when
  the style finishes loading before Dart is listening (slow launches).
- Example app: a journal on a night globe (tap a city, drop A and B, run
  the Directions route, drive it in 3D, switch between all built-in styles)
  and simulated turn-by-turn navigation with spoken guidance (SuperTonic-3
  on-device TTS through `dartnative_audio`).
