// JSON <-> MapboxMaps type conversions. Field names match the Dart side.

import Foundation
import UIKit
import CoreLocation
@_spi(Experimental) import MapboxMaps

typealias JSON = [String: Any]

// MARK: - Primitive readers

func dbl(_ v: Any?) -> Double? {
    if let n = v as? NSNumber { return n.doubleValue }
    if let d = v as? Double { return d }
    return nil
}

func int64(_ v: Any?) -> Int64? {
    if let n = v as? NSNumber { return n.int64Value }
    return nil
}

func int(_ v: Any?) -> Int? {
    if let n = v as? NSNumber { return n.intValue }
    return nil
}

func bool(_ v: Any?) -> Bool? {
    if let b = v as? Bool { return b }
    if let n = v as? NSNumber { return n.boolValue }
    return nil
}

func str(_ v: Any?) -> String? {
    if v is NSNull { return nil }
    return v as? String
}

func doubles(_ v: Any?) -> [Double]? {
    (v as? [Any])?.compactMap(dbl)
}

func strings(_ v: Any?) -> [String]? {
    (v as? [Any])?.compactMap { $0 as? String }
}

func json(_ v: Any?) -> JSON? {
    if v is NSNull { return nil }
    return v as? JSON
}

func jsonString(_ dict: Any?) -> String {
    guard let dict = dict,
          let data = try? JSONSerialization.data(withJSONObject: Reply.sanitize(dict), options: []),
          let text = String(data: data, encoding: .utf8) else { return "" }
    return text
}

func parseJSON(_ text: String?) -> Any? {
    guard let text = text, let data = text.data(using: .utf8) else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
}

func jsonDict(_ text: String?) -> JSON {
    parseJSON(text) as? JSON ?? [:]
}

struct MapboxKitError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

// MARK: - Colors

func uiColor(fromArgb rgbValue: Int64) -> UIColor {
    let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 0xFF
    let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 0xFF
    let blue = CGFloat(rgbValue & 0x0000FF) / 0xFF
    let alpha = CGFloat((rgbValue & 0xFF000000) >> 24) / 0xFF
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
}

extension UIColor {
    func argb() -> Int64 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return 0 }
        let ai = Int64(a * 255), ri = Int64(r * 255), gi = Int64(g * 255), bi = Int64(b * 255)
        return (ai << 24) | (ri << 16) | (gi << 8) | bi
    }
}

func styleColor(_ v: Any?) -> StyleColor? {
    guard let argb = int64(v) else { return nil }
    return StyleColor(uiColor(fromArgb: argb))
}

extension StyleColor {
    /// Packed ARGB for the `rgba(r, g, b, a)` / `hsla(...)` colors the SDK returns.
    var argbValue: Int64? {
        let pattern = #"(rgb|rgba|hsl|hsla)\((.*)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: rawValue, range: NSRange(rawValue.startIndex..., in: rawValue)),
              let tagRange = Range(match.range(at: 1), in: rawValue),
              let valueRange = Range(match.range(at: 2), in: rawValue) else { return nil }
        let tag = String(rawValue[tagRange])
        let values = rawValue[valueRange].components(separatedBy: ",").compactMap {
            Double($0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: ""))
        }
        guard values.count >= 3 else { return nil }
        var r = values[0], g = values[1], b = values[2]
        let a = values.count > 3 ? values[3] : 1.0
        if tag.hasPrefix("hsl") {
            let (h, s, l) = (r, g, b)
            let c = (1 - abs(2 * l - 1)) * s
            let h60 = h / 60
            let x = c * (1 - abs(h60.truncatingRemainder(dividingBy: 2) - 1))
            var rr = 0.0, gg = 0.0, bb = 0.0
            switch h60 {
            case ..<1: (rr, gg) = (c, x)
            case ..<2: (rr, gg) = (x, c)
            case ..<3: (gg, bb) = (c, x)
            case ..<4: (gg, bb) = (x, c)
            case ..<5: (rr, bb) = (x, c)
            default: (rr, bb) = (c, x)
            }
            let m = l - c / 2
            r = (rr + m) * 255; g = (gg + m) * 255; b = (bb + m) * 255
        }
        let ai = Int64(a * 255), ri = Int64(r), gi = Int64(g), bi = Int64(b)
        return (ai << 24) | (ri << 16) | (gi << 8) | bi
    }
}

