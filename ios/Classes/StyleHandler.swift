// style#... calls, ported from mapbox_maps_flutter's StyleController.

import Foundation
import UIKit
@_spi(Experimental) import MapboxMaps

final class StyleHandler {
    private unowned let map: MapController
    private var style: MapboxMap { map.mapboxMap }

    init(map: MapController) { self.map = map }

    func invoke(_ name: String, _ a: JSON, _ reply: Reply) -> Int32 {
        switch name {
        case "getStyleURI":
            reply.run { style.styleURI?.rawValue ?? "" }
        case "setStyleURI":
            guard let uri = str(a["uri"]), let styleURI = StyleURI(rawValue: uri) else {
                reply.error(code: "0", message: "Invalid style uri"); return 0
            }
            style.load(mapStyle: MapStyle(uri: styleURI)) { error in
                if let error { reply.error(error) } else { reply.success(nil) }
            }
        case "getStyleJSON":
            reply.run { style.styleJSON }
        case "setStyleJSON":
            style.load(mapStyle: MapStyle(json: str(a["json"]) ?? "{}")) { error in
                if let error { reply.error(error) } else { reply.success(nil) }
            }
        case "getStyleDefaultCamera":
            reply.run { Mappers.cameraOptionsJSON(style.styleDefaultCamera) }
        case "getStyleTransition":
            reply.run { Mappers.transitionOptionsJSON(style.styleTransition) }
        case "setStyleTransition":
            reply.run { style.styleTransition = Mappers.transitionOptions(json(a["transitionOptions"]) ?? [:]); return nil }

        // Imports
        case "addStyleImportFromJSON":
            reply.run {
                try style.addStyleImport(withId: str(a["importId"]) ?? "", json: str(a["json"]) ?? "{}",
                                         config: json(a["config"]), importPosition: Mappers.importPosition(a["importPosition"]))
                return nil
            }
        case "addStyleImportFromURI":
            reply.run {
                guard let uri = str(a["uri"]), let styleURI = StyleURI(rawValue: uri) else { throw MapboxKitError("Incorrect Style URI") }
                try style.addStyleImport(withId: str(a["importId"]) ?? "", uri: styleURI,
                                         config: json(a["config"]), importPosition: Mappers.importPosition(a["importPosition"]))
                return nil
            }
        case "updateStyleImportWithJSON":
            reply.run {
                try style.updateStyleImport(withId: str(a["importId"]) ?? "", json: str(a["json"]) ?? "{}", config: json(a["config"]))
                return nil
            }
        case "updateStyleImportWithURI":
            reply.run {
                guard let uri = str(a["uri"]), let styleURI = StyleURI(rawValue: uri) else { throw MapboxKitError("Incorrect Style URI") }
                try style.updateStyleImport(withId: str(a["importId"]) ?? "", uri: styleURI, config: json(a["config"]))
                return nil
            }
        case "moveStyleImport":
            reply.run {
                try style.moveStyleImport(withId: str(a["importId"]) ?? "", to: Mappers.importPosition(a["importPosition"]) ?? .default)
                return nil
            }
        case "getStyleImports":
            reply.run { style.styleImports.map { Mappers.infoJSON(id: $0.id, type: $0.type) } }
        case "removeStyleImport":
            reply.run { try style.removeStyleImport(withId: str(a["importId"]) ?? ""); return nil }
        case "getStyleImportSchema":
            reply.run { try style.getStyleImportSchema(for: str(a["importId"]) ?? "") }
        case "getStyleImportConfigProperties":
            reply.run {
                let props = try style.getStyleImportConfigProperties(for: str(a["importId"]) ?? "")
                return props.mapValues(Mappers.stylePropertyValueJSON)
            }
        case "getStyleImportConfigProperty":
            reply.run {
                Mappers.stylePropertyValueJSON(try style.getStyleImportConfigProperty(for: str(a["importId"]) ?? "", config: str(a["config"]) ?? ""))
            }
        case "setStyleImportConfigProperties":
            reply.run { try style.setStyleImportConfigProperties(for: str(a["importId"]) ?? "", configs: json(a["configs"]) ?? [:]); return nil }
        case "setStyleImportConfigProperty":
            reply.run {
                try style.setStyleImportConfigProperty(for: str(a["importId"]) ?? "", config: str(a["config"]) ?? "",
                                                       value: Mappers.styleValue(a["value"]))
                return nil
            }

        // Layers
        case "addStyleLayer":
            reply.run { try style.addLayer(with: jsonDict(str(a["properties"])), layerPosition: Mappers.layerPosition(a["layerPosition"])); return nil }
        case "addPersistentStyleLayer":
            reply.run { try style.addPersistentLayer(with: jsonDict(str(a["properties"])), layerPosition: Mappers.layerPosition(a["layerPosition"])); return nil }
        case "isStyleLayerPersistent":
            reply.run { try style.isPersistentLayer(id: str(a["layerId"]) ?? "") }
        case "removeStyleLayer":
            reply.run { try style.removeLayer(withId: str(a["layerId"]) ?? ""); return nil }
        case "moveStyleLayer":
            reply.run { try style.moveLayer(withId: str(a["layerId"]) ?? "", to: Mappers.layerPosition(a["layerPosition"]) ?? .default); return nil }
        case "styleLayerExists":
            reply.run { style.layerExists(withId: str(a["layerId"]) ?? "") }
        case "getStyleLayers":
            reply.run { style.allLayerIdentifiers.map { Mappers.infoJSON(id: $0.id, type: $0.type.rawValue) } }
        case "getStyleLayerProperty":
            reply.run { Mappers.stylePropertyValueJSON(style.layerProperty(for: str(a["layerId"]) ?? "", property: str(a["property"]) ?? "")) }
        case "setStyleLayerProperty":
            reply.run {
                try style.setLayerProperty(for: str(a["layerId"]) ?? "", property: str(a["property"]) ?? "", value: Mappers.styleValue(a["value"]))
                return nil
            }
        case "getStyleLayerProperties":
            reply.run { jsonString(try style.layerProperties(for: str(a["layerId"]) ?? "")) }
        case "setStyleLayerProperties":
            reply.run { try style.setLayerProperties(for: str(a["layerId"]) ?? "", properties: jsonDict(str(a["properties"]))); return nil }

        // Sources
        case "addStyleSource":
            reply.run { try style.addSource(withId: str(a["sourceId"]) ?? "", properties: jsonDict(str(a["properties"]))); return nil }
        case "getStyleSourceProperty":
            reply.run { Mappers.stylePropertyValueJSON(style.sourceProperty(for: str(a["sourceId"]) ?? "", property: str(a["property"]) ?? "")) }
        case "setStyleSourceProperty":
            reply.run {
                try style.setSourceProperty(for: str(a["sourceId"]) ?? "", property: str(a["property"]) ?? "", value: Mappers.styleValue(a["value"]))
                return nil
            }
        case "getStyleSourceProperties":
            reply.run { jsonString(try style.sourceProperties(for: str(a["sourceId"]) ?? "")) }
        case "setStyleSourceProperties":
            reply.run { try style.setSourceProperties(for: str(a["sourceId"]) ?? "", properties: jsonDict(str(a["properties"]))); return nil }
        case "addGeoJSONSourceFeatures":
            reply.run {
                let features = (a["features"] as? [Any])?.compactMap(Mappers.feature) ?? []
                style.addGeoJSONSourceFeatures(forSourceId: str(a["sourceId"]) ?? "", features: features, dataId: str(a["dataId"]))
                return nil
            }
        case "updateGeoJSONSourceFeatures":
            reply.run {
                let features = (a["features"] as? [Any])?.compactMap(Mappers.feature) ?? []
                style.updateGeoJSONSourceFeatures(forSourceId: str(a["sourceId"]) ?? "", features: features, dataId: str(a["dataId"]))
                return nil
            }
        case "removeGeoJSONSourceFeatures":
            reply.run {
                style.removeGeoJSONSourceFeatures(forSourceId: str(a["sourceId"]) ?? "", featureIds: strings(a["featureIds"]) ?? [], dataId: str(a["dataId"]))
                return nil
            }
        case "updateStyleImageSourceImage":
            reply.run {
                guard let image = Mappers.image(a["image"]) else { throw MapboxKitError("Could not decode the image data.") }
                try style.updateImageSource(withId: str(a["sourceId"]) ?? "", image: image)
                return nil
            }
        case "removeStyleSource":
            reply.run { try style.removeSource(withId: str(a["sourceId"]) ?? ""); return nil }
        case "styleSourceExists":
            reply.run { style.sourceExists(withId: str(a["sourceId"]) ?? "") }
        case "getStyleSources":
            reply.run { style.allSourceIdentifiers.map { Mappers.infoJSON(id: $0.id, type: $0.type.rawValue) } }

        // Lights
        case "getStyleLights":
            reply.run { style.allLightIdentifiers.map { Mappers.infoJSON(id: $0.id, type: $0.type.rawValue) } }
        case "setLight":
            reply.run { try style.setLights(flatLight(json(a["flatLight"]) ?? [:])); return nil }
        case "setLights":
            reply.run {
                try style.setLights(ambient: ambientLight(json(a["ambientLight"]) ?? [:]),
                                    directional: directionalLight(json(a["directionalLight"]) ?? [:]))
                return nil
            }
        case "getStyleLightProperty":
            reply.run {
                let property = str(a["property"]) ?? ""
                let value = style.lightProperty(for: str(a["id"]) ?? "", property: property)
                return ["value": value ?? NSNull(), "kind": property.hasSuffix("transition") ? 3 : 1]
            }
        case "setStyleLightProperty":
            reply.run {
                try style.setLightProperty(for: str(a["id"]) ?? "", property: str(a["property"]) ?? "", value: Mappers.styleValue(a["value"]))
                return nil
            }

        // Terrain
        case "setStyleTerrain":
            reply.run { try style.setTerrain(properties: jsonDict(str(a["properties"]))); return nil }
        case "getStyleTerrainProperty":
            reply.run { Mappers.stylePropertyValueJSON(style.terrainProperty(str(a["property"]) ?? "")) }
        case "setStyleTerrainProperty":
            reply.run { try style.setTerrainProperty(str(a["property"]) ?? "", value: Mappers.styleValue(a["value"])); return nil }

        // Images
        case "getStyleImage":
            reply.run { style.image(withId: str(a["imageId"]) ?? "").flatMap(Mappers.imageJSON) }
        case "addStyleImage":
            reply.run {
                let scale = CGFloat(dbl(a["scale"]) ?? Double(UIScreen.main.scale))
                guard let image = Mappers.image(a["image"], scale: scale) else { throw MapboxKitError("Could not decode the image data.") }
                let stretches: (Any?) -> [ImageStretches] = { v in
                    (v as? [Any])?.compactMap(json).map { ImageStretches(first: Float(dbl($0["first"]) ?? 0), second: Float(dbl($0["second"]) ?? 0)) } ?? []
                }
                let content: ImageContent? = json(a["content"]).map {
                    ImageContent(left: Float(dbl($0["left"]) ?? 0), top: Float(dbl($0["top"]) ?? 0),
                                 right: Float(dbl($0["right"]) ?? 0), bottom: Float(dbl($0["bottom"]) ?? 0))
                }
                try style.addImage(image, id: str(a["imageId"]) ?? "", sdf: bool(a["sdf"]) ?? false,
                                   stretchX: stretches(a["stretchX"]), stretchY: stretches(a["stretchY"]), content: content)
                return nil
            }
        case "removeStyleImage":
            reply.run { try style.removeImage(withId: str(a["imageId"]) ?? ""); return nil }
        case "hasStyleImage":
            reply.run { style.imageExists(withId: str(a["imageId"]) ?? "") }
        case "addStyleModel":
            reply.run { try style.addStyleModel(modelId: str(a["modelId"]) ?? "", modelUri: str(a["modelUri"]) ?? ""); return nil }
        case "removeStyleModel":
            reply.run { try style.removeStyleModel(modelId: str(a["modelId"]) ?? ""); return nil }
        case "isStyleLoaded":
            reply.run { style.isStyleLoaded }
        case "getProjection":
            reply.run {
                guard let projection = style.projection else { return nil }
                switch projection.name {
                case .globe: return ["name": 1]
                case .mercator: return ["name": 0]
                default: return nil
                }
            }
        case "setProjection":
            reply.run {
                let name: StyleProjectionName = int(json(a["projection"])?["name"]) == 1 ? .globe : .mercator
                try style.setProjection(StyleProjection(name: name))
                return nil
            }
        case "localizeLabels":
            reply.run {
                try style.localizeLabels(into: Locale(identifier: str(a["locale"]) ?? "en"), forLayerIds: strings(a["layerIds"]))
                return nil
            }
        default:
            return 2
        }
        return 0
    }

