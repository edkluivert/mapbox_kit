// annotation#, pointAnnotation#, polylineAnnotation# calls and the
// interaction stream, ported from mapbox_maps_flutter's annotation controllers.

import Foundation
import UIKit
@_spi(Experimental) import MapboxMaps

final class AnnotationHandler {
    private unowned let map: MapController
    private var mapView: MapView { map.mapView }

    private var pointManagers: [String: PointAnnotationManager] = [:]
    private var polylineManagers: [String: PolylineAnnotationManager] = [:]
    /// Interaction stream per manager id.
    private var interactionReplies: [String: (token: Int64, reply: Reply)] = [:]

    init(map: MapController) { self.map = map }

    // MARK: - Streams

    func listen(token: Int64, managerId: String, reply: Reply) {
        interactionReplies[managerId] = (token, reply)
    }

    func cancel(token: Int64) {
        for (id, entry) in interactionReplies where entry.token == token {
            interactionReplies[id] = nil
        }
    }

    func cancelAll() {
        for entry in interactionReplies.values { MapboxKitPlugin.shared.unregisterStream(token: entry.token) }
        interactionReplies.removeAll()
    }

    private func send(managerId: String, type: String, state: Int, annotation: JSON) -> Bool {
        guard let entry = interactionReplies[managerId] else { return false }
        entry.reply.success(["type": type, "gestureState": state, "annotation": annotation])
        return true
    }

    // MARK: - Calls

    func invoke(group: String, _ name: String, _ a: JSON, _ reply: Reply) -> Int32 {
        switch group {
        case "annotation":
            switch name {
            case "createManager": reply.run { try createManager(a) }
            case "removeManager":
                reply.run {
                    let id = str(a["id"]) ?? ""
                    pointManagers[id] = nil
                    polylineManagers[id] = nil
                    interactionReplies[id] = nil
                    mapView.annotations.removeAnnotationManager(withId: id)
                    return nil
                }
            default: return 2
            }
        case "pointAnnotation": return invokePoint(name, a, reply)
        case "polylineAnnotation": return invokePolyline(name, a, reply)
        default: return 2
        }
        return 0
    }

    private func createManager(_ a: JSON) throws -> String {
        let type = str(a["type"]) ?? ""
        let id = str(a["id"]) ?? String(UUID().uuidString.prefix(8))
        var position: LayerPosition? = nil
        if let below = str(a["belowLayerId"]), mapView.mapboxMap.layerExists(withId: below) {
            position = .below(below)
        }
        switch type {
        case "point":
            pointManagers[id] = mapView.annotations.makePointAnnotationManager(id: id, layerPosition: position)
        case "polyline":
            polylineManagers[id] = mapView.annotations.makePolylineAnnotationManager(id: id, layerPosition: position)
        default:
            throw MapboxKitError("Unsupported annotation manager type: \(type)")
        }
        return id
    }

    private func layerProperty(managerId: String, layerId: String, _ a: JSON, _ reply: Reply, _ name: String) -> Int32 {
        let property = str(a["property"]) ?? ""
        switch name {
        case "setProperty":
            reply.run {
                try mapView.mapboxMap.setLayerProperty(for: layerId, property: property, value: Mappers.styleValue(a["value"]))
                return nil
            }
        case "getProperty":
            reply.run {
                let value = mapView.mapboxMap.layerProperty(for: layerId, property: property)
                switch value.kind {
                case .constant: return value.value is NSNull ? nil : value.value
                default: return nil
                }
            }
        default:
            return 2
        }
        return 0
    }

    // MARK: - Point

