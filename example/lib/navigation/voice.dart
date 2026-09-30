// Spoken turn-by-turn guidance.
//
// Speech is synthesised on device by SuperTonic-3 (dartnative_supertonic_tts,
// a pure-Dart pipeline on dartnative_onnxruntime) and played through the
// native low-latency PCM player from dartnative_audio (AVAudioEngine on iOS,
// AudioTrack on Android). The models (~144 MB) are downloaded once on the
// first run and cached in the app-support directory; until they are ready
// announcements are shown under the banner only.

import 'dart:async';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_audio/dartnative_audio.dart';
import 'package:dartnative_supertonic_tts/dartnative_supertonic_tts.dart';

abstract final class NavigationVoice {
  static SuperTonicTTS? _tts;
  static PcmStreamPlayer? _player;
  static Future<void>? _warmup;
  static bool _ready = false;
  static bool _speaking = false;
  static bool _stopped = false;
  static final List<_Utterance> _queue = <_Utterance>[];

  /// Human-readable engine state for the UI ("Downloading voice 42%", …).
  /// Null once the engine is ready.
  static final ValueNotifier<String?> status = ValueNotifier<String?>(null);

  static bool get isReady => _ready;

  /// Downloads (first run) and loads the speech models. Safe to call more
  /// than once; navigation calls it when the screen opens so the voice is
  /// ready before the first manoeuvre.
  static Future<void> warmUp() => _warmup ??= _doWarmUp();

  static Future<void> _doWarmUp() async {
    try {
      final tts = SuperTonicTTS();
      status.value = 'Preparing voice';
      await tts.initialize(
        intraOpNumThreads: 2,
        onProgress: (p, msg) {
          final pct = (p * 100).round();
          status.value = 'Voice: $msg $pct%';
          if (pct % 20 == 0) dnLog('[voice] $msg $pct%');
        },
      );
      final player = PcmStreamPlayer()
        ..configure(sampleRate: tts.sampleRate, channels: 1, bitsPerSample: 32);
      AudioSession.setCategory(
        AudioSessionCategory.playback,
        mode: AudioSessionMode.spokenAudio,
      );
      _tts = tts;
      _player = player;
      _ready = true;
      status.value = null;
      dnLog('[voice] ready (${tts.sampleRate} Hz, ${supertonicVoices.length} voices)');
      unawaited(_drain());
    } catch (e) {
      // Usually a dropped model download; the next announcement retries.
      _warmup = null;
      status.value = 'Voice unavailable (retrying)';
      dnLog('[voice] failed to initialise: $e');
    }
  }

  /// Queues [text] to be spoken. Announcements older than [maxAge] when their
  /// turn comes are dropped so a slow synthesis never reads a stale turn.
  static Future<void> speak(String text, {Duration maxAge = const Duration(seconds: 12)}) async {
    dnLog('[voice] $text');
    _stopped = false;
    _queue.add(_Utterance(text, DateTime.now(), maxAge));
    if (!_ready) {
      unawaited(warmUp());
      return;
    }
    unawaited(_drain());
  }

  /// Stops playback and forgets anything queued.
  static Future<void> stop() async {
    _stopped = true;
    _queue.clear();
    _player?.flush();
  }

  static Future<void> _drain() async {
    if (_speaking || !_ready) return;
    _speaking = true;
    try {
      while (_queue.isNotEmpty && !_stopped) {
        final u = _queue.removeAt(0);
        if (DateTime.now().difference(u.at) > u.maxAge) {
          dnLog('[voice] skipped stale: ${u.text}');
          continue;
        }
        await _say(u.text);
      }
    } finally {
      _speaking = false;
    }
  }

  static Future<void> _say(String text) async {
    final tts = _tts;
    final player = _player;
    if (tts == null || player == null) return;
    final sw = Stopwatch()..start();
    var first = true;
    var samples = 0;
    try {
      await for (final chunk in tts.generateStream(text, voice: 'F2', speed: 1.05, steps: 4)) {
        if (_stopped) break;
        if (first) {
          first = false;
          dnLog('[voice] first audio after ${sw.elapsedMilliseconds} ms');
        }
        samples += chunk.length;
        player.feedChunk(Uint8List.view(chunk.buffer, chunk.offsetInBytes, chunk.lengthInBytes));
      }
      // Let the tail play out before the next utterance starts.
      final tail = Duration(milliseconds: (samples / tts.sampleRate * 1000).round() - sw.elapsedMilliseconds + 250);
      if (!_stopped && tail > Duration.zero) await Future<void>.delayed(tail);
    } catch (e) {
      dnLog('[voice] synthesis failed: $e');
    }
  }
}

class _Utterance {
  const _Utterance(this.text, this.at, this.maxAge);
  final String text;
  final DateTime at;
  final Duration maxAge;
}
