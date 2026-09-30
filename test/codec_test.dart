import 'dart:convert';

import 'package:mapbox_kit/mapbox_kit.dart';
import 'package:test/test.dart';

void main() {
  group('camera codecs', () {
    test('CameraOptions round-trips through JSON', () {
      final options = CameraOptions(
        center: Point(coordinates: Position(-122.39, 37.79)),
        padding: MbxEdgeInsets(top: 1, left: 2, bottom: 3, right: 4),
        anchor: ScreenCoordinate(x: 10, y: 20),
        zoom: 14.5,
        bearing: 30,
        pitch: 45,
      );
      final decoded = CameraOptions.fromJson(
          jsonDecode(jsonEncode(options.toJson())) as Map<String, dynamic>);
      expect(decoded.center!.coordinates.lng, -122.39);
      expect(decoded.center!.coordinates.lat, 37.79);
      expect(decoded.padding!.bottom, 3);
      expect(decoded.anchor!.y, 20);
      expect(decoded.zoom, 14.5);
      expect(decoded.bearing, 30);
      expect(decoded.pitch, 45);
    });

    test('CameraState decodes integer numbers', () {
      final state = Conversion.fromJson({
        'center': {'type': 'Point', 'coordinates': [1, 2]},
        'padding': {'top': 0, 'left': 0, 'bottom': 0, 'right': 0},
        'zoom': 12,
        'bearing': 0,
        'pitch': 0,
      });
      expect(state.zoom, 12.0);
      expect(state.toCameraOptions().center!.coordinates.lat, 2);
    });
  });

  group('colors', () {
    test('int to rgba string and back', () {
      const color = 0x801E5EFF;
      expect(color.toRGBA(), 'rgba(30, 94, 255, ${0x80 / 255})');
      expect(color.toRGBA().toRGBAInt(), color);
    });

    test('rgba expression to int', () {
      expect(['rgba', 255, 0, 0, 1].toRGBAInt(), 0xFFFF0000);
    });

    test('hsl expression to int', () {
      expect(['hsl', 0, 1, 0.5].toRGBAInt(), 0xFFFF0000);
    });
  });

  group('annotations', () {
    test('PointAnnotationOptions drops unset fields and keeps enums as indices',
        () {
      final options = PointAnnotationOptions(
        geometry: Point(coordinates: Position(1, 2)),
        iconAnchor: IconAnchor.BOTTOM,
        textField: 'hi',
        iconColor: 0xFF00FF00,
      );
      final json = options.toJson();
      expect(json['iconAnchor'], IconAnchor.BOTTOM.index);
      expect(json['textField'], 'hi');
      expect(json.containsKey('iconSize'), isFalse);
      final annotation = PointAnnotation.fromJson({...json, 'id': 'a1'});
      expect(annotation.id, 'a1');
      expect(annotation.iconAnchor, IconAnchor.BOTTOM);
      expect(annotation.iconColor, 0xFF00FF00);
    });

    test('PolylineAnnotation geometry round-trips', () {
      final options = PolylineAnnotationOptions(
        geometry: LineString(coordinates: [Position(0, 0), Position(1, 1)]),
        lineWidth: 4,
        lineJoin: LineJoin.ROUND,
      );
      final annotation =
          PolylineAnnotation.fromJson({...options.toJson(), 'id': 'l1'});
      expect(annotation.geometry.coordinates.length, 2);
      expect(annotation.lineJoin, LineJoin.ROUND);
      expect(annotation.lineWidth, 4);
    });
  });

  group('events', () {
    test('camera changed event decodes', () {
      final event = CameraChangedEventData.fromJson({
        'timestamp': 1,
        'cameraState': {
          'center': {'type': 'Point', 'coordinates': [3.0, 4.0]},
          'padding': {'top': 0, 'left': 0, 'bottom': 0, 'right': 0},
          'zoom': 5.5,
          'bearing': 10,
          'pitch': 20,
        },
      });
      expect(event.cameraState.center.coordinates.lng, 3);
      expect(event.cameraState.pitch, 20);
    });

    test('map loading error tolerates a missing tile id', () {
      final event = MapLoadingErrorEventData.fromJson({
        'type': 2,
        'message': 'boom',
        'sourceId': 's',
        'tileId': null,
        'timestamp': 9,
      });
      expect(event.type, MapLoadErrorType.SOURCE);
      expect(event.tileId, isNull);
    });
  });

  group('settings', () {
    test('LocationComponentSettings keeps only the set fields', () {
      final json = LocationComponentSettings(
        enabled: true,
        puckBearing: PuckBearing.COURSE,
        locationPuck: LocationPuck(locationPuck2D: DefaultLocationPuck2D()),
      ).toJson();
      expect(json['enabled'], true);
      expect(json['puckBearing'], PuckBearing.COURSE.index);
      expect(json.containsKey('pulsingColor'), isFalse);
      expect(json['locationPuck'], {'locationPuck2D': <String, dynamic>{}});
    });
  });

  group('style', () {
    test('TileCacheBudget decodes both units', () {
      expect(TileCacheBudget.decode({'megabytes': 12})!.type,
          TileCacheBudgetType.MEGABYTES);
      expect(TileCacheBudget.decode({'tiles': 3})!.size, 3);
      expect(TileCacheBudget.decode(null), isNull);
    });

    test('StylePropertyValue decodes kind', () {
      final value = StylePropertyValue.fromJson({'value': 'day', 'kind': 1});
      expect(value.kind, StylePropertyValueKind.CONSTANT);
      expect(value.value, 'day');
    });
  });
}
