package com.kluivert.mapboxkit

import com.mapbox.bindgen.Expected
import com.mapbox.bindgen.None
import com.mapbox.maps.MapboxStyleManager
import com.mapbox.maps.extension.localization.localizeLabels
import com.mapbox.maps.extension.style.layers.properties.generated.ProjectionName
import com.mapbox.maps.extension.style.light.LightPosition
import com.mapbox.maps.extension.style.light.generated.ambientLight
import com.mapbox.maps.extension.style.light.generated.directionalLight
import com.mapbox.maps.extension.style.light.generated.flatLight
import com.mapbox.maps.extension.style.light.setLight
import com.mapbox.maps.extension.style.projection.generated.Projection
import com.mapbox.maps.extension.style.projection.generated.getProjection
import com.mapbox.maps.extension.style.projection.generated.setProjection
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

/** style#... calls, ported from mapbox_maps_flutter's StyleController. */
class StyleHandler(private val map: MapController) {
    private val style: MapboxStyleManager get() = map.mapboxMap
    private val context get() = map.context

    private fun Expected<String, None>.orThrow(): Any? { if (isError) expectedError(error); return null }
    private fun <T> Expected<String, T>.valueOrThrow(): T { if (isError) expectedError(error); return value!! }

    fun invoke(name: String, a: JSONObject, reply: Reply): Int {
        when (name) {
            "getStyleURI" -> reply.run { style.styleURI }
            "setStyleURI" -> map.mapboxMap.loadStyleUri(
                a.optString("uri"), { reply.success(null) },
                object : com.mapbox.maps.plugin.delegates.listeners.OnMapLoadErrorListener {
                    override fun onMapLoadError(eventData: com.mapbox.maps.extension.observable.eventdata.MapLoadingErrorEventData) {
                        reply.error("0", eventData.message, null)
                    }
                },
            )
            "getStyleJSON" -> reply.run { style.styleJSON }
            "setStyleJSON" -> map.mapboxMap.loadStyleJson(
                a.optString("json", "{}"), { reply.success(null) },
                object : com.mapbox.maps.plugin.delegates.listeners.OnMapLoadErrorListener {
                    override fun onMapLoadError(eventData: com.mapbox.maps.extension.observable.eventdata.MapLoadingErrorEventData) {
                        reply.error("0", eventData.message, null)
                    }
                },
            )
            "getStyleDefaultCamera" -> reply.run { Mappers.cameraOptionsJson(style.styleDefaultCamera, context) }
            "getStyleTransition" -> reply.run { Mappers.transitionOptionsJson(style.getStyleTransition()) }
            "setStyleTransition" -> reply.run { style.setStyleTransition(Mappers.transitionOptions(a.optObject("transitionOptions") ?: JSONObject())); null }

            // Imports
            "addStyleImportFromJSON" -> reply.run {
                style.addStyleImportFromJSON(a.optString("importId"), a.optString("json", "{}"), Mappers.configValues(a.optObject("config")), Mappers.importPosition(a.optObject("importPosition"))).orThrow()
            }
            "addStyleImportFromURI" -> reply.run {
                style.addStyleImportFromURI(a.optString("importId"), a.optString("uri"), Mappers.configValues(a.optObject("config")), Mappers.importPosition(a.optObject("importPosition"))).orThrow()
            }
            "updateStyleImportWithJSON" -> reply.run {
                style.updateStyleImportWithJSON(a.optString("importId"), a.optString("json", "{}"), Mappers.configValues(a.optObject("config"))).orThrow()
            }
            "updateStyleImportWithURI" -> reply.run {
                style.updateStyleImportWithURI(a.optString("importId"), a.optString("uri"), Mappers.configValues(a.optObject("config"))).orThrow()
            }
            "moveStyleImport" -> reply.run { style.moveStyleImport(a.optString("importId"), Mappers.importPosition(a.optObject("importPosition"))).orThrow() }
            "getStyleImports" -> reply.run { JSONArray(style.getStyleImports().map { Mappers.infoJson(it.id, it.type) }) }
            "removeStyleImport" -> reply.run { style.removeStyleImport(a.optString("importId")).orThrow() }
            "getStyleImportSchema" -> reply.run { valueToJson(style.getStyleImportSchema(a.optString("importId")).valueOrThrow()) }
            "getStyleImportConfigProperties" -> reply.run {
                val props = style.getStyleImportConfigProperties(a.optString("importId")).valueOrThrow()
                JSONObject().apply { props.forEach { (k, v) -> put(k, stylePropertyValueJson(v)) } }
            }
            "getStyleImportConfigProperty" -> reply.run {
                stylePropertyValueJson(style.getStyleImportConfigProperty(a.optString("importId"), a.optString("config")).valueOrThrow())
            }
            "setStyleImportConfigProperties" -> reply.run {
                style.setStyleImportConfigProperties(a.optString("importId"), Mappers.configValues(a.optObject("configs")) ?: HashMap()).orThrow()
            }
            "setStyleImportConfigProperty" -> reply.run {
                style.setStyleImportConfigProperty(a.optString("importId"), a.optString("config"), styleValue(a.opt("value"))).orThrow()
            }

            // Layers
            "addStyleLayer" -> reply.run {
                style.addStyleLayer(propertiesValue(a.optString("properties")), Mappers.layerPosition(a.optObject("layerPosition"))).orThrow()
            }
            "addPersistentStyleLayer" -> reply.run {
                style.addPersistentStyleLayer(propertiesValue(a.optString("properties")), Mappers.layerPosition(a.optObject("layerPosition"))).orThrow()
            }
            "isStyleLayerPersistent" -> reply.run { style.isStyleLayerPersistent(a.optString("layerId")).valueOrThrow() }
            "removeStyleLayer" -> reply.run { style.removeStyleLayer(a.optString("layerId")).orThrow() }
            "moveStyleLayer" -> reply.run { style.moveStyleLayer(a.optString("layerId"), Mappers.layerPosition(a.optObject("layerPosition"))).orThrow() }
            "styleLayerExists" -> reply.run { style.styleLayerExists(a.optString("layerId")) }
            "getStyleLayers" -> reply.run { JSONArray(style.styleLayers.map { Mappers.infoJson(it.id, it.type) }) }
            "getStyleLayerProperty" -> reply.run { stylePropertyValueJson(style.getStyleLayerProperty(a.optString("layerId"), a.optString("property"))) }
            "setStyleLayerProperty" -> reply.run { style.setStyleLayerProperty(a.optString("layerId"), a.optString("property"), styleValue(a.opt("value"))).orThrow() }
            "getStyleLayerProperties" -> reply.run { style.getStyleLayerProperties(a.optString("layerId")).valueOrThrow().toJson() }
            "setStyleLayerProperties" -> reply.run { style.setStyleLayerProperties(a.optString("layerId"), propertiesValue(a.optString("properties"))).orThrow() }

            // Sources
            "addStyleSource" -> reply.run { style.addStyleSource(a.optString("sourceId"), propertiesValue(a.optString("properties"))).orThrow() }
            "getStyleSourceProperty" -> reply.run { stylePropertyValueJson(style.getStyleSourceProperty(a.optString("sourceId"), a.optString("property"))) }
            "setStyleSourceProperty" -> reply.run { style.setStyleSourceProperty(a.optString("sourceId"), a.optString("property"), styleValue(a.opt("value"))).orThrow() }
            "getStyleSourceProperties" -> reply.run { style.getStyleSourceProperties(a.optString("sourceId")).valueOrThrow().toJson() }
            "setStyleSourceProperties" -> reply.run { style.setStyleSourceProperties(a.optString("sourceId"), propertiesValue(a.optString("properties"))).orThrow() }
            "addGeoJSONSourceFeatures" -> reply.run {
                style.addGeoJSONSourceFeatures(a.optString("sourceId"), a.optString("dataId"), a.optJSONArray("features")?.objects()?.mapNotNull { Mappers.feature(it) } ?: emptyList()).orThrow()
            }
            "updateGeoJSONSourceFeatures" -> reply.run {
                style.updateGeoJSONSourceFeatures(a.optString("sourceId"), a.optString("dataId"), a.optJSONArray("features")?.objects()?.mapNotNull { Mappers.feature(it) } ?: emptyList()).orThrow()
            }
            "removeGeoJSONSourceFeatures" -> reply.run {
                style.removeGeoJSONSourceFeatures(a.optString("sourceId"), a.optString("dataId"), a.stringList("featureIds") ?: emptyList()).orThrow()
            }
            "updateStyleImageSourceImage" -> reply.run {
                val image = Mappers.image(a.optObject("image")) ?: throw IllegalArgumentException("Could not decode the image data.")
                style.updateStyleImageSourceImage(a.optString("sourceId"), image).orThrow()
            }
            "removeStyleSource" -> reply.run { style.removeStyleSource(a.optString("sourceId")).orThrow() }
            "styleSourceExists" -> reply.run { style.styleSourceExists(a.optString("sourceId")) }
            "getStyleSources" -> reply.run { JSONArray(style.styleSources.map { Mappers.infoJson(it.id, it.type) }) }

            // Lights
            "getStyleLights" -> reply.run { JSONArray(style.getStyleLights().map { Mappers.infoJson(it.id, it.type) }) }
            "setLight" -> reply.run { style.setLight(flatLight(a.optObject("flatLight") ?: JSONObject())); null }
            "setLights" -> reply.run {
                style.setLight(ambientLight(a.optObject("ambientLight") ?: JSONObject()), directionalLight(a.optObject("directionalLight") ?: JSONObject()))
                null
            }
            "getStyleLightProperty" -> reply.run { stylePropertyValueJson(style.getStyleLightProperty(a.optString("id"), a.optString("property"))) }
            "setStyleLightProperty" -> reply.run { style.setStyleLightProperty(a.optString("id"), a.optString("property"), styleValue(a.opt("value"))).orThrow() }

            // Terrain
            "setStyleTerrain" -> reply.run { style.setStyleTerrain(propertiesValue(a.optString("properties"))).orThrow() }
            "getStyleTerrainProperty" -> reply.run { stylePropertyValueJson(style.getStyleTerrainProperty(a.optString("property"))) }
            "setStyleTerrainProperty" -> reply.run { style.setStyleTerrainProperty(a.optString("property"), styleValue(a.opt("value"))).orThrow() }

            // Images
            "getStyleImage" -> reply.run { style.getStyleImage(a.optString("imageId"))?.let { Mappers.imageJson(it) } }
            "addStyleImage" -> reply.run {
                val image = Mappers.image(a.optObject("image")) ?: throw IllegalArgumentException("Could not decode the image data.")
                fun stretches(key: String) = a.optJSONArray(key)?.objects()?.map {
                    com.mapbox.maps.ImageStretches(it.optDouble("first", 0.0).toFloat(), it.optDouble("second", 0.0).toFloat())
                } ?: emptyList()
                val content = a.optObject("content")?.let {
                    com.mapbox.maps.ImageContent(
                        it.optDouble("left", 0.0).toFloat(), it.optDouble("top", 0.0).toFloat(),
                        it.optDouble("right", 0.0).toFloat(), it.optDouble("bottom", 0.0).toFloat(),
                    )
                }
                style.addStyleImage(
                    a.optString("imageId"), a.optDouble("scale", Mappers.density(context).toDouble()).toFloat(), image,
                    a.optBoolean("sdf", false), stretches("stretchX"), stretches("stretchY"), content,
                ).orThrow()
            }
            "removeStyleImage" -> reply.run { style.removeStyleImage(a.optString("imageId")).orThrow() }
            "hasStyleImage" -> reply.run { style.hasStyleImage(a.optString("imageId")) }
            "addStyleModel" -> reply.run { style.addStyleModel(a.optString("modelId"), a.optString("modelUri")).orThrow() }
            "removeStyleModel" -> reply.run { style.removeStyleModel(a.optString("modelId")).orThrow() }
            "isStyleLoaded" -> reply.run { style.isStyleLoaded() }
            "getProjection" -> reply.run {
                when (style.getProjection()?.name) {
                    ProjectionName.GLOBE -> JSONObject().apply { put("name", 1) }
                    ProjectionName.MERCATOR -> JSONObject().apply { put("name", 0) }
                    else -> null
                }
            }
            "setProjection" -> reply.run {
                val name = if (a.optObject("projection")?.optInt("name", 0) == 1) ProjectionName.GLOBE else ProjectionName.MERCATOR
                style.setProjection(Projection(name))
                null
            }
            "localizeLabels" -> reply.run { style.localizeLabels(Locale(a.optString("locale", "en")), a.stringList("layerIds")); null }
            else -> return 2
        }
        return 0
    }

