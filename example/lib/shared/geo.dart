// Great-circle helpers and a player that walks a polyline at a given speed.

import 'dart:math' as math;

import 'package:mapbox_kit/mapbox_kit.dart';

double bearingBetween(Position a, Position b) {
  final lat1 = a.lat * math.pi / 180, lat2 = b.lat * math.pi / 180;
  final dLng = (b.lng - a.lng) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

double distanceMeters(Position a, Position b) {
  const r = 6371000.0;
  final dLat = (b.lat - a.lat) * math.pi / 180;
  final dLng = (b.lng - a.lng) * math.pi / 180;
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(a.lat * math.pi / 180) *
          math.cos(b.lat * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(h));
}

String miles(double meters) => '${(meters / 1609.344).toStringAsFixed(2)} mi';

String milesShort(double meters) {
  final mi = meters / 1609.344;
  if (mi < 0.1) return '${(meters * 3.28084 / 10).round() * 10} ft';
  return '${mi.toStringAsFixed(1)} mi';
}

/// A position along a polyline, [distance] meters from its start.
class RouteSample {
  const RouteSample(this.position, this.heading, this.distance, this.fraction, this.segment);
  final Position position;
  final double heading;
  final double distance;
  final double fraction;

  /// Index of the vertex the sample sits after.
  final int segment;
}

/// Walks a polyline by distance.
class RoutePlayer {
  RoutePlayer(this.points) {
    var acc = 0.0;
    _cumulative.add(0);
    for (var i = 1; i < points.length; i++) {
      acc += distanceMeters(points[i - 1], points[i]);
      _cumulative.add(acc);
    }
    total = acc;
  }

  final List<Position> points;
  final List<double> _cumulative = [];
  late final double total;

  /// Cumulative distance to vertex [index].
  double distanceAt(int index) => _cumulative[index.clamp(0, _cumulative.length - 1)];

  RouteSample sample(double distance) {
    final d = distance.clamp(0.0, total);
    var i = 1;
    while (i < _cumulative.length - 1 && _cumulative[i] < d) {
      i++;
    }
    final a = points[i - 1], b = points[i];
    final segLength = _cumulative[i] - _cumulative[i - 1];
    final t = segLength == 0 ? 0.0 : ((d - _cumulative[i - 1]) / segLength).clamp(0.0, 1.0);
    final position = Position(a.lng + (b.lng - a.lng) * t, a.lat + (b.lat - a.lat) * t);
    var heading = bearingBetween(a, b);
    // Look a little ahead so the heading does not snap at every vertex.
    if (i < points.length - 1) {
      final next = bearingBetween(b, points[i + 1]);
      final delta = ((next - heading + 540) % 360) - 180;
      heading = (heading + delta * t + 360) % 360;
    }
    return RouteSample(position, heading, d, total == 0 ? 1 : d / total, i - 1);
  }
}

