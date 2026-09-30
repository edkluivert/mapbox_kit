// Manager-level annotation properties (experimental @_spi ones such as
// line-trim-color fall through to the layer-property path)
// (`pointAnnotation#setProperty` /
// `polylineAnnotation#setProperty`) applied to the Mapbox manager object
// itself, as upstream does. Setting them on the manager's layer directly is
// silently overridden when the manager syncs its layer, so `icon-allow-overlap`
// & co. would read back nil and markers stayed hidden by collision.

import Foundation
@_spi(Experimental) import MapboxMaps

enum ManagerProperties {
    private static func strs(_ v: Any?) -> [String]? { (v as? [Any])?.compactMap(str) }
    private static func nn(_ v: Any?) -> Any? { v is NSNull ? nil : v }

    // MARK: Point

    /// Returns true when [property] is a manager-level property (and was applied).
    static func set(_ m: PointAnnotationManager, _ property: String, _ raw: Any?) -> Bool {
        let v = nn(raw)
        switch property {
        case "icon-allow-overlap": m.iconAllowOverlap = bool(v)
        case "icon-anchor": m.iconAnchor = str(v).map(IconAnchor.init(rawValue:))
        case "icon-ignore-placement": m.iconIgnorePlacement = bool(v)
        case "icon-image": m.iconImage = str(v)
        case "icon-keep-upright": m.iconKeepUpright = bool(v)
        case "icon-offset": m.iconOffset = doubles(v)
        case "icon-optional": m.iconOptional = bool(v)
        case "icon-padding": m.iconPadding = dbl(v)
        case "icon-pitch-alignment": m.iconPitchAlignment = str(v).map(IconPitchAlignment.init(rawValue:))
        case "icon-rotate": m.iconRotate = dbl(v)
        case "icon-rotation-alignment": m.iconRotationAlignment = str(v).map(IconRotationAlignment.init(rawValue:))
        case "icon-size": m.iconSize = dbl(v)
        case "icon-text-fit": m.iconTextFit = str(v).map(IconTextFit.init(rawValue:))
        case "icon-text-fit-padding": m.iconTextFitPadding = doubles(v)
        case "symbol-avoid-edges": m.symbolAvoidEdges = bool(v)
        case "symbol-placement": m.symbolPlacement = str(v).map(SymbolPlacement.init(rawValue:))
        case "symbol-sort-key": m.symbolSortKey = dbl(v)
        case "symbol-spacing": m.symbolSpacing = dbl(v)
        case "symbol-z-elevate": m.symbolZElevate = bool(v)
        case "symbol-elevation-reference": m.symbolElevationReference = str(v).map(SymbolElevationReference.init(rawValue:))
        case "symbol-z-order": m.symbolZOrder = str(v).map(SymbolZOrder.init(rawValue:))
        case "text-allow-overlap": m.textAllowOverlap = bool(v)
        case "text-anchor": m.textAnchor = str(v).map(TextAnchor.init(rawValue:))
        case "text-field": m.textField = str(v)
        case "text-font": m.textFont = strs(v)
        case "text-ignore-placement": m.textIgnorePlacement = bool(v)
        case "text-justify": m.textJustify = str(v).map(TextJustify.init(rawValue:))
        case "text-keep-upright": m.textKeepUpright = bool(v)
        case "text-letter-spacing": m.textLetterSpacing = dbl(v)
        case "text-line-height": m.textLineHeight = dbl(v)
        case "text-max-angle": m.textMaxAngle = dbl(v)
        case "text-max-width": m.textMaxWidth = dbl(v)
        case "text-offset": m.textOffset = doubles(v)
        case "text-optional": m.textOptional = bool(v)
        case "text-padding": m.textPadding = dbl(v)
        case "text-pitch-alignment": m.textPitchAlignment = str(v).map(TextPitchAlignment.init(rawValue:))
        case "text-radial-offset": m.textRadialOffset = dbl(v)
        case "text-rotate": m.textRotate = dbl(v)
        case "text-rotation-alignment": m.textRotationAlignment = str(v).map(TextRotationAlignment.init(rawValue:))
        case "text-size": m.textSize = dbl(v)
        case "text-transform": m.textTransform = str(v).map(TextTransform.init(rawValue:))
        case "text-variable-anchor": m.textVariableAnchor = strs(v)?.map(TextAnchor.init(rawValue:))
        case "text-writing-mode": m.textWritingMode = strs(v)?.map(TextWritingMode.init(rawValue:))
        case "icon-color": m.iconColor = styleColor(v)
        case "icon-color-brightness-max": m.iconColorBrightnessMax = dbl(v)
        case "icon-color-brightness-min": m.iconColorBrightnessMin = dbl(v)
        case "icon-color-contrast": m.iconColorContrast = dbl(v)
        case "icon-color-saturation": m.iconColorSaturation = dbl(v)
        case "icon-emissive-strength": m.iconEmissiveStrength = dbl(v)
        case "icon-halo-blur": m.iconHaloBlur = dbl(v)
        case "icon-halo-color": m.iconHaloColor = styleColor(v)
        case "icon-halo-width": m.iconHaloWidth = dbl(v)
        case "icon-image-cross-fade": m.iconImageCrossFade = dbl(v)
        case "icon-occlusion-opacity": m.iconOcclusionOpacity = dbl(v)
        case "icon-opacity": m.iconOpacity = dbl(v)
        case "icon-translate": m.iconTranslate = doubles(v)
        case "icon-translate-anchor": m.iconTranslateAnchor = str(v).map(IconTranslateAnchor.init(rawValue:))
        case "occlusion-opacity-mode": m.occlusionOpacityMode = str(v).map(OcclusionOpacityMode.init(rawValue:))
        case "symbol-z-offset": m.symbolZOffset = dbl(v)
        case "text-color": m.textColor = styleColor(v)
        case "text-emissive-strength": m.textEmissiveStrength = dbl(v)
        case "text-halo-blur": m.textHaloBlur = dbl(v)
        case "text-halo-color": m.textHaloColor = styleColor(v)
        case "text-halo-width": m.textHaloWidth = dbl(v)
        case "text-occlusion-opacity": m.textOcclusionOpacity = dbl(v)
        case "text-opacity": m.textOpacity = dbl(v)
        case "text-translate": m.textTranslate = doubles(v)
        case "text-translate-anchor": m.textTranslateAnchor = str(v).map(TextTranslateAnchor.init(rawValue:))
        case "slot": m.slot = str(v)
        default: return false
        }
        return true
    }

