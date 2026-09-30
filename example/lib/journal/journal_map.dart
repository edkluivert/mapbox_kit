// Everything the journal does with the map: the style (all the built-in
// ones), the look (Standard's light preset + monochrome), the place markers
// and their taps, the
// A / B pins, the route line that runs between them and the 3D drive along
// it. The screen only talks to this class.

import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:mapbox_kit/mapbox_kit.dart';

import '../config.dart';
import '../navigation/directions.dart';
import '../navigation/drive_simulator.dart';
import '../shared/geo.dart';
import '../shared/marker_images.dart';
import '../shared/widgets.dart';
import 'places.dart';

/// The Standard style light presets, in the order the sun button cycles.
const List<String> lightPresets = ['night', 'dawn', 'day', 'dusk'];

class JournalMap {
  JournalMap(this.map, {required this.onPlaceTapped});

  final MapboxMap map;

  /// A bracket marker was tapped.
  final void Function(Place place) onPlaceTapped;

  static const _routeSource = 'journal-route';
  static const _routeCasing = 'journal-route-casing';
  static const _routeLayer = 'journal-route-line';
  static const _routeLayers = [_routeCasing, _routeLayer];
  static const _emptyGeoJson = '{"type":"FeatureCollection","features":[]}';

  PointAnnotationManager? _markers;
  PointAnnotationManager? _pins;
  PointAnnotationManager? _pucks;
  PointAnnotation? _puck;
  DriveSimulator? _drive;
  Cancelable? _taps;
  GeoJsonSource? _route;
  Timer? _drawing;
  final List<PointAnnotation> _pinAnnotations = [];

  /// Annotation id → place, and place → its current annotation. A marker is
  /// recreated when its look changes (see [setSelected]), so both maps are
  /// kept up to date there.
  final Map<String, Place> _placeOf = {};
  final Map<Place, PointAnnotation> _markerOf = {};

  /// When a bracket marker was last tapped. The map reports that tap as a
  /// map tap as well, which must not drop a pin.
  DateTime _lastMarkerTap = DateTime.fromMillisecondsSinceEpoch(0);

  /// Bumped whenever a route starts so a slower, older one cannot keep
  /// drawing after a newer one began.
  int _generation = 0;

  // ── Setup ─────────────────────────────────────────────────────────────

  /// The style showing now, and whether its layers are in place (false
  /// between [setStyle] and the next [onStyleLoaded], when route writes
  /// would hit layers that are not there yet).
  MapStyle style = mapStyles.first;
  bool _styleReady = false;
  bool _managersReady = false;

  /// The route line as last set, so a style change can put it back: the
  /// style's sources and layers are gone after `loadStyleURI`, while the
  /// annotation managers (markers, pins, puck) carry over on their own.
  String _routeData = _emptyGeoJson;
  List<double> _trim = [0, 1];
  String _trimColor = 'rgba(0, 0, 0, 0)';

  /// Called on every style load (the first one and each [setStyle]): the
  /// look for Standard, the route layers, and on the first load the marker
  /// managers with their taps.
  Future<void> onStyleLoaded({required String lightPreset, required bool monochrome}) async {
    if (style.isStandard) {
      await map.style.setStyleImportConfigProperties('basemap', {
        'lightPreset': lightPreset,
        'theme': monochrome ? 'monochrome' : 'default',
        'show3dObjects': true,
        'showPlaceLabels': false,
        'showRoadLabels': false,
        'showPointOfInterestLabels': false,
        'showTransitLabels': false,
      });
    }
    await _addRouteLayers();
    _styleReady = true;

    if (!_managersReady) {
      _managersReady = true;
      _markers = await _markerManager();
      _pins = await _markerManager();
      _pucks = await _markerManager();
      // The puck rotates with the map (not the screen) so it points along
      // the road.
      await _pucks!.setIconRotationAlignment(IconRotationAlignment.MAP);
      for (final place in places) {
        await _createMarker(place, selected: false);
      }
      _taps = _markers!.tapEvents(onTap: (annotation) {
        _lastMarkerTap = DateTime.now();
        final place = _placeOf[annotation.id];
        if (place != null) onPlaceTapped(place);
      });
      await map.compass.updateSettings(CompassSettings(enabled: false));
      await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    }
  }

  /// The route: a dark casing under an orange line. On Standard they go in
  /// the `middle` slot so they sit on the streets and the 3D buildings
  /// stand in front of them (in the default top slot the line would be
  /// painted over the rooftops); the classic styles have no slots.
  /// `lineMetrics` lets `line-trim-offset` hide or grey part of the line.
  Future<void> _addRouteLayers() async {
    final slot = style.isStandard ? 'middle' : null;
    _route = GeoJsonSource(id: _routeSource, data: _routeData, lineMetrics: true);
    await map.style.addSource(_route!);
    await map.style.addLayer(LineLayer(
      id: _routeCasing,
      sourceId: _routeSource,
      slot: slot,
      lineColor: activityOrangeDark,
      lineWidth: 11,
      lineCap: LineCap.ROUND,
      lineJoin: LineJoin.ROUND,
      lineTrimOffset: _trim,
      lineEmissiveStrength: 1,
    ));
    await map.style.addLayer(LineLayer(
      id: _routeLayer,
      sourceId: _routeSource,
      slot: slot,
      lineColor: activityOrange,
      lineWidth: 7,
      lineCap: LineCap.ROUND,
      lineJoin: LineJoin.ROUND,
      lineTrimOffset: _trim,
      lineEmissiveStrength: 1,
    ));
    for (final id in _routeLayers) {
      await map.style.setStyleLayerProperty(id, 'line-trim-color', _trimColor);
    }
  }

