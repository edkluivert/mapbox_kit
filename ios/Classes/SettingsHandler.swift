// location#, gestures#, logo#, compass#, scaleBar#, attribution# calls.

import Foundation
import UIKit
@_spi(Experimental) @_spi(Restricted) import MapboxMaps

/// Caches the 4 margin values Dart exposes per ornament, since the native
/// SDK stores only a single `CGPoint` (the 2 values for the current position).
struct OrnamentMargins {
    var left: Double, top: Double, right: Double, bottom: Double

    init(seedingFrom point: CGPoint) {
        left = point.x; right = point.x; top = point.y; bottom = point.y
    }

    mutating func apply(_ s: JSON, for position: OrnamentPosition) -> CGPoint {
        if let v = dbl(s["marginLeft"]) { left = v }
        if let v = dbl(s["marginTop"]) { top = v }
        if let v = dbl(s["marginRight"]) { right = v }
        if let v = dbl(s["marginBottom"]) { bottom = v }
        switch position {
        case .bottomLeading: return CGPoint(x: left, y: bottom)
        case .bottomTrailing: return CGPoint(x: right, y: bottom)
        case .topLeading: return CGPoint(x: left, y: top)
        default: return CGPoint(x: right, y: top)
        }
    }

    var json: JSON { ["marginLeft": left, "marginTop": top, "marginRight": right, "marginBottom": bottom] }
}

func ornamentPosition(_ v: Any?) -> OrnamentPosition? {
    switch int(v) {
    case 0: return .topLeading
    case 1: return .topTrailing
    case 2: return .bottomTrailing
    case 3: return .bottomLeading
    default: return nil
    }
}

func ornamentPositionIndex(_ p: OrnamentPosition) -> Int {
    switch p {
    case .topLeading: return 0
    case .bottomTrailing: return 2
    case .bottomLeading: return 3
    default: return 1
    }
}

final class SettingsHandler {
    private unowned let map: MapController
    private var mapView: MapView { map.mapView }

    private lazy var logoMargins = OrnamentMargins(seedingFrom: mapView.ornaments.options.logo.margins)
    private lazy var compassMargins = OrnamentMargins(seedingFrom: mapView.ornaments.options.compass.margins)
    private lazy var scaleBarMargins = OrnamentMargins(seedingFrom: mapView.ornaments.options.scaleBar.margins)
    private lazy var attributionMargins = OrnamentMargins(seedingFrom: mapView.ornaments.options.attributionButton.margins)

    // Location: `puckType` conflates appearance with visibility, so the real
    // config is tracked here and only projected while enabled.
    private var locationEnabled = false
    private var puckType: PuckType?
    private var puck2DConfiguration: Puck2DConfiguration?
    private var puck3DConfiguration: Puck3DConfiguration?

    init(map: MapController) { self.map = map }

