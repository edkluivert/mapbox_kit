// Annotation data classes.
// Ported from mapbox_maps_flutter 2.31.0 (pigeon-generated; BSD-3, Mapbox).

part of '../../mapbox_kit.dart';

/// A point annotation shown by a [PointAnnotationManager].
class PointAnnotation {
  PointAnnotation({
    required this.id,
    required this.geometry,
    this.image,
    this.iconAnchor,
    this.iconImage,
    this.iconOffset,
    this.iconRotate,
    this.iconSize,
    this.iconTextFit,
    this.iconTextFitPadding,
    this.symbolSortKey,
    this.textAnchor,
    this.textField,
    this.textJustify,
    this.textLetterSpacing,
    this.textLineHeight,
    this.textMaxWidth,
    this.textOffset,
    this.textRadialOffset,
    this.textRotate,
    this.textSize,
    this.textTransform,
    this.iconColor,
    this.iconEmissiveStrength,
    this.iconHaloBlur,
    this.iconHaloColor,
    this.iconHaloWidth,
    this.iconImageCrossFade,
    this.iconOcclusionOpacity,
    this.iconOpacity,
    this.symbolZOffset,
    this.textColor,
    this.textEmissiveStrength,
    this.textHaloBlur,
    this.textHaloColor,
    this.textHaloWidth,
    this.textOcclusionOpacity,
    this.textOpacity,
    this.isDraggable,
    this.customData,
  });

  /// The id for annotation
  String id;

  /// The geometry that determines the location/shape of this annotation
  Point geometry;

  /// The bitmap image for this Annotation, as PNG bytes.
  Uint8List? image;

  /// Part of the icon placed closest to the anchor.
  IconAnchor? iconAnchor;

  /// Name of image in sprite to use for drawing an image background.
  String? iconImage;

  /// Offset distance of icon from its anchor.
  List<double?>? iconOffset;

  /// Rotates the icon clockwise.
  double? iconRotate;

  /// Scales the original size of the icon by the provided factor.
  double? iconSize;

  /// Scales the icon to fit around the associated text.
  IconTextFit? iconTextFit;

  /// Size of the additional area added to dimensions determined by `icon-text-fit`.
  List<double?>? iconTextFitPadding;

  /// Sorts features in ascending order based on this value.
  double? symbolSortKey;

  /// Part of the text placed closest to the anchor.
  TextAnchor? textAnchor;

  /// Value to use for a text label.
  String? textField;

  /// Text justification options.
  TextJustify? textJustify;

  /// Text tracking amount.
  double? textLetterSpacing;

  /// Text leading value for multi-line text.
  double? textLineHeight;

  /// The maximum line width for text wrapping.
  double? textMaxWidth;

  /// Offset distance of text from its anchor.
  List<double?>? textOffset;

  /// Radial offset of text, in the direction of the symbol's anchor.
  double? textRadialOffset;

  /// Rotates the text clockwise.
  double? textRotate;

  /// Font size.
  double? textSize;

  /// Specifies how to capitalize text.
  TextTransform? textTransform;

  /// The color of the icon. This can only be used with SDF icons.
  int? iconColor;

  /// Controls the intensity of light emitted on the source features.
  double? iconEmissiveStrength;

  /// Fade out the halo towards the outside.
  double? iconHaloBlur;

  /// The color of the icon's halo.
  int? iconHaloColor;

  /// Distance of halo to the icon outline.
  double? iconHaloWidth;

  /// Controls the transition progress between the image variants of icon-image.
  double? iconImageCrossFade;

  /// The opacity at which the icon will be drawn in case of being depth occluded.
  double? iconOcclusionOpacity;

  /// The opacity at which the icon will be drawn.
  double? iconOpacity;

  /// Specifies an uniform elevation from the ground, in meters.
  double? symbolZOffset;

  /// The color with which the text will be drawn.
  int? textColor;

  /// Controls the intensity of light emitted on the source features.
  double? textEmissiveStrength;

  /// The halo's fadeout distance towards the outside.
  double? textHaloBlur;

  /// The color of the text's halo, which helps it stand out from backgrounds.
  int? textHaloColor;

  /// Distance of halo to the font outline.
  double? textHaloWidth;