  /// Switches to another built-in style. The camera, markers, pins and
  /// puck stay; [onStyleLoaded] puts the route back once the style is in.
  Future<void> setStyle(MapStyle next) async {
    style = next;
    _styleReady = false;
    await map.loadStyleURI(next.uri);
  }

  Future<void> _setRouteData(String data) async {
    _routeData = data;
    if (_styleReady) await _route?.updateGeoJSON(data);
  }

  Future<void> _setTrim(List<double> offset, {String? color}) async {
    _trim = offset;
    if (color != null) _trimColor = color;
    if (!_styleReady) return; // remembered; applied when the style is in
    for (final id in _routeLayers) {
      if (color != null) await map.style.setStyleLayerProperty(id, 'line-trim-color', color);
      await map.style.setStyleLayerProperty(id, 'line-trim-offset', offset);
    }
  }

  /// A marker manager that always draws its icons, even where labels would
  /// collide with them, and in front of 3D buildings (Standard style on iOS
  /// hides them otherwise).
  Future<PointAnnotationManager> _markerManager() async {
    final manager = await map.annotations.createPointAnnotationManager();
    await manager.setIconAllowOverlap(true);
    await manager.setIconIgnorePlacement(true);
    await manager.setIconOcclusionOpacity(1.0);
    return manager;
  }

  /// Applies a light preset and theme to the Standard style.
  Future<void> setLook({required String lightPreset, required bool monochrome}) async {
    if (!style.isStandard) return;
    await map.style.setStyleImportConfigProperties('basemap', {
      'lightPreset': lightPreset,
      'theme': monochrome ? 'monochrome' : 'default',
    });
  }

  Future<void> _createMarker(Place place, {required bool selected}) async {
    final index = places.indexOf(place) + 1;
    final annotation = await _markers!.create(PointAnnotationOptions(
      geometry: Point(coordinates: place.position),
      image: placeMarker(
        count: index.toString().padLeft(2, '0'),
        label: place.label,
        color: selected ? activityOrange : 0xFFFFFFFF,
      ),
      iconSize: 1.0,
    ));
    _placeOf[annotation.id] = place;
    _markerOf[place] = annotation;
  }

  // ── Places ────────────────────────────────────────────────────────────

  /// Whether a map tap is really the tail of a marker tap.
  bool get tapWasOnMarker =>
      DateTime.now().difference(_lastMarkerTap) < const Duration(milliseconds: 600);

  /// Turns a place's brackets orange (or back to white). The marker is
  /// recreated rather than updated: an updated image keeps its old name on
  /// iOS and the SDK keeps showing the old bitmap for it.
  Future<void> setSelected(Place place, bool selected) async {
    final old = _markerOf.remove(place);
    if (old != null) {
      _placeOf.remove(old.id);
      await _markers!.delete(old);
    }
    await _createMarker(place, selected: selected);
  }

  /// Flies down to a place: street level, tilted, among its 3D buildings.
  /// Like the SDK, this returns as soon as the animation starts.
  Future<void> flyTo(Place place) {
    return map.flyTo(
      CameraOptions(
          center: Point(coordinates: place.position), zoom: place.zoom, pitch: 58, bearing: 30),
      MapAnimationOptions(duration: 3000),
    );
  }

  /// Back to the globe with every place in view.
  Future<void> showGlobe() => map.flyTo(globeCamera, MapAnimationOptions(duration: 2200));

  // ── Pins and route ────────────────────────────────────────────────────

  /// Drops the A or B pin.
  Future<void> addPin(String letter, Position position) async {
    _pinAnnotations.add(await _pins!.create(PointAnnotationOptions(
      geometry: Point(coordinates: position),
      image: pinMarker(letter, color: activityOrange),
      iconSize: 1.0,
      iconAnchor: IconAnchor.CENTER,
    )));
  }

  /// Removes the pins, the route line and the drive.
  Future<void> clear() async {
    _drawing?.cancel();
    _drawing = null;
    ++_generation;
    await stopDrive();
    final pins = List<PointAnnotation>.from(_pinAnnotations);
    _pinAnnotations.clear();
    await _setRouteData(_emptyGeoJson);
    await _setTrim([0.0, 1.0], color: 'rgba(0, 0, 0, 0)');
    if (pins.isNotEmpty) await _pins?.deleteMulti(pins);
  }

