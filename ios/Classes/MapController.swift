// One hosted map: routes the map#/style#/... calls and owns the streams.

import Foundation
import UIKit
import CoreLocation
@_spi(Experimental) import MapboxMaps

final class MapController {
    let mapView: MapView
    let mapboxMap: MapboxMap
    let viewId: Int64

    private var cameraAnimation: Cancelable?
    private var eventCancelables = Set<AnyCancelable>()
    private var eventsToken: Int64 = 0
    private var gesturesToken: Int64 = 0
    private var gestureCancelables = Set<AnyCancelable>()
    private var gestureTargetsInstalled = false
    private var gestureReply: Reply?

    lazy var style = StyleHandler(map: self)
    lazy var settings = SettingsHandler(map: self)
    lazy var annotations = AnnotationHandler(map: self)

    init(mapView: MapView, viewId: Int64) {
        self.mapView = mapView
        self.mapboxMap = mapView.mapboxMap
        self.viewId = viewId
    }

    func dispose() {
        cancelAllStreams()
        cameraAnimation?.cancel()
    }

    // MARK: - Streams

    func listen(token: Int64, channel: String, arguments: JSON, reply: Reply) -> Int32 {
        switch channel {
        case "map#events":
            if eventsToken != 0 { cancelStream(token: eventsToken) }
            eventsToken = token
            let types = (arguments["eventTypes"] as? [Any])?.compactMap(int) ?? []
            subscribeEvents(types: types) { reply.success($0) }
            // Replay whatever fired between map creation and this listen.
            let buffered = pendingEvents
            pendingEvents.removeAll()
            for event in buffered where types.contains((event["type"] as? Int) ?? -1) { reply.success(event) }
        case "map#gestures":
            if gesturesToken != 0 { cancelStream(token: gesturesToken) }
            gesturesToken = token
            gestureReply = reply
            installGestureListeners()
        case "annotation#interactions":
            guard let managerId = str(arguments["managerId"]) else {
                reply.error(code: "ARGS", message: "managerId missing")
                return 0
            }
            annotations.listen(token: token, managerId: managerId, reply: reply)
        default:
            return 2
        }
        return 0
    }

    func cancelStream(token: Int64) {
        if token == eventsToken {
            eventCancelables.removeAll()
            eventsToken = 0
        } else if token == gesturesToken {
            removeGestureListeners()
            gesturesToken = 0
            gestureReply = nil
        } else {
            annotations.cancel(token: token)
        }
        MapboxKitPlugin.shared.unregisterStream(token: token)
    }

    func cancelAllStreams() {
        if eventsToken != 0 { cancelStream(token: eventsToken) }
        if gesturesToken != 0 { cancelStream(token: gesturesToken) }
        annotations.cancelAll()
    }

    // MARK: - Events (indices match Dart _MapEvent)

    /// Events that fired before Dart listened on `map#events` (bounded).
    private var pendingEvents: [JSON] = []

    /// Subscribes at map creation (event types come with INIT) and buffers
    /// events until the Dart stream attaches, so an early styleLoaded on a
    /// slow launch is not lost.
    func presubscribe(types: [Int]) {
        subscribeEvents(types: types) { [weak self] event in
            guard let self = self, self.pendingEvents.count < 256 else { return }
            self.pendingEvents.append(event)
        }
    }