  /// The opacity at which the text will be drawn in case of being depth occluded.
  double? textOcclusionOpacity;

  /// The opacity at which the text will be drawn.
  double? textOpacity;

  /// Property to determine whether annotation can be manually moved around map
  bool? isDraggable;

  /// Custom data attached to the annotation, returned with the interaction events.
  Map<String, Object>? customData;

  Map<String, dynamic> toJson() => {
        'id': id,
        'geometry': geometry.toJson(),
        ..._pointAnnotationFieldsToJson(this),
      };

  static PointAnnotation fromJson(Map<String, dynamic> json) {
    final options = PointAnnotationOptions.fromJson(json);
    return PointAnnotation(
      id: json['id']?.toString() ?? '',
      geometry: options.geometry,
      image: options.image,
      iconAnchor: options.iconAnchor,
      iconImage: options.iconImage,
      iconOffset: options.iconOffset,
      iconRotate: options.iconRotate,
      iconSize: options.iconSize,
      iconTextFit: options.iconTextFit,
      iconTextFitPadding: options.iconTextFitPadding,
      symbolSortKey: options.symbolSortKey,
      textAnchor: options.textAnchor,
      textField: options.textField,
      textJustify: options.textJustify,
      textLetterSpacing: options.textLetterSpacing,
      textLineHeight: options.textLineHeight,
      textMaxWidth: options.textMaxWidth,
      textOffset: options.textOffset,
      textRadialOffset: options.textRadialOffset,
      textRotate: options.textRotate,
      textSize: options.textSize,
      textTransform: options.textTransform,
      iconColor: options.iconColor,
      iconEmissiveStrength: options.iconEmissiveStrength,
      iconHaloBlur: options.iconHaloBlur,
      iconHaloColor: options.iconHaloColor,
      iconHaloWidth: options.iconHaloWidth,
      iconImageCrossFade: options.iconImageCrossFade,
      iconOcclusionOpacity: options.iconOcclusionOpacity,
      iconOpacity: options.iconOpacity,
      symbolZOffset: options.symbolZOffset,
      textColor: options.textColor,
      textEmissiveStrength: options.textEmissiveStrength,
      textHaloBlur: options.textHaloBlur,
      textHaloColor: options.textHaloColor,
      textHaloWidth: options.textHaloWidth,
      textOcclusionOpacity: options.textOcclusionOpacity,
      textOpacity: options.textOpacity,
      isDraggable: options.isDraggable,
      customData: options.customData,
    );
  }
}

/// The options to create a [PointAnnotation].
class PointAnnotationOptions {
  PointAnnotationOptions({
    required this.geometry,
    this.image,
    this.iconAnchor,
    this.iconImage,
    this.iconOffset,
    this.iconRotate,
    this.iconSize,
    this.iconTextFit,
    this.iconTextFitPadding,
    this.symbolSortKey,
    this.textAnchor,
    this.textField,
    this.textJustify,
    this.textLetterSpacing,
    this.textLineHeight,
    this.textMaxWidth,
    this.textOffset,
    this.textRadialOffset,
    this.textRotate,
    this.textSize,
    this.textTransform,
    this.iconColor,
    this.iconEmissiveStrength,
    this.iconHaloBlur,
    this.iconHaloColor,
    this.iconHaloWidth,
    this.iconImageCrossFade,
    this.iconOcclusionOpacity,
    this.iconOpacity,
    this.symbolZOffset,
    this.textColor,
    this.textEmissiveStrength,
    this.textHaloBlur,
    this.textHaloColor,
    this.textHaloWidth,
    this.textOcclusionOpacity,
    this.textOpacity,
    this.isDraggable,
    this.customData,
  });

  /// The geometry that determines the location/shape of this annotation
  Point geometry;

