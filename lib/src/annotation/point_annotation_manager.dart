part of '../../mapbox_kit.dart';

/// The PointAnnotationManager to add/update/delete PointAnnotations on the map.
class PointAnnotationManager extends BaseAnnotationManager {
  PointAnnotationManager._({required super.id, required super.channel})
      : super._();

  static const _prefix = 'pointAnnotation';

  PointAnnotation _annotation(Map<String, dynamic> event) =>
      PointAnnotation.fromJson(_requireMap(event['annotation']));

  /// Registers tap event callbacks for the annotations managed by this manager.
  ///
  /// Note: Tap events will now not propagate to annotations below the topmost one. If you tap on overlapping annotations, only the top annotation's tap event will be triggered.
  Cancelable tapEvents({required Function(PointAnnotation) onTap}) {
    return _interactions('tap')
        .listen((data) => onTap(_annotation(data)))
        .asCancelable();
  }

  /// Registers long press event callbacks for the annotations managed by this manager.
  ///
  /// Note: This event will be triggered simultaneously with the [dragEvents] `onBegin` if the annotation is draggable.
  Cancelable longPressEvents({required Function(PointAnnotation) onLongPress}) {
    return _interactions('longPress')
        .listen((data) => onLongPress(_annotation(data)))
        .asCancelable();
  }