// MARK: - Geometry

enum Mappers {
    static func coordinate(_ v: Any?) -> CLLocationCoordinate2D? {
        guard let dict = json(v), let coords = doubles(dict["coordinates"]), coords.count >= 2 else { return nil }
        return CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
    }

    static func coordinates(_ v: Any?) -> [CLLocationCoordinate2D] {
        (v as? [Any])?.compactMap(coordinate) ?? []
    }

    static func lineCoordinates(_ v: Any?) -> [CLLocationCoordinate2D]? {
        guard let dict = json(v), let coords = dict["coordinates"] as? [[Any]] else { return nil }
        return coords.compactMap { pair -> CLLocationCoordinate2D? in
            let values = pair.compactMap(dbl)
            guard values.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: values[1], longitude: values[0])
        }
    }

    static func pointJSON(_ c: CLLocationCoordinate2D) -> JSON {
        ["type": "Point", "coordinates": [c.longitude, c.latitude]]
    }

    static func lineStringJSON(_ coords: [CLLocationCoordinate2D]) -> JSON {
        ["type": "LineString", "coordinates": coords.map { [$0.longitude, $0.latitude] }]
    }

    static func geometry(_ v: Any?) -> Geometry? {
        guard let dict = json(v), let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return try? JSONDecoder().decode(Geometry.self, from: data)
    }

    static func geometryJSON(_ geometry: Geometry) -> JSON {
        guard let data = try? JSONEncoder().encode(geometry),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? JSON else { return [:] }
        return dict
    }

    static func feature(_ v: Any?) -> Feature? {
        guard let dict = json(v), let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return try? JSONDecoder().decode(Feature.self, from: data)
    }

    static func featureJSON(_ feature: Feature) -> JSON {
        guard let data = try? JSONEncoder().encode(feature),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? JSON else { return [:] }
        return dict
    }

    // MARK: Screen / padding

    static func point(_ v: Any?) -> CGPoint? {
        guard let dict = json(v), let x = dbl(dict["x"]), let y = dbl(dict["y"]) else { return nil }
        return CGPoint(x: x, y: y)
    }

    static func pointJSON(_ p: CGPoint) -> JSON { ["x": p.x, "y": p.y] }

    static func rect(_ v: Any?) -> CGRect? {
        guard let dict = json(v), let min = point(dict["min"]), let max = point(dict["max"]) else { return nil }
        return CGRect(x: min.x, y: min.y, width: max.x - min.x, height: max.y - min.y)
    }

    static func insets(_ v: Any?) -> UIEdgeInsets? {
        guard let dict = json(v) else { return nil }
        return UIEdgeInsets(top: dbl(dict["top"]) ?? 0, left: dbl(dict["left"]) ?? 0,
                            bottom: dbl(dict["bottom"]) ?? 0, right: dbl(dict["right"]) ?? 0)
    }

    static func insetsJSON(_ i: UIEdgeInsets) -> JSON {
        ["top": i.top, "left": i.left, "bottom": i.bottom, "right": i.right]
    }

    static func sizeJSON(_ s: CGSize) -> JSON { ["width": s.width, "height": s.height] }

    // MARK: Camera

    static func cameraOptions(_ dict: JSON) -> CameraOptions {
        CameraOptions(
            center: coordinate(dict["center"]),
            padding: insets(dict["padding"]),
            anchor: point(dict["anchor"]),
            zoom: dbl(dict["zoom"]).map { CGFloat($0) },
            bearing: dbl(dict["bearing"]),
            pitch: dbl(dict["pitch"]).map { CGFloat($0) })
    }

    static func cameraOptionsJSON(_ c: CameraOptions) -> JSON {
        [
            "center": c.center.map(pointJSON) as Any,
            "padding": c.padding.map(insetsJSON) as Any,
            "anchor": c.anchor.map(pointJSON) as Any,
            "zoom": c.zoom.map { Double($0) } as Any,
            "bearing": c.bearing as Any,
            "pitch": c.pitch.map { Double($0) } as Any,
        ]
    }

    static func cameraStateJSON(_ s: CameraState) -> JSON {
        [
            "center": pointJSON(s.center),
            "padding": insetsJSON(s.padding),
            "zoom": s.zoom,
            "bearing": s.bearing,
            "pitch": s.pitch,
        ]
    }

    static func coordinateBounds(_ v: Any?) -> CoordinateBounds? {
        guard let dict = json(v), let sw = coordinate(dict["southwest"]), let ne = coordinate(dict["northeast"]) else { return nil }
        return CoordinateBounds(southwest: sw, northeast: ne, infiniteBounds: bool(dict["infiniteBounds"]) ?? false)
    }

    static func coordinateBoundsJSON(_ b: CoordinateBounds) -> JSON {
        ["southwest": pointJSON(b.southwest), "northeast": pointJSON(b.northeast), "infiniteBounds": b.infiniteBounds]
    }

    static func cameraBoundsOptions(_ dict: JSON) -> CameraBoundsOptions {
        CameraBoundsOptions(
            bounds: coordinateBounds(dict["bounds"]),
            maxZoom: dbl(dict["maxZoom"]).map { CGFloat($0) },
            minZoom: dbl(dict["minZoom"]).map { CGFloat($0) },
            maxPitch: dbl(dict["maxPitch"]).map { CGFloat($0) },
            minPitch: dbl(dict["minPitch"]).map { CGFloat($0) })
    }

    static func cameraBoundsJSON(_ b: CameraBounds) -> JSON {
        [
            "bounds": coordinateBoundsJSON(b.bounds),
            "maxZoom": Double(b.maxZoom), "minZoom": Double(b.minZoom),
            "maxPitch": Double(b.maxPitch), "minPitch": Double(b.minPitch),
        ]
    }

    static func animationDuration(_ v: Any?) -> TimeInterval {
        guard let dict = json(v), let ms = dbl(dict["duration"]) else { return 1.0 }
        return ms / 1000.0
    }

    // MARK: Map options

    static func mapOptions(_ dict: JSON) -> MapOptions {
        let defaults = MapOptions()
        let constrain: ConstrainMode = {
            switch int(dict["constrainMode"]) {
            case 0: return .none
            case 2: return .widthAndHeight
            default: return .heightOnly
            }
        }()
        let viewport: ViewportMode = int(dict["viewportMode"]) == 1 ? .flippedY : .default
        let orientation: NorthOrientation = {
            switch int(dict["orientation"]) {
            case 1: return .rightwards
            case 2: return .downwards
            case 3: return .leftwards
            default: return .upwards
            }
        }()
        var glyphs = GlyphsRasterizationOptions()
        if let g = json(dict["glyphsRasterizationOptions"]) {
            let mode: GlyphsRasterizationMode = {
                switch int(g["rasterizationMode"]) {
                case 1: return .ideographsRasterizedLocally
                case 2: return .allGlyphsRasterizedLocally
                default: return .noGlyphsRasterizedLocally
                }
            }()
            glyphs = GlyphsRasterizationOptions(rasterizationMode: mode,
                                                fontFamilies: str(g["fontFamily"]).map { [$0] } ?? [])
        }
        let size: CGSize? = json(dict["size"]).map { CGSize(width: dbl($0["width"]) ?? 0, height: dbl($0["height"]) ?? 0) }
        return MapOptions(
            constrainMode: constrain,
            viewportMode: viewport,
            orientation: orientation,
            crossSourceCollisions: bool(dict["crossSourceCollisions"]) ?? defaults.crossSourceCollisions,
            size: size ?? defaults.size,
            pixelRatio: dbl(dict["pixelRatio"]).map { CGFloat($0) } ?? UIScreen.main.scale,
            glyphsRasterizationOptions: glyphs)
    }

    static func mapOptionsJSON(_ o: MapOptions) -> JSON {
        [
            "contextMode": NSNull(),
            "constrainMode": o.__constrainMode.map { $0.intValue } as Any,
            "viewportMode": o.__viewportMode.map { $0.intValue } as Any,
            "orientation": o.__orientation.map { $0.intValue } as Any,
            "crossSourceCollisions": o.crossSourceCollisions,
            "size": o.size.map(sizeJSON) as Any,
            "pixelRatio": Double(o.pixelRatio),
            "glyphsRasterizationOptions": o.glyphsRasterizationOptions.map {
                ["rasterizationMode": $0.rasterizationMode.rawValue, "fontFamily": $0.fontFamily as Any] as JSON
            } as Any,
        ]
    }

    // MARK: Style values

    static func stylePropertyValueJSON(_ v: StylePropertyValue) -> JSON {
        let converted: Any
        switch v.value {
        case is [AnyHashable: Any], is [Any], is NSNumber, is String:
            converted = v.value
        case is NSNull:
            converted = NSNull()
        default:
            converted = String(describing: v.value)
        }
        return ["value": converted, "kind": v.kind.rawValue]
    }

    /// Expressions arrive as JSON strings from the generated layer code; turn
    /// them back into arrays/objects before handing them to the style.
    static func styleValue(_ v: Any?) -> Any {
        guard let v = v else { return NSNull() }
        if let s = v as? String, s.hasPrefix("[") || s.hasPrefix("{"),
           let parsed = parseJSON(s) {
            return parsed
        }
        return v
    }

    static func layerPosition(_ v: Any?) -> LayerPosition? {
        guard let dict = json(v) else { return nil }
        if let above = str(dict["above"]) { return .above(above) }
        if let below = str(dict["below"]) { return .below(below) }
        if let at = int(dict["at"]) { return .at(at) }
        return nil
    }

    static func importPosition(_ v: Any?) -> ImportPosition? {
        guard let dict = json(v) else { return nil }
        if let above = str(dict["above"]) { return .above(above) }
        if let below = str(dict["below"]) { return .below(below) }
        if let at = int(dict["at"]) { return .at(at) }
        return nil
    }

    static func transitionOptions(_ dict: JSON) -> TransitionOptions {
        TransitionOptions(
            duration: dbl(dict["duration"]).map { $0 / 1000 },
            delay: dbl(dict["delay"]).map { $0 / 1000 },
            enablePlacementTransitions: bool(dict["enablePlacementTransitions"]))
    }

    static func transitionOptionsJSON(_ t: TransitionOptions) -> JSON {
        [
            "duration": t.duration.map { Int64($0 * 1000) } as Any,
            "delay": t.delay.map { Int64($0 * 1000) } as Any,
            "enablePlacementTransitions": t.enablePlacementTransitions as Any,
        ]
    }

    static func styleTransition(_ v: Any?) -> StyleTransition? {
        guard let dict = json(v) else { return nil }
        return StyleTransition(duration: (dbl(dict["duration"]) ?? 300) / 1000,
                               delay: (dbl(dict["delay"]) ?? 0) / 1000)
    }

    static func infoJSON(id: String, type: String) -> JSON { ["id": id, "type": type] }

    static func image(_ v: Any?, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        guard let dict = json(v), let base64 = str(dict["data"]), let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data, scale: scale)
    }

    static func imageBytes(_ v: Any?, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        guard let base64 = str(v), let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data, scale: scale)
    }

    static func imageJSON(_ image: UIImage) -> JSON? {
        guard let png = image.pngData() else { return nil }
        return ["width": Int(image.size.width * image.scale),
                "height": Int(image.size.height * image.scale),
                "data": png.base64EncodedString()]
    }

    static func queriedFeatureJSON(_ f: QueriedFeature) -> JSON {
        [
            "feature": featureJSON(f.feature),
            "source": f.source,
            "sourceLayer": f.sourceLayer as Any,
            "state": jsonString(f.state as? JSON ?? [:]),
        ]
    }

    static func canonicalTileIDJSON(_ t: CanonicalTileID) -> JSON { ["z": t.z, "x": t.x, "y": t.y] }

    static func gestureState(_ state: UIGestureRecognizer.State) -> Int {
        switch state {
        case .possible, .began: return 0
        case .changed: return 1
        default: return 2
        }
    }

    static func gestureContextJSON(point: CGPoint, coordinate: CLLocationCoordinate2D, state: Int) -> JSON {
        ["touchPosition": pointJSON(point), "point": pointJSON(coordinate), "gestureState": state]
    }
}
