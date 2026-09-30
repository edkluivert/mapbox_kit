part of '../../mapbox_kit.dart';

/// A failure reported by the native side of a call or stream.
///
/// Mirrors Flutter's `PlatformException` so code ported from
/// `mapbox_maps_flutter` keeps its `on PlatformException` handlers.
class PlatformException implements Exception {
  PlatformException({required this.code, this.message, this.details});

  /// The native error code.
  final String code;

  /// A human readable description of the failure.
  final String? message;

  /// Extra error information, if the native side attached any.
  final Object? details;

  @override
  String toString() => 'PlatformException($code, $message, $details)';
}

/// One-shot calls and broadcast streams into the native side, JSON over FFI.
///
/// Replies always arrive later on the main thread, never inside the call.
abstract final class _NativeChannel {
  static Future<dynamic> invoke(String method,
      [Map<String, dynamic>? arguments]) {
    final completer = Completer<dynamic>();
    late final int token;
    token = MapboxKitFFIBindings.registerHandler((type, payload) {
      MapboxKitFFIBindings.removeHandler(token);
      if (completer.isCompleted) return;
      mapboxKitLog('$method -> type=$type $payload');
      // Runs inside a native callback, which must not throw.
      try {
        if (type == MapboxKitEventType.error) {
          completer.completeError(_decodeError(payload));
        } else {
          completer.complete(_decode(payload));
        }
      } catch (e) {
        completer.completeError(_decodeFailure(method, e));
      }
    }, oneShot: true);
    final encoded = _encode(arguments);
    final rc = MapboxKitFFIBindings.invoke(token, method, encoded);
    mapboxKitLog('invoke $method $encoded rc=$rc');
    if (rc != 0) {
      MapboxKitFFIBindings.removeHandler(token);
      completer.completeError(_unavailable(rc, method));
    }
    return completer.future;
  }

  /// Starts the native stream [channel] when first listened to and stops it
  /// when the last listener cancels.
  static Stream<dynamic> stream(String channel,
      [Map<String, dynamic>? arguments]) {
    late final StreamController<dynamic> controller;
    int? token;
    controller = StreamController<dynamic>.broadcast(
      onListen: () {
        final t = MapboxKitFFIBindings.registerHandler((type, payload) {
          if (controller.isClosed) return;
          mapboxKitLog('$channel event type=$type $payload');
          try {
            if (type == MapboxKitEventType.error) {
              controller.addError(_decodeError(payload));
            } else {
              controller.add(_decode(payload));
            }
          } catch (e) {
            controller.addError(_decodeFailure(channel, e));
          }
        });
        token = t;
        final rc = MapboxKitFFIBindings.listen(t, channel, _encode(arguments));
        mapboxKitLog('listen $channel rc=$rc');
        if (rc != 0) {
          MapboxKitFFIBindings.removeHandler(t);
          token = null;
          controller.addError(_unavailable(rc, channel));
        }
      },
      onCancel: () {
        final t = token;
        token = null;
        if (t != null) {
          MapboxKitFFIBindings.cancel(t);
          MapboxKitFFIBindings.removeHandler(t);
          mapboxKitLog('cancel $channel');
        }
      },
    );
    return controller.stream;
  }

  static String _encode(Map<String, dynamic>? arguments) => jsonEncode(
        arguments ?? const <String, dynamic>{},
        toEncodable: (object) {
          if (object is Uint8List) return base64Encode(object);
          if (object is Enum) return object.index;
          if (object is Duration) return object.inMilliseconds;
          if (object is turf.GeoJSONObject) return object.toJson();
          try {
            return (object as dynamic).toJson();
          } on NoSuchMethodError {
            return object.toString();
          }
        },
      );

  static dynamic _decode(String payload) =>
      payload.isEmpty ? null : jsonDecode(payload);

  static PlatformException _decodeError(String payload) {
    dynamic decoded;
    try {
      decoded = jsonDecode(payload);
    } catch (_) {
      decoded = null;
    }
    if (decoded is Map) {
      return PlatformException(
        code: decoded['code']?.toString() ?? 'UNKNOWN',
        message: decoded['message']?.toString(),
        details: decoded['details'],
      );
    }
    return PlatformException(code: 'UNKNOWN', message: payload);
  }

  static PlatformException _decodeFailure(String what, Object error) =>
      PlatformException(
        code: 'DECODE_ERROR',
        message: 'Could not decode the native reply to "$what": $error',
      );

  static PlatformException _unavailable(int rc, String what) =>
      PlatformException(
        code: rc == -1 ? 'NATIVE_UNAVAILABLE' : 'NOT_IMPLEMENTED',
        message: rc == -1
            ? 'mapbox_kit native symbols are not loaded. Run `dn pub get` so '
                'the plugin registrant calls MapboxKitFFIBindings.loadSymbols(), '
                'then rebuild.'
            : 'The native side rejected "$what" (code $rc).',
      );
}

/// The calls and streams of one hosted map view, keyed by its view id.
class _MapChannel {
  _MapChannel(this.viewId);

  final int viewId;

  Future<dynamic> invoke(String method, [Map<String, dynamic>? arguments]) =>
      _NativeChannel.invoke(method, {'viewId': viewId, ...?arguments});

  Stream<dynamic> stream(String channel, [Map<String, dynamic>? arguments]) =>
      _NativeChannel.stream(channel, {'viewId': viewId, ...?arguments});
}
