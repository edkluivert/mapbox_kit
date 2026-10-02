// Step timings for the two drive demos, printed with dnLog every 5 seconds
// of driving while `perfLogs` in config.dart is on.

import 'package:dartnative/dartnative.dart';

import '../config.dart';

class DriveStepStats {
  DriveStepStats(this.name);

  final String name;

  final Stopwatch _window = Stopwatch();
  final Stopwatch _sinceLastStep = Stopwatch();
  int _steps = 0;
  int _gaps = 0;
  int _gapMicros = 0;
  int _maxGapMicros = 0;
  int _cameraMicros = 0;
  int _maxCameraMicros = 0;
  int _doneMicros = 0;
  int _maxDoneMicros = 0;

  /// Starts timing one step, or returns null while `perfLogs` is off. The
  /// time since the previous step is the gap: one display frame when the
  /// drive keeps up with the screen.
  Stopwatch? start() {
    if (!perfLogs) return null;
    if (_sinceLastStep.isRunning) {
      final gap = _sinceLastStep.elapsedMicroseconds;
      // A drive that stopped and started again is not a gap.
      if (gap < 1000000) {
        _gaps++;
        _gapMicros += gap;
        if (gap > _maxGapMicros) _maxGapMicros = gap;
      }
    }
    _sinceLastStep
      ..reset()
      ..start();
    if (!_window.isRunning) _window.start();
    return Stopwatch()..start();
  }

  /// [cameraMicros]: when the step's camera move was sent;
  /// [doneMicros]: when every call of the step had its reply.
  void add({required int cameraMicros, required int doneMicros}) {
    _steps++;
    _cameraMicros += cameraMicros;
    _doneMicros += doneMicros;
    if (cameraMicros > _maxCameraMicros) _maxCameraMicros = cameraMicros;
    if (doneMicros > _maxDoneMicros) _maxDoneMicros = doneMicros;
    if (_window.elapsedMilliseconds < 5000) return;
    final seconds = _window.elapsedMilliseconds / 1000;
    final gapText = _gaps == 0
        ? ''
        : ', ${_ms(_gapMicros / _gaps)} ms apart (max ${_ms(_maxGapMicros)})';
    dnLog('[$name perf] ${seconds.toStringAsFixed(1)} s: $_steps steps '
        '(${(_steps / seconds).round()}/s)$gapText; camera sent after '
        '${_ms(_cameraMicros / _steps)} ms (max ${_ms(_maxCameraMicros)}), '
        'step done after ${_ms(_doneMicros / _steps)} ms '
        '(max ${_ms(_maxDoneMicros)})');
    _window
      ..reset()
      ..start();
    _steps = _gaps = _gapMicros = _maxGapMicros = 0;
    _cameraMicros = _maxCameraMicros = _doneMicros = _maxDoneMicros = 0;
  }

  static String _ms(num micros) => (micros / 1000).toStringAsFixed(1);
}
