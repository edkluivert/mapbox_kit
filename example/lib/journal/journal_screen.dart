// The journal: a dark globe with four bracket markers. Tap one and it turns
// orange while the map flies down into that city. Tap the map twice there
// to drop A and B, "Get us there" runs the route between them and "Drive it
// in 3D" drives it with a puck and a low follow camera. The pill at the
// top switches between the built-in styles (and Standard's light presets);
// the arrow
// button opens the navigation demo and the button under it zooms back out
// to the globe.

import 'package:dartnative/dartnative.dart';
import 'package:mapbox_kit/mapbox_kit.dart';

import '../config.dart';
import '../navigation/directions.dart';
import '../shared/geo.dart';
import '../shared/widgets.dart';
import 'journal_map.dart';
import 'places.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, this.onNavigate});

  /// Opens the turn-by-turn screen (the arrow button).
  final VoidCallback? onNavigate;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const _presetIcons = [
    MaterialSymbolsRounded.dark_mode,
    MaterialSymbolsRounded.wb_twilight,
    MaterialSymbolsRounded.light_mode,
    MaterialSymbolsRounded.wb_twilight,
  ];

  JournalMap? _journal;
  bool _ready = false;

  // Style and look.
  int _style = 0; // index into mapStyles
  int _preset = 0; // index into lightPresets (Standard only)
  final bool _monochrome = true;

  MapStyle get _mapStyle => mapStyles[_style];

  // The picked place, the A / B points inside it and the route between them.
  Place? _place;
  Position? _from;
  Position? _to;
  bool _fetching = false;
  bool _routeShown = false;
  String _routeMiles = '';
  String? _error;
  DirectionsRoute? _route;

  // The 3D drive along the route.
  bool _driving = false;
  bool _arrived = false;
  String _driveText = '';

  /// Dark chrome for the dark styles; on Standard for the night preset and
  /// monochrome dusk, light for dawn and day.
  bool get _dark {
    if (_mapStyle.uri == MapboxStyles.STANDARD) {
      return _preset == 0 || (_monochrome && _preset == 3);
    }
    return _mapStyle.dark;
  }

  @override
  void dispose() {
    _journal?.dispose();
    super.dispose();
  }

  // ── Map ───────────────────────────────────────────────────────────────

  void _onMapCreated(MapboxMap map) {
    _journal = JournalMap(map, onPlaceTapped: _onPlaceTapped);
  }

  /// Fires for the first style and again after every style switch.
  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final journal = _journal;
    if (journal == null) return;
    try {
      await journal.onStyleLoaded(lightPreset: lightPresets[_preset], monochrome: _monochrome);
      if (!mounted) return;
      if (!_ready) {
        setState(() => _ready = true);
        dnLog('[journal] ready');
      }
    } catch (e) {
      dnLog('[journal] setup failed: $e');
    }
  }

  /// The style button: the next built-in style.
  Future<void> _cycleStyle() async {
    final journal = _journal;
    if (journal == null || !_ready) return;
    setState(() => _style = (_style + 1) % mapStyles.length);
    try {
      await journal.setStyle(_mapStyle);
    } on PlatformException catch (e) {
      // A quicker second tap cancels the load in progress; the newer style
      // still arrives, so there is nothing to report.
      if (e.message?.contains('CancelError') ?? false) return;
      dnLog('[journal] style failed: $e');
    } catch (e) {
      dnLog('[journal] style failed: $e');
    }
  }

  /// A bracket marker was tapped: it becomes the place (orange) and the map
  /// flies down into it. Any pins or route from before are cleared.
  Future<void> _onPlaceTapped(Place place) async {
    final journal = _journal;
    if (journal == null || !_ready) return;
    try {
      final previous = _place;
      if (previous == place) {
        await journal.flyTo(place);
        return;
      }
      await _clearTrip();
      setState(() => _place = place);
      if (previous != null) await journal.setSelected(previous, false);
      await journal.setSelected(place, true);
      await journal.flyTo(place);
    } catch (e) {
      dnLog('[journal] could not pick ${place.name}: $e');
    }
  }

  /// A tap on the map inside a place: the first one is A, the second B.
  /// After a route, a new tap starts over.
  Future<void> _onMapTap(MapContentGestureContext context) async {
    final journal = _journal;
    if (journal == null || !_ready || _place == null || _fetching || _driving) return;
    if (journal.tapWasOnMarker) return;
    final position = context.point.coordinates;
    try {
      if (_routeShown || (_from != null && _to != null)) {
        await _clearTrip();
      }
      if (_from == null) {
        setState(() {
          _from = position;
          _error = null;
        });
        await journal.addPin('A', position);
      } else {
        setState(() {
          _to = position;
          _error = null;
        });
        await journal.addPin('B', position);
      }
    } catch (e) {
      dnLog('[journal] could not drop a pin: $e');
    }
  }

  /// "Get us there": fetch the route from A to B and run the line.
  Future<void> _getUsThere() async {
    final journal = _journal;
    final from = _from, to = _to;
    if (journal == null || from == null || to == null || _fetching) return;
    setState(() {
      _fetching = true;
      _error = null;
    });
    final route = await DirectionsRoute.fetch(mapboxAccessToken, origin: from, destination: to);
    if (!mounted) return;
    if (route == null) {
      setState(() {
        _fetching = false;
        _error = 'No route between those points';
      });
      return;
    }
    setState(() {
      _fetching = false;
      _routeShown = true;
      _route = route;
      _routeMiles = '0.00 mi';
    });
    try {
      await journal.showRoute(route, onProgress: (distance) {
        if (mounted) setState(() => _routeMiles = distance);
      });
      await journal.logState();
    } catch (e) {
      dnLog('[journal] route failed: $e');
    }
  }

  /// "Drive it in 3D": the puck drives the route with a follow camera.
  Future<void> _drive() async {
    final journal = _journal;
    final route = _route;
    if (journal == null || route == null || _driving) return;
    setState(() {
      _driving = true;
      _arrived = false;
      _driveText = 'Starting…';
    });
    try {
      await journal.startDrive(
        route,
        onUpdate: (drive) {
          if (!mounted) return;
          if (drive.arrived) {
            // The puck is at B: say so and end the drive, leaving the
            // route and the puck where they are.
            setState(() {
              _driving = false;
              _arrived = true;
            });
            return;
          }
          setState(() {
            _driveText = '${drive.step?.bannerText ?? drive.step?.instruction ?? ''} · '
                '${milesShort(drive.remaining)} left';
          });
        },
        onAnnounce: (text) {
          if (mounted) setState(() => _driveText = text);
        },
      );
    } catch (e) {
      dnLog('[journal] drive failed: $e');
      if (mounted) setState(() => _driving = false);
    }
  }

  /// "Stop": ends the drive; the route stays on the map.
  Future<void> _stopDrive() async {
    setState(() {
      _driving = false;
      _arrived = false;
      _driveText = '';
    });
    await _journal?.stopDrive();
  }

  /// Removes the pins, the route and the drive, keeping the place.
  Future<void> _clearTrip() async {
    setState(() {
      _from = null;
      _to = null;
      _routeShown = false;
      _routeMiles = '';
      _error = null;
      _route = null;
      _driving = false;
      _arrived = false;
      _driveText = '';
    });
    await _journal?.clear();
  }

  /// Clear: everything off, back to the globe.
  Future<void> _reset() async {
    final journal = _journal;
    if (journal == null) return;
    final place = _place;
    await _clearTrip();
    setState(() => _place = null);
    if (place != null) await journal.setSelected(place, false);
    await journal.showGlobe();
  }

  /// The zoom-out button: back to the globe, everything else untouched.
  Future<void> _zoomOut() async {
    try {
      await _journal?.showGlobe();
    } catch (e) {
      dnLog('[journal] zoom out failed: $e');
    }
  }

  Future<void> _applyLook() async {
    try {
      await _journal?.setLook(lightPreset: lightPresets[_preset], monochrome: _monochrome);
    } catch (e) {
      dnLog('[journal] look failed: $e');
    }
  }

  void _cyclePreset() {
    setState(() => _preset = (_preset + 1) % lightPresets.length);
    _applyLook();
  }

  // ── UI ────────────────────────────────────────────────────────────────

  Color get _pill => _dark ? const Color(0xCC1B1F26) : const Color(0xCCFFFFFF);
  Color get _ink => _dark ? const Color(0xFFF3F4F6) : const Color(0xFF16191F);
  Color get _muted => _dark ? const Color(0xFFB0B6C1) : const Color(0xFF5B6270);

  String get _title => _place?.name ?? 'World';

  String get _subtitle {
    if (_error != null) return _error!;
    if (_arrived) return 'We are here · $_routeMiles';
    if (_driving) return _driveText;
    if (_routeShown) return 'Trip · $_routeMiles';
    if (_fetching) return 'Finding a route…';
    if (_place == null) return '${places.length} places · tap one to start';
    if (_from == null) return 'Tap the map: where from?';
    if (_to == null) return 'Now tap where to';
    return 'Ready when you are';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: MapWidget(
            styleUri: mapStyles.first.uri,
            cameraOptions: globeCamera,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onTapListener: _onMapTap,
            onMapLoadErrorListener: (e) => dnLog('[journal] load error ${e.type.name}: ${e.message}'),
          ),
        ),
        _topBar(),
        _caption(),
        _buttons(),
        if (_from != null && _to != null) _tripButton(),
        if (!_ready) LoadingHint('Loading Mapbox Standard…', color: _muted),
      ],
    );
  }

  /// The style pill on the left (style button, the style's name, and on
  /// Standard the light-preset button) and Clear on the right once a place
  /// is picked.
  Widget _topBar() {
    final standard = _mapStyle.isStandard;
    final label = standard ? '${_mapStyle.name} · ${lightPresets[_preset]}' : _mapStyle.name;
    return Positioned(
      left: 16,
      right: 16,
      top: 0,
      child: SafeArea(
        child: Row(
          children: [
            GlassEffectContainer(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(color: _pill, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        onPressed: _cycleStyle,
                        icon: Icon(MaterialSymbolsRounded.layers, size: 20, color: _ink)),
                    Text(label, style: TextStyle(color: _ink, fontSize: 12, fontFamily: monoFont)),
                    if (standard)
                      IconButton(
                          onPressed: _cyclePreset,
                          icon: Icon(_presetIcons[_preset], size: 20, color: _ink))
                    else
                      const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (_place != null)
              TextPill(text: 'Clear', onTap: _reset, background: _pill, foreground: _ink),
          ],
        ),
      ),
    );
  }

  /// Title and state, bottom left.
  Widget _caption() {
    return Positioned(
      left: 20,
      right: 92,
      bottom: 44,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title,
                maxLines: 2,
                style: TextStyle(
                    color: _ink, fontSize: 22, fontWeight: FontWeight.w600, fontFamily: monoFont)),
            const SizedBox(height: 4),
            Text(_subtitle,
                maxLines: 2, style: TextStyle(color: _muted, fontSize: 12, fontFamily: monoFont)),
          ],
        ),
      ),
    );
  }

  /// Navigate and zoom-out buttons, bottom right. They live in their own
  /// column: a Row with an Expanded and two buttons only drew one of them
  /// on iOS.
  Widget _buttons() {
    return Positioned(
      right: 20,
      bottom: 44,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoundButton(
              icon: MaterialSymbolsRounded.navigation,
              onTap: () => widget.onNavigate?.call(),
              background: _pill,
              foreground: _ink,
            ),
            const SizedBox(height: 12),
            RoundButton(
              icon: MaterialSymbolsRounded.zoom_out_map,
              onTap: _zoomOut,
              background: _pill,
              foreground: _ink,
            ),
          ],
        ),
      ),
    );
  }

  /// "Get us there" once A and B are down, then "Drive it in 3D" once the
  /// route is on the map, "Stop" while driving and "We are here" at B.
  Widget _tripButton() {
    final String text;
    final VoidCallback onTap;
    if (_driving) {
      text = 'Stop';
      onTap = _stopDrive;
    } else if (_arrived) {
      text = 'We are here';
      onTap = _drive; // drive it again
    } else if (_routeShown) {
      text = 'Drive it in 3D';
      onTap = _drive;
    } else {
      text = _fetching ? 'Finding a route…' : 'Get us there';
      onTap = _getUsThere;
    }
    return Positioned(
      left: 0,
      right: 0,
      bottom: 124,
      child: SafeArea(
        child: Center(
          child: TextPill(
            text: text,
            onTap: onTap,
            background: _driving || _arrived ? _pill : const Color(activityOrange),
            foreground: _driving || _arrived ? _ink : Colors.white,
          ),
        ),
      ),
    );
  }
}