    private func invokePoint(_ name: String, _ a: JSON, _ reply: Reply) -> Int32 {
        let managerId = str(a["managerId"]) ?? ""
        guard let manager = pointManagers[managerId] else {
            reply.error(code: "0", message: "No manager found with id: \(managerId)"); return 0
        }
        switch name {
        case "getAnnotations":
            reply.run { manager.annotations.map(pointJSON) }
        case "create":
            reply.run {
                var annotation = try pointAnnotation(json(a["annotationOption"]) ?? [:], managerId: managerId)
                configure(&annotation, managerId: managerId)
                manager.annotations.append(annotation)
                return pointJSON(annotation)
            }
        case "createMulti":
            reply.run {
                var created: [PointAnnotation] = []
                for o in (a["annotationOptions"] as? [Any])?.compactMap(json) ?? [] {
                    var annotation = try pointAnnotation(o, managerId: managerId)
                    configure(&annotation, managerId: managerId)
                    created.append(annotation)
                }
                manager.annotations.append(contentsOf: created)
                return created.map(pointJSON)
            }
        case "update":
            reply.run {
                let d = json(a["annotation"]) ?? [:]
                var annotation = try pointAnnotation(d, managerId: managerId)
                configure(&annotation, managerId: managerId)
                guard let index = manager.annotations.firstIndex(where: { $0.id == annotation.id }) else {
                    throw MapboxKitError("No annotation found with id: \(annotation.id)")
                }
                manager.annotations[index] = annotation
                return nil
            }
        case "delete":
            reply.run {
                let id = str(json(a["annotation"])?["id"]) ?? ""
                manager.annotations.removeAll { $0.id == id }
                return nil
            }
        case "deleteMulti":
            reply.run {
                let ids = Set((a["annotations"] as? [Any])?.compactMap { str(json($0)?["id"]) } ?? [])
                manager.annotations.removeAll { ids.contains($0.id) }
                return nil
            }
        case "deleteAll":
            reply.run { manager.annotations = []; return nil }
        case "setProperty":
            let property = str(a["property"]) ?? ""
            if ManagerProperties.set(manager, property, Mappers.styleValue(a["value"])) { reply.success(nil); return 0 }
            return layerProperty(managerId: managerId, layerId: manager.layerId, a, reply, name)
        case "getProperty":
            let r = ManagerProperties.get(manager, str(a["property"]) ?? "")
            if r.handled { reply.success(r.value); return 0 }
            return layerProperty(managerId: managerId, layerId: manager.layerId, a, reply, name)
        default:
            return 2
        }
        return 0
    }

    private func configure(_ annotation: inout PointAnnotation, managerId: String) {
        let id = annotation.id
        annotation.tapHandler = { [weak self] _ in
            guard let self, let current = self.pointManagers[managerId]?.annotations.first(where: { $0.id == id }) else { return false }
            return self.send(managerId: managerId, type: "tap", state: 2, annotation: self.pointJSON(current))
        }
        annotation.longPressHandler = { [weak self] _ in
            guard let self, let current = self.pointManagers[managerId]?.annotations.first(where: { $0.id == id }) else { return false }
            return self.send(managerId: managerId, type: "longPress", state: 2, annotation: self.pointJSON(current))
        }
        annotation.dragBeginHandler = { [weak self] a, _ in
            guard let self else { return false }
            _ = self.send(managerId: managerId, type: "drag", state: 0, annotation: self.pointJSON(a))
            return true
        }
        annotation.dragChangeHandler = { [weak self] a, _ in
            guard let self else { return }
            _ = self.send(managerId: managerId, type: "drag", state: 1, annotation: self.pointJSON(a))
        }
        annotation.dragEndHandler = { [weak self] a, _ in
            guard let self else { return }
            _ = self.send(managerId: managerId, type: "drag", state: 2, annotation: self.pointJSON(a))
        }
    }