    func invoke(group: String, _ name: String, _ a: JSON, _ reply: Reply) -> Int32 {
        let s = json(a["settings"]) ?? [:]
        switch (group, name) {
        case ("location", "getSettings"): reply.run { locationSettings() }
        case ("location", "updateSettings"):
            reply.run { try updateLocation(s, useDefaultPuck2D: bool(a["useDefaultPuck2DIfNeeded"]) ?? false); return nil }
        case ("gestures", "getSettings"): reply.run { gesturesSettings() }
        case ("gestures", "updateSettings"): reply.run { updateGestures(s); return nil }
        case ("logo", "getSettings"):
            reply.run {
                let o = mapView.ornaments.options.logo
                return ["enabled": o.visibility != .hidden, "position": ornamentPositionIndex(o.position)].merging(logoMargins.json) { a, _ in a }
            }
        case ("logo", "updateSettings"):
            reply.run {
                var logo = mapView.ornaments.options.logo
                if let p = ornamentPosition(s["position"]) { logo.position = p }
                logo.margins = logoMargins.apply(s, for: logo.position)
                if let enabled = bool(s["enabled"]) { logo.visibility = enabled ? .visible : .hidden }
                mapView.ornaments.options.logo = logo
                return nil
            }
        case ("attribution", "getSettings"):
            reply.run {
                let o = mapView.ornaments.options.attributionButton
                return ["enabled": o.visibility != .hidden, "position": ornamentPositionIndex(o.position),
                        "iconColor": mapView.ornaments.attributionButton.tintColor.argb(),
                        "clickable": NSNull()].merging(attributionMargins.json) { a, _ in a }
            }
        case ("attribution", "updateSettings"):
            reply.run {
                var button = mapView.ornaments.options.attributionButton
                if let p = ornamentPosition(s["position"]) { button.position = p }
                button.margins = attributionMargins.apply(s, for: button.position)
                if let enabled = bool(s["enabled"]) { button.visibility = enabled ? .visible : .hidden }
                mapView.ornaments.options.attributionButton = button
                if let color = int64(s["iconColor"]) { mapView.ornaments.attributionButton.tintColor = uiColor(fromArgb: color) }
                return nil
            }
        case ("compass", "getSettings"):
            reply.run {
                let o = mapView.ornaments.options.compass
                let (visible, fadeNorth): (Bool, Bool) = {
                    switch o.visibility {
                    case .adaptive: return (true, true)
                    case .hidden: return (false, false)
                    default: return (true, false)
                    }
                }()
                return ["enabled": visible, "position": ornamentPositionIndex(o.position), "opacity": 1, "rotation": 0,
                        "visibility": visible, "fadeWhenFacingNorth": fadeNorth, "clickable": true,
                        "image": o.image?.pngData()?.base64EncodedString() as Any].merging(compassMargins.json) { a, _ in a }
            }
        case ("compass", "updateSettings"):
            reply.run {
                var compass = mapView.ornaments.options.compass
                if let p = ornamentPosition(s["position"]) { compass.position = p }
                compass.margins = compassMargins.apply(s, for: compass.position)
                if let image = Mappers.imageBytes(s["image"]) { compass.image = image }
                if bool(s["enabled"]) != nil || bool(s["fadeWhenFacingNorth"]) != nil {
                    let current = compass.visibility
                    let enabled = bool(s["enabled"]) ?? (current != .hidden)
                    let fade = bool(s["fadeWhenFacingNorth"]) ?? (current == .adaptive)
                    compass.visibility = !enabled ? .hidden : (fade ? .adaptive : .visible)
                }
                mapView.ornaments.options.compass = compass
                return nil
            }
        case ("scaleBar", "getSettings"):
            reply.run {
                let o = mapView.ornaments.options.scaleBar
                let units: Any = {
                    switch o.units {
                    case .metric: return 0
                    case .imperial: return 1
                    case .nautical: return 2
                    default: return NSNull()
                    }
                }()
                return ["enabled": o.visibility != .hidden, "position": ornamentPositionIndex(o.position),
                        "isMetricUnits": o.useMetricUnits, "distanceUnits": units].merging(scaleBarMargins.json) { a, _ in a }
            }
        case ("scaleBar", "updateSettings"):
            reply.run {
                var bar = mapView.ornaments.options.scaleBar
                if let p = ornamentPosition(s["position"]) { bar.position = p }
                bar.margins = scaleBarMargins.apply(s, for: bar.position)
                if let metric = bool(s["isMetricUnits"]) { bar.useMetricUnits = metric }
                if let enabled = bool(s["enabled"]) { bar.visibility = enabled ? .adaptive : .hidden }
                switch int(s["distanceUnits"]) {
                case 0: bar.units = .metric
                case 1: bar.units = .imperial
                case 2: bar.units = .nautical
                default: break
                }
                mapView.ornaments.options.scaleBar = bar
                return nil
            }
        default:
            return 2
        }
        return 0
    }

    // MARK: - Gestures

    private func updateGestures(_ s: JSON) {
        var o = mapView.gestures.options
        if let v = bool(s["scrollEnabled"]) { o.panEnabled = v }
        if let v = bool(s["rotateEnabled"]) { o.rotateEnabled = v }
        if let v = bool(s["simultaneousRotateAndPinchToZoomEnabled"]) { o.simultaneousRotateAndPinchZoomEnabled = v }
        if let v = bool(s["pinchPanEnabled"]) { o.pinchPanEnabled = v }
        if let v = bool(s["pitchEnabled"]) { o.pitchEnabled = v }
        if let v = bool(s["doubleTapToZoomInEnabled"]) { o.doubleTapToZoomInEnabled = v }
        if let v = bool(s["doubleTouchToZoomOutEnabled"]) { o.doubleTouchToZoomOutEnabled = v }
        if let v = bool(s["quickZoomEnabled"]) { o.quickZoomEnabled = v }
        if let v = bool(s["pinchToZoomEnabled"]) { o.pinchZoomEnabled = v }
        if let v = bool(s["scrollDecelerationEnabled"]) { o.panDecelerationFactor = v ? UIScrollView.DecelerationRate.normal.rawValue : 0 }
        switch int(s["scrollMode"]) {
        case 0: o.panMode = .horizontal
        case 1: o.panMode = .vertical
        case 2: o.panMode = .horizontalAndVertical
        default: break
        }
        if let p = Mappers.point(s["focalPoint"]) { o.focalPoint = p }
        mapView.gestures.options = o
    }