    /// `handled` is false for properties that are not manager-level.
    static func get(_ m: PointAnnotationManager, _ property: String) -> (handled: Bool, value: Any?) {
        let value: Any?
        switch property {
        case "icon-allow-overlap": value = m.iconAllowOverlap
        case "icon-anchor": value = m.iconAnchor?.rawValue
        case "icon-ignore-placement": value = m.iconIgnorePlacement
        case "icon-image": value = m.iconImage
        case "icon-keep-upright": value = m.iconKeepUpright
        case "icon-offset": value = m.iconOffset
        case "icon-optional": value = m.iconOptional
        case "icon-padding": value = m.iconPadding
        case "icon-pitch-alignment": value = m.iconPitchAlignment?.rawValue
        case "icon-rotate": value = m.iconRotate
        case "icon-rotation-alignment": value = m.iconRotationAlignment?.rawValue
        case "icon-size": value = m.iconSize
        case "icon-text-fit": value = m.iconTextFit?.rawValue
        case "icon-text-fit-padding": value = m.iconTextFitPadding
        case "symbol-avoid-edges": value = m.symbolAvoidEdges
        case "symbol-placement": value = m.symbolPlacement?.rawValue
        case "symbol-sort-key": value = m.symbolSortKey
        case "symbol-spacing": value = m.symbolSpacing
        case "symbol-z-elevate": value = m.symbolZElevate
        case "symbol-elevation-reference": value = m.symbolElevationReference?.rawValue
        case "symbol-z-order": value = m.symbolZOrder?.rawValue
        case "text-allow-overlap": value = m.textAllowOverlap
        case "text-anchor": value = m.textAnchor?.rawValue
        case "text-field": value = m.textField
        case "text-font": value = m.textFont
        case "text-ignore-placement": value = m.textIgnorePlacement
        case "text-justify": value = m.textJustify?.rawValue
        case "text-keep-upright": value = m.textKeepUpright
        case "text-letter-spacing": value = m.textLetterSpacing
        case "text-line-height": value = m.textLineHeight
        case "text-max-angle": value = m.textMaxAngle
        case "text-max-width": value = m.textMaxWidth
        case "text-offset": value = m.textOffset
        case "text-optional": value = m.textOptional
        case "text-padding": value = m.textPadding
        case "text-pitch-alignment": value = m.textPitchAlignment?.rawValue
        case "text-radial-offset": value = m.textRadialOffset
        case "text-rotate": value = m.textRotate
        case "text-rotation-alignment": value = m.textRotationAlignment?.rawValue
        case "text-size": value = m.textSize
        case "text-transform": value = m.textTransform?.rawValue
        case "text-variable-anchor": value = m.textVariableAnchor?.map(\.rawValue)
        case "text-writing-mode": value = m.textWritingMode?.map(\.rawValue)
        case "icon-color": value = m.iconColor?.rawValue
        case "icon-color-brightness-max": value = m.iconColorBrightnessMax
        case "icon-color-brightness-min": value = m.iconColorBrightnessMin
        case "icon-color-contrast": value = m.iconColorContrast
        case "icon-color-saturation": value = m.iconColorSaturation
        case "icon-emissive-strength": value = m.iconEmissiveStrength
        case "icon-halo-blur": value = m.iconHaloBlur
        case "icon-halo-color": value = m.iconHaloColor?.rawValue
        case "icon-halo-width": value = m.iconHaloWidth
        case "icon-image-cross-fade": value = m.iconImageCrossFade
        case "icon-occlusion-opacity": value = m.iconOcclusionOpacity
        case "icon-opacity": value = m.iconOpacity
        case "icon-translate": value = m.iconTranslate
        case "icon-translate-anchor": value = m.iconTranslateAnchor?.rawValue
        case "occlusion-opacity-mode": value = m.occlusionOpacityMode?.rawValue
        case "symbol-z-offset": value = m.symbolZOffset
        case "text-color": value = m.textColor?.rawValue
        case "text-emissive-strength": value = m.textEmissiveStrength
        case "text-halo-blur": value = m.textHaloBlur
        case "text-halo-color": value = m.textHaloColor?.rawValue
        case "text-halo-width": value = m.textHaloWidth
        case "text-occlusion-opacity": value = m.textOcclusionOpacity
        case "text-opacity": value = m.textOpacity
        case "text-translate": value = m.textTranslate
        case "text-translate-anchor": value = m.textTranslateAnchor?.rawValue
        case "slot": value = m.slot
        default: return (false, nil)
        }
        return (true, value)
    }

