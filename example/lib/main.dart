// mapbox_kit example.
//
// Two demos on top of the Mapbox Standard style:
//
//   * Journal   – a globe with four tappable place markers; pick two and
//                 "Get us there" draws the trip between them.
//   * Navigate  – tap the map twice for A and B, then "Navigate there":
//                 turn-by-turn driving with a Directions route, a bearing
//                 puck, maneuver banner, ETA bar and spoken guidance.
//
// The switches (token, verbose logs) live in config.dart. Run with:
//
//   dn run -d <device-id> --dart-define=ACCESS_TOKEN=$(cat .mapbox_token)

import 'package:dartnative/dartnative.dart';
import 'package:mapbox_kit/mapbox_kit.dart';

import 'config.dart';
import 'dartnative_plugin_registrant.dart';
import 'journal/journal_screen.dart';
import 'navigation/navigation_screen.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  if (mapboxAccessToken.isNotEmpty) MapboxOptions.setAccessToken(mapboxAccessToken);
  mapboxKitVerbose = verboseLogs;
  SystemChrome.defaultStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
  runApp(const MapboxExample());
}

class MapboxExample extends StatefulWidget {
  const MapboxExample({super.key});

  @override
  State<MapboxExample> createState() => _MapboxExampleState();
}

class _MapboxExampleState extends State<MapboxExample> {
  bool _navigating = false;

  @override
  Widget build(BuildContext context) {
    if (mapboxAccessToken.isEmpty) return const _NoTokenScreen();
    return Scaffold(
      brightness: Brightness.light,
      backgroundColor: const Color(0xFF0B0D12),
      // Only one map is alive at a time: the journal's, or the navigation's.
      body: _navigating
          ? NavigationScreen(
              key: const ValueKey('navigation'),
              onClose: () => setState(() => _navigating = false),
            )
          : JournalScreen(
              key: const ValueKey('journal'),
              onNavigate: () => setState(() => _navigating = true),
            ),
    );
  }
}

/// Shown instead of the map when no token was provided.
class _NoTokenScreen extends StatelessWidget {
  const _NoTokenScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      brightness: Brightness.light,
      backgroundColor: Color(0xFFFFFFFF),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No Mapbox token.\n\nPaste it into lib/config.dart or run with\n'
            'dn run --dart-define=ACCESS_TOKEN=\$(cat .mapbox_token)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF16191F), fontSize: 15, height: 1.5),
          ),
        ),
      ),
    );
  }
}