    private func gesturesSettings() -> JSON {
        let o = mapView.gestures.options
        let scrollMode: Int = {
            switch o.panMode {
            case .horizontal: return 0
            case .vertical: return 1
            default: return 2
            }
        }()
        return [
            "rotateEnabled": o.rotateEnabled,
            "pinchToZoomEnabled": o.pinchZoomEnabled,
            "scrollEnabled": o.panEnabled,
            "simultaneousRotateAndPinchToZoomEnabled": o.simultaneousRotateAndPinchZoomEnabled,
            "pitchEnabled": o.pitchEnabled,
            "scrollMode": scrollMode,
            "doubleTapToZoomInEnabled": o.doubleTapToZoomInEnabled,
            "doubleTouchToZoomOutEnabled": o.doubleTouchToZoomOutEnabled,
            "quickZoomEnabled": o.quickZoomEnabled,
            "focalPoint": o.focalPoint.map(Mappers.pointJSON) as Any,
            "scrollDecelerationEnabled": o.panDecelerationFactor > 0,
            "pinchPanEnabled": o.pinchPanEnabled,
        ]
    }

    // MARK: - Location

    private func updateLocation(_ s: JSON, useDefaultPuck2D: Bool) throws {
        if let enabled = bool(s["enabled"]) { locationEnabled = enabled }
        var options = mapView.location.options
        options.puckType = puckType
        if let bearingEnabled = bool(s["puckBearingEnabled"]) { options.puckBearingEnabled = bearingEnabled }
        if let bearing = int(s["puckBearing"]) { options.puckBearing = bearing == 1 ? .course : .heading }

        let puck = json(s["locationPuck"])
        if let puck3D = puck.flatMap({ json($0["locationPuck3D"]) }) {
            var configuration: Puck3DConfiguration
            if case .puck3D(let existing) = options.puckType {
                configuration = existing
            } else if let cached = puck3DConfiguration {
                configuration = cached
            } else {
                guard let uri = str(puck3D["modelUri"]), let url = URL(string: uri) else {
                    throw MapboxKitError("modelUri must be provided the first time a 3D puck is configured.")
                }
                configuration = Puck3DConfiguration(model: Model(uri: url, position: doubles(puck3D["position"])))
            }
            if let uri = str(puck3D["modelUri"]), let url = URL(string: uri) { configuration.model.uri = url }
            if let position = doubles(puck3D["position"]) { configuration.model.position = position }
            if let opacity = dbl(puck3D["modelOpacity"]) { configuration.modelOpacity = .constant(opacity) }
            if let scale = doubles(puck3D["modelScale"]) { configuration.modelScale = .constant(scale) }
            if let expr = str(puck3D["modelScaleExpression"]), let data = expr.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(Exp.self, from: data) {
                configuration.modelScale = .expression(decoded)
            }
            if let ref = int(puck3D["modelElevationReference"]) { configuration.modelElevationReference = .constant(ref == 0 ? .sea : .ground) }
            if let rotation = doubles(puck3D["modelRotation"]) { configuration.modelRotation = .constant(rotation) }
            options.puckType = .puck3D(configuration)
        } else {
            let live: Puck2DConfiguration? = { if case .puck2D(let c) = options.puckType { return c }; return nil }()
            let puck2D = puck.flatMap { json($0["locationPuck2D"]) }
            if puck2D != nil || live != nil || options.puckType == nil {
                var configuration: Puck2DConfiguration
                var carryForward = false
                if puck2D != nil && useDefaultPuck2D {
                    configuration = Puck2DConfiguration.makeDefault(showBearing: options.puckBearingEnabled)
                    carryForward = true
                } else if let live {
                    configuration = live
                } else {
                    configuration = useDefaultPuck2D
                        ? Puck2DConfiguration.makeDefault(showBearing: options.puckBearingEnabled)
                        : (puck2DConfiguration ?? Puck2DConfiguration())
                    carryForward = true
                }
                if carryForward, let cached = puck2DConfiguration {
                    configuration.pulsing = cached.pulsing
                    configuration.showsAccuracyRing = cached.showsAccuracyRing
                    configuration.accuracyRingColor = cached.accuracyRingColor
                    configuration.accuracyRingBorderColor = cached.accuracyRingBorderColor
                }
                if let image = Mappers.imageBytes(puck2D?["topImage"]) { configuration.topImage = image }
                if let image = Mappers.imageBytes(puck2D?["bearingImage"]) { configuration.bearingImage = image }
                if let image = Mappers.imageBytes(puck2D?["shadowImage"]) { configuration.shadowImage = image }
                if let expr = str(puck2D?["scaleExpression"]), let data = expr.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(Value<Double>.self, from: data) {
                    configuration.scale = decoded
                }
                if let color = int64(s["accuracyRingColor"]) { configuration.accuracyRingColor = uiColor(fromArgb: color) }
                if let color = int64(s["accuracyRingBorderColor"]) { configuration.accuracyRingBorderColor = uiColor(fromArgb: color) }
                if let show = bool(s["showAccuracyRing"]) { configuration.showsAccuracyRing = show }
                let pulsingEnabled = bool(s["pulsingEnabled"]) ?? (configuration.pulsing != nil)
                if pulsingEnabled {
                    var pulsing = configuration.pulsing ?? Puck2DConfiguration.Pulsing()
                    if let radius = dbl(s["pulsingMaxRadius"]) { pulsing.radius = radius == -1 ? .accuracy : .constant(radius) }
                    if let color = int64(s["pulsingColor"]) { pulsing.color = uiColor(fromArgb: color) }
                    configuration.pulsing = pulsing
                } else {
                    configuration.pulsing = nil
                }
                if let opacity = dbl(puck2D?["opacity"]) { configuration.opacity = opacity }
                options.puckType = .puck2D(configuration)
            }
        }
        if let slot = str(s["slot"]) {
            switch options.puckType {
            case .puck2D(var c): c.slot = Slot(rawValue: slot); options.puckType = .puck2D(c)
            case .puck3D(var c): c.slot = Slot(rawValue: slot); options.puckType = .puck3D(c)
            case .none: break
            }
        }
        puckType = options.puckType
        if case .puck2D(let c) = options.puckType { puck2DConfiguration = c }
        if case .puck3D(let c) = options.puckType { puck3DConfiguration = c }
        options.puckType = locationEnabled ? puckType : nil
        mapView.location.options = options
    }