    // ── Lights ────────────────────────────────────────────────────────────

    private fun flatLight(d: JSONObject) = flatLight(d.optString("id", "flat")) {
        d.optIntOrNull("anchor")?.let {
            anchor(if (it == 1) com.mapbox.maps.extension.style.layers.properties.generated.Anchor.VIEWPORT else com.mapbox.maps.extension.style.layers.properties.generated.Anchor.MAP)
        }
        d.optLongOrNull("color")?.let { color(it.toInt()) }
        Mappers.styleTransition(d.optObject("colorTransition"))?.let { colorTransition(it) }
        d.optDoubleOrNull("intensity")?.let { intensity(it) }
        Mappers.styleTransition(d.optObject("intensityTransition"))?.let { intensityTransition(it) }
        d.doubleList("position")?.takeIf { it.size == 3 }?.let { position(LightPosition(it[0], it[1], it[2])) }
        Mappers.styleTransition(d.optObject("positionTransition"))?.let { positionTransition(it) }
    }

    private fun ambientLight(d: JSONObject) = ambientLight(d.optString("id", "ambient")) {
        d.optLongOrNull("color")?.let { color(it.toInt()) }
        Mappers.styleTransition(d.optObject("colorTransition"))?.let { colorTransition(it) }
        d.optDoubleOrNull("intensity")?.let { intensity(it) }
        Mappers.styleTransition(d.optObject("intensityTransition"))?.let { intensityTransition(it) }
    }

    private fun directionalLight(d: JSONObject) = directionalLight(d.optString("id", "directional")) {
        d.optBooleanOrNull("castShadows")?.let { castShadows(it) }
        d.optLongOrNull("color")?.let { color(it.toInt()) }
        Mappers.styleTransition(d.optObject("colorTransition"))?.let { colorTransition(it) }
        d.doubleList("direction")?.let { direction(it) }
        Mappers.styleTransition(d.optObject("directionTransition"))?.let { directionTransition(it) }
        d.optDoubleOrNull("intensity")?.let { intensity(it) }
        Mappers.styleTransition(d.optObject("intensityTransition"))?.let { intensityTransition(it) }
        d.optDoubleOrNull("shadowIntensity")?.let { shadowIntensity(it) }
        Mappers.styleTransition(d.optObject("shadowIntensityTransition"))?.let { shadowIntensityTransition(it) }
    }
}