    private func subscribeEvents(types: [Int], emit: @escaping (JSON) -> Void) {
        eventCancelables.removeAll()
        func send(_ type: Int, _ data: JSON) {
            emit(["type": type, "data": data])
        }
        func interval(_ i: EventTimeInterval) -> JSON {
            ["begin": i.begin.micros, "end": i.end.micros]
        }
        for type in types {
            switch type {
            case 0:
                mapboxMap.onMapLoaded.observe { send(0, ["timeInterval": interval($0.timeInterval)]) }.store(in: &eventCancelables)
            case 1:
                mapboxMap.onMapLoadingError.observe { e in
                    send(1, ["type": e.type.rawValue, "message": e.message, "sourceId": e.sourceId as Any,
                             "tileId": e.tileId.map { ["x": $0.x, "y": $0.y, "z": $0.z] } as Any,
                             "timestamp": e.timestamp.micros])
                }.store(in: &eventCancelables)
            case 2:
                mapboxMap.onStyleLoaded.observe { send(2, ["timeInterval": interval($0.timeInterval)]) }.store(in: &eventCancelables)
            case 3:
                mapboxMap.onStyleDataLoaded.observe { send(3, ["type": $0.type.rawValue, "timeInterval": interval($0.timeInterval)]) }.store(in: &eventCancelables)
            case 4:
                mapboxMap.onCameraChanged.observe { send(4, ["timestamp": $0.timestamp.micros, "cameraState": Mappers.cameraStateJSON($0.cameraState)]) }.store(in: &eventCancelables)
            case 5:
                mapboxMap.onMapIdle.observe { send(5, ["timestamp": $0.timestamp.micros]) }.store(in: &eventCancelables)
            case 6:
                mapboxMap.onSourceAdded.observe { send(6, ["sourceId": $0.sourceId, "timestamp": $0.timestamp.micros]) }.store(in: &eventCancelables)
            case 7:
                mapboxMap.onSourceRemoved.observe { send(7, ["sourceId": $0.sourceId, "timestamp": $0.timestamp.micros]) }.store(in: &eventCancelables)
            case 8:
                mapboxMap.onSourceDataLoaded.observe { e in
                    send(8, ["sourceId": e.sourceId, "type": e.type.rawValue, "loaded": e.loaded as Any,
                             "tileId": e.tileId.map { ["x": $0.x, "y": $0.y, "z": $0.z] } as Any,
                             "dataId": e.dataId as Any, "timeInterval": interval(e.timeInterval)])
                }.store(in: &eventCancelables)
            case 9:
                mapboxMap.onStyleImageMissing.observe { send(9, ["imageId": $0.imageId, "timestamp": $0.timestamp.micros]) }.store(in: &eventCancelables)
            case 10:
                mapboxMap.onStyleImageRemoveUnused.observe { send(10, ["imageId": $0.imageId, "timestamp": $0.timestamp.micros]) }.store(in: &eventCancelables)
            case 11:
                mapboxMap.onRenderFrameStarted.observe { send(11, ["timestamp": $0.timestamp.micros]) }.store(in: &eventCancelables)
            case 12:
                mapboxMap.onRenderFrameFinished.observe { e in
                    send(12, ["renderMode": e.renderMode.rawValue, "timeInterval": interval(e.timeInterval),
                              "needsRepaint": e.needsRepaint, "placementChanged": e.placementChanged])
                }.store(in: &eventCancelables)
            case 13:
                mapboxMap.onResourceRequest.observe { e in
                    var response: JSON? = nil
                    if let r = e.response {
                        response = ["noContent": r.noContent, "notModified": r.notModified, "mustRevalidate": r.mustRevalidate,
                                    "source": r.source.rawValue, "size": r.size,
                                    "modified": r.modified?.micros as Any, "expires": r.expires?.micros as Any,
                                    "etag": r.etag as Any,
                                    "error": r.error.map { ["reason": $0.reason.rawValue, "message": $0.message] } as Any]
                    }
                    send(13, ["source": e.source.rawValue,
                              "request": ["url": e.request.url, "resource": e.request.resource.rawValue,
                                          "priority": e.request.priority.rawValue,
                                          "loadingMethod": e.request.loadingMethod.map(\.rawValue)],
                              "response": response as Any, "cancelled": e.cancelled,
                              "timeInterval": interval(e.timeInterval)])
                }.store(in: &eventCancelables)
            default:
                break
            }
        }
    }

    // MARK: - Gestures

    private func sendGesture(_ type: String, point: CGPoint, state: Int) {
        guard let reply = gestureReply else { return }
        let coordinate = mapboxMap.coordinate(for: point)
        reply.success(["type": type, "context": Mappers.gestureContextJSON(point: point, coordinate: coordinate, state: state)])
    }

