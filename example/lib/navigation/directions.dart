// A small Mapbox Directions API client and the route model the Navigate
// screen drives on. Only the fields the UI needs are kept.

import 'dart:convert';
import 'dart:io';

import 'package:mapbox_kit/mapbox_kit.dart';


/// A spoken instruction, due when [distanceAlongGeometry] meters of the
/// step remain.
class VoiceInstruction {
  const VoiceInstruction(this.distanceAlongGeometry, this.announcement);
  final double distanceAlongGeometry;
  final String announcement;
}

class DirectionsStep {
  const DirectionsStep({
    required this.distance,
    required this.duration,
    required this.name,
    required this.ref,
    required this.instruction,
    required this.maneuverType,
    required this.maneuverModifier,
    required this.bannerText,
    required this.bannerType,
    required this.bannerModifier,
    required this.location,
    this.voice = const [],
  });

  /// Length of the step in meters, from its maneuver to the next one.
  final double distance;
  final double duration;
  final String name;
  final String? ref;
  final String instruction;
  final String maneuverType;
  final String? maneuverModifier;

  /// What the top banner shows while driving this step: the NEXT maneuver.
  final String? bannerText;
  final String? bannerType;
  final String? bannerModifier;

  /// `[lng, lat]` of the maneuver that starts this step.
  final List<double> location;

  /// Voice announcements of this step, in the order they are due.
  final List<VoiceInstruction> voice;

  static DirectionsStep fromJson(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>;
    final banners = json['bannerInstructions'] as List?;
    final primary = banners != null && banners.isNotEmpty
        ? (banners.first as Map<String, dynamic>)['primary'] as Map<String, dynamic>?
        : null;
    return DirectionsStep(
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      name: json['name'] as String? ?? '',
      ref: json['ref'] as String?,
      instruction: maneuver['instruction'] as String? ?? '',
      maneuverType: maneuver['type'] as String? ?? '',
      maneuverModifier: maneuver['modifier'] as String?,
      bannerText: primary?['text'] as String?,
      bannerType: primary?['type'] as String?,
      bannerModifier: primary?['modifier'] as String?,
      location: (maneuver['location'] as List).cast<num>().map((e) => e.toDouble()).toList(),
      voice: [
        for (final v in (json['voiceInstructions'] as List?) ?? const [])
          VoiceInstruction(
            ((v as Map<String, dynamic>)['distanceAlongGeometry'] as num).toDouble(),
            v['announcement'] as String? ?? '',
          )
      ],
    );
  }
}

class DirectionsRoute {
  const DirectionsRoute({
    required this.coordinates,
    required this.distance,
    required this.duration,
    required this.steps,
  });

  /// `[lng, lat]` pairs of the full route geometry.
  final List<List<double>> coordinates;
  final double distance;
  final double duration;
  final List<DirectionsStep> steps;

  List<Position> get positions =>
      [for (final c in coordinates) Position(c[0], c[1])];

  /// Fetches a route from [origin] to [destination] with the given token
  /// (`driving`, `walking` or `cycling`), or null when the API cannot be
  /// reached or finds no route.
  static Future<DirectionsRoute?> fetch(
    String accessToken, {
    required Position origin,
    required Position destination,
    String profile = 'driving',
  }) async {
    if (accessToken.isEmpty) return null;
    try {
      return await _fetch(accessToken, origin, destination, profile)
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      return null;
    }
  }

  static Future<DirectionsRoute?> _fetch(
      String accessToken, Position origin, Position destination, String profile) async {
    final uri = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/$profile/'
        '${origin.lng},${origin.lat};${destination.lng},${destination.lat}'
        '?steps=true&geometries=geojson&overview=full&banner_instructions=true'
        '&voice_instructions=true&voice_units=imperial'
        '&access_token=$accessToken');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) return null;
      final json = jsonDecode(body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List;
      final steps = [
        for (final leg in legs)
          for (final step in (leg as Map<String, dynamic>)['steps'] as List)
            DirectionsStep.fromJson(step as Map<String, dynamic>)
      ];
      final coords = ((route['geometry'] as Map<String, dynamic>)['coordinates'] as List)
          .map((c) => (c as List).cast<num>().map((e) => e.toDouble()).toList())
          .toList();
      return DirectionsRoute(
        coordinates: coords,
        distance: (route['distance'] as num).toDouble(),
        duration: (route['duration'] as num).toDouble(),
        steps: steps,
      );
    } finally {
      client.close(force: true);
    }
  }
}
