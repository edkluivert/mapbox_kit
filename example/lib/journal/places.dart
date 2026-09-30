// The places on the globe. Each one is a bracket marker you can tap to fly
// into that city; the A / B trip is picked on the map inside it.

import 'package:mapbox_kit/mapbox_kit.dart';

class Place {
  const Place({required this.name, required this.position, this.zoom = 15.6});

  final String name;

  /// `Position(lng, lat)`.
  final Position position;

  /// How close the fly-to lands when the place is picked: street level,
  /// among the 3D buildings.
  final double zoom;

  String get label => name.toUpperCase();
}

final List<Place> places = [
  Place(name: 'San Francisco', position: Position(-122.3960, 37.7935)),
  Place(name: 'Denver', position: Position(-104.9903, 39.7392)),
  Place(name: 'Austin', position: Position(-97.7431, 30.2672)),
  Place(name: 'New York', position: Position(-73.9857, 40.7484)),
];

/// Where the globe starts: all four places in view.
final CameraOptions globeCamera = CameraOptions(
  center: Point(coordinates: Position(-100, 36)),
  zoom: 2.0,
  pitch: 0,
  bearing: 0,
);

/// The built-in Mapbox styles, in the order the style button cycles.
class MapStyle {
  const MapStyle(this.name, this.uri, {this.dark = false});

  final String name;
  final String uri;

  /// Whether the chrome (pills, captions) should be light-on-dark.
  final bool dark;

  /// Standard and Standard Satellite take light presets and themes.
  bool get isStandard =>
      uri == MapboxStyles.STANDARD || uri == MapboxStyles.STANDARD_SATELLITE;
}

const List<MapStyle> mapStyles = [
  MapStyle('Standard', MapboxStyles.STANDARD, dark: true),
  MapStyle('Standard Satellite', MapboxStyles.STANDARD_SATELLITE, dark: true),
  MapStyle('Streets', MapboxStyles.MAPBOX_STREETS),
  MapStyle('Outdoors', MapboxStyles.OUTDOORS),
  MapStyle('Light', MapboxStyles.LIGHT),
  MapStyle('Dark', MapboxStyles.DARK, dark: true),
  MapStyle('Satellite', MapboxStyles.SATELLITE, dark: true),
  MapStyle('Satellite Streets', MapboxStyles.SATELLITE_STREETS, dark: true),
];