  /// Fits [route] on screen, then draws its line from A to B over about
  /// four seconds. [onProgress] gets the miles drawn so far.
  Future<void> showRoute(DirectionsRoute route, {required void Function(String miles) onProgress}) async {
    final generation = ++_generation;
    // The trimmed part is hidden while the line is revealed; the drive
    // recolours it grey instead.
    await _setTrim([0.0, 1.0], color: 'rgba(0, 0, 0, 0)');
    await _setRouteData(
        '{"type":"Feature","properties":{},"geometry":{"type":"LineString","coordinates":'
        '${route.coordinates}}}');

    final camera = await map.cameraForCoordinatesPadding(
      [for (final p in route.positions) Point(coordinates: p)],
      CameraOptions(pitch: 40, bearing: 0),
      MbxEdgeInsets(top: 160, left: 60, bottom: 240, right: 60),
      null,
      null,
    );
    await map.flyTo(camera, MapAnimationOptions(duration: 1800));
    // Let the camera land before the line starts running.
    await Future<void>.delayed(const Duration(milliseconds: 2000));
    if (generation != _generation) return;

    const ticks = 100; // 100 ticks of 40 ms
    var tick = 0;
    _drawing = Timer.periodic(const Duration(milliseconds: 40), (timer) async {
      tick++;
      final fraction = (tick / ticks).clamp(0.0, 1.0);
      try {
        // Hide the part of the line ahead of the pen.
        await _setTrim([fraction, 1.0]);
      } catch (e) {
        // The map is gone (screen closed or hot restart): stop for good.
        if (e is PlatformException && e.code == 'NO_MAP') {
          timer.cancel();
          return;
        }
        dnLog('[journal] route tick failed: $e');
      }
      onProgress(miles(route.distance * fraction));
      if (tick >= ticks) timer.cancel();
    });
  }

  // ── 3D drive ──────────────────────────────────────────────────────────

  /// Drives [route] on the 3D map: a puck follows the road, the camera
  /// follows the puck low and tilted among the buildings, and the line
  /// greys out behind it. [onUpdate] gets every tick, [onAnnounce] each
  /// spoken-style instruction as it becomes due.
  Future<void> startDrive(
    DirectionsRoute route, {
    required void Function(DriveSimulator drive) onUpdate,
    required void Function(String text) onAnnounce,
  }) async {
    await stopDrive();
    _drawing?.cancel();
    _drawing = null;
    await _setTrim([0.0, 0.0], color: navTraveled.toRGBA());
    final drive = DriveSimulator(
      route: route,
      onUpdate: (sample) => _onDriveTick(sample, onUpdate),
      onAnnounce: onAnnounce,
    );
    _drive = drive;
    final first = drive.player.sample(0);
    _puck = await _pucks!.create(PointAnnotationOptions(
      geometry: Point(coordinates: first.position),
      image: puckImage(color: activityOrange),
      iconSize: 1.6,
      iconRotate: first.heading,
    ));
    await _follow(first, 1500);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (_drive != drive) return;
    drive.start();
  }

  Future<void> _onDriveTick(RouteSample s, void Function(DriveSimulator) onUpdate) async {
    final drive = _drive;
    final puck = _puck;
    if (drive == null || puck == null) return;
    puck.geometry = Point(coordinates: s.position);
    puck.iconRotate = s.heading;
    try {
      await _pucks!.update(puck);
      await _setTrim([0.0, s.fraction]);
      await _follow(s, 100);
    } catch (e) {
      // The map is gone (screen closed or hot restart): stop for good.
      if (e is PlatformException && e.code == 'NO_MAP') {
        drive.stop();
        return;
      }
      dnLog('[journal] drive tick failed: $e');
    }
    onUpdate(drive);
    if (drive.arrived) _drive = null; // the puck stays at B until the next clear
  }

  /// The follow camera: low, tilted, heading up, the puck two thirds of
  /// the way down the screen.
  Future<void> _follow(RouteSample s, int milliseconds) {
    return map.easeTo(
      CameraOptions(
        center: Point(coordinates: s.position),
        zoom: 17.2,
        pitch: 62,
        bearing: s.heading,
        padding: MbxEdgeInsets(top: 320, left: 0, bottom: 0, right: 0),
      ),
      MapAnimationOptions(duration: milliseconds),
    );
  }

  /// Stops the drive and removes the puck; the route stays as it is.
  Future<void> stopDrive() async {
    _drive?.stop();
    _drive = null;
    final puck = _puck;
    _puck = null;
    if (puck != null) await _pucks?.delete(puck);
  }

  /// Logs a few readbacks from the SDK, for checking a run from the terminal.
  Future<void> logState() async {
    if (!verboseLogs) return;
    try {
      final trim = await map.style.getStyleLayerProperty(_routeLayer, 'line-trim-offset');
      final markers = await _markers?.getAnnotations();
      dnLog('[journal] trim ${trim.value} markers ${markers?.length} '
          'camera ${(await map.getCameraState()).zoom}');
    } catch (e) {
      dnLog('[journal] readback failed: $e');
    }
  }

  void dispose() {
    _drawing?.cancel();
    _drawing = null;
    _drive?.stop();
    _drive = null;
    _taps?.cancel();
    _taps = null;
  }
}
