// The switches for this example. Change a value, save, run again.

/// Your public Mapbox token (`pk.…`).
///
/// Either paste it into [_pastedToken] below, or keep it out of the source
/// and pass it on the command line:
///
///     dn run -d <device-id> --dart-define=ACCESS_TOKEN=$(cat .mapbox_token)
///
/// The command-line value wins when both are set.
const String mapboxAccessToken =
    String.fromEnvironment('ACCESS_TOKEN', defaultValue: _pastedToken);
const String _pastedToken = '';

/// Prints extra readbacks from the SDK (layer properties, annotation counts)
/// with `dnLog` while the demos run.
const bool verboseLogs = false;
