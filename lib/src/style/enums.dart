// Enums used by the ported style layers, sources and annotations.
// Ported from mapbox_maps_flutter 2.31.0 (pigeon-generated; BSD-3, Mapbox).

part of '../../mapbox_kit.dart';

/// Selects the base of circle-elevation. Some modes might require precomputed elevation data in the tileset.
/// Default value: "none".
enum CircleElevationReference {
  /// Elevated rendering is disabled.
  NONE,

  /// Elevated rendering is enabled. Use this mode to describe additive and stackable features that should exist only on top of road polygons.
  HD_ROAD_MARKUP,
}

/// Orientation of circle when map is pitched.
/// Default value: "viewport".
enum CirclePitchAlignment {
  /// The circle is aligned to the plane of the map.
  MAP,

  /// The circle is aligned to the plane of the viewport.
  VIEWPORT,
}

/// Controls the scaling behavior of the circle when the map is pitched.
/// Default value: "map".
enum CirclePitchScale {
  /// Circles are scaled according to their apparent distance to the camera.
  MAP,

  /// Circles are not scaled.
  VIEWPORT,
}

/// Controls the frame of reference for `circle-translate`.
/// Default value: "map".
enum CircleTranslateAnchor {
  /// The circle is translated relative to the map.
  MAP,

  /// The circle is translated relative to the viewport.
  VIEWPORT,
}

/// Selects the base of fill-elevation. Some modes might require precomputed elevation data in the tileset.
/// Default value: "none".
enum FillElevationReference {
  /// Elevated rendering is disabled.
  NONE,

  /// Elevate geometry relative to HD roads. Use this mode to describe base polygons of the road networks.
  HD_ROAD_BASE,

  /// Elevated rendering is enabled. Use this mode to describe additive and stackable features such as 'hatched areas' that should exist only on top of road polygons.
  HD_ROAD_MARKUP,
}

/// Controls the behavior of fill extrusion base over terrain
enum FillExtrusionBaseAlignment {
  /// The fill extrusion base follows terrain slope.
  TERRAIN,

  /// The fill extrusion base is flat over terrain.
  FLAT,
}

/// Controls the behavior of fill extrusion height over terrain
enum FillExtrusionHeightAlignment {
  /// The fill extrusion base follows terrain slope.
  TERRAIN,

  /// The fill extrusion base is flat over terrain.
  FLAT,
}

/// Controls the frame of reference for `fill-extrusion-translate`.
enum FillExtrusionTranslateAnchor {
  /// The fill extrusion is translated relative to the map.
  MAP,

  /// The fill extrusion is translated relative to the viewport.
  VIEWPORT,
}

/// Controls the frame of reference for `fill-translate`.
/// Default value: "map".
enum FillTranslateAnchor {
  /// The fill is translated relative to the map.
  MAP,

  /// The fill is translated relative to the viewport.
  VIEWPORT,
}

/// Enumeration of gesture states.
enum GestureState {
  /// Gesture has started.
  started,

  /// Gesture is in progress.
  changed,

  /// Gesture has ended.
  ended,
}

/// Part of the icon placed closest to the anchor.
/// Default value: "center".
enum IconAnchor {
  /// The center of the icon is placed closest to the anchor.
  CENTER,

  /// The left side of the icon is placed closest to the anchor.
  LEFT,

  /// The right side of the icon is placed closest to the anchor.
  RIGHT,

  /// The top of the icon is placed closest to the anchor.
  TOP,

  /// The bottom of the icon is placed closest to the anchor.
  BOTTOM,

  /// The top left corner of the icon is placed closest to the anchor.
  TOP_LEFT,

  /// The top right corner of the icon is placed closest to the anchor.
  TOP_RIGHT,

  /// The bottom left corner of the icon is placed closest to the anchor.
  BOTTOM_LEFT,

  /// The bottom right corner of the icon is placed closest to the anchor.
  BOTTOM_RIGHT,
}

/// Orientation of icon when map is pitched.
/// Default value: "auto".
enum IconPitchAlignment {
  /// The icon is aligned to the plane of the map.
  MAP,

  /// The icon is aligned to the plane of the viewport.
  VIEWPORT,

  /// Automatically matches the value of `icon-rotation-alignment`.
  AUTO,
}

