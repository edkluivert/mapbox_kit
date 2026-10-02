part of '../mapbox_kit.dart';

/// What the calls into the native side cost, summed per method over
/// [_window] and printed with `dnLog` while [mapboxKitPerfLogs] is on: how
/// many calls, the bytes each sent, the time to encode them in Dart, the
/// time the native side spent on them, and the time until the reply.
abstract final class _Perf {
  static const Duration _window = Duration(seconds: 5);

  static final Map<String, _MethodStats> _stats = {};
  static Timer? _timer;
  static final Stopwatch _clock = Stopwatch();

  static void record(
    String method, {
    required int bytes,
    required int encodeMicros,
    required int replyMicros,
  }) {
    (_stats[method] ??= _MethodStats()).add(bytes, encodeMicros, replyMicros);
    if (_timer == null) {
      _clock
        ..reset()
        ..start();
      _timer = Timer.periodic(_window, (_) => _report());
    }
  }

  static Future<void> _report() async {
    if (_stats.isEmpty) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    final seconds = _clock.elapsedMilliseconds / 1000;
    _clock
      ..reset()
      ..start();
    final window = Map.of(_stats);
    _stats.clear();
    // The native side's time for the same window, per method.
    Map<String, dynamic> native = const {};
    try {
      final reply = await _NativeChannel.invoke(
        'options#perfReport',
        null,
        false,
      );
      if (reply is Map) native = reply.cast<String, dynamic>();
    } catch (_) {}
    final lines = window.entries.toList()
      ..sort((a, b) => b.value.replyMicros.compareTo(a.value.replyMicros));
    dnLog('[mapbox_kit perf] ${seconds.toStringAsFixed(1)} s');
    for (final entry in lines) {
      final s = entry.value;
      final n = native[entry.key];
      final nativeText = n is Map
          ? ', native ${_ms((n['micros'] as num) / (n['count'] as num))} ms'
                ' (max ${_ms(n['maxMicros'] as num)})'
          : '';
      dnLog(
        '[mapbox_kit perf]   ${entry.key} x${s.count}: '
        '${(s.bytes / s.count / 1024).toStringAsFixed(1)} KB out, '
        'encode ${_ms(s.encodeMicros / s.count)} ms$nativeText, '
        'reply ${_ms(s.replyMicros / s.count)} ms '
        '(max ${_ms(s.maxReplyMicros)})',
      );
    }
  }

  static String _ms(num micros) => (micros / 1000).toStringAsFixed(2);
}

final class _MethodStats {
  int count = 0;
  int bytes = 0;
  int encodeMicros = 0;
  int replyMicros = 0;
  int maxReplyMicros = 0;

  void add(int bytes, int encodeMicros, int replyMicros) {
    count++;
    this.bytes += bytes;
    this.encodeMicros += encodeMicros;
    this.replyMicros += replyMicros;
    if (replyMicros > maxReplyMicros) maxReplyMicros = replyMicros;
  }
}
