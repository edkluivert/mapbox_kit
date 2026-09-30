part of '../mapbox_kit.dart';

/// Returns back the passed value casted to the desired type
/// or null if typecasting fails
T? _optionalCast<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  // Cast int(num) to double,
  // as GL Native converts e.g. 1.0 to 1 (int),
  // which trips dart up
  if (value is num && T == double) {
    return value.toDouble() as T;
  }
  return null;
}

List<T>? _optionalCastList<T>(dynamic value) {
  if (value is List) {
    return value.where((value) => value is T).cast<T>().toList();
  }
  return null;
}

/// `null` for `null`, else the JSON map with string keys.
Map<String, dynamic>? _asMap(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : null;

Map<String, dynamic> _requireMap(dynamic value) =>
    (value as Map).cast<String, dynamic>();

double? _asDouble(dynamic value) => value is num ? value.toDouble() : null;

int? _asInt(dynamic value) => value is num ? value.toInt() : null;

List<double?>? _asDoubleList(dynamic value) => value is List
    ? value.map((e) => e is num ? e.toDouble() : null).toList()
    : null;

List<String?>? _asStringList(dynamic value) =>
    value is List ? value.map((e) => e?.toString()).toList() : null;

T? _enumFromIndex<T extends Enum>(List<T> values, dynamic value) =>
    value is int && value >= 0 && value < values.length ? values[value] : null;

Uint8List? _bytesFromJson(dynamic value) =>
    value is String ? base64Decode(value) : null;

String? _bytesToJson(Uint8List? bytes) =>
    bytes == null ? null : base64Encode(bytes);

/// Drops the `null` entries so partial updates only carry the fields set.
Map<String, dynamic> _compact(Map<String, dynamic> map) =>
    Map.fromEntries(map.entries.where((e) => e.value != null));