    // MARK: - Lights

    private func flatLight(_ d: JSON) -> FlatLight {
        var light = FlatLight(id: str(d["id"]) ?? "flat")
        if let anchor = int(d["anchor"]) { light.anchor = .constant(anchor == 1 ? .viewport : .map) }
        if let color = styleColor(d["color"]) { light.color = .constant(color) }
        light.colorTransition = Mappers.styleTransition(d["colorTransition"])
        if let intensity = dbl(d["intensity"]) { light.intensity = .constant(intensity) }
        light.intensityTransition = Mappers.styleTransition(d["intensityTransition"])
        if let position = doubles(d["position"]) { light.position = .constant(position) }
        light.positionTransition = Mappers.styleTransition(d["positionTransition"])
        return light
    }

    private func ambientLight(_ d: JSON) -> AmbientLight {
        var light = AmbientLight(id: str(d["id"]) ?? "ambient")
        if let color = styleColor(d["color"]) { light.color = .constant(color) }
        light.colorTransition = Mappers.styleTransition(d["colorTransition"])
        if let intensity = dbl(d["intensity"]) { light.intensity = .constant(intensity) }
        light.intensityTransition = Mappers.styleTransition(d["intensityTransition"])
        return light
    }

    private func directionalLight(_ d: JSON) -> DirectionalLight {
        var light = DirectionalLight(id: str(d["id"]) ?? "directional")
        if let castShadows = bool(d["castShadows"]) { light.castShadows = .constant(castShadows) }
        if let color = styleColor(d["color"]) { light.color = .constant(color) }
        light.colorTransition = Mappers.styleTransition(d["colorTransition"])
        if let direction = doubles(d["direction"]) { light.direction = .constant(direction) }
        light.directionTransition = Mappers.styleTransition(d["directionTransition"])
        if let intensity = dbl(d["intensity"]) { light.intensity = .constant(intensity) }
        light.intensityTransition = Mappers.styleTransition(d["intensityTransition"])
        if let shadowIntensity = dbl(d["shadowIntensity"]) { light.shadowIntensity = .constant(shadowIntensity) }
        light.shadowIntensityTransition = Mappers.styleTransition(d["shadowIntensityTransition"])
        if let layer = str(d["shadowDrawBeforeLayer"]) { light.shadowDrawBeforeLayer = .constant(layer) }
        return light
    }
}
