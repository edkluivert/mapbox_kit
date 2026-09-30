part of '../../mapbox_kit.dart';

/// The PolylineAnnotationManager to add/update/delete PolylineAnnotations on the map.
class PolylineAnnotationManager extends BaseAnnotationManager {
  PolylineAnnotationManager._({required super.id, required super.channel})
      : super._();

  static const _prefix = 'polylineAnnotation';

  PolylineAnnotation _annotation(Map<String, dynamic> event) =>
      PolylineAnnotation.fromJson(_requireMap(event['annotation']));

  /// Registers tap event callbacks for the annotations managed by this manager.
  Cancelable tapEvents({required Function(PolylineAnnotation) onTap}) {
    return _interactions('tap')
        .listen((data) => onTap(_annotation(data)))
        .asCancelable();
  }

  /// Registers long press event callbacks for the annotations managed by this manager.
  Cancelable longPressEvents(
      {required Function(PolylineAnnotation) onLongPress}) {
    return _interactions('longPress')
        .listen((data) => onLongPress(_annotation(data)))
        .asCancelable();
  }

  /// Registers drag event callbacks for the annotations managed by this manager.
  Cancelable dragEvents({
    Function(PolylineAnnotation)? onBegin,
    Function(PolylineAnnotation)? onChanged,
    Function(PolylineAnnotation)? onEnd,
  }) {
    return _interactions('drag').listen((data) {
      final state = _enumFromIndex(GestureState.values, data['gestureState']);
      switch (state) {
        case GestureState.started when onBegin != null:
          onBegin(_annotation(data));
        case GestureState.changed when onChanged != null:
          onChanged(_annotation(data));
        case GestureState.ended when onEnd != null:
          onEnd(_annotation(data));
        default:
          break;
      }
    }).asCancelable();
  }

  /// Get all annotations of manager.
  Future<List<PolylineAnnotation>> getAnnotations() async =>
      ((await _invoke(_prefix, 'getAnnotations')) as List)
          .map((e) => PolylineAnnotation.fromJson(_requireMap(e)))
          .toList();

  /// Create a new annotation with the option.
  Future<PolylineAnnotation> create(PolylineAnnotationOptions annotation) async =>
      PolylineAnnotation.fromJson(_requireMap(await _invoke(
          _prefix, 'create', {'annotationOption': annotation.toJson()})));

  /// Create multi annotations with the options.
  Future<List<PolylineAnnotation?>> createMulti(
          List<PolylineAnnotationOptions> annotations) async =>
      ((await _invoke(_prefix, 'createMulti', {
        'annotationOptions': annotations.map((e) => e.toJson()).toList()
      })) as List)
          .map((e) =>
              e == null ? null : PolylineAnnotation.fromJson(_requireMap(e)))
          .toList();

  /// Update an added annotation with new properties.
  Future<void> update(PolylineAnnotation annotation) =>
      _invoke(_prefix, 'update', {'annotation': annotation.toJson()});

  /// Delete an added annotation.
  Future<void> delete(PolylineAnnotation annotation) =>
      _invoke(_prefix, 'delete', {'annotation': annotation.toJson()});

  /// Delete all the annotation added by this manager.
  Future<void> deleteAll() => _invoke(_prefix, 'deleteAll');

  /// Delete multiple annotations added by this manager.
  Future<void> deleteMulti(List<PolylineAnnotation> annotations) =>
      _invoke(_prefix, 'deleteMulti',
          {'annotations': annotations.map((e) => e.toJson()).toList()});

  // ── Layer-level properties ─────────────────────────────────────────────

  /// The slot of the annotation layer (Mapbox Standard: `bottom`, `middle`,
  /// `top`). Layers without a slot sit above everything; with 3D terrain on
  /// iOS only slotted layers are draped onto the surface.
  Future<void> setSlot(String slot) => _set('slot', slot);

  /// The slot of the annotation layer, `null` when unset.
  Future<String?> getSlot() => _get('slot');