    private func pointAnnotation(_ d: JSON, managerId: String) throws -> PointAnnotation {
        guard let coordinate = Mappers.coordinate(d["geometry"]) else { throw MapboxKitError("geometry missing") }
        var annotation: PointAnnotation
        if let id = str(d["id"]), !id.isEmpty {
            annotation = PointAnnotation(id: id, coordinate: coordinate, isSelected: false, isDraggable: bool(d["isDraggable"]) ?? false)
        } else {
            annotation = PointAnnotation(coordinate: coordinate, isSelected: false, isDraggable: bool(d["isDraggable"]) ?? false)
        }
        if let v = int(d["iconAnchor"]) { annotation.iconAnchor = iconAnchors[safe: v] }
        if let name = str(d["iconImage"]) { annotation.iconImage = name }
        // `image` sets `iconImage` to its name, so it goes after the name field.
        if let image = Mappers.imageBytes(d["image"]) {
            annotation.image = PointAnnotation.Image(image: image, name: "mapbox_kit/\(managerId)/\(annotation.id)")
        }
        annotation.iconOffset = doubles(d["iconOffset"])
        annotation.iconRotate = dbl(d["iconRotate"])
        annotation.iconSize = dbl(d["iconSize"])
        if let v = int(d["iconTextFit"]) { annotation.iconTextFit = [IconTextFit.none, .width, .height, .both][safe: v] }
        annotation.iconTextFitPadding = doubles(d["iconTextFitPadding"])
        annotation.symbolSortKey = dbl(d["symbolSortKey"])
        if let v = int(d["textAnchor"]) { annotation.textAnchor = textAnchors[safe: v] }
        annotation.textField = str(d["textField"])
        if let v = int(d["textJustify"]) { annotation.textJustify = [TextJustify.auto, .left, .center, .right][safe: v] }
        annotation.textLetterSpacing = dbl(d["textLetterSpacing"])
        annotation.textLineHeight = dbl(d["textLineHeight"])
        annotation.textMaxWidth = dbl(d["textMaxWidth"])
        annotation.textOffset = doubles(d["textOffset"])
        annotation.textRadialOffset = dbl(d["textRadialOffset"])
        annotation.textRotate = dbl(d["textRotate"])
        annotation.textSize = dbl(d["textSize"])
        if let v = int(d["textTransform"]) { annotation.textTransform = [TextTransform.none, .uppercase, .lowercase][safe: v] }
        annotation.iconColor = styleColor(d["iconColor"])
        annotation.iconEmissiveStrength = dbl(d["iconEmissiveStrength"])
        annotation.iconHaloBlur = dbl(d["iconHaloBlur"])
        annotation.iconHaloColor = styleColor(d["iconHaloColor"])
        annotation.iconHaloWidth = dbl(d["iconHaloWidth"])
        annotation.iconImageCrossFade = dbl(d["iconImageCrossFade"])
        annotation.iconOcclusionOpacity = dbl(d["iconOcclusionOpacity"])
        annotation.iconOpacity = dbl(d["iconOpacity"])
        annotation.symbolZOffset = dbl(d["symbolZOffset"])
        annotation.textColor = styleColor(d["textColor"])
        annotation.textEmissiveStrength = dbl(d["textEmissiveStrength"])
        annotation.textHaloBlur = dbl(d["textHaloBlur"])
        annotation.textHaloColor = styleColor(d["textHaloColor"])
        annotation.textHaloWidth = dbl(d["textHaloWidth"])
        annotation.textOcclusionOpacity = dbl(d["textOcclusionOpacity"])
        annotation.textOpacity = dbl(d["textOpacity"])
        if let custom = json(d["customData"]) { annotation.customData = JSONObject(turfRawValue: custom) ?? [:] }
        return annotation
    }

    private func pointJSON(_ a: PointAnnotation) -> JSON {
        var d: JSON = [
            "id": a.id,
            "geometry": Mappers.pointJSON(a.point.coordinates),
            "isDraggable": a.isDraggable,
        ]
        d["image"] = a.image?.image.pngData()?.base64EncodedString()
        d["iconAnchor"] = a.iconAnchor.flatMap { iconAnchors.firstIndex(of: $0) }
        d["iconImage"] = a.iconImage
        d["iconOffset"] = a.iconOffset
        d["iconRotate"] = a.iconRotate
        d["iconSize"] = a.iconSize
        d["iconTextFit"] = a.iconTextFit.flatMap { [IconTextFit.none, .width, .height, .both].firstIndex(of: $0) }
        d["iconTextFitPadding"] = a.iconTextFitPadding
        d["symbolSortKey"] = a.symbolSortKey
        d["textAnchor"] = a.textAnchor.flatMap { textAnchors.firstIndex(of: $0) }
        d["textField"] = a.textField
        d["textJustify"] = a.textJustify.flatMap { [TextJustify.auto, .left, .center, .right].firstIndex(of: $0) }
        d["textLetterSpacing"] = a.textLetterSpacing
        d["textLineHeight"] = a.textLineHeight
        d["textMaxWidth"] = a.textMaxWidth
        d["textOffset"] = a.textOffset
        d["textRadialOffset"] = a.textRadialOffset
        d["textRotate"] = a.textRotate
        d["textSize"] = a.textSize
        d["textTransform"] = a.textTransform.flatMap { [TextTransform.none, .uppercase, .lowercase].firstIndex(of: $0) }
        d["iconColor"] = a.iconColor?.argbValue
        d["iconEmissiveStrength"] = a.iconEmissiveStrength
        d["iconHaloBlur"] = a.iconHaloBlur
        d["iconHaloColor"] = a.iconHaloColor?.argbValue
        d["iconHaloWidth"] = a.iconHaloWidth
        d["iconImageCrossFade"] = a.iconImageCrossFade
        d["iconOcclusionOpacity"] = a.iconOcclusionOpacity
        d["iconOpacity"] = a.iconOpacity
        d["symbolZOffset"] = a.symbolZOffset
        d["textColor"] = a.textColor?.argbValue
        d["textEmissiveStrength"] = a.textEmissiveStrength
        d["textHaloBlur"] = a.textHaloBlur
        d["textHaloColor"] = a.textHaloColor?.argbValue
        d["textHaloWidth"] = a.textHaloWidth
        d["textOcclusionOpacity"] = a.textOcclusionOpacity
        d["textOpacity"] = a.textOpacity
        d["customData"] = a.customData.turfRawValue
        return d
    }

