// Drives along a Directions route on a timer, like the emulator's route
// playback in the reference video. It works out which step you are on, how
// far is left, and when each voice instruction is due. The screen draws.

import 'dart:async';
import 'dart:math' as math;

import '../shared/geo.dart';
import 'directions.dart';

class DriveSimulator {
  DriveSimulator({
    required this.route,
    required this.onUpdate,
    required this.onAnnounce,
    this.playback = 3.0,
  })  : player = RoutePlayer(route.positions),
        remaining = route.distance,
        remainingSeconds = route.duration;

  final DirectionsRoute route;
  final RoutePlayer player;

  /// How much faster than the Directions ETA the drive plays. 1.0 is real
  /// time; 3.0 keeps a typical city route to a few minutes.
  final double playback;

  /// Called every tick with the current position along the route.
  final void Function(RouteSample sample) onUpdate;

  /// Called when a voice instruction becomes due.
  final void Function(String text) onAnnounce;

  Timer? _timer;
  double distance = 0;
  int stepIndex = 0;
  double stepRemaining = 0;
  double remaining;
  double remainingSeconds;
  final Set<String> _spoken = {};

  DirectionsStep? get step => route.steps.isEmpty ? null : route.steps[stepIndex];
  RouteSample get sample => player.sample(distance);
  bool get running => _timer != null;
  bool get arrived => distance >= player.total;

  /// Starts (or restarts) from the origin.
  void start() {
    stop();
    distance = 0;
    stepIndex = 0;
    _spoken.clear();
    _updateProgress(player.sample(0));
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    final metersPerSecond = route.distance / route.duration * playback;
    distance = math.min(player.total, distance + metersPerSecond * 0.1);
    final s = player.sample(distance);
    _updateProgress(s);
    onUpdate(s);
    if (arrived) stop();
  }

  /// Finds the current step (steps start at their maneuver) and fires the
  /// voice instructions that are due.
  void _updateProgress(RouteSample s) {
    var startOfStep = 0.0;
    var index = 0;
    for (var i = 0; i < route.steps.length; i++) {
      final last = i == route.steps.length - 1;
      if (s.distance < startOfStep + route.steps[i].distance || last) {
        index = i;
        break;
      }
      startOfStep += route.steps[i].distance;
    }
    final step = route.steps[index];
    stepIndex = index;
    stepRemaining = math.max(0, startOfStep + step.distance - s.distance);
    for (var v = 0; v < step.voice.length; v++) {
      final key = '$index/$v';
      if (stepRemaining <= step.voice[v].distanceAlongGeometry && _spoken.add(key)) {
        onAnnounce(step.voice[v].announcement);
      }
    }
    remaining = math.max(0, route.distance - s.distance);
    remainingSeconds = route.duration * (remaining / route.distance);
  }
}
