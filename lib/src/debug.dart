import 'package:dartnative/dartnative.dart' show dnLog;

/// Set to true to log every native call and event of mapbox_kit.
bool mapboxKitVerbose = false;

void mapboxKitLog(String message) {
  if (mapboxKitVerbose) dnLog('[mapbox_kit] $message');
}