    private let iconAnchors: [IconAnchor] = [.center, .left, .right, .top, .bottom, .topLeft, .topRight, .bottomLeft, .bottomRight]
    private let textAnchors: [TextAnchor] = [.center, .left, .right, .top, .bottom, .topLeft, .topRight, .bottomLeft, .bottomRight]
    private let lineJoins: [LineJoin] = [.bevel, .round, .miter, .none]

    // MARK: - Polyline

    private func invokePolyline(_ name: String, _ a: JSON, _ reply: Reply) -> Int32 {
        let managerId = str(a["managerId"]) ?? ""
        guard let manager = polylineManagers[managerId] else {
            reply.error(code: "0", message: "No manager found with id: \(managerId)"); return 0
        }
        switch name {
        case "getAnnotations":
            reply.run { manager.annotations.map(polylineJSON) }
        case "create":
            reply.run {
                var annotation = try polylineAnnotation(json(a["annotationOption"]) ?? [:])
                configure(&annotation, managerId: managerId)
                manager.annotations.append(annotation)
                return polylineJSON(annotation)
            }
        case "createMulti":
            reply.run {
                var created: [PolylineAnnotation] = []
                for o in (a["annotationOptions"] as? [Any])?.compactMap(json) ?? [] {
                    var annotation = try polylineAnnotation(o)
                    configure(&annotation, managerId: managerId)
                    created.append(annotation)
                }
                manager.annotations.append(contentsOf: created)
                return created.map(polylineJSON)
            }
        case "update":
            reply.run {
                var annotation = try polylineAnnotation(json(a["annotation"]) ?? [:])
                configure(&annotation, managerId: managerId)
                guard let index = manager.annotations.firstIndex(where: { $0.id == annotation.id }) else {
                    throw MapboxKitError("No annotation found with id: \(annotation.id)")
                }
                manager.annotations[index] = annotation
                return nil
            }
        case "delete":
            reply.run {
                let id = str(json(a["annotation"])?["id"]) ?? ""
                manager.annotations.removeAll { $0.id == id }
                return nil
            }
        case "deleteMulti":
            reply.run {
                let ids = Set((a["annotations"] as? [Any])?.compactMap { str(json($0)?["id"]) } ?? [])
                manager.annotations.removeAll { ids.contains($0.id) }
                return nil
            }
        case "deleteAll":
            reply.run { manager.annotations = []; return nil }
        case "setProperty":
            let property = str(a["property"]) ?? ""
            if ManagerProperties.set(manager, property, Mappers.styleValue(a["value"])) { reply.success(nil); return 0 }
            return layerProperty(managerId: managerId, layerId: manager.layerId, a, reply, name)
        case "getProperty":
            let r = ManagerProperties.get(manager, str(a["property"]) ?? "")
            if r.handled { reply.success(r.value); return 0 }
            return layerProperty(managerId: managerId, layerId: manager.layerId, a, reply, name)
        default:
            return 2
        }
        return 0
    }