  /// Registers drag event callbacks for the annotations managed by this manager.
  ///
  /// - [onBegin]: Triggered when a drag gesture begins on an annotation.
  /// - [onChanged]: Triggered continuously as the annotation is being dragged.
  /// - [onEnd]: Triggered when the drag gesture ends.
  Cancelable dragEvents({
    Function(PointAnnotation)? onBegin,
    Function(PointAnnotation)? onChanged,
    Function(PointAnnotation)? onEnd,
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
  Future<List<PointAnnotation>> getAnnotations() async =>
      ((await _invoke(_prefix, 'getAnnotations')) as List)
          .map((e) => PointAnnotation.fromJson(_requireMap(e)))
          .toList();

  // The image bytes the native side holds for each annotation, by id: an
  // update sends them again only when the annotation carries other bytes.
  final Map<String, Uint8List> _sentImages = {};

  PointAnnotation _created(dynamic reply) {
    final annotation = PointAnnotation.fromJson(_requireMap(reply));
    final image = annotation.image;
    if (image != null) _sentImages[annotation.id] = image;
    return annotation;
  }

  /// Create a new annotation with the option.
  Future<PointAnnotation> create(PointAnnotationOptions annotation) async =>
      _created(await _invoke(
          _prefix, 'create', {'annotationOption': annotation.toJson()}));

  /// Create multi annotations with the options.
  Future<List<PointAnnotation?>> createMulti(
          List<PointAnnotationOptions> annotations) async =>
      ((await _invoke(_prefix, 'createMulti', {
        'annotationOptions': annotations.map((e) => e.toJson()).toList()
      })) as List)
          .map((e) => e == null ? null : _created(e))
          .toList();

  /// Update an added annotation with new properties.
  ///
  /// Its image is sent only when it is not the bytes the map already has
  /// for it, so moving an annotation (a puck, every frame) sends its
  /// position and nothing more.
  Future<void> update(PointAnnotation annotation) {
    final image = annotation.image;
    final unchanged =
        image != null && identical(image, _sentImages[annotation.id]);
    if (image != null) _sentImages[annotation.id] = image;
    return _invoke(_prefix, 'update',
        {'annotation': annotation._toJson(image: !unchanged)});
  }

  /// Delete an added annotation.
  Future<void> delete(PointAnnotation annotation) {
    _sentImages.remove(annotation.id);
    return _invoke(
        _prefix, 'delete', {'annotation': annotation._toJson(image: false)});
  }

  /// Delete all the annotation added by this manager.
  Future<void> deleteAll() {
    _sentImages.clear();
    return _invoke(_prefix, 'deleteAll');
  }

  /// Delete multiple annotations added by this manager.
  Future<void> deleteMulti(List<PointAnnotation> annotations) {
    for (final a in annotations) {
      _sentImages.remove(a.id);
    }
    return _invoke(_prefix, 'deleteMulti', {
      'annotations': [for (final a in annotations) a._toJson(image: false)]
    });
  }

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

  /// If true, the icon will be visible even if it collides with other previously drawn symbols. Default value: false.
  Future<void> setIconAllowOverlap(bool iconAllowOverlap) =>
      _set('icon-allow-overlap', iconAllowOverlap);

  /// If true, the icon will be visible even if it collides with other previously drawn symbols. Default value: false.
  Future<bool?> getIconAllowOverlap() => _get('icon-allow-overlap');

  /// Part of the icon placed closest to the anchor. Default value: "center".
  Future<void> setIconAnchor(IconAnchor iconAnchor) =>
      _set('icon-anchor', BaseAnnotationManager._enumName(iconAnchor));

  /// Part of the icon placed closest to the anchor. Default value: "center".
  Future<IconAnchor?> getIconAnchor() =>
      _getEnum('icon-anchor', IconAnchor.values);

  /// If true, other symbols can be visible even if they collide with the icon. Default value: false.
  Future<void> setIconIgnorePlacement(bool iconIgnorePlacement) =>
      _set('icon-ignore-placement', iconIgnorePlacement);

  /// If true, other symbols can be visible even if they collide with the icon. Default value: false.
  Future<bool?> getIconIgnorePlacement() => _get('icon-ignore-placement');

  /// Name of image in sprite to use for drawing an image background.
  Future<void> setIconImage(String iconImage) => _set('icon-image', iconImage);

  /// Name of image in sprite to use for drawing an image background.
  Future<String?> getIconImage() => _get('icon-image');

  /// If true, the icon may be flipped to prevent it from being rendered upside-down. Default value: false.
  Future<void> setIconKeepUpright(bool iconKeepUpright) =>
      _set('icon-keep-upright', iconKeepUpright);

  /// If true, the icon may be flipped to prevent it from being rendered upside-down. Default value: false.
  Future<bool?> getIconKeepUpright() => _get('icon-keep-upright');

  /// Offset distance of icon from its anchor. Default value: [0,0].
  Future<void> setIconOffset(List<double?> iconOffset) =>
      _set('icon-offset', iconOffset);

  /// Offset distance of icon from its anchor. Default value: [0,0].
  Future<List<double?>?> getIconOffset() => _getDoubles('icon-offset');

  /// If true, text will display without their corresponding icons when the icon collides with other symbols and the text does not. Default value: false.
  Future<void> setIconOptional(bool iconOptional) =>
      _set('icon-optional', iconOptional);

  /// If true, text will display without their corresponding icons when the icon collides with other symbols and the text does not. Default value: false.
  Future<bool?> getIconOptional() => _get('icon-optional');

  /// Size of the additional area around the icon bounding box used for detecting symbol collisions. Default value: 2.
  Future<void> setIconPadding(double iconPadding) =>
      _set('icon-padding', iconPadding);

  /// Size of the additional area around the icon bounding box used for detecting symbol collisions. Default value: 2.
  Future<double?> getIconPadding() => _get('icon-padding');

  /// Orientation of icon when map is pitched. Default value: "auto".
  Future<void> setIconPitchAlignment(IconPitchAlignment iconPitchAlignment) =>
      _set('icon-pitch-alignment',
          BaseAnnotationManager._enumName(iconPitchAlignment));

  /// Orientation of icon when map is pitched. Default value: "auto".
  Future<IconPitchAlignment?> getIconPitchAlignment() =>
      _getEnum('icon-pitch-alignment', IconPitchAlignment.values);

  /// Rotates the icon clockwise. Default value: 0.
  Future<void> setIconRotate(double iconRotate) =>
      _set('icon-rotate', iconRotate);

  /// Rotates the icon clockwise. Default value: 0.
  Future<double?> getIconRotate() => _get('icon-rotate');

  /// In combination with `symbol-placement`, determines the rotation behavior of icons. Default value: "auto".
  Future<void> setIconRotationAlignment(
          IconRotationAlignment iconRotationAlignment) =>
      _set('icon-rotation-alignment',
          BaseAnnotationManager._enumName(iconRotationAlignment));

  /// In combination with `symbol-placement`, determines the rotation behavior of icons. Default value: "auto".
  Future<IconRotationAlignment?> getIconRotationAlignment() =>
      _getEnum('icon-rotation-alignment', IconRotationAlignment.values);

  /// Scales the original size of the icon by the provided factor. Default value: 1.
  Future<void> setIconSize(double iconSize) => _set('icon-size', iconSize);

  /// Scales the original size of the icon by the provided factor. Default value: 1.
  Future<double?> getIconSize() => _get('icon-size');

  /// Limits the possible scaling range for `icon-size`, `icon-halo-width`, `icon-halo-blur` properties. Default value: [0.8,2].
  @experimental
  Future<void> setIconSizeScaleRange(List<double?> iconSizeScaleRange) =>
      _set('icon-size-scale-range', iconSizeScaleRange);

  /// Limits the possible scaling range for `icon-size`, `icon-halo-width`, `icon-halo-blur` properties. Default value: [0.8,2].
  @experimental
  Future<List<double?>?> getIconSizeScaleRange() =>
      _getDoubles('icon-size-scale-range');

  /// Scales the icon to fit around the associated text. Default value: "none".
  Future<void> setIconTextFit(IconTextFit iconTextFit) =>
      _set('icon-text-fit', BaseAnnotationManager._enumName(iconTextFit));

  /// Scales the icon to fit around the associated text. Default value: "none".
  Future<IconTextFit?> getIconTextFit() =>
      _getEnum('icon-text-fit', IconTextFit.values);

  /// Size of the additional area added to dimensions determined by `icon-text-fit`. Default value: [0,0,0,0].
  Future<void> setIconTextFitPadding(List<double?> iconTextFitPadding) =>
      _set('icon-text-fit-padding', iconTextFitPadding);

  /// Size of the additional area added to dimensions determined by `icon-text-fit`. Default value: [0,0,0,0].
  Future<List<double?>?> getIconTextFitPadding() =>
      _getDoubles('icon-text-fit-padding');

  /// If true, the symbols will not cross tile edges to avoid mutual collisions. Default value: false.
  Future<void> setSymbolAvoidEdges(bool symbolAvoidEdges) =>
      _set('symbol-avoid-edges', symbolAvoidEdges);

  /// If true, the symbols will not cross tile edges to avoid mutual collisions. Default value: false.
  Future<bool?> getSymbolAvoidEdges() => _get('symbol-avoid-edges');

  /// Selects the base of symbol-elevation. Default value: "ground".
  @experimental
  Future<void> setSymbolElevationReference(
          SymbolElevationReference symbolElevationReference) =>
      _set('symbol-elevation-reference',
          BaseAnnotationManager._enumName(symbolElevationReference));

  /// Selects the base of symbol-elevation. Default value: "ground".
  @experimental
  Future<SymbolElevationReference?> getSymbolElevationReference() =>
      _getEnum('symbol-elevation-reference', SymbolElevationReference.values);

  /// Label placement relative to its geometry. Default value: "point".
  Future<void> setSymbolPlacement(SymbolPlacement symbolPlacement) =>
      _set('symbol-placement', BaseAnnotationManager._enumName(symbolPlacement));

  /// Label placement relative to its geometry. Default value: "point".
  Future<SymbolPlacement?> getSymbolPlacement() =>
      _getEnum('symbol-placement', SymbolPlacement.values);

  /// Sorts features in ascending order based on this value.
  Future<void> setSymbolSortKey(double symbolSortKey) =>
      _set('symbol-sort-key', symbolSortKey);

  /// Sorts features in ascending order based on this value.
  Future<double?> getSymbolSortKey() => _get('symbol-sort-key');

  /// Distance between two symbol anchors. Default value: 250.
  Future<void> setSymbolSpacing(double symbolSpacing) =>
      _set('symbol-spacing', symbolSpacing);

  /// Distance between two symbol anchors. Default value: 250.
  Future<double?> getSymbolSpacing() => _get('symbol-spacing');

  /// Position symbol on buildings (both fill extrusions and models) rooftops. Default value: false.
  Future<void> setSymbolZElevate(bool symbolZElevate) =>
      _set('symbol-z-elevate', symbolZElevate);

  /// Position symbol on buildings (both fill extrusions and models) rooftops. Default value: false.
  Future<bool?> getSymbolZElevate() => _get('symbol-z-elevate');

  /// Determines whether overlapping symbols in the same layer are rendered in the order that they appear in the data source or by their y-position relative to the viewport. Default value: "auto".
  Future<void> setSymbolZOrder(SymbolZOrder symbolZOrder) =>
      _set('symbol-z-order', BaseAnnotationManager._enumName(symbolZOrder));

  /// Determines whether overlapping symbols in the same layer are rendered in the order that they appear in the data source or by their y-position relative to the viewport. Default value: "auto".
  Future<SymbolZOrder?> getSymbolZOrder() =>
      _getEnum('symbol-z-order', SymbolZOrder.values);

  /// If true, the text will be visible even if it collides with other previously drawn symbols. Default value: false.
  Future<void> setTextAllowOverlap(bool textAllowOverlap) =>
      _set('text-allow-overlap', textAllowOverlap);

  /// If true, the text will be visible even if it collides with other previously drawn symbols. Default value: false.
  Future<bool?> getTextAllowOverlap() => _get('text-allow-overlap');

  /// Part of the text placed closest to the anchor. Default value: "center".
  Future<void> setTextAnchor(TextAnchor textAnchor) =>
      _set('text-anchor', BaseAnnotationManager._enumName(textAnchor));

  /// Part of the text placed closest to the anchor. Default value: "center".
  Future<TextAnchor?> getTextAnchor() =>
      _getEnum('text-anchor', TextAnchor.values);

  /// Value to use for a text label. Default value: "".
  Future<void> setTextField(String textField) => _set('text-field', textField);

  /// Value to use for a text label. Default value: "".
  Future<String?> getTextField() => _get('text-field');

  /// Font stack to use for displaying text.
  Future<void> setTextFont(List<String?> textFont) => _set('text-font', textFont);

  /// Font stack to use for displaying text.
  Future<List<String?>?> getTextFont() async =>
      _asStringList(await _getProperty(_prefix, 'text-font'));

  /// If true, other symbols can be visible even if they collide with the text. Default value: false.
  Future<void> setTextIgnorePlacement(bool textIgnorePlacement) =>
      _set('text-ignore-placement', textIgnorePlacement);

  /// If true, other symbols can be visible even if they collide with the text. Default value: false.
  Future<bool?> getTextIgnorePlacement() => _get('text-ignore-placement');

  /// Text justification options. Default value: "center".
  Future<void> setTextJustify(TextJustify textJustify) =>
      _set('text-justify', BaseAnnotationManager._enumName(textJustify));

  /// Text justification options. Default value: "center".
  Future<TextJustify?> getTextJustify() =>
      _getEnum('text-justify', TextJustify.values);

  /// If true, the text may be flipped vertically to prevent it from being rendered upside-down. Default value: true.
  Future<void> setTextKeepUpright(bool textKeepUpright) =>
      _set('text-keep-upright', textKeepUpright);

  /// If true, the text may be flipped vertically to prevent it from being rendered upside-down. Default value: true.
  Future<bool?> getTextKeepUpright() => _get('text-keep-upright');

  /// Text tracking amount. Default value: 0.
  Future<void> setTextLetterSpacing(double textLetterSpacing) =>
      _set('text-letter-spacing', textLetterSpacing);

  /// Text tracking amount. Default value: 0.
  Future<double?> getTextLetterSpacing() => _get('text-letter-spacing');

  /// Text leading value for multi-line text. Default value: 1.2.
  Future<void> setTextLineHeight(double textLineHeight) =>
      _set('text-line-height', textLineHeight);

  /// Text leading value for multi-line text. Default value: 1.2.
  Future<double?> getTextLineHeight() => _get('text-line-height');

  /// Maximum angle change between adjacent characters. Default value: 45.
  Future<void> setTextMaxAngle(double textMaxAngle) =>
      _set('text-max-angle', textMaxAngle);

  /// Maximum angle change between adjacent characters. Default value: 45.
  Future<double?> getTextMaxAngle() => _get('text-max-angle');

  /// The maximum line width for text wrapping. Default value: 10.
  Future<void> setTextMaxWidth(double textMaxWidth) =>
      _set('text-max-width', textMaxWidth);

  /// The maximum line width for text wrapping. Default value: 10.
  Future<double?> getTextMaxWidth() => _get('text-max-width');

  /// Offset distance of text from its anchor. Default value: [0,0].
  Future<void> setTextOffset(List<double?> textOffset) =>
      _set('text-offset', textOffset);

  /// Offset distance of text from its anchor. Default value: [0,0].
  Future<List<double?>?> getTextOffset() => _getDoubles('text-offset');

  /// If true, icons will display without their corresponding text when the text collides with other symbols and the icon does not. Default value: false.
  Future<void> setTextOptional(bool textOptional) =>
      _set('text-optional', textOptional);

  /// If true, icons will display without their corresponding text when the text collides with other symbols and the icon does not. Default value: false.
  Future<bool?> getTextOptional() => _get('text-optional');

  /// Size of the additional area around the text bounding box used for detecting symbol collisions. Default value: 2.
  Future<void> setTextPadding(double textPadding) =>
      _set('text-padding', textPadding);

  /// Size of the additional area around the text bounding box used for detecting symbol collisions. Default value: 2.
  Future<double?> getTextPadding() => _get('text-padding');

  /// Orientation of text when map is pitched. Default value: "auto".
  Future<void> setTextPitchAlignment(TextPitchAlignment textPitchAlignment) =>
      _set('text-pitch-alignment',
          BaseAnnotationManager._enumName(textPitchAlignment));

  /// Orientation of text when map is pitched. Default value: "auto".
  Future<TextPitchAlignment?> getTextPitchAlignment() =>
      _getEnum('text-pitch-alignment', TextPitchAlignment.values);

  /// Radial offset of text, in the direction of the symbol's anchor. Default value: 0.
  Future<void> setTextRadialOffset(double textRadialOffset) =>
      _set('text-radial-offset', textRadialOffset);

  /// Radial offset of text, in the direction of the symbol's anchor. Default value: 0.
  Future<double?> getTextRadialOffset() => _get('text-radial-offset');

  /// Rotates the text clockwise. Default value: 0.
  Future<void> setTextRotate(double textRotate) =>
      _set('text-rotate', textRotate);

  /// Rotates the text clockwise. Default value: 0.
  Future<double?> getTextRotate() => _get('text-rotate');

  /// In combination with `symbol-placement`, determines the rotation behavior of the individual glyphs forming the text. Default value: "auto".
  Future<void> setTextRotationAlignment(
          TextRotationAlignment textRotationAlignment) =>
      _set('text-rotation-alignment',
          BaseAnnotationManager._enumName(textRotationAlignment));

  /// In combination with `symbol-placement`, determines the rotation behavior of the individual glyphs forming the text. Default value: "auto".
  Future<TextRotationAlignment?> getTextRotationAlignment() =>
      _getEnum('text-rotation-alignment', TextRotationAlignment.values);

  /// Font size. Default value: 16.
  Future<void> setTextSize(double textSize) => _set('text-size', textSize);

  /// Font size. Default value: 16.
  Future<double?> getTextSize() => _get('text-size');

  /// Limits the possible scaling range for `text-size`, `text-halo-width`, `text-halo-blur` properties. Default value: [0.8,2].
  @experimental
  Future<void> setTextSizeScaleRange(List<double?> textSizeScaleRange) =>
      _set('text-size-scale-range', textSizeScaleRange);

  /// Limits the possible scaling range for `text-size`, `text-halo-width`, `text-halo-blur` properties. Default value: [0.8,2].
  @experimental
  Future<List<double?>?> getTextSizeScaleRange() =>
      _getDoubles('text-size-scale-range');

  /// Specifies how to capitalize text, similar to the CSS `text-transform` property. Default value: "none".
  Future<void> setTextTransform(TextTransform textTransform) =>
      _set('text-transform', BaseAnnotationManager._enumName(textTransform));

  /// Specifies how to capitalize text, similar to the CSS `text-transform` property. Default value: "none".
  Future<TextTransform?> getTextTransform() =>
      _getEnum('text-transform', TextTransform.values);

  /// The color of the icon. This can only be used with SDF icons. Default value: "#000000".
  Future<void> setIconColor(int iconColor) =>
      _set('icon-color', iconColor.toRGBA());

  /// The color of the icon. This can only be used with SDF icons. Default value: "#000000".
  Future<int?> getIconColor() => _getColor('icon-color');

  /// Increase or reduce the brightness of the symbols. The value is the maximum brightness. Default value: 1.
  Future<void> setIconColorBrightnessMax(double iconColorBrightnessMax) =>
      _set('icon-color-brightness-max', iconColorBrightnessMax);

  /// Increase or reduce the brightness of the symbols. The value is the maximum brightness. Default value: 1.
  Future<double?> getIconColorBrightnessMax() =>
      _get('icon-color-brightness-max');

  /// Increase or reduce the brightness of the symbols. The value is the minimum brightness. Default value: 0.
  Future<void> setIconColorBrightnessMin(double iconColorBrightnessMin) =>
      _set('icon-color-brightness-min', iconColorBrightnessMin);

  /// Increase or reduce the brightness of the symbols. The value is the minimum brightness. Default value: 0.
  Future<double?> getIconColorBrightnessMin() =>
      _get('icon-color-brightness-min');

  /// Increase or reduce the contrast of the symbol icon. Default value: 0.
  Future<void> setIconColorContrast(double iconColorContrast) =>
      _set('icon-color-contrast', iconColorContrast);

  /// Increase or reduce the contrast of the symbol icon. Default value: 0.
  Future<double?> getIconColorContrast() => _get('icon-color-contrast');

  /// Increase or reduce the saturation of the symbol icon. Default value: 0.
  Future<void> setIconColorSaturation(double iconColorSaturation) =>
      _set('icon-color-saturation', iconColorSaturation);

  /// Increase or reduce the saturation of the symbol icon. Default value: 0.
  Future<double?> getIconColorSaturation() => _get('icon-color-saturation');

  /// Controls the intensity of light emitted on the source features. Default value: 1.
  Future<void> setIconEmissiveStrength(double iconEmissiveStrength) =>
      _set('icon-emissive-strength', iconEmissiveStrength);

  /// Controls the intensity of light emitted on the source features. Default value: 1.
  Future<double?> getIconEmissiveStrength() => _get('icon-emissive-strength');

  /// Fade out the halo towards the outside. Default value: 0.
  Future<void> setIconHaloBlur(double iconHaloBlur) =>
      _set('icon-halo-blur', iconHaloBlur);

  /// Fade out the halo towards the outside. Default value: 0.
  Future<double?> getIconHaloBlur() => _get('icon-halo-blur');

  /// The color of the icon's halo. Icon halos can only be used with SDF icons. Default value: "rgba(0, 0, 0, 0)".
  Future<void> setIconHaloColor(int iconHaloColor) =>
      _set('icon-halo-color', iconHaloColor.toRGBA());

  /// The color of the icon's halo. Icon halos can only be used with SDF icons. Default value: "rgba(0, 0, 0, 0)".
  Future<int?> getIconHaloColor() => _getColor('icon-halo-color');

  /// Distance of halo to the icon outline. Default value: 0.
  Future<void> setIconHaloWidth(double iconHaloWidth) =>
      _set('icon-halo-width', iconHaloWidth);

  /// Distance of halo to the icon outline. Default value: 0.
  Future<double?> getIconHaloWidth() => _get('icon-halo-width');

  /// Controls the transition progress between the image variants of icon-image. Default value: 0.
  Future<void> setIconImageCrossFade(double iconImageCrossFade) =>
      _set('icon-image-cross-fade', iconImageCrossFade);

  /// Controls the transition progress between the image variants of icon-image. Default value: 0.
  Future<double?> getIconImageCrossFade() => _get('icon-image-cross-fade');

  /// The opacity at which the icon will be drawn in case of being depth occluded. Default value: 0.
  Future<void> setIconOcclusionOpacity(double iconOcclusionOpacity) =>
      _set('icon-occlusion-opacity', iconOcclusionOpacity);

  /// The opacity at which the icon will be drawn in case of being depth occluded. Default value: 0.
  Future<double?> getIconOcclusionOpacity() => _get('icon-occlusion-opacity');

  /// The opacity at which the icon will be drawn. Default value: 1.
  Future<void> setIconOpacity(double iconOpacity) =>
      _set('icon-opacity', iconOpacity);

  /// The opacity at which the icon will be drawn. Default value: 1.
  Future<double?> getIconOpacity() => _get('icon-opacity');

  /// Distance that the icon's anchor is moved from its original placement. Default value: [0,0].
  Future<void> setIconTranslate(List<double?> iconTranslate) =>
      _set('icon-translate', iconTranslate);

  /// Distance that the icon's anchor is moved from its original placement. Default value: [0,0].
  Future<List<double?>?> getIconTranslate() => _getDoubles('icon-translate');

  /// Controls the frame of reference for `icon-translate`. Default value: "map".
  Future<void> setIconTranslateAnchor(IconTranslateAnchor iconTranslateAnchor) =>
      _set('icon-translate-anchor',
          BaseAnnotationManager._enumName(iconTranslateAnchor));

  /// Controls the frame of reference for `icon-translate`. Default value: "map".
  Future<IconTranslateAnchor?> getIconTranslateAnchor() =>
      _getEnum('icon-translate-anchor', IconTranslateAnchor.values);

  /// Specify how opacity in case of being occluded should be applied. Default value: "anchor".
  Future<void> setOcclusionOpacityMode(
          OcclusionOpacityMode occlusionOpacityMode) =>
      _set('occlusion-opacity-mode',
          BaseAnnotationManager._enumName(occlusionOpacityMode));

  /// Specify how opacity in case of being occluded should be applied. Default value: "anchor".
  Future<OcclusionOpacityMode?> getOcclusionOpacityMode() =>
      _getEnum('occlusion-opacity-mode', OcclusionOpacityMode.values);

  /// Specifies an uniform elevation from the ground, in meters. Default value: 0.
  Future<void> setSymbolZOffset(double symbolZOffset) =>
      _set('symbol-z-offset', symbolZOffset);

  /// Specifies an uniform elevation from the ground, in meters. Default value: 0.
  Future<double?> getSymbolZOffset() => _get('symbol-z-offset');

  /// The color with which the text will be drawn. Default value: "#000000".
  Future<void> setTextColor(int textColor) =>
      _set('text-color', textColor.toRGBA());

  /// The color with which the text will be drawn. Default value: "#000000".
  Future<int?> getTextColor() => _getColor('text-color');

  /// Controls the intensity of light emitted on the source features. Default value: 1.
  Future<void> setTextEmissiveStrength(double textEmissiveStrength) =>
      _set('text-emissive-strength', textEmissiveStrength);

  /// Controls the intensity of light emitted on the source features. Default value: 1.
  Future<double?> getTextEmissiveStrength() => _get('text-emissive-strength');

  /// The halo's fadeout distance towards the outside. Default value: 0.
  Future<void> setTextHaloBlur(double textHaloBlur) =>
      _set('text-halo-blur', textHaloBlur);

  /// The halo's fadeout distance towards the outside. Default value: 0.
  Future<double?> getTextHaloBlur() => _get('text-halo-blur');

  /// The color of the text's halo, which helps it stand out from backgrounds. Default value: "rgba(0, 0, 0, 0)".
  Future<void> setTextHaloColor(int textHaloColor) =>
      _set('text-halo-color', textHaloColor.toRGBA());

  /// The color of the text's halo, which helps it stand out from backgrounds. Default value: "rgba(0, 0, 0, 0)".
  Future<int?> getTextHaloColor() => _getColor('text-halo-color');

  /// Distance of halo to the font outline. Max text halo width is 1/4 of the font-size. Default value: 0.
  Future<void> setTextHaloWidth(double textHaloWidth) =>
      _set('text-halo-width', textHaloWidth);

  /// Distance of halo to the font outline. Max text halo width is 1/4 of the font-size. Default value: 0.
  Future<double?> getTextHaloWidth() => _get('text-halo-width');

  /// The opacity at which the text will be drawn in case of being depth occluded. Default value: 0.
  Future<void> setTextOcclusionOpacity(double textOcclusionOpacity) =>
      _set('text-occlusion-opacity', textOcclusionOpacity);

  /// The opacity at which the text will be drawn in case of being depth occluded. Default value: 0.
  Future<double?> getTextOcclusionOpacity() => _get('text-occlusion-opacity');

  /// The opacity at which the text will be drawn. Default value: 1.
  Future<void> setTextOpacity(double textOpacity) =>
      _set('text-opacity', textOpacity);

  /// The opacity at which the text will be drawn. Default value: 1.
  Future<double?> getTextOpacity() => _get('text-opacity');

  /// Distance that the text's anchor is moved from its original placement. Default value: [0,0].
  Future<void> setTextTranslate(List<double?> textTranslate) =>
      _set('text-translate', textTranslate);

  /// Distance that the text's anchor is moved from its original placement. Default value: [0,0].
  Future<List<double?>?> getTextTranslate() => _getDoubles('text-translate');

  /// Controls the frame of reference for `text-translate`. Default value: "map".
  Future<void> setTextTranslateAnchor(TextTranslateAnchor textTranslateAnchor) =>
      _set('text-translate-anchor',
          BaseAnnotationManager._enumName(textTranslateAnchor));

  /// Controls the frame of reference for `text-translate`. Default value: "map".
  Future<TextTranslateAnchor?> getTextTranslateAnchor() =>
      _getEnum('text-translate-anchor', TextTranslateAnchor.values);
}