  /// The bitmap image for this Annotation, as PNG bytes.
  Uint8List? image;
  IconAnchor? iconAnchor;
  String? iconImage;
  List<double?>? iconOffset;
  double? iconRotate;
  double? iconSize;
  IconTextFit? iconTextFit;
  List<double?>? iconTextFitPadding;
  double? symbolSortKey;
  TextAnchor? textAnchor;
  String? textField;
  TextJustify? textJustify;
  double? textLetterSpacing;
  double? textLineHeight;
  double? textMaxWidth;
  List<double?>? textOffset;
  double? textRadialOffset;
  double? textRotate;
  double? textSize;
  TextTransform? textTransform;
  int? iconColor;
  double? iconEmissiveStrength;
  double? iconHaloBlur;
  int? iconHaloColor;
  double? iconHaloWidth;
  double? iconImageCrossFade;
  double? iconOcclusionOpacity;
  double? iconOpacity;
  double? symbolZOffset;
  int? textColor;
  double? textEmissiveStrength;
  double? textHaloBlur;
  int? textHaloColor;
  double? textHaloWidth;
  double? textOcclusionOpacity;
  double? textOpacity;

  /// Property to determine whether annotation can be manually moved around map
  bool? isDraggable;

  /// Custom data attached to the annotation, returned with the interaction events.
  Map<String, Object>? customData;

  Map<String, dynamic> toJson() => {
        'geometry': geometry.toJson(),
        ..._pointAnnotationFieldsToJson(this),
      };

  static PointAnnotationOptions fromJson(Map<String, dynamic> json) =>
      PointAnnotationOptions(
        geometry: Point.fromJson(_requireMap(json['geometry'])),
        image: _bytesFromJson(json['image']),
        iconAnchor: _enumFromIndex(IconAnchor.values, json['iconAnchor']),
        iconImage: json['iconImage'] as String?,
        iconOffset: _asDoubleList(json['iconOffset']),
        iconRotate: _asDouble(json['iconRotate']),
        iconSize: _asDouble(json['iconSize']),
        iconTextFit: _enumFromIndex(IconTextFit.values, json['iconTextFit']),
        iconTextFitPadding: _asDoubleList(json['iconTextFitPadding']),
        symbolSortKey: _asDouble(json['symbolSortKey']),
        textAnchor: _enumFromIndex(TextAnchor.values, json['textAnchor']),
        textField: json['textField'] as String?,
        textJustify: _enumFromIndex(TextJustify.values, json['textJustify']),
        textLetterSpacing: _asDouble(json['textLetterSpacing']),
        textLineHeight: _asDouble(json['textLineHeight']),
        textMaxWidth: _asDouble(json['textMaxWidth']),
        textOffset: _asDoubleList(json['textOffset']),
        textRadialOffset: _asDouble(json['textRadialOffset']),
        textRotate: _asDouble(json['textRotate']),
        textSize: _asDouble(json['textSize']),
        textTransform:
            _enumFromIndex(TextTransform.values, json['textTransform']),
        iconColor: _asInt(json['iconColor']),
        iconEmissiveStrength: _asDouble(json['iconEmissiveStrength']),
        iconHaloBlur: _asDouble(json['iconHaloBlur']),
        iconHaloColor: _asInt(json['iconHaloColor']),
        iconHaloWidth: _asDouble(json['iconHaloWidth']),
        iconImageCrossFade: _asDouble(json['iconImageCrossFade']),
        iconOcclusionOpacity: _asDouble(json['iconOcclusionOpacity']),
        iconOpacity: _asDouble(json['iconOpacity']),
        symbolZOffset: _asDouble(json['symbolZOffset']),
        textColor: _asInt(json['textColor']),
        textEmissiveStrength: _asDouble(json['textEmissiveStrength']),
        textHaloBlur: _asDouble(json['textHaloBlur']),
        textHaloColor: _asInt(json['textHaloColor']),
        textHaloWidth: _asDouble(json['textHaloWidth']),
        textOcclusionOpacity: _asDouble(json['textOcclusionOpacity']),
        textOpacity: _asDouble(json['textOpacity']),
        isDraggable: json['isDraggable'] as bool?,
        customData: _asMap(json['customData'])?.cast<String, Object>(),
      );
}

