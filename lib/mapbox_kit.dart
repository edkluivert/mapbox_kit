/// Mapbox maps for DartNative with the `mapbox_maps_flutter` API.
///
/// ```dart
/// import 'package:mapbox_kit/mapbox_kit.dart';
///
/// MapboxOptions.setAccessToken(const String.fromEnvironment('ACCESS_TOKEN'));
///
/// MapWidget(
///   cameraOptions: CameraOptions(
///     center: Point(coordinates: Position(-122.4194, 37.7749)),
///     zoom: 12,
///   ),
///   onMapCreated: (MapboxMap map) async {
///     await map.style.setStyleImportConfigProperty(
///         'basemap', 'lightPreset', 'dusk');
///   },
/// );
/// ```
///
/// The public surface mirrors mapbox_maps_flutter 2.31.0 on pub.dev:
/// [MapWidget], [MapboxMap], [StyleManager] with sources and layers, the
/// annotation managers, [LocationSettings] and [MapboxOptions]. The map view
/// is hosted through DartNative's plugin view system and driven over FFI;
/// there are no platform channels.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative/plugin.dart';
import 'package:meta/meta.dart';
import 'package:turf/turf.dart' as turf;

import 'src/debug.dart';
import 'src/native/mapbox_kit_ffi_bindings.dart';

export 'package:turf/turf.dart' show Position, BBox;

export 'src/debug.dart' show mapboxKitPerfLogs, mapboxKitVerbose;
export 'src/native/mapbox_kit_ffi_bindings.dart' show MapboxKitFFIBindings;

part 'src/native/channel.dart';
part 'src/perf.dart';
part 'src/turf_adapters.dart';
part 'src/types.dart';
part 'src/events.dart';
part 'src/callbacks.dart';
part 'src/cancelable.dart';
part 'src/utils.dart';
part 'src/map_widget.dart';
part 'src/mapbox_map.dart';
part 'src/mapbox_options.dart';
part 'src/settings.dart';
part 'src/location_settings.dart';
part 'src/annotation/annotation_manager.dart';
part 'src/annotation/annotation_types.dart';
part 'src/annotation/point_annotation_manager.dart';
part 'src/annotation/polyline_annotation_manager.dart';
part 'src/style/style.dart';
part 'src/style/enums.dart';
part 'src/style/mapbox_styles.dart';
part 'src/style/layer/circle_layer.dart';
part 'src/style/layer/fill_extrusion_layer.dart';
part 'src/style/layer/fill_layer.dart';
part 'src/style/layer/line_layer.dart';
part 'src/style/layer/symbol_layer.dart';
part 'src/style/source/geojson_source.dart';
part 'src/style/source/rasterdem_source.dart';
