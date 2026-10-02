// The switches for this example. Change a value, save, run again.

import 'dart:convert';

import 'package:dartnative/dartnative.dart';

/// Your public Mapbox token (`pk.…`), read from `mapbox.env` in the example
/// folder:
///
///     MAPBOX_ACCESS_TOKEN=pk.…
///
/// Copy `mapbox.env.example`, paste your token, run. The file is gitignored
/// and bundled as an asset, so nothing goes on the command line.
final String mapboxAccessToken = _envValue('MAPBOX_ACCESS_TOKEN');

/// Prints extra readbacks from the SDK (layer properties, annotation counts)
/// with `dnLog` while the demos run.
const bool verboseLogs = false;

/// Prints, every 5 seconds while a map is busy, what the calls into the
/// native side cost (mapbox_kit's `mapboxKitPerfLogs`), and how long each
/// step of the two drives takes.
const bool perfLogs = false;

/// Reads `KEY=value` lines from the bundled `mapbox.env`. Blank lines and
/// `#` comments are skipped; surrounding quotes on the value are dropped.
String _envValue(String key) {
  final bytes = loadAssetBytes('mapbox.env');
  if (bytes == null) return '';
  for (final raw in const LineSplitter().convert(utf8.decode(bytes))) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq < 0 || line.substring(0, eq).trim() != key) continue;
    var value = line.substring(eq + 1).trim();
    if (value.length >= 2 && (value.startsWith('"') && value.endsWith('"') || value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    return value;
  }
  return '';
}