Map<String, dynamic> _pointAnnotationFieldsToJson(dynamic a) => _compact({
      'image': _bytesToJson(a.image as Uint8List?),
      'iconAnchor': (a.iconAnchor as IconAnchor?)?.index,
      'iconImage': a.iconImage,
      'iconOffset': a.iconOffset,
      'iconRotate': a.iconRotate,
      'iconSize': a.iconSize,
      'iconTextFit': (a.iconTextFit as IconTextFit?)?.index,
      'iconTextFitPadding': a.iconTextFitPadding,
      'symbolSortKey': a.symbolSortKey,
      'textAnchor': (a.textAnchor as TextAnchor?)?.index,
      'textField': a.textField,
      'textJustify': (a.textJustify as TextJustify?)?.index,
      'textLetterSpacing': a.textLetterSpacing,
      'textLineHeight': a.textLineHeight,
      'textMaxWidth': a.textMaxWidth,
      'textOffset': a.textOffset,
      'textRadialOffset': a.textRadialOffset,
      'textRotate': a.textRotate,
      'textSize': a.textSize,
      'textTransform': (a.textTransform as TextTransform?)?.index,
      'iconColor': a.iconColor,
      'iconEmissiveStrength': a.iconEmissiveStrength,
      'iconHaloBlur': a.iconHaloBlur,
      'iconHaloColor': a.iconHaloColor,
      'iconHaloWidth': a.iconHaloWidth,
      'iconImageCrossFade': a.iconImageCrossFade,
      'iconOcclusionOpacity': a.iconOcclusionOpacity,
      'iconOpacity': a.iconOpacity,
      'symbolZOffset': a.symbolZOffset,
      'textColor': a.textColor,
      'textEmissiveStrength': a.textEmissiveStrength,
      'textHaloBlur': a.textHaloBlur,
      'textHaloColor': a.textHaloColor,
      'textHaloWidth': a.textHaloWidth,
      'textOcclusionOpacity': a.textOcclusionOpacity,
      'textOpacity': a.textOpacity,
      'isDraggable': a.isDraggable,
      'customData': a.customData,
    });

/// A polyline annotation shown by a [PolylineAnnotationManager].
class PolylineAnnotation {
  PolylineAnnotation({
    required this.id,
    required this.geometry,
    this.lineElevationGroundScale,
    this.lineJoin,
    this.lineSortKey,
    this.lineZOffset,
    this.lineBlur,
    this.lineBorderColor,
    this.lineBorderWidth,
    this.lineColor,
    this.lineEmissiveStrength,
    this.lineGapWidth,
    this.lineOffset,
    this.lineOpacity,
    this.linePattern,
    this.lineWidth,
    this.isDraggable,
    this.customData,
  });

  /// The id for annotation
  String id;

  /// The geometry that determines the location/shape of this annotation
  LineString geometry;

  /// Controls how much the elevation of lines with `line-elevation-reference` set to `sea` scales with terrain exaggeration.
  double? lineElevationGroundScale;

  /// The display of lines when joining.
  LineJoin? lineJoin;

  /// Sorts features in ascending order based on this value.
  double? lineSortKey;

  /// Vertical offset from ground, in meters.
  double? lineZOffset;

  /// Blur applied to the line, in pixels.
  double? lineBlur;

  /// The color of the line border.
  int? lineBorderColor;

  /// The width of the line border. A value of zero means no border.
  double? lineBorderWidth;

  /// The color with which the line will be drawn.
  int? lineColor;

  /// Controls the intensity of light emitted on the source features.
  double? lineEmissiveStrength;

  /// Draws a line casing outside of a line's actual path. Value indicates the width of the inner gap.
  double? lineGapWidth;

  /// The line's offset.
  double? lineOffset;

  /// The opacity at which the line will be drawn.
  double? lineOpacity;

  /// Name of image in sprite to use for drawing image lines.
  String? linePattern;

  /// Stroke thickness.
  double? lineWidth;

  /// Property to determine whether annotation can be manually moved around map
  bool? isDraggable;

  /// Custom data attached to the annotation, returned with the interaction events.
  Map<String, Object>? customData;

  Map<String, dynamic> toJson() => {
        'id': id,
        'geometry': geometry.toJson(),
        ..._polylineAnnotationFieldsToJson(this),
      };