/// In combination with `symbol-placement`, determines the rotation behavior of icons.
/// Default value: "auto".
enum IconRotationAlignment {
  /// When `symbol-placement` is set to `point`, aligns icons east-west. When `symbol-placement` is set to `line` or `line-center`, aligns icon x-axes with the line.
  MAP,

  /// Produces icons whose x-axes are aligned with the x-axis of the viewport, regardless of the value of `symbol-placement`.
  VIEWPORT,

  /// When `symbol-placement` is set to `point`, this is equivalent to `viewport`. When `symbol-placement` is set to `line` or `line-center`, this is equivalent to `map`.
  AUTO,
}

/// Scales the icon to fit around the associated text.
/// Default value: "none".
enum IconTextFit {
  /// The icon is displayed at its intrinsic aspect ratio.
  NONE,

  /// The icon is scaled in the x-dimension to fit the width of the text.
  WIDTH,

  /// The icon is scaled in the y-dimension to fit the height of the text.
  HEIGHT,

  /// The icon is scaled in both x- and y-dimensions.
  BOTH,
}

/// Controls the frame of reference for `icon-translate`.
/// Default value: "map".
enum IconTranslateAnchor {
  /// Icons are translated relative to the map.
  MAP,

  /// Icons are translated relative to the viewport.
  VIEWPORT,
}

/// The display of line endings.
/// Default value: "butt".
enum LineCap {
  /// A cap with a squared-off end which is drawn to the exact endpoint of the line.
  BUTT,

  /// A cap with a rounded end which is drawn beyond the endpoint of the line at a radius of one-half of the line's width and centered on the endpoint of the line.
  ROUND,

  /// A cap with a squared-off end which is drawn beyond the endpoint of the line at a distance of one-half of the line's width.
  SQUARE,
}

/// Selects the base of line-elevation. Some modes might require precomputed elevation data in the tileset.
/// Default value: "none".
enum LineElevationReference {
  /// Elevated rendering is disabled.
  NONE,

  /// Elevated rendering is enabled. Use this mode to elevate lines relative to the sea level.
  SEA,

  /// Elevated rendering is enabled. Use this mode to elevate lines relative to the ground's height below them.
  GROUND,

  /// Elevated rendering is enabled. Use this mode to describe additive and stackable features that should exist only on top of road polygons.
  HD_ROAD_MARKUP,
}

/// The display of lines when joining.
/// Default value: "miter".
enum LineJoin {
  /// A join with a squared-off end which is drawn beyond the endpoint of the line at a distance of one-half of the line's width.
  BEVEL,

  /// A join with a rounded end which is drawn beyond the endpoint of the line at a radius of one-half of the line's width and centered on the endpoint of the line.
  ROUND,

  /// A join with a sharp, angled corner which is drawn with the outer sides beyond the endpoint of the path until they meet.
  MITER,

  /// Line segments are not joined together, each one creates a separate line. Useful in combination with line-pattern. Line-cap property is not respected. Can't be used with data-driven styling.
  NONE,
}

/// Controls the frame of reference for `line-translate`.
/// Default value: "map".
enum LineTranslateAnchor {
  /// The line is translated relative to the map.
  MAP,

  /// The line is translated relative to the viewport.
  VIEWPORT,
}

/// Selects the unit of line-width. The same unit is automatically used for line-blur and line-offset. Note: This is an experimental property and might be removed in a future release.
/// Default value: "pixels".
enum LineWidthUnit {
  /// Width is rendered in pixels.
  PIXELS,

  /// Width is rendered in meters.
  METERS,
}

/// Specify how opacity in case of being occluded should be applied
/// Default value: "anchor".
enum OcclusionOpacityMode {
  /// Whole symbol is treated as occluded if it's anchor point is occluded
  ANCHOR,

  /// Occlusion is applied on a per-pixel basis
  PIXEL,
}

/// Describes the kind of a style property value.
enum StylePropertyValueKind {
  /// The property value is not defined.
  UNDEFINED,

  /// The property value is a constant.
  CONSTANT,

  /// The property value is a style [expression](https://docs.mapbox.com/mapbox-gl-js/style-spec/#expressions).
  EXPRESSION,

  /// Property value is a style [transition](https://docs.mapbox.com/mapbox-gl-js/style-spec/#transition).
  TRANSITION,
}

/// Selects the base of symbol-elevation.
/// Default value: "ground".
enum SymbolElevationReference {
  /// Elevate symbols relative to the sea level.
  SEA,

  /// Elevate symbols relative to the ground's height below them.
  GROUND,

