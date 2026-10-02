import 'package:dartnative/dartnative.dart' show dnLog;

/// Set to true to log every native call and event of mapbox_kit.
bool mapboxKitVerbose = false;

/// Set to true to print, every 5 seconds while the map is busy, what the
/// calls into the native side cost per method: count, bytes sent, Dart
/// encode time, native time and the time until the reply.
bool mapboxKitPerfLogs = false;

void mapboxKitLog(String message) {
  if (mapboxKitVerbose) dnLog('[mapbox_kit] $message');
}