  static PolylineAnnotation fromJson(Map<String, dynamic> json) {
    final o = PolylineAnnotationOptions.fromJson(json);
    return PolylineAnnotation(
      id: json['id']?.toString() ?? '',
      geometry: o.geometry,
      lineElevationGroundScale: o.lineElevationGroundScale,
      lineJoin: o.lineJoin,
      lineSortKey: o.lineSortKey,
      lineZOffset: o.lineZOffset,
      lineBlur: o.lineBlur,
      lineBorderColor: o.lineBorderColor,
      lineBorderWidth: o.lineBorderWidth,
      lineColor: o.lineColor,
      lineEmissiveStrength: o.lineEmissiveStrength,
      lineGapWidth: o.lineGapWidth,
      lineOffset: o.lineOffset,
      lineOpacity: o.lineOpacity,
      linePattern: o.linePattern,
      lineWidth: o.lineWidth,
      isDraggable: o.isDraggable,
      customData: o.customData,
    );
  }
}

/// The options to create a [PolylineAnnotation].
class PolylineAnnotationOptions {
  PolylineAnnotationOptions({
    required this.geometry,
    this.lineElevationGroundScale,
    this.lineJoin,
    this.lineSortKey,
    this.lineZOffset,
    this.lineBlur,
    this.lineBorderColor,
    this.lineBorderWidth,
    this.lineColor,
    this.lineEmissiveStrength,
    this.lineGapWidth,
    this.lineOffset,
    this.lineOpacity,
    this.linePattern,
    this.lineWidth,
    this.isDraggable,
    this.customData,
  });

  /// The geometry that determines the location/shape of this annotation
  LineString geometry;
  double? lineElevationGroundScale;
  LineJoin? lineJoin;
  double? lineSortKey;
  double? lineZOffset;
  double? lineBlur;
  int? lineBorderColor;
  double? lineBorderWidth;
  int? lineColor;
  double? lineEmissiveStrength;
  double? lineGapWidth;
  double? lineOffset;
  double? lineOpacity;
  String? linePattern;
  double? lineWidth;

  /// Property to determine whether annotation can be manually moved around map
  bool? isDraggable;

  /// Custom data attached to the annotation, returned with the interaction events.
  Map<String, Object>? customData;

  Map<String, dynamic> toJson() => {
        'geometry': geometry.toJson(),
        ..._polylineAnnotationFieldsToJson(this),
      };

  static PolylineAnnotationOptions fromJson(Map<String, dynamic> json) =>
      PolylineAnnotationOptions(
        geometry: LineString.fromJson(_requireMap(json['geometry'])),
        lineElevationGroundScale: _asDouble(json['lineElevationGroundScale']),
        lineJoin: _enumFromIndex(LineJoin.values, json['lineJoin']),
        lineSortKey: _asDouble(json['lineSortKey']),
        lineZOffset: _asDouble(json['lineZOffset']),
        lineBlur: _asDouble(json['lineBlur']),
        lineBorderColor: _asInt(json['lineBorderColor']),
        lineBorderWidth: _asDouble(json['lineBorderWidth']),
        lineColor: _asInt(json['lineColor']),
        lineEmissiveStrength: _asDouble(json['lineEmissiveStrength']),
        lineGapWidth: _asDouble(json['lineGapWidth']),
        lineOffset: _asDouble(json['lineOffset']),
        lineOpacity: _asDouble(json['lineOpacity']),
        linePattern: json['linePattern'] as String?,
        lineWidth: _asDouble(json['lineWidth']),
        isDraggable: json['isDraggable'] as bool?,
        customData: _asMap(json['customData'])?.cast<String, Object>(),
      );
}

Map<String, dynamic> _polylineAnnotationFieldsToJson(dynamic a) => _compact({
      'lineElevationGroundScale': a.lineElevationGroundScale,
      'lineJoin': (a.lineJoin as LineJoin?)?.index,
      'lineSortKey': a.lineSortKey,
      'lineZOffset': a.lineZOffset,
      'lineBlur': a.lineBlur,
      'lineBorderColor': a.lineBorderColor,
      'lineBorderWidth': a.lineBorderWidth,
      'lineColor': a.lineColor,
      'lineEmissiveStrength': a.lineEmissiveStrength,
      'lineGapWidth': a.lineGapWidth,
      'lineOffset': a.lineOffset,
      'lineOpacity': a.lineOpacity,
      'linePattern': a.linePattern,
      'lineWidth': a.lineWidth,
      'isDraggable': a.isDraggable,
      'customData': a.customData,
    });