    private func configure(_ annotation: inout PolylineAnnotation, managerId: String) {
        let id = annotation.id
        annotation.tapHandler = { [weak self] _ in
            guard let self, let current = self.polylineManagers[managerId]?.annotations.first(where: { $0.id == id }) else { return false }
            return self.send(managerId: managerId, type: "tap", state: 2, annotation: self.polylineJSON(current))
        }
        annotation.longPressHandler = { [weak self] _ in
            guard let self, let current = self.polylineManagers[managerId]?.annotations.first(where: { $0.id == id }) else { return false }
            return self.send(managerId: managerId, type: "longPress", state: 2, annotation: self.polylineJSON(current))
        }
        annotation.dragBeginHandler = { [weak self] a, _ in
            guard let self else { return false }
            _ = self.send(managerId: managerId, type: "drag", state: 0, annotation: self.polylineJSON(a))
            return true
        }
        annotation.dragChangeHandler = { [weak self] a, _ in
            guard let self else { return }
            _ = self.send(managerId: managerId, type: "drag", state: 1, annotation: self.polylineJSON(a))
        }
        annotation.dragEndHandler = { [weak self] a, _ in
            guard let self else { return }
            _ = self.send(managerId: managerId, type: "drag", state: 2, annotation: self.polylineJSON(a))
        }
    }

    private func polylineAnnotation(_ d: JSON) throws -> PolylineAnnotation {
        guard let coordinates = Mappers.lineCoordinates(d["geometry"]) else { throw MapboxKitError("geometry missing") }
        var annotation: PolylineAnnotation
        if let id = str(d["id"]), !id.isEmpty {
            annotation = PolylineAnnotation(id: id, lineCoordinates: coordinates, isSelected: false, isDraggable: bool(d["isDraggable"]) ?? false)
        } else {
            annotation = PolylineAnnotation(lineCoordinates: coordinates, isSelected: false, isDraggable: bool(d["isDraggable"]) ?? false)
        }
        if let v = int(d["lineJoin"]) { annotation.lineJoin = lineJoins[safe: v] }
        annotation.lineSortKey = dbl(d["lineSortKey"])
        annotation.lineZOffset = dbl(d["lineZOffset"])
        annotation.lineBlur = dbl(d["lineBlur"])
        annotation.lineBorderColor = styleColor(d["lineBorderColor"])
        annotation.lineBorderWidth = dbl(d["lineBorderWidth"])
        annotation.lineColor = styleColor(d["lineColor"])
        annotation.lineEmissiveStrength = dbl(d["lineEmissiveStrength"])
        annotation.lineGapWidth = dbl(d["lineGapWidth"])
        annotation.lineOffset = dbl(d["lineOffset"])
        annotation.lineOpacity = dbl(d["lineOpacity"])
        annotation.linePattern = str(d["linePattern"])
        annotation.lineWidth = dbl(d["lineWidth"])
        if let custom = json(d["customData"]) { annotation.customData = JSONObject(turfRawValue: custom) ?? [:] }
        return annotation
    }

    private func polylineJSON(_ a: PolylineAnnotation) -> JSON {
        var d: JSON = [
            "id": a.id,
            "geometry": Mappers.lineStringJSON(a.lineString.coordinates),
            "isDraggable": a.isDraggable,
        ]
        d["lineJoin"] = a.lineJoin.flatMap { lineJoins.firstIndex(of: $0) }
        d["lineSortKey"] = a.lineSortKey
        d["lineZOffset"] = a.lineZOffset
        d["lineBlur"] = a.lineBlur
        d["lineBorderColor"] = a.lineBorderColor?.argbValue
        d["lineBorderWidth"] = a.lineBorderWidth
        d["lineColor"] = a.lineColor?.argbValue
        d["lineEmissiveStrength"] = a.lineEmissiveStrength
        d["lineGapWidth"] = a.lineGapWidth
        d["lineOffset"] = a.lineOffset
        d["lineOpacity"] = a.lineOpacity
        d["linePattern"] = a.linePattern
        d["lineWidth"] = a.lineWidth
        d["customData"] = a.customData.turfRawValue
        return d
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
