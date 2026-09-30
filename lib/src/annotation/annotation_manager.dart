part of '../../mapbox_kit.dart';

/// Creates and removes the annotation managers of a map.
class AnnotationManager {
  final _MapChannel _channel;

  AnnotationManager._(this._channel);

  Future<String> _create(String type, String? id, String? below) async =>
      (await _channel.invoke('annotation#createManager',
              {'type': type, 'id': id, 'belowLayerId': below}))
          .toString();

  /// Create a [PointAnnotationManager] to add/remove/update [PointAnnotation]s on the map.
  ///
  /// If [id] is specified, the string is used as an identifier for a layer and a source backing the create manager.
  /// Use [below] to specify the id of the layer above the annotation layer.
  Future<PointAnnotationManager> createPointAnnotationManager(
      {String? id, String? below}) async {
    final managerId = await _create('point', id, below);
    return PointAnnotationManager._(id: managerId, channel: _channel);
  }

  /// Create a [PolylineAnnotationManager] to add/remove/update [PolylineAnnotation]s on the map.
  ///
  /// If [id] is specified, the string is used as an identifier for a layer and a source backing the create manager.
  /// Use [below] to specify the id of the layer above the annotation layer.
  Future<PolylineAnnotationManager> createPolylineAnnotationManager(
      {String? id, String? below}) async {
    final managerId = await _create('polyline', id, below);
    return PolylineAnnotationManager._(id: managerId, channel: _channel);
  }

  /// Remove an [AnnotationManager] and all the annotations created by it.
  Future<void> removeAnnotationManager(BaseAnnotationManager manager) async {
    return removeAnnotationManagerById(manager.id);
  }

  /// Remove an [AnnotationManager] with the specified [id] and all the annotation created by it.
  Future<void> removeAnnotationManagerById(String id) async {
    await _channel.invoke('annotation#removeManager', {'id': id});
  }
}

/// The super class for all AnnotationManagers.
class BaseAnnotationManager {
  BaseAnnotationManager._({required this.id, required _MapChannel channel})
      : _channel = channel;

  final String id;
  final _MapChannel _channel;

  /// The interaction events (tap, long press, drag) of this manager's annotations.
  Stream<Map<String, dynamic>> _interactions(String kind) => _channel
      .stream('annotation#interactions', {'managerId': id})
      .map(_requireMap)
      .where((event) => event['type'] == kind);

  Future<dynamic> _invoke(String prefix, String method,
          [Map<String, dynamic>? args]) =>
      _channel.invoke('$prefix#$method', {'managerId': id, ...?args});

  /// Sets a layer property of the annotation layer (style spec name).
  Future<void> _setProperty(String prefix, String property, Object value) =>
      _invoke(prefix, 'setProperty', {'property': property, 'value': value});

  /// Reads a layer property of the annotation layer; `null` when unset or
  /// when the layer holds an expression.
  Future<dynamic> _getProperty(String prefix, String property) =>
      _invoke(prefix, 'getProperty', {'property': property});

  static String _enumName(Enum value) =>
      value.name.toLowerCase().replaceAll('_', '-');

  static T? _enumFromName<T extends Enum>(List<T> values, dynamic value) {
    if (value is! String) return null;
    for (final v in values) {
      if (_enumName(v) == value) return v;
    }
    return null;
  }

  static int? _colorFrom(dynamic value) {
    if (value is String) return value.toRGBAInt();
    if (value is List) return value.toRGBAInt();
    return null;
  }
}