    @objc private func onMapPan(_ sender: UIPanGestureRecognizer) {
        guard sender.state == .began || sender.state == .changed || sender.state == .ended else { return }
        sendGesture("scroll", point: sender.location(in: mapView), state: Mappers.gestureState(sender.state))
    }

    @objc private func onMapZoomGesture(_ sender: UIGestureRecognizer) {
        guard sender.state == .began || sender.state == .changed || sender.state == .ended else { return }
        sendGesture("zoom", point: sender.location(in: mapView), state: Mappers.gestureState(sender.state))
    }

    @objc private func onMapDoubleTapZoom(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }
        sendGesture("zoom", point: sender.location(in: mapView), state: 2)
    }

    private func installGestureListeners() {
        removeGestureListeners()
        guard let gestures = mapView.gestures else { return }
        gestures.panGestureRecognizer.addTarget(self, action: #selector(onMapPan))
        gestures.quickZoomGestureRecognizer.addTarget(self, action: #selector(onMapZoomGesture))
        gestures.pinchGestureRecognizer.addTarget(self, action: #selector(onMapZoomGesture))
        gestures.doubleTapToZoomInGestureRecognizer.addTarget(self, action: #selector(onMapDoubleTapZoom))
        gestures.doubleTouchToZoomOutGestureRecognizer.addTarget(self, action: #selector(onMapDoubleTapZoom))
        gestureTargetsInstalled = true
        gestures.onMapTap.observe { [weak self] context in
            self?.gestureReply?.success(["type": "tap", "context": Mappers.gestureContextJSON(point: context.point, coordinate: context.coordinate, state: 2)])
        }.store(in: &gestureCancelables)
        gestures.onMapLongPress.observe { [weak self] context in
            self?.gestureReply?.success(["type": "longTap", "context": Mappers.gestureContextJSON(point: context.point, coordinate: context.coordinate, state: 2)])
        }.store(in: &gestureCancelables)
    }

    private func removeGestureListeners() {
        gestureCancelables.removeAll()
        guard gestureTargetsInstalled, let gestures = mapView.gestures else { return }
        gestures.panGestureRecognizer.removeTarget(self, action: nil)
        gestures.quickZoomGestureRecognizer.removeTarget(self, action: nil)
        gestures.pinchGestureRecognizer.removeTarget(self, action: nil)
        gestures.doubleTapToZoomInGestureRecognizer.removeTarget(self, action: nil)
        gestures.doubleTouchToZoomOutGestureRecognizer.removeTarget(self, action: nil)
        gestureTargetsInstalled = false
    }

    // MARK: - Calls

    /// Returns 0 when accepted, 2 for an unknown method.
    func invoke(method: String, arguments args: JSON, reply: Reply) -> Int32 {
        let parts = method.split(separator: "#", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return 2 }
        let (group, name) = (parts[0], parts[1])
        switch group {
        case "map": return invokeMap(name, args, reply)
        case "style": return style.invoke(name, args, reply)
        case "location", "gestures", "logo", "compass", "scaleBar", "attribution":
            return settings.invoke(group: group, name, args, reply)
        case "annotation", "pointAnnotation", "polylineAnnotation":
            return annotations.invoke(group: group, name, args, reply)
        default: return 2
        }
    }

    private func invokeMap(_ name: String, _ a: JSON, _ reply: Reply) -> Int32 {
        switch name {
        // Camera
        case "cameraForCoordinatesPadding":
            reply.run {
                let camera = try mapboxMap.camera(
                    for: Mappers.coordinates(a["coordinates"]),
                    camera: Mappers.cameraOptions(json(a["camera"]) ?? [:]),
                    coordinatesPadding: Mappers.insets(a["coordinatesPadding"]),
                    maxZoom: dbl(a["maxZoom"]),
                    offset: Mappers.point(a["offset"]))
                return Mappers.cameraOptionsJSON(camera)
            }
        case "cameraForCoordinateBounds":
            reply.run {
                guard let bounds = Mappers.coordinateBounds(a["bounds"]) else { throw MapboxKitError("bounds missing") }
                let camera = mapboxMap.camera(for: bounds, padding: Mappers.insets(a["padding"]),
                                              bearing: dbl(a["bearing"]), pitch: dbl(a["pitch"]),
                                              maxZoom: dbl(a["maxZoom"]), offset: Mappers.point(a["offset"]))
                return Mappers.cameraOptionsJSON(camera)
            }
        case "cameraForCoordinates":
            reply.run {
                let camera = mapboxMap.camera(for: Mappers.coordinates(a["coordinates"]),
                                              padding: Mappers.insets(a["padding"]),
                                              bearing: dbl(a["bearing"]), pitch: dbl(a["pitch"]))
                return Mappers.cameraOptionsJSON(camera)
            }
        case "cameraForCoordinatesCameraOptions":
            reply.run {
                guard let rect = Mappers.rect(a["box"]) else { throw MapboxKitError("box missing") }
                let camera = mapboxMap.camera(for: Mappers.coordinates(a["coordinates"]),
                                              camera: Mappers.cameraOptions(json(a["camera"]) ?? [:]),
                                              rect: rect)
                return Mappers.cameraOptionsJSON(camera)
            }
        case "cameraForGeometry":
            reply.run {
                guard let geometry = Mappers.geometry(a["geometry"]) else { throw MapboxKitError("geometry invalid") }
                let camera = mapboxMap.camera(for: geometry,
                                              padding: Mappers.insets(a["padding"]) ?? .zero,
                                              bearing: dbl(a["bearing"]).map { CGFloat($0) },
                                              pitch: dbl(a["pitch"]).map { CGFloat($0) })
                return Mappers.cameraOptionsJSON(camera)
            }
        case "coordinateBoundsForCamera", "coordinateBoundsForCameraUnwrapped":
            reply.run {
                Mappers.coordinateBoundsJSON(mapboxMap.coordinateBounds(for: Mappers.cameraOptions(json(a["camera"]) ?? [:])))
            }
        case "coordinateBoundsZoomForCamera":
            reply.run {
                let r = mapboxMap.coordinateBoundsZoom(for: Mappers.cameraOptions(json(a["camera"]) ?? [:]))
                return ["bounds": Mappers.coordinateBoundsJSON(r.bounds), "zoom": r.zoom]
            }
        case "coordinateBoundsZoomForCameraUnwrapped":
            reply.run {
                let r = mapboxMap.coordinateBoundsZoomUnwrapped(for: Mappers.cameraOptions(json(a["camera"]) ?? [:]))
                return ["bounds": Mappers.coordinateBoundsJSON(r.bounds), "zoom": r.zoom]
            }
        case "pixelForCoordinate":
            reply.run {
                guard let c = Mappers.coordinate(a["coordinate"]) else { throw MapboxKitError("coordinate missing") }
                return Mappers.pointJSON(mapboxMap.point(for: c))
            }
        case "coordinateForPixel":
            reply.run {
                guard let p = Mappers.point(a["pixel"]) else { throw MapboxKitError("pixel missing") }
                return Mappers.pointJSON(mapboxMap.coordinate(for: p))
            }
        case "pixelsForCoordinates":
            reply.run { mapboxMap.points(for: Mappers.coordinates(a["coordinates"])).map(Mappers.pointJSON) }
        case "coordinatesForPixels":
            reply.run {
                let points = (a["pixels"] as? [Any])?.compactMap(Mappers.point) ?? []
                return mapboxMap.coordinates(for: points).map(Mappers.pointJSON)
            }
        case "setCamera":
            reply.run { mapboxMap.setCamera(to: Mappers.cameraOptions(json(a["cameraOptions"]) ?? [:])); return nil }
        case "getCameraState":
            reply.run { Mappers.cameraStateJSON(mapboxMap.cameraState) }
        case "setBounds":
            reply.run { try mapboxMap.setCameraBounds(with: Mappers.cameraBoundsOptions(json(a["options"]) ?? [:])); return nil }
        case "getBounds":
            reply.run { Mappers.cameraBoundsJSON(mapboxMap.cameraBounds) }

        // Animation
        case "easeTo":
            reply.run {
                cameraAnimation = mapView.camera.ease(to: Mappers.cameraOptions(json(a["cameraOptions"]) ?? [:]),
                                                     duration: Mappers.animationDuration(a["mapAnimationOptions"]))
                return nil
            }
        case "flyTo":
            reply.run {
                cameraAnimation = mapView.camera.fly(to: Mappers.cameraOptions(json(a["cameraOptions"]) ?? [:]),
                                                    duration: Mappers.animationDuration(a["mapAnimationOptions"]))
                return nil
            }
        case "pitchBy", "scaleBy", "moveBy", "rotateBy":
            reply.error(code: "0", message: "Not available on iOS.")
        case "cancelCameraAnimation":
            reply.run { cameraAnimation?.cancel(); return nil }

        // Map interface
        case "loadStyleURI":
            guard let uri = str(a["styleURI"]), let styleURI = StyleURI(rawValue: uri) else {
                reply.error(code: "loadStyleUriError", message: "Invalid style URI"); return 0
            }
            mapboxMap.loadStyle(styleURI) { error in
                if let error { reply.error(error, code: "loadStyleUriError") } else { reply.success(nil) }
            }
        case "loadStyleJson":
            mapboxMap.loadStyle(str(a["styleJson"]) ?? "{}") { error in
                if let error { reply.error(error, code: "loadStyleUriError") } else { reply.success(nil) }
            }
        case "clearData":
            MapboxMap.clearData { error in
                if let error { reply.error(error, code: "clearDataError") } else { reply.success(nil) }
            }
        case "setTileCacheBudget":
            reply.run {
                if let mb = json(a["tileCacheBudgetInMegabytes"]), let size = int64(mb["size"]) {
                    mapboxMap.setTileCacheBudget(TileCacheBudget.fromTileCacheBudget(TileCacheBudgetInMegabytes(size: UInt64(size))))
                } else if let tiles = json(a["tileCacheBudgetInTiles"]), let size = int64(tiles["size"]) {
                    mapboxMap.setTileCacheBudget(TileCacheBudget.fromTileCacheBudget(TileCacheBudgetInTiles(size: UInt64(size))))
                }
                return nil
            }
        case "getSize":
            reply.run { Mappers.sizeJSON(mapView.bounds.size) }
        case "triggerRepaint":
            reply.run { mapboxMap.triggerRepaint(); return nil }
        case "setGestureInProgress":
            reply.run { if bool(a["inProgress"]) == true { mapboxMap.beginGesture() } else { mapboxMap.endGesture() }; return nil }
        case "isGestureInProgress":
            reply.run { mapboxMap.isGestureInProgress }
        case "setUserAnimationInProgress":
            reply.run { if bool(a["inProgress"]) == true { mapboxMap.beginAnimation() } else { mapboxMap.endAnimation() }; return nil }
        case "isUserAnimationInProgress":
            reply.run { mapboxMap.isAnimationInProgress }
        case "setPrefetchZoomDelta":
            reply.run { mapboxMap.prefetchZoomDelta = UInt8(clamping: int(a["delta"]) ?? 4); return nil }
        case "getPrefetchZoomDelta":
            reply.run { Int(mapboxMap.prefetchZoomDelta) }
        case "setNorthOrientation":
            reply.run {
                let o: NorthOrientation = [.upwards, .rightwards, .downwards, .leftwards][max(0, min(3, int(a["orientation"]) ?? 0))]
                mapboxMap.setNorthOrientation(o); return nil
            }
        case "setConstrainMode":
            reply.run {
                let m: ConstrainMode = [.none, .heightOnly, .widthAndHeight][max(0, min(2, int(a["mode"]) ?? 1))]
                mapboxMap.setConstrainMode(m); return nil
            }
        case "setViewportMode":
            reply.run { mapboxMap.setViewportMode(int(a["mode"]) == 1 ? .flippedY : .default); return nil }
        case "getMapOptions":
            reply.run { Mappers.mapOptionsJSON(mapboxMap.options) }
        case "styleGlyphURL":
            reply.run { mapboxMap.styleGlyphURL }
        case "setStyleGlyphURL":
            reply.run { mapboxMap.styleGlyphURL = str(a["glyphURL"]) ?? ""; return nil }
        case "getDebugOptions":
            reply.run {
                let all: [(MapViewDebugOptions, Int)] = [(.tileBorders, 0), (.parseStatus, 1), (.timestamps, 2), (.collision, 3),
                                                        (.overdraw, 4), (.stencilClip, 5), (.depthBuffer, 6), (.modelBounds, 7),
                                                        (.light, 11), (.camera, 12), (.padding, 13)]
                return all.filter { mapView.debugOptions.contains($0.0) }.map { $0.1 }
            }
        case "setDebugOptions":
            reply.run {
                var options: MapViewDebugOptions = []
                for i in (a["debugOptions"] as? [Any])?.compactMap(int) ?? [] {
                    switch i {
                    case 0: options.insert(.tileBorders)
                    case 1: options.insert(.parseStatus)
                    case 2: options.insert(.timestamps)
                    case 3: options.insert(.collision)
                    case 4: options.insert(.overdraw)
                    case 5: options.insert(.stencilClip)
                    case 6: options.insert(.depthBuffer)
                    case 7: options.insert(.modelBounds)
                    case 11: options.insert(.light)
                    case 12: options.insert(.camera)
                    case 13: options.insert(.padding)
                    default: break
                    }
                }
                mapView.debugOptions = options
                return nil
            }
        case "queryRenderedFeatures":
            queryRenderedFeatures(a, reply)
        case "querySourceFeatures":
            do {
                let options = json(a["options"]) ?? [:]
                let filter = str(options["filter"]).flatMap { try? JSONDecoder().decode(Exp.self, from: $0.data(using: .utf8)!) }
                let query = SourceQueryOptions(sourceLayerIds: strings(options["sourceLayerIds"]), filter: filter as Any)
                try mapboxMap.querySourceFeatures(for: str(a["sourceId"]) ?? "", options: query) { result in
                    switch result {
                    case .success(let features):
                        reply.success(features.map { ["queriedFeature": Mappers.queriedFeatureJSON($0.queriedFeature)] })
                    case .failure(let error):
                        reply.error(error)
                    }
                }
            } catch {
                reply.error(error)
            }
        case "getGeoJsonClusterLeaves", "getGeoJsonClusterChildren", "getGeoJsonClusterExpansionZoom":
            guard let feature = Mappers.feature(a["cluster"]) else {
                reply.error(code: "0", message: "Feature format error"); return 0
            }
            let sourceId = str(a["sourceIdentifier"]) ?? ""
            let completion: (Result<FeatureExtensionValue, Error>) -> Void = { result in
                switch result {
                case .success(let v):
                    reply.success(["value": v.value.map { String(describing: $0) } as Any,
                                   "featureCollection": v.features?.map(Mappers.featureJSON) as Any])
                case .failure(let error):
                    reply.error(error)
                }
            }
            if name == "getGeoJsonClusterLeaves" {
                mapboxMap.getGeoJsonClusterLeaves(forSourceId: sourceId, feature: feature,
                                                  limit: UInt64(int(a["limit"]) ?? 10), offset: UInt64(int(a["offset"]) ?? 0),
                                                  completion: completion)
            } else if name == "getGeoJsonClusterChildren" {
                mapboxMap.getGeoJsonClusterChildren(forSourceId: sourceId, feature: feature, completion: completion)
            } else {
                mapboxMap.getGeoJsonClusterExpansionZoom(forSourceId: sourceId, feature: feature, completion: completion)
            }
        case "setFeatureState":
            mapboxMap.setFeatureState(sourceId: str(a["sourceId"]) ?? "", sourceLayerId: str(a["sourceLayerId"]),
                                      featureId: str(a["featureId"]) ?? "", state: jsonDict(str(a["state"]))) { result in
                switch result {
                case .success: reply.success(nil)
                case .failure(let error): reply.error(error)
                }
            }
        case "getFeatureState":
            mapboxMap.getFeatureState(sourceId: str(a["sourceId"]) ?? "", sourceLayerId: str(a["sourceLayerId"]),
                                      featureId: str(a["featureId"]) ?? "") { result in
                switch result {
                case .success(let map): reply.success(jsonString(map))
                case .failure(let error): reply.error(error)
                }
            }
        case "removeFeatureState":
            mapboxMap.removeFeatureState(sourceId: str(a["sourceId"]) ?? "", sourceLayerId: str(a["sourceLayerId"]),
                                         featureId: str(a["featureId"]) ?? "", stateKey: str(a["stateKey"])) { result in
                switch result {
                case .success: reply.success(nil)
                case .failure(let error): reply.error(error)
                }
            }
        case "reduceMemoryUse":
            reply.run { mapboxMap.reduceMemoryUse(); return nil }
        case "getElevation":
            reply.run {
                guard let c = Mappers.coordinate(a["coordinate"]) else { throw MapboxKitError("coordinate missing") }
                return mapboxMap.elevation(at: c)
            }
        case "tileCover":
            reply.run {
                let o = json(a["options"]) ?? [:]
                let options = TileCoverOptions(tileSize: int(o["tileSize"]).map { UInt16($0) },
                                               minZoom: int(o["minZoom"]).map { UInt8($0) },
                                               maxZoom: int(o["maxZoom"]).map { UInt8($0) },
                                               roundZoom: bool(o["roundZoom"]))
                return mapboxMap.tileCover(for: options).map { Mappers.canonicalTileIDJSON($0.canonical) }
            }
        case "snapshot":
            reply.run {
                let image = try mapView.snapshot()
                guard let png = image.pngData() else { throw MapboxKitError("Could not encode snapshot") }
                return png.base64EncodedString()
            }
        default:
            return 2
        }
        return 0
    }

    private func queryRenderedFeatures(_ a: JSON, _ reply: Reply) {
        let geometry = json(a["geometry"]) ?? [:]
        let options = json(a["options"]) ?? [:]
        let filter = str(options["filter"]).flatMap { try? JSONDecoder().decode(Exp.self, from: $0.data(using: .utf8)!) }
        let queryOptions = RenderedQueryOptions(layerIds: strings(options["layerIds"]), filter: filter)
        let value = str(geometry["value"]) ?? ""
        let completion: (Result<[QueriedRenderedFeature], Error>) -> Void = { result in
            switch result {
            case .success(let features):
                reply.success(features.map { ["queriedFeature": Mappers.queriedFeatureJSON($0.queriedFeature), "layers": $0.layers] })
            case .failure(let error):
                reply.error(error)
            }
        }
        switch int(geometry["type"]) {
        case 0:
            guard let rect = Mappers.rect(parseJSON(value)) else { reply.error(code: "0", message: "Geometry format error"); return }
            mapboxMap.queryRenderedFeatures(with: rect, options: queryOptions, completion: completion)
        case 1:
            guard let point = Mappers.point(parseJSON(value)) else { reply.error(code: "0", message: "Geometry format error"); return }
            mapboxMap.queryRenderedFeatures(with: point, options: queryOptions, completion: completion)
        default:
            let points = (parseJSON(value) as? [Any])?.compactMap(Mappers.point) ?? []
            mapboxMap.queryRenderedFeatures(with: points, options: queryOptions, completion: completion)
        }
    }
}

extension Date {
    var micros: Int64 { Int64((timeIntervalSince1970 * 1_000_000).rounded()) }
}