    // MARK: Polyline

    static func set(_ m: PolylineAnnotationManager, _ property: String, _ raw: Any?) -> Bool {
        let v = nn(raw)
        switch property {
        case "line-cap": m.lineCap = str(v).map(LineCap.init(rawValue:))
        case "line-elevation-ground-scale": m.lineElevationGroundScale = dbl(v)
        case "line-elevation-reference": m.lineElevationReference = str(v).map(LineElevationReference.init(rawValue:))
        case "line-join": m.lineJoin = str(v).map(LineJoin.init(rawValue:))
        case "line-miter-limit": m.lineMiterLimit = dbl(v)
        case "line-round-limit": m.lineRoundLimit = dbl(v)
        case "line-sort-key": m.lineSortKey = dbl(v)
        case "line-z-offset": m.lineZOffset = dbl(v)
        case "line-blur": m.lineBlur = dbl(v)
        case "line-border-color": m.lineBorderColor = styleColor(v)
        case "line-border-width": m.lineBorderWidth = dbl(v)
        case "line-color": m.lineColor = styleColor(v)
        case "line-dasharray": m.lineDasharray = doubles(v)
        case "line-depth-occlusion-factor": m.lineDepthOcclusionFactor = dbl(v)
        case "line-emissive-strength": m.lineEmissiveStrength = dbl(v)
        case "line-gap-width": m.lineGapWidth = dbl(v)
        case "line-occlusion-opacity": m.lineOcclusionOpacity = dbl(v)
        case "line-offset": m.lineOffset = dbl(v)
        case "line-opacity": m.lineOpacity = dbl(v)
        case "line-pattern": m.linePattern = str(v)
        case "line-pattern-cross-fade": m.linePatternCrossFade = dbl(v)
        case "line-translate": m.lineTranslate = doubles(v)
        case "line-translate-anchor": m.lineTranslateAnchor = str(v).map(LineTranslateAnchor.init(rawValue:))
        case "line-trim-offset": m.lineTrimOffset = doubles(v)
        case "line-width": m.lineWidth = dbl(v)
        case "slot": m.slot = str(v)
        default: return false
        }
        return true
    }

    static func get(_ m: PolylineAnnotationManager, _ property: String) -> (handled: Bool, value: Any?) {
        let value: Any?
        switch property {
        case "line-cap": value = m.lineCap?.rawValue
        case "line-elevation-ground-scale": value = m.lineElevationGroundScale
        case "line-elevation-reference": value = m.lineElevationReference?.rawValue
        case "line-join": value = m.lineJoin?.rawValue
        case "line-miter-limit": value = m.lineMiterLimit
        case "line-round-limit": value = m.lineRoundLimit
        case "line-sort-key": value = m.lineSortKey
        case "line-z-offset": value = m.lineZOffset
        case "line-blur": value = m.lineBlur
        case "line-border-color": value = m.lineBorderColor?.rawValue
        case "line-border-width": value = m.lineBorderWidth
        case "line-color": value = m.lineColor?.rawValue
        case "line-dasharray": value = m.lineDasharray
        case "line-depth-occlusion-factor": value = m.lineDepthOcclusionFactor
        case "line-emissive-strength": value = m.lineEmissiveStrength
        case "line-gap-width": value = m.lineGapWidth
        case "line-occlusion-opacity": value = m.lineOcclusionOpacity
        case "line-offset": value = m.lineOffset
        case "line-opacity": value = m.lineOpacity
        case "line-pattern": value = m.linePattern
        case "line-pattern-cross-fade": value = m.linePatternCrossFade
        case "line-translate": value = m.lineTranslate
        case "line-translate-anchor": value = m.lineTranslateAnchor?.rawValue
        case "line-trim-offset": value = m.lineTrimOffset
        case "line-width": value = m.lineWidth
        case "slot": value = m.slot
        default: return (false, nil)
        }
        return (true, value)
    }
}
