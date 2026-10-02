// Turn-by-turn navigation. Tap the map twice to drop the A and B pins, then
// "Navigate there" fetches a Directions route and drives it: a blue line
// that greys out behind a bearing puck, a maneuver banner, an ETA bar and
// the floating mute / overview / recenter buttons. The drive is simulated
// by DriveSimulator; the voice comes from NavigationVoice.

import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:mapbox_kit/mapbox_kit.dart';

import '../config.dart';
import '../shared/geo.dart';
import '../shared/marker_images.dart';
import '../shared/perf.dart';
import '../shared/widgets.dart';
import 'directions.dart';
import 'drive_simulator.dart';
import 'voice.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key, this.onClose});

  /// Called by the X button: back to the journal.
  final VoidCallback? onClose;

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  static const _routeSource = 'nav-route';
  static const _routeLayers = ['nav-route-casing', 'nav-route-line'];
  static const _emptyGeoJson = '{"type":"FeatureCollection","features":[]}';

  /// Where the map opens: Mountain View, close enough to pick two points.
  static final _startCamera = CameraOptions(
      center: Point(coordinates: Position(-122.07, 37.385)), zoom: 12.6, pitch: 0, bearing: 0);

  MapboxMap? _map;
  bool _ready = false;
  GeoJsonSource? _routeGeo;

  // The picked points and their pins.
  PointAnnotationManager? _pins;
  Position? _origin;
  Position? _destination;
  PointAnnotation? _pinA;
  PointAnnotation? _pinB;

  // The drive.
  bool _fetching = false;
  String? _error;
  DriveSimulator? _drive;
  final DriveStepStats _stepStats = DriveStepStats('navigation');
  final Stopwatch _slowUpdates = Stopwatch()..start();
  PointAnnotationManager? _pucks;
  PointAnnotation? _puck;

  bool _muted = false;
  bool _overview = false;
  String _lastAnnouncement = '';

  bool get _driving => _drive != null;

  @override
  void initState() {
    super.initState();
    // Download (first run) and load the on-device voice early so the first
    // manoeuvre is spoken, not just shown.
    unawaited(NavigationVoice.warmUp());
    NavigationVoice.status.addListener(_onVoiceStatus);
  }

  void _onVoiceStatus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    NavigationVoice.status.removeListener(_onVoiceStatus);
    _drive?.stop();
    unawaited(NavigationVoice.stop());
    super.dispose();
  }

  // ── Map ───────────────────────────────────────────────────────────────

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _map;
    if (map == null || _ready) return;
    try {
      await _addRouteLayers(map);
      _pins = await _markerManager(map);
      _pucks = await _markerManager(map);
      // The puck rotates with the map (not the screen) so it points along
      // the road.
      await _pucks!.setIconRotationAlignment(IconRotationAlignment.MAP);
      await map.compass.updateSettings(CompassSettings(enabled: false));
      await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
      await map.logo.updateSettings(LogoSettings(marginBottom: 96));
      await map.attribution.updateSettings(AttributionSettings(marginBottom: 96));
      if (!mounted) return;
      setState(() => _ready = true);
      dnLog('[navigation] ready');
    } catch (e) {
      dnLog('[navigation] setup failed: $e');
    }
  }

  /// A marker manager that always draws its icons, on top of everything.
  Future<PointAnnotationManager> _markerManager(MapboxMap map) async {
    final manager = await map.annotations.createPointAnnotationManager();
    await manager.setIconAllowOverlap(true);
    await manager.setIconIgnorePlacement(true);
    await manager.setIconOcclusionOpacity(1.0);
    return manager;
  }

  /// The route as a casing plus a line, empty until a route is fetched.
  /// `line-trim-color` greys the part already driven instead of hiding it.
  Future<void> _addRouteLayers(MapboxMap map) async {
    _routeGeo = GeoJsonSource(id: _routeSource, data: _emptyGeoJson, lineMetrics: true);
    await map.style.addSource(_routeGeo!);
    await map.style.addLayer(LineLayer(
      id: _routeLayers[0],
      sourceId: _routeSource,
      lineColor: navBlueDark,
      lineWidth: 16,
      lineCap: LineCap.ROUND,
      lineJoin: LineJoin.ROUND,
      lineTrimOffset: [0, 0],
    ));
    await map.style.addLayer(LineLayer(
      id: _routeLayers[1],
      sourceId: _routeSource,
      lineColor: navBlue,
      lineWidth: 11,
      lineCap: LineCap.ROUND,
      lineJoin: LineJoin.ROUND,
      lineTrimOffset: [0, 0],
    ));
    for (final id in _routeLayers) {
      await map.style.setStyleLayerProperty(id, 'line-trim-color', navTraveled.toRGBA());
    }
  }

  // ── Picking ───────────────────────────────────────────────────────────

  /// A tap on the map: the first one is A, the second B. While driving,
  /// taps are ignored; after both pins are set a new tap starts over.
  Future<void> _onMapTap(MapContentGestureContext context) async {
    if (!_ready || _driving || _fetching) return;
    final position = context.point.coordinates;
    try {
      if (_origin == null) {
        setState(() {
          _origin = position;
          _error = null;
        });
        _pinA = await _pins!.create(_pin('A', position));
      } else if (_destination == null) {
        setState(() {
          _destination = position;
          _error = null;
        });
        _pinB = await _pins!.create(_pin('B', position));
      } else {
        // Both pins down: the tap just dismisses them; the next one is A.
        await _reset();
      }
    } catch (e) {
      dnLog('[navigation] could not drop a pin: $e');
    }
  }

  PointAnnotationOptions _pin(String letter, Position position) => PointAnnotationOptions(
        geometry: Point(coordinates: position),
        image: pinMarker(letter),
        iconSize: 1.0,
        iconAnchor: IconAnchor.CENTER,
      );

  /// Removes the pins, the route and the drive.
  Future<void> _reset() async {
    _drive?.stop();
    unawaited(NavigationVoice.stop());
    final pinA = _pinA, pinB = _pinB, puck = _puck;
    setState(() {
      _origin = null;
      _destination = null;
      _pinA = null;
      _pinB = null;
      _puck = null;
      _drive = null;
      _error = null;
      _overview = false;
      _lastAnnouncement = '';
    });
    try {
      if (pinA != null) await _pins?.delete(pinA);
      if (pinB != null) await _pins?.delete(pinB);
      if (puck != null) await _pucks?.delete(puck);
      await _routeGeo?.updateGeoJSON(_emptyGeoJson);
      await _map?.easeTo(_startCamera, MapAnimationOptions(duration: 700));
    } catch (e) {
      dnLog('[navigation] reset failed: $e');
    }
  }

  // ── Drive ─────────────────────────────────────────────────────────────

  /// "Navigate there": fetch the route between the pins and start driving.
  Future<void> _navigateThere() async {
    final map = _map;
    final origin = _origin, destination = _destination;
    if (map == null || origin == null || destination == null || _fetching) return;
    setState(() {
      _fetching = true;
      _error = null;
    });
    final route = await DirectionsRoute.fetch(mapboxAccessToken,
        origin: origin, destination: destination);
    if (!mounted) return;
    if (route == null) {
      setState(() {
        _fetching = false;
        _error = 'No driving route between those points. Try two others.';
      });
      return;
    }
    try {
      await _routeGeo!.updateGeoJSON(
          '{"type":"Feature","properties":{},"geometry":{"type":"LineString","coordinates":'
          '${route.coordinates}}}');
      for (final id in _routeLayers) {
        await map.style.setStyleLayerProperty(id, 'line-trim-offset', [0.0, 0.0]);
      }
      if (!mounted) return;
      _drive = DriveSimulator(route: route, onUpdate: _onDriveUpdate, onAnnounce: _announce);
      setState(() => _fetching = false);
      dnLog('[navigation] route ${route.distance.round()} m, ${route.steps.length} steps');
      await _start();
    } catch (e) {
      dnLog('[navigation] could not start: $e');
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _start() async {
    final drive = _drive;
    if (drive == null) return;
    final first = drive.player.sample(0);
    _puck ??= await _pucks!.create(PointAnnotationOptions(
      geometry: Point(coordinates: first.position),
      image: puckImage(),
      // The 96 px bitmap lands at 32 pt on screen; the clip's puck is about
      // a seventh of the screen width.
      iconSize: 1.9,
      iconRotate: first.heading,
    ));
    await _follow(first, const Duration(milliseconds: 900));
    setState(() => _overview = false);
    drive.start();
    dnLog('[navigation] started');
  }

  /// One frame of the drive. The puck and the camera move in the same
  /// frame, so the puck holds still on screen while the map moves under it;
  /// the route trim and the banner follow ten times a second.
  Future<void> _onDriveUpdate(RouteSample s) async {
    final map = _map;
    final puck = _puck;
    if (map == null || puck == null) return;
    final step = _stepStats.start();
    puck.geometry = Point(coordinates: s.position);
    puck.iconRotate = s.heading;
    final calls = <Future<void>>[_pucks!.update(puck)];
    if (!_overview) calls.add(map.setCamera(_followCamera(s)));
    final cameraMicros = step?.elapsedMicroseconds ?? 0;
    if (_slowUpdates.elapsedMilliseconds >= 100) {
      _slowUpdates.reset();
      for (final id in _routeLayers) {
        calls.add(map.style.setStyleLayerProperty(id, 'line-trim-offset', [0.0, s.fraction]));
      }
      if (mounted) setState(() {});
    }
    try {
      await Future.wait(calls);
      if (step != null) _stepStats.add(cameraMicros: cameraMicros, doneMicros: step.elapsedMicroseconds);
    } catch (e) {
      // The map is gone (screen closed or hot restart): stop for good.
      if (e is PlatformException && e.code == 'NO_MAP') {
        _drive?.stop();
        return;
      }
      dnLog('[navigation] tick failed: $e');
    }
    if (_drive?.arrived ?? false) dnLog('[navigation] arrived');
  }

  /// The follow camera, matched to the reference clip: a few blocks ahead
  /// visible, a moderate tilt, heading up, and the puck about two thirds
  /// of the way down the screen (the top padding pushes it there).
  static const _followZoom = 16.8;
  static const _followPitch = 45.0;
  static const _followPaddingTop = 280.0;

  Future<void> _follow(RouteSample s, Duration duration) {
    return _map!.easeTo(
      _followCamera(s),
      MapAnimationOptions(duration: duration.inMilliseconds),
    );
  }

  CameraOptions _followCamera(RouteSample s) => CameraOptions(
        center: Point(coordinates: s.position),
        zoom: _followZoom,
        pitch: _followPitch,
        bearing: s.heading,
        padding: MbxEdgeInsets(top: _followPaddingTop, left: 0, bottom: 0, right: 0),
      );

  /// Fits the whole route, or goes back to following the puck.
  Future<void> _toggleOverview() async {
    final map = _map;
    final drive = _drive;
    if (map == null || drive == null) return;
    setState(() => _overview = !_overview);
    if (_overview) {
      final camera = await map.cameraForCoordinatesPadding(
        [for (final p in drive.route.positions) Point(coordinates: p)],
        CameraOptions(bearing: 0, pitch: 0),
        MbxEdgeInsets(top: 160, left: 60, bottom: 220, right: 60),
        null,
        null,
      );
      await map.easeTo(camera, MapAnimationOptions(duration: 900));
    } else {
      await _follow(drive.sample, const Duration(milliseconds: 900));
    }
  }

  /// Speaks an instruction unless muted. It is also shown under the banner
  /// so the guidance is visible on devices without audio.
  void _announce(String text) {
    if (mounted) setState(() => _lastAnnouncement = text);
    if (_muted) return;
    unawaited(NavigationVoice.speak(text));
  }

  Future<void> _zoomBy(double delta) async {
    final map = _map;
    if (map == null || !_ready) return;
    // While driving the follow camera eases every tick; a manual zoom would
    // be overridden at once, so the buttons only act when not following.
    if (_driving && !_overview) return;
    await zoomBy(map, delta);
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    if (_muted) unawaited(NavigationVoice.stop());
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final drive = _drive;
    final step = drive?.step;
    return Stack(
      children: [
        Positioned.fill(
          child: MapWidget(
            styleUri: MapboxStyles.MAPBOX_STREETS,
            cameraOptions: _startCamera,
            onMapCreated: (map) => _map = map,
            onStyleLoadedListener: _onStyleLoaded,
            onTapListener: _onMapTap,
            onMapLoadErrorListener: (e) => dnLog('[navigation] load error ${e.type.name}: ${e.message}'),
          ),
        ),
        _banner(step, drive?.stepRemaining ?? 0),
        _floatingButtons(),
        if (_origin != null && _destination != null && !_driving) _navigateButton(),
        _etaBar(drive),
        if (!_ready) const LoadingHint('Loading map…', color: Color(0xFF4B5563)),
      ],
    );
  }

  /// While picking: what to tap next. While driving: the next maneuver,
  /// its distance, the last spoken line and the voice engine state.
  Widget _banner(DirectionsStep? step, double stepRemaining) {
    final String text;
    final IconData icon;
    if (_driving) {
      text = step?.bannerText ?? step?.instruction ?? 'Calculating route…';
      icon = _maneuverIcon(step);
    } else if (_error != null) {
      text = _error!;
      icon = MaterialSymbolsRounded.error;
    } else if (_origin == null) {
      text = 'Tap the map where you are';
      icon = MaterialSymbolsRounded.touch_app;
    } else if (_destination == null) {
      text = 'Now tap where you are going';
      icon = MaterialSymbolsRounded.touch_app;
    } else {
      text = _fetching ? 'Finding a route…' : 'Ready. Navigate there?';
      icon = MaterialSymbolsRounded.route;
    }
    final voiceStatus = NavigationVoice.status.value;
    return Positioned(
      left: 10,
      right: 10,
      top: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(color: bannerNavy, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, size: 34, color: Colors.white),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                    if (_driving) ...[
                      const SizedBox(height: 4),
                      Text(step == null ? '' : milesShort(stepRemaining),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                    if (_lastAnnouncement.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_lastAnnouncement,
                            maxLines: 2, style: const TextStyle(color: Color(0xFFC7D0E6), fontSize: 12)),
                      ),
                    if (voiceStatus != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(voiceStatus,
                            maxLines: 1, style: const TextStyle(color: Color(0xFF8FA0C4), fontSize: 11)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _floatingButtons() {
    return Positioned(
      right: 12,
      top: 118,
      child: SafeArea(
        child: Column(
          children: [
            FloatingButton(icon: MaterialSymbolsRounded.add, onTap: () => _zoomBy(1)),
            FloatingButton(icon: MaterialSymbolsRounded.remove, onTap: () => _zoomBy(-1)),
            FloatingButton(
              icon: _muted ? MaterialSymbolsRounded.volume_off : MaterialSymbolsRounded.volume_up,
              onTap: _toggleMute,
            ),
            FloatingButton(icon: MaterialSymbolsRounded.route, onTap: _toggleOverview, active: _overview),
            FloatingButton(
              icon: MaterialSymbolsRounded.navigation,
              onTap: () {
                if (_overview) _toggleOverview();
              },
            ),
            if (_origin != null)
              FloatingButton(icon: MaterialSymbolsRounded.restart_alt, onTap: _reset),
          ],
        ),
      ),
    );
  }

  /// "Navigate there", floating clear of the ETA bar once both pins are down.
  Widget _navigateButton() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 156,
      child: Center(
        child: TextPill(
          text: _fetching ? 'Finding a route…' : 'Navigate there',
          onTap: _navigateThere,
          background: const Color(navBlue),
          foreground: Colors.white,
        ),
      ),
    );
  }

  /// Minutes left, distance, arrival time and the X.
  Widget _etaBar(DriveSimulator? drive) {
    final seconds = drive?.remainingSeconds ?? 0;
    final remaining = drive?.remaining ?? 0;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(drive == null ? '–' : '${(seconds / 60).ceil()}',
                            style: const TextStyle(color: Color(0xFF111827), fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Text('min', style: TextStyle(color: Color(0xFF111827), fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(drive == null ? 'Pick two points to begin' : '${milesShort(remaining)} · ${_arrivalTime(seconds)}',
                        style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  _drive?.stop();
                  widget.onClose?.call();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  color: Colors.transparent,
                  child: const Icon(MaterialSymbolsRounded.close, size: 26, color: Color(0xFF111827)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _maneuverIcon(DirectionsStep? step) {
    final type = step?.bannerType ?? step?.maneuverType;
    final modifier = step?.bannerModifier ?? step?.maneuverModifier;
    if (type == 'arrive') return MaterialSymbolsRounded.flag;
    return switch (modifier) {
      'right' => MaterialSymbolsRounded.turn_right,
      'left' => MaterialSymbolsRounded.turn_left,
      'slight right' => MaterialSymbolsRounded.turn_slight_right,
      'slight left' => MaterialSymbolsRounded.turn_slight_left,
      'uturn' => MaterialSymbolsRounded.u_turn_left,
      _ => MaterialSymbolsRounded.straight,
    };
  }

  static String _arrivalTime(double secondsLeft) {
    final at = DateTime.now().add(Duration(seconds: secondsLeft.round()));
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${at.hour < 12 ? 'am' : 'pm'}';
  }
}
