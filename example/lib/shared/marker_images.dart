// Marker, cluster and puck bitmaps drawn at runtime with package:image, so
// the example needs no image assets.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

img.ColorRgba8 _c(int argb) => img.ColorRgba8(
    (argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF, (argb >> 24) & 0xFF);

/// A white disc with a blue navigation arrow, like the puck in the reference.
Uint8List puckImage({int size = 96, int color = 0xFF3B82F6}) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  final c = size ~/ 2;
  img.fillCircle(image, x: c, y: c, radius: c - 1, color: _c(0x33000000), antialias: true);
  img.fillCircle(image, x: c, y: c, radius: c - 6, color: _c(0xFFFFFFFF), antialias: true);
  final s = size / 96;
  img.Point p(double x, double y) => img.Point((x * s).round(), (y * s).round());
  img.fillPolygon(image,
      vertices: [p(48, 22), p(68, 66), p(48, 56), p(28, 66)], color: _c(color));
  return img.encodePng(image);
}

/// Bracket corners with a count and a label, like the place markers in the
/// reference ("SAN FRANCISCO / 01"). [color] is the ink: white at rest,
/// orange when picked.
Uint8List placeMarker({
  required String count,
  required String label,
  int color = 0xFFFFFFFF,
  int size = 168,
}) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  final ink = _c(color);
  final s = size / 168;
  int px(double v) => (v * s).round();
  const inset = 42.0, arm = 22.0;
  final t = math.max(2, px(4));
  void line(double x1, double y1, double x2, double y2) =>
      img.drawLine(image, x1: px(x1), y1: px(y1), x2: px(x2), y2: px(y2), color: ink, thickness: t);
  // Four corners of the square [inset, 168-inset].
  line(inset, inset, inset + arm, inset); line(inset, inset, inset, inset + arm);
  line(168 - inset, inset, 168 - inset - arm, inset); line(168 - inset, inset, 168 - inset, inset + arm);
  line(inset, 168 - inset, inset + arm, 168 - inset); line(inset, 168 - inset, inset, 168 - inset - arm);
  line(168 - inset, 168 - inset, 168 - inset - arm, 168 - inset);
  line(168 - inset, 168 - inset, 168 - inset, 168 - inset - arm);
  // Count centred in the brackets (arial48 glyphs are ~26 px wide).
  img.drawString(image, count, font: img.arial48, x: px(84) - count.length * 13, y: px(58), color: ink);
  // Label above the brackets (arial14 glyphs are ~8 px wide).
  img.drawString(image, label, font: img.arial14, x: px(84) - label.length * 4, y: px(18), color: ink);
  return img.encodePng(image);
}

/// A navy disc with a white letter: the A and B pins of the Navigate screen.
Uint8List pinMarker(String letter, {int size = 96, int color = 0xFF2E3A52}) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  final c = size ~/ 2;
  img.fillCircle(image, x: c, y: c, radius: c - 2, color: _c(0xFFFFFFFF), antialias: true);
  img.fillCircle(image, x: c, y: c, radius: c - 8, color: _c(color), antialias: true);
  // arial48 glyphs are ~26 px wide and ~48 px tall.
  img.drawString(image, letter, font: img.arial48, x: c - 13, y: c - 24, color: _c(0xFFFFFFFF));
  return img.encodePng(image);
}