  /// Use this mode to enable elevated behavior for features that are rendered on top of 3D road polygons. The feature is currently being developed.
  HD_ROAD_MARKUP,
}

/// Label placement relative to its geometry.
/// Default value: "point".
enum SymbolPlacement {
  /// The label is placed at the point where the geometry is located.
  POINT,

  /// The label is placed along the line of the geometry. Can only be used on `LineString` and `Polygon` geometries.
  LINE,

  /// The label is placed at the center of the line of the geometry. Can only be used on `LineString` and `Polygon` geometries. Note that a single feature in a vector tile may contain multiple line geometries.
  LINE_CENTER,
}

/// Determines whether overlapping symbols in the same layer are rendered in the order that they appear in the data source or by their y-position relative to the viewport. To control the order and prioritization of symbols otherwise, use `symbol-sort-key`.
/// Default value: "auto".
enum SymbolZOrder {
  /// Sorts symbols by `symbol-sort-key` if set. Otherwise, sorts symbols by their y-position relative to the viewport if `icon-allow-overlap` or `text-allow-overlap` is set to `true` or `icon-ignore-placement` or `text-ignore-placement` is `false`.
  AUTO,

  /// Sorts symbols by their y-position relative to the viewport if any of the following is set to `true`: `icon-allow-overlap`, `text-allow-overlap`, `icon-ignore-placement`, `text-ignore-placement`.
  VIEWPORT_Y,

  /// Sorts symbols by `symbol-sort-key` if set. Otherwise, no sorting is applied; symbols are rendered in the same order as the source data.
  SOURCE,
}

/// Part of the text placed closest to the anchor.
/// Default value: "center".
enum TextAnchor {
  /// The center of the text is placed closest to the anchor.
  CENTER,

  /// The left side of the text is placed closest to the anchor.
  LEFT,

  /// The right side of the text is placed closest to the anchor.
  RIGHT,

  /// The top of the text is placed closest to the anchor.
  TOP,

  /// The bottom of the text is placed closest to the anchor.
  BOTTOM,

  /// The top left corner of the text is placed closest to the anchor.
  TOP_LEFT,

  /// The top right corner of the text is placed closest to the anchor.
  TOP_RIGHT,

  /// The bottom left corner of the text is placed closest to the anchor.
  BOTTOM_LEFT,

  /// The bottom right corner of the text is placed closest to the anchor.
  BOTTOM_RIGHT,
}

/// Text justification options.
/// Default value: "center".
enum TextJustify {
  /// The text is aligned towards the anchor position.
  AUTO,

  /// The text is aligned to the left.
  LEFT,

  /// The text is centered.
  CENTER,

  /// The text is aligned to the right.
  RIGHT,
}

/// Orientation of text when map is pitched.
/// Default value: "auto".
enum TextPitchAlignment {
  /// The text is aligned to the plane of the map.
  MAP,

  /// The text is aligned to the plane of the viewport.
  VIEWPORT,

  /// Automatically matches the value of `text-rotation-alignment`.
  AUTO,
}

/// In combination with `symbol-placement`, determines the rotation behavior of the individual glyphs forming the text.
/// Default value: "auto".
enum TextRotationAlignment {
  /// When `symbol-placement` is set to `point`, aligns text east-west. When `symbol-placement` is set to `line` or `line-center`, aligns text x-axes with the line.
  MAP,

  /// Produces glyphs whose x-axes are aligned with the x-axis of the viewport, regardless of the value of `symbol-placement`.
  VIEWPORT,

  /// When `symbol-placement` is set to `point`, this is equivalent to `viewport`. When `symbol-placement` is set to `line` or `line-center`, this is equivalent to `map`.
  AUTO,
}

/// Specifies how to capitalize text, similar to the CSS `text-transform` property.
/// Default value: "none".
enum TextTransform {
  /// The text is not altered.
  NONE,

  /// Forces all letters to be displayed in uppercase.
  UPPERCASE,

  /// Forces all letters to be displayed in lowercase.
  LOWERCASE,
}

/// Controls the frame of reference for `text-translate`.
/// Default value: "map".
enum TextTranslateAnchor {
  /// The text is translated relative to the map.
  MAP,

  /// The text is translated relative to the viewport.
  VIEWPORT,
}

/// The visibility of a layer.
enum Visibility {
  /// The layer is shown.
  VISIBLE,

  /// The layer is hidden.
  NONE
}