  Future<void> _set(String property, Object value) =>
      _setProperty(_prefix, property, value);
  Future<T?> _get<T>(String property) async =>
      _optionalCast<T>(await _getProperty(_prefix, property));
  Future<List<double?>?> _getDoubles(String property) async =>
      _asDoubleList(await _getProperty(_prefix, property));
  Future<T?> _getEnum<T extends Enum>(String property, List<T> values) async =>
      BaseAnnotationManager._enumFromName(
          values, await _getProperty(_prefix, property));
  Future<int?> _getColor(String property) async =>
      BaseAnnotationManager._colorFrom(await _getProperty(_prefix, property));

  /// The display of line endings. Default value: "butt".
  Future<void> setLineCap(LineCap lineCap) =>
      _set('line-cap', BaseAnnotationManager._enumName(lineCap));

  /// The display of line endings. Default value: "butt".
  Future<LineCap?> getLineCap() => _getEnum('line-cap', LineCap.values);

  /// Defines the slope of an elevated line.
  @experimental
  Future<void> setLineCrossSlope(double lineCrossSlope) =>
      _set('line-cross-slope', lineCrossSlope);

  /// Defines the slope of an elevated line.
  @experimental
  Future<double?> getLineCrossSlope() => _get('line-cross-slope');

  /// Controls how much the elevation of lines with `line-elevation-reference` set to `sea` scales with terrain exaggeration. Default value: 0.
  Future<void> setLineElevationGroundScale(double lineElevationGroundScale) =>
      _set('line-elevation-ground-scale', lineElevationGroundScale);

  /// Controls how much the elevation of lines with `line-elevation-reference` set to `sea` scales with terrain exaggeration. Default value: 0.
  Future<double?> getLineElevationGroundScale() =>
      _get('line-elevation-ground-scale');

  /// Selects the base of line-elevation. Default value: "none".
  Future<void> setLineElevationReference(
          LineElevationReference lineElevationReference) =>
      _set('line-elevation-reference',
          BaseAnnotationManager._enumName(lineElevationReference));

  /// Selects the base of line-elevation. Default value: "none".
  Future<LineElevationReference?> getLineElevationReference() =>
      _getEnum('line-elevation-reference', LineElevationReference.values);

  /// The display of lines when joining. Default value: "miter".
  Future<void> setLineJoin(LineJoin lineJoin) =>
      _set('line-join', BaseAnnotationManager._enumName(lineJoin));

  /// The display of lines when joining. Default value: "miter".
  Future<LineJoin?> getLineJoin() => _getEnum('line-join', LineJoin.values);

  /// Used to automatically convert miter joins to bevel joins for sharp angles. Default value: 2.
  Future<void> setLineMiterLimit(double lineMiterLimit) =>
      _set('line-miter-limit', lineMiterLimit);

  /// Used to automatically convert miter joins to bevel joins for sharp angles. Default value: 2.
  Future<double?> getLineMiterLimit() => _get('line-miter-limit');

  /// Used to automatically convert round joins to miter joins for shallow angles. Default value: 1.05.
  Future<void> setLineRoundLimit(double lineRoundLimit) =>
      _set('line-round-limit', lineRoundLimit);

  /// Used to automatically convert round joins to miter joins for shallow angles. Default value: 1.05.
  Future<double?> getLineRoundLimit() => _get('line-round-limit');

  /// Sorts features in ascending order based on this value.
  Future<void> setLineSortKey(double lineSortKey) =>
      _set('line-sort-key', lineSortKey);

  /// Sorts features in ascending order based on this value.
  Future<double?> getLineSortKey() => _get('line-sort-key');

  /// Selects the unit of line-width. Default value: "pixels".
  @experimental
  Future<void> setLineWidthUnit(LineWidthUnit lineWidthUnit) =>
      _set('line-width-unit', BaseAnnotationManager._enumName(lineWidthUnit));

  /// Selects the unit of line-width. Default value: "pixels".
  @experimental
  Future<LineWidthUnit?> getLineWidthUnit() =>
      _getEnum('line-width-unit', LineWidthUnit.values);