    private func locationSettings() -> JSON {
        let options = mapView.location.options
        var result: JSON = [
            "enabled": locationEnabled,
            "puckBearingEnabled": options.puckBearingEnabled,
            "puckBearing": options.puckBearing == .course ? 1 : 0,
        ]
        var puck2D: JSON = [:]
        var puck3D: JSON = [:]
        if case .puck2D(let c) = puckType {
            result["accuracyRingColor"] = c.accuracyRingColor.argb()
            result["accuracyRingBorderColor"] = c.accuracyRingBorderColor.argb()
            result["showAccuracyRing"] = c.showsAccuracyRing
            puck2D["topImage"] = c.topImage?.pngData()?.base64EncodedString()
            puck2D["bearingImage"] = c.bearingImage?.pngData()?.base64EncodedString()
            puck2D["shadowImage"] = c.shadowImage?.pngData()?.base64EncodedString()
            if case .expression(let e) = c.scale, let data = try? JSONEncoder().encode(e) {
                puck2D["scaleExpression"] = String(data: data, encoding: .utf8)
            }
            puck2D["opacity"] = c.opacity
            if let pulsing = c.pulsing {
                result["pulsingEnabled"] = true
                switch pulsing.radius {
                case .accuracy: result["pulsingMaxRadius"] = -1
                case .constant(let r): result["pulsingMaxRadius"] = r
                }
                result["pulsingColor"] = pulsing.color.argb()
            }
            result["slot"] = c.slot?.rawValue
        }
        if case .puck3D(let c) = puckType {
            puck3D["modelUri"] = c.model.uri?.absoluteString
            puck3D["position"] = c.model.position
            if case .constant(let v) = c.modelOpacity { puck3D["modelOpacity"] = v }
            if case .constant(let v) = c.modelScale { puck3D["modelScale"] = v }
            if case .expression(let e) = c.modelScale, let data = try? JSONEncoder().encode(e) {
                puck3D["modelScaleExpression"] = String(data: data, encoding: .utf8)
            }
            if case .constant(let v) = c.modelRotation { puck3D["modelRotation"] = v }
            if case .constant(let v) = c.modelElevationReference { puck3D["modelElevationReference"] = v == .sea ? 0 : 1 }
            result["slot"] = c.slot?.rawValue
        }
        result["locationPuck"] = ["locationPuck2D": puck2D, "locationPuck3D": puck3D]
        return result
    }
}