  /// Vertical offset from ground, in meters. Default value: 0.
  Future<void> setLineZOffset(double lineZOffset) =>
      _set('line-z-offset', lineZOffset);

  /// Vertical offset from ground, in meters. Default value: 0.
  Future<double?> getLineZOffset() => _get('line-z-offset');

  /// Blur applied to the line, in pixels. Default value: 0.
  Future<void> setLineBlur(double lineBlur) => _set('line-blur', lineBlur);

  /// Blur applied to the line, in pixels. Default value: 0.
  Future<double?> getLineBlur() => _get('line-blur');

  /// The color of the line border. Default value: "rgba(0, 0, 0, 0)".
  Future<void> setLineBorderColor(int lineBorderColor) =>
      _set('line-border-color', lineBorderColor.toRGBA());

  /// The color of the line border. Default value: "rgba(0, 0, 0, 0)".
  Future<int?> getLineBorderColor() => _getColor('line-border-color');

  /// The width of the line border. A value of zero means no border. Default value: 0.
  Future<void> setLineBorderWidth(double lineBorderWidth) =>
      _set('line-border-width', lineBorderWidth);

  /// The width of the line border. A value of zero means no border. Default value: 0.
  Future<double?> getLineBorderWidth() => _get('line-border-width');

  /// The color with which the line will be drawn. Default value: "#000000".
  Future<void> setLineColor(int lineColor) =>
      _set('line-color', lineColor.toRGBA());

  /// The color with which the line will be drawn. Default value: "#000000".
  Future<int?> getLineColor() => _getColor('line-color');

  /// The width of the cutout fade effect as a proportion of the cutout width. Default value: 0.4.
  @experimental
  Future<void> setLineCutoutFadeWidth(double lineCutoutFadeWidth) =>
      _set('line-cutout-fade-width', lineCutoutFadeWidth);

  /// The width of the cutout fade effect as a proportion of the cutout width. Default value: 0.4.
  @experimental
  Future<double?> getLineCutoutFadeWidth() => _get('line-cutout-fade-width');

  /// The opacity of the aboveground objects affected by the line cutout. Default value: 1.
  @experimental
  Future<void> setLineCutoutOpacity(double lineCutoutOpacity) =>
      _set('line-cutout-opacity', lineCutoutOpacity);

  /// The opacity of the aboveground objects affected by the line cutout. Default value: 1.
  @experimental
  Future<double?> getLineCutoutOpacity() => _get('line-cutout-opacity');

  /// Specifies the lengths of the alternating dashes and gaps that form the dash pattern.
  Future<void> setLineDasharray(List<double?> lineDasharray) =>
      _set('line-dasharray', lineDasharray);

  /// Specifies the lengths of the alternating dashes and gaps that form the dash pattern.
  Future<List<double?>?> getLineDasharray() => _getDoubles('line-dasharray');

  /// This property is deprecated and replaced by line-occlusion-opacity. Default value: 1.
  Future<void> setLineDepthOcclusionFactor(double lineDepthOcclusionFactor) =>
      _set('line-depth-occlusion-factor', lineDepthOcclusionFactor);

  /// This property is deprecated and replaced by line-occlusion-opacity. Default value: 1.
  Future<double?> getLineDepthOcclusionFactor() =>
      _get('line-depth-occlusion-factor');

  /// Controls the intensity of light emitted on the source features. Default value: 0.
  Future<void> setLineEmissiveStrength(double lineEmissiveStrength) =>
      _set('line-emissive-strength', lineEmissiveStrength);

  /// Controls the intensity of light emitted on the source features. Default value: 0.
  Future<double?> getLineEmissiveStrength() => _get('line-emissive-strength');

  /// Draws a line casing outside of a line's actual path. Value indicates the width of the inner gap. Default value: 0.
  Future<void> setLineGapWidth(double lineGapWidth) =>
      _set('line-gap-width', lineGapWidth);

  /// Draws a line casing outside of a line's actual path. Value indicates the width of the inner gap. Default value: 0.
  Future<double?> getLineGapWidth() => _get('line-gap-width');

  /// Opacity multiplier (multiplies line-opacity value) of the line part that is occluded by 3D objects. Default value: 0.
  Future<void> setLineOcclusionOpacity(double lineOcclusionOpacity) =>
      _set('line-occlusion-opacity', lineOcclusionOpacity);

  /// Opacity multiplier (multiplies line-opacity value) of the line part that is occluded by 3D objects. Default value: 0.
  Future<double?> getLineOcclusionOpacity() => _get('line-occlusion-opacity');

  /// The line's offset. Default value: 0.
  Future<void> setLineOffset(double lineOffset) =>
      _set('line-offset', lineOffset);

  /// The line's offset. Default value: 0.
  Future<double?> getLineOffset() => _get('line-offset');

  /// The opacity at which the line will be drawn. Default value: 1.
  Future<void> setLineOpacity(double lineOpacity) =>
      _set('line-opacity', lineOpacity);

  /// The opacity at which the line will be drawn. Default value: 1.
  Future<double?> getLineOpacity() => _get('line-opacity');

  /// Name of image in sprite to use for drawing image lines.
  Future<void> setLinePattern(String linePattern) =>
      _set('line-pattern', linePattern);

  /// Name of image in sprite to use for drawing image lines.
  Future<String?> getLinePattern() => _get('line-pattern');

  /// The geometry's offset. Values are [x, y] where negatives indicate left and up, respectively. Default value: [0,0].
  Future<void> setLineTranslate(List<double?> lineTranslate) =>
      _set('line-translate', lineTranslate);

  /// The geometry's offset. Values are [x, y] where negatives indicate left and up, respectively. Default value: [0,0].
  Future<List<double?>?> getLineTranslate() => _getDoubles('line-translate');

  /// Controls the frame of reference for `line-translate`. Default value: "map".
  Future<void> setLineTranslateAnchor(LineTranslateAnchor lineTranslateAnchor) =>
      _set('line-translate-anchor',
          BaseAnnotationManager._enumName(lineTranslateAnchor));

  /// Controls the frame of reference for `line-translate`. Default value: "map".
  Future<LineTranslateAnchor?> getLineTranslateAnchor() =>
      _getEnum('line-translate-anchor', LineTranslateAnchor.values);

  /// The color to be used for rendering the trimmed line section that is defined by the `line-trim-offset` property. Default value: "transparent".
  @experimental
  Future<void> setLineTrimColor(int lineTrimColor) =>
      _set('line-trim-color', lineTrimColor.toRGBA());

  /// The color to be used for rendering the trimmed line section that is defined by the `line-trim-offset` property. Default value: "transparent".
  @experimental
  Future<int?> getLineTrimColor() => _getColor('line-trim-color');

  /// The fade range for the trim-start and trim-end points. Default value: [0,0].
  @experimental
  Future<void> setLineTrimFadeRange(List<double?> lineTrimFadeRange) =>
      _set('line-trim-fade-range', lineTrimFadeRange);

  /// The fade range for the trim-start and trim-end points. Default value: [0,0].
  @experimental
  Future<List<double?>?> getLineTrimFadeRange() =>
      _getDoubles('line-trim-fade-range');

  /// The line part between [trim-start, trim-end] will be painted using `line-trim-color`. Default value: [0,0].
  Future<void> setLineTrimOffset(List<double?> lineTrimOffset) =>
      _set('line-trim-offset', lineTrimOffset);

  /// The line part between [trim-start, trim-end] will be painted using `line-trim-color`. Default value: [0,0].
  Future<List<double?>?> getLineTrimOffset() => _getDoubles('line-trim-offset');

  /// Stroke thickness. Default value: 1.
  Future<void> setLineWidth(double lineWidth) => _set('line-width', lineWidth);

  /// Stroke thickness. Default value: 1.
  Future<double?> getLineWidth() => _get('line-width');
}
