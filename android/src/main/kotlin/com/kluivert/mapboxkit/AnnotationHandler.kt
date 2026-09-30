package com.kluivert.mapboxkit

import com.mapbox.maps.StylePropertyValueKind
import com.mapbox.maps.extension.style.layers.properties.generated.IconAnchor
import com.mapbox.maps.extension.style.layers.properties.generated.IconTextFit
import com.mapbox.maps.extension.style.layers.properties.generated.LineJoin
import com.mapbox.maps.extension.style.layers.properties.generated.TextAnchor
import com.mapbox.maps.extension.style.layers.properties.generated.TextJustify
import com.mapbox.maps.extension.style.layers.properties.generated.TextTransform
import com.mapbox.maps.plugin.annotation.Annotation
import com.mapbox.maps.plugin.annotation.AnnotationConfig
import com.mapbox.maps.plugin.annotation.AnnotationManager
import com.mapbox.maps.plugin.annotation.annotations
import com.mapbox.maps.plugin.annotation.generated.OnPointAnnotationClickListener
import com.mapbox.maps.plugin.annotation.generated.OnPointAnnotationDragListener
import com.mapbox.maps.plugin.annotation.generated.OnPointAnnotationLongClickListener
import com.mapbox.maps.plugin.annotation.generated.OnPolylineAnnotationClickListener
import com.mapbox.maps.plugin.annotation.generated.OnPolylineAnnotationDragListener
import com.mapbox.maps.plugin.annotation.generated.OnPolylineAnnotationLongClickListener
import com.mapbox.maps.plugin.annotation.generated.PointAnnotation
import com.mapbox.maps.plugin.annotation.generated.PointAnnotationManager
import com.mapbox.maps.plugin.annotation.generated.PointAnnotationOptions
import com.mapbox.maps.plugin.annotation.generated.PolylineAnnotation
import com.mapbox.maps.plugin.annotation.generated.PolylineAnnotationManager
import com.mapbox.maps.plugin.annotation.generated.PolylineAnnotationOptions
import com.mapbox.maps.plugin.annotation.generated.createPointAnnotationManager
import com.mapbox.maps.plugin.annotation.generated.createPolylineAnnotationManager
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/** annotation#, pointAnnotation#, polylineAnnotation# calls and the interaction stream. */
class AnnotationHandler(private val map: MapController) {
    private val mapView get() = map.mapView

    private val managers = HashMap<String, AnnotationManager<*, *, *, *, *, *, *>>()
    private val pointAnnotations = HashMap<String, PointAnnotation>()
    private val polylineAnnotations = HashMap<String, PolylineAnnotation>()
    private val interactionReplies = HashMap<String, Pair<Long, Reply>>()

    // ── Streams ───────────────────────────────────────────────────────────

    fun listen(token: Long, managerId: String, reply: Reply) {
        interactionReplies[managerId] = token to reply
    }

    fun cancel(token: Long) {
        interactionReplies.entries.removeAll { it.value.first == token }
    }

    fun cancelAll() {
        interactionReplies.values.forEach { MapboxKitBridge.unregisterStream(it.first) }
        interactionReplies.clear()
    }

    private fun send(managerId: String, type: String, state: Int, annotation: Annotation<*>): Boolean {
        val entry = interactionReplies[managerId] ?: return false
        val json = when (annotation) {
            is PointAnnotation -> pointJson(annotation)
            is PolylineAnnotation -> polylineJson(annotation)
            else -> return false
        }
        entry.second.success(JSONObject().apply { put("type", type); put("gestureState", state); put("annotation", json) })
        return true
    }

    // ── Calls ─────────────────────────────────────────────────────────────

    fun invoke(group: String, name: String, a: JSONObject, reply: Reply): Int {
        return when (group) {
            "annotation" -> when (name) {
                "createManager" -> { reply.run { createManager(a) }; 0 }
                "removeManager" -> {
                    reply.run {
                        val id = a.optString("id")
                        managers.remove(id)?.let { mapView.annotations.removeAnnotationManager(it) }
                        interactionReplies.remove(id)
                        null
                    }
                    0
                }
                else -> 2
            }
            "pointAnnotation" -> invokePoint(name, a, reply)
            "polylineAnnotation" -> invokePolyline(name, a, reply)
            else -> 2
        }
    }

    private fun createManager(a: JSONObject): String {
        val id = a.optStringOrNull("id") ?: UUID.randomUUID().toString().substring(0, 8)
        val below = a.optStringOrNull("belowLayerId")?.takeIf { mapView.mapboxMap.styleLayerExists(it) }
        val config = AnnotationConfig(below, id, id)
        val manager: AnnotationManager<*, *, *, *, *, *, *> = when (a.optString("type")) {
            "point" -> mapView.annotations.createPointAnnotationManager(config).apply {
                addClickListener(OnPointAnnotationClickListener { send(id, "tap", 2, it) })
                addLongClickListener(OnPointAnnotationLongClickListener { send(id, "longPress", 2, it) })
                addDragListener(object : OnPointAnnotationDragListener {
                    override fun onAnnotationDragStarted(annotation: Annotation<*>) { send(id, "drag", 0, annotation) }
                    override fun onAnnotationDrag(annotation: Annotation<*>) { send(id, "drag", 1, annotation) }
                    override fun onAnnotationDragFinished(annotation: Annotation<*>) { send(id, "drag", 2, annotation) }
                })
            }
            "polyline" -> mapView.annotations.createPolylineAnnotationManager(config).apply {
                addClickListener(OnPolylineAnnotationClickListener { send(id, "tap", 2, it) })
                addLongClickListener(OnPolylineAnnotationLongClickListener { send(id, "longPress", 2, it) })
                addDragListener(object : OnPolylineAnnotationDragListener {
                    override fun onAnnotationDragStarted(annotation: Annotation<*>) { send(id, "drag", 0, annotation) }
                    override fun onAnnotationDrag(annotation: Annotation<*>) { send(id, "drag", 1, annotation) }
                    override fun onAnnotationDragFinished(annotation: Annotation<*>) { send(id, "drag", 2, annotation) }
                })
            }
            else -> throw IllegalArgumentException("Unsupported annotation manager type: ${a.optString("type")}")
        }
        managers[id] = manager
        return id
    }

    private fun layerProperty(layerId: String, name: String, a: JSONObject, reply: Reply): Int {
        val property = a.optString("property")
        when (name) {
            "setProperty" -> reply.run {
                val expected = mapView.mapboxMap.setStyleLayerProperty(layerId, property, styleValue(a.opt("value")))
                if (expected.isError) expectedError(expected.error)
                null
            }
            "getProperty" -> reply.run {
                val value = mapView.mapboxMap.getStyleLayerProperty(layerId, property)
                if (value.kind == StylePropertyValueKind.CONSTANT) valueToJson(value.value) else null
            }
            else -> return 2
        }
        return 0
    }

    // ── Point ─────────────────────────────────────────────────────────────

    private fun invokePoint(name: String, a: JSONObject, reply: Reply): Int {
        val managerId = a.optString("managerId")
        val manager = managers[managerId] as? PointAnnotationManager
        if (manager == null) {
            reply.error("0", "No manager found with id: $managerId", null)
            return 0
        }
        when (name) {
            "getAnnotations" -> reply.run { JSONArray(manager.annotations.map { pointJson(it) }) }
            "create" -> reply.run {
                val annotation = manager.create(pointOptions(a.optObject("annotationOption") ?: JSONObject()))
                pointAnnotations[annotation.id] = annotation
                pointJson(annotation)
            }
            "createMulti" -> reply.run {
                val created = manager.create((a.optJSONArray("annotationOptions")?.objects() ?: emptyList()).map { pointOptions(it) })
                created.forEach { pointAnnotations[it.id] = it }
                JSONArray(created.map { pointJson(it) })
            }
            "update" -> reply.run {
                val d = a.optObject("annotation") ?: JSONObject()
                val original = pointAnnotations[d.optString("id")] ?: throw IllegalArgumentException("Annotation has not been added on the map: ${d.optString("id")}")
                applyPoint(original, d)
                manager.update(original)
                null
            }
            "delete" -> reply.run {
                val id = a.optObject("annotation")?.optString("id") ?: ""
                pointAnnotations.remove(id)?.let { manager.delete(it) }
                null
            }
            "deleteMulti" -> reply.run {
                val ids = a.optJSONArray("annotations")?.objects()?.map { it.optString("id") } ?: emptyList()
                val existing = ids.mapNotNull { pointAnnotations.remove(it) }
                if (existing.isNotEmpty()) manager.delete(existing)
                null
            }
            "deleteAll" -> reply.run {
                manager.annotations.forEach { pointAnnotations.remove(it.id) }
                manager.deleteAll()
                null
            }
            "setProperty", "getProperty" -> return layerProperty(managerId, name, a, reply)
            else -> return 2
        }
        return 0
    }

    // The style enums are plain classes on Android; indices follow the Dart enums.
    private val iconAnchors = listOf(IconAnchor.CENTER, IconAnchor.LEFT, IconAnchor.RIGHT, IconAnchor.TOP, IconAnchor.BOTTOM,
        IconAnchor.TOP_LEFT, IconAnchor.TOP_RIGHT, IconAnchor.BOTTOM_LEFT, IconAnchor.BOTTOM_RIGHT)
    private val textAnchors = listOf(TextAnchor.CENTER, TextAnchor.LEFT, TextAnchor.RIGHT, TextAnchor.TOP, TextAnchor.BOTTOM,
        TextAnchor.TOP_LEFT, TextAnchor.TOP_RIGHT, TextAnchor.BOTTOM_LEFT, TextAnchor.BOTTOM_RIGHT)
    private val iconTextFits = listOf(IconTextFit.NONE, IconTextFit.WIDTH, IconTextFit.HEIGHT, IconTextFit.BOTH)
    private val textJustifies = listOf(TextJustify.AUTO, TextJustify.LEFT, TextJustify.CENTER, TextJustify.RIGHT)
    private val textTransforms = listOf(TextTransform.NONE, TextTransform.UPPERCASE, TextTransform.LOWERCASE)
    private val lineJoins = listOf(LineJoin.BEVEL, LineJoin.ROUND, LineJoin.MITER, LineJoin.NONE)

    private fun <T> at(list: List<T>, index: Int?): T? = index?.let { list.getOrNull(it) }
    private fun <T> idx(list: List<T>, value: T?): Int? = value?.let { v -> list.indexOf(v).takeIf { it >= 0 } }

    private fun pointOptions(d: JSONObject): PointAnnotationOptions {
        val o = PointAnnotationOptions()
        Mappers.point(d.optObject("geometry"))?.let { o.withPoint(it) }
        Mappers.bitmap(d.optStringOrNull("image"))?.let { o.withIconImage(it) }
        d.optBooleanOrNull("isDraggable")?.let { o.withDraggable(it) }
        at(iconAnchors, d.optIntOrNull("iconAnchor"))?.let { o.withIconAnchor(it) }
        d.optStringOrNull("iconImage")?.let { o.withIconImage(it) }
        d.doubleList("iconOffset")?.let { o.withIconOffset(it) }
        d.optDoubleOrNull("iconRotate")?.let { o.withIconRotate(it) }
        d.optDoubleOrNull("iconSize")?.let { o.withIconSize(it) }
        at(iconTextFits, d.optIntOrNull("iconTextFit"))?.let { o.withIconTextFit(it) }
        d.doubleList("iconTextFitPadding")?.let { o.withIconTextFitPadding(it) }
        d.optDoubleOrNull("symbolSortKey")?.let { o.withSymbolSortKey(it) }
        at(textAnchors, d.optIntOrNull("textAnchor"))?.let { o.withTextAnchor(it) }
        d.optStringOrNull("textField")?.let { o.withTextField(it) }
        at(textJustifies, d.optIntOrNull("textJustify"))?.let { o.withTextJustify(it) }
        d.optDoubleOrNull("textLetterSpacing")?.let { o.withTextLetterSpacing(it) }
        d.optDoubleOrNull("textLineHeight")?.let { o.withTextLineHeight(it) }
        d.optDoubleOrNull("textMaxWidth")?.let { o.withTextMaxWidth(it) }
        d.doubleList("textOffset")?.let { o.withTextOffset(it) }
        d.optDoubleOrNull("textRadialOffset")?.let { o.withTextRadialOffset(it) }
        d.optDoubleOrNull("textRotate")?.let { o.withTextRotate(it) }
        d.optDoubleOrNull("textSize")?.let { o.withTextSize(it) }
        at(textTransforms, d.optIntOrNull("textTransform"))?.let { o.withTextTransform(it) }
        d.optLongOrNull("iconColor")?.let { o.withIconColor(it.toInt()) }
        d.optDoubleOrNull("iconEmissiveStrength")?.let { o.withIconEmissiveStrength(it) }
        d.optDoubleOrNull("iconHaloBlur")?.let { o.withIconHaloBlur(it) }
        d.optLongOrNull("iconHaloColor")?.let { o.withIconHaloColor(it.toInt()) }
        d.optDoubleOrNull("iconHaloWidth")?.let { o.withIconHaloWidth(it) }
        d.optDoubleOrNull("iconImageCrossFade")?.let { o.withIconImageCrossFade(it) }
        d.optDoubleOrNull("iconOcclusionOpacity")?.let { o.withIconOcclusionOpacity(it) }
        d.optDoubleOrNull("iconOpacity")?.let { o.withIconOpacity(it) }
        d.optDoubleOrNull("symbolZOffset")?.let { o.withSymbolZOffset(it) }
        d.optLongOrNull("textColor")?.let { o.withTextColor(it.toInt()) }
        d.optDoubleOrNull("textEmissiveStrength")?.let { o.withTextEmissiveStrength(it) }
        d.optDoubleOrNull("textHaloBlur")?.let { o.withTextHaloBlur(it) }
        d.optLongOrNull("textHaloColor")?.let { o.withTextHaloColor(it.toInt()) }
        d.optDoubleOrNull("textHaloWidth")?.let { o.withTextHaloWidth(it) }
        d.optDoubleOrNull("textOcclusionOpacity")?.let { o.withTextOcclusionOpacity(it) }
        d.optDoubleOrNull("textOpacity")?.let { o.withTextOpacity(it) }
        d.optObject("customData")?.let { o.withData(Mappers.gson.toJsonTree(fromJson(it))) }
        return o
    }

    private fun applyPoint(a: PointAnnotation, d: JSONObject) {
        Mappers.point(d.optObject("geometry"))?.let { a.geometry = it }
        Mappers.bitmap(d.optStringOrNull("image"))?.let { a.iconImageBitmap = it }
        at(iconAnchors, d.optIntOrNull("iconAnchor"))?.let { a.iconAnchor = it }
        d.optStringOrNull("iconImage")?.let { a.iconImage = it }
        d.doubleList("iconOffset")?.let { a.iconOffset = it }
        d.optDoubleOrNull("iconRotate")?.let { a.iconRotate = it }
        d.optDoubleOrNull("iconSize")?.let { a.iconSize = it }
        at(iconTextFits, d.optIntOrNull("iconTextFit"))?.let { a.iconTextFit = it }
        d.doubleList("iconTextFitPadding")?.let { a.iconTextFitPadding = it }
        d.optDoubleOrNull("symbolSortKey")?.let { a.symbolSortKey = it }
        at(textAnchors, d.optIntOrNull("textAnchor"))?.let { a.textAnchor = it }
        d.optStringOrNull("textField")?.let { a.textField = it }
        at(textJustifies, d.optIntOrNull("textJustify"))?.let { a.textJustify = it }
        d.optDoubleOrNull("textLetterSpacing")?.let { a.textLetterSpacing = it }
        d.optDoubleOrNull("textLineHeight")?.let { a.textLineHeight = it }
        d.optDoubleOrNull("textMaxWidth")?.let { a.textMaxWidth = it }
        d.doubleList("textOffset")?.let { a.textOffset = it }
        d.optDoubleOrNull("textRadialOffset")?.let { a.textRadialOffset = it }
        d.optDoubleOrNull("textRotate")?.let { a.textRotate = it }
        d.optDoubleOrNull("textSize")?.let { a.textSize = it }
        at(textTransforms, d.optIntOrNull("textTransform"))?.let { a.textTransform = it }
        d.optLongOrNull("iconColor")?.let { a.iconColorInt = it.toInt() }
        d.optDoubleOrNull("iconEmissiveStrength")?.let { a.iconEmissiveStrength = it }
        d.optDoubleOrNull("iconHaloBlur")?.let { a.iconHaloBlur = it }
        d.optLongOrNull("iconHaloColor")?.let { a.iconHaloColorInt = it.toInt() }
        d.optDoubleOrNull("iconHaloWidth")?.let { a.iconHaloWidth = it }
        d.optDoubleOrNull("iconImageCrossFade")?.let { a.iconImageCrossFade = it }
        d.optDoubleOrNull("iconOcclusionOpacity")?.let { a.iconOcclusionOpacity = it }
        d.optDoubleOrNull("iconOpacity")?.let { a.iconOpacity = it }
        d.optDoubleOrNull("symbolZOffset")?.let { a.symbolZOffset = it }
        d.optLongOrNull("textColor")?.let { a.textColorInt = it.toInt() }
        d.optDoubleOrNull("textEmissiveStrength")?.let { a.textEmissiveStrength = it }
        d.optDoubleOrNull("textHaloBlur")?.let { a.textHaloBlur = it }
        d.optLongOrNull("textHaloColor")?.let { a.textHaloColorInt = it.toInt() }
        d.optDoubleOrNull("textHaloWidth")?.let { a.textHaloWidth = it }
        d.optDoubleOrNull("textOcclusionOpacity")?.let { a.textOcclusionOpacity = it }
        d.optDoubleOrNull("textOpacity")?.let { a.textOpacity = it }
        d.optBooleanOrNull("isDraggable")?.let { a.isDraggable = it }
        d.optObject("customData")?.let { a.setData(Mappers.gson.toJsonTree(fromJson(it))) }
    }

    private fun JSONObject.putOpt(key: String, value: Any?): JSONObject = apply { put(key, value ?: JSONObject.NULL) }

    private fun pointJson(a: PointAnnotation): JSONObject = JSONObject().apply {
        put("id", a.id)
        put("geometry", Mappers.pointJson(a.geometry))
        putOpt("image", Mappers.base64(a.iconImageBitmap))
        putOpt("iconAnchor", idx(iconAnchors, a.iconAnchor))
        putOpt("iconImage", a.iconImage)
        putOpt("iconOffset", a.iconOffset?.let { JSONArray(it) })
        putOpt("iconRotate", a.iconRotate)
        putOpt("iconSize", a.iconSize)
        putOpt("iconTextFit", idx(iconTextFits, a.iconTextFit))
        putOpt("iconTextFitPadding", a.iconTextFitPadding?.let { JSONArray(it) })
        putOpt("symbolSortKey", a.symbolSortKey)
        putOpt("textAnchor", idx(textAnchors, a.textAnchor))
        putOpt("textField", a.textField)
        putOpt("textJustify", idx(textJustifies, a.textJustify))
        putOpt("textLetterSpacing", a.textLetterSpacing)
        putOpt("textLineHeight", a.textLineHeight)
        putOpt("textMaxWidth", a.textMaxWidth)
        putOpt("textOffset", a.textOffset?.let { JSONArray(it) })
        putOpt("textRadialOffset", a.textRadialOffset)
        putOpt("textRotate", a.textRotate)
        putOpt("textSize", a.textSize)
        putOpt("textTransform", idx(textTransforms, a.textTransform))
        putOpt("iconColor", a.iconColorInt?.toUInt()?.toLong())
        putOpt("iconEmissiveStrength", a.iconEmissiveStrength)
        putOpt("iconHaloBlur", a.iconHaloBlur)
        putOpt("iconHaloColor", a.iconHaloColorInt?.toUInt()?.toLong())
        putOpt("iconHaloWidth", a.iconHaloWidth)
        putOpt("iconImageCrossFade", a.iconImageCrossFade)
        putOpt("iconOcclusionOpacity", a.iconOcclusionOpacity)
        putOpt("iconOpacity", a.iconOpacity)
        putOpt("symbolZOffset", a.symbolZOffset)
        putOpt("textColor", a.textColorInt?.toUInt()?.toLong())
        putOpt("textEmissiveStrength", a.textEmissiveStrength)
        putOpt("textHaloBlur", a.textHaloBlur)
        putOpt("textHaloColor", a.textHaloColorInt?.toUInt()?.toLong())
        putOpt("textHaloWidth", a.textHaloWidth)
        putOpt("textOcclusionOpacity", a.textOcclusionOpacity)
        putOpt("textOpacity", a.textOpacity)
        put("isDraggable", a.isDraggable)
        putOpt("customData", a.getData()?.let { parseJson(it.toString()) })
    }

    // ── Polyline ──────────────────────────────────────────────────────────

    private fun invokePolyline(name: String, a: JSONObject, reply: Reply): Int {
        val managerId = a.optString("managerId")
        val manager = managers[managerId] as? PolylineAnnotationManager
        if (manager == null) {
            reply.error("0", "No manager found with id: $managerId", null)
            return 0
        }
        when (name) {
            "getAnnotations" -> reply.run { JSONArray(manager.annotations.map { polylineJson(it) }) }
            "create" -> reply.run {
                val annotation = manager.create(polylineOptions(a.optObject("annotationOption") ?: JSONObject()))
                polylineAnnotations[annotation.id] = annotation
                polylineJson(annotation)
            }
            "createMulti" -> reply.run {
                val created = manager.create((a.optJSONArray("annotationOptions")?.objects() ?: emptyList()).map { polylineOptions(it) })
                created.forEach { polylineAnnotations[it.id] = it }
                JSONArray(created.map { polylineJson(it) })
            }
            "update" -> reply.run {
                val d = a.optObject("annotation") ?: JSONObject()
                val original = polylineAnnotations[d.optString("id")] ?: throw IllegalArgumentException("Annotation has not been added on the map: ${d.optString("id")}")
                applyPolyline(original, d)
                manager.update(original)
                null
            }
            "delete" -> reply.run {
                val id = a.optObject("annotation")?.optString("id") ?: ""
                polylineAnnotations.remove(id)?.let { manager.delete(it) }
                null
            }
            "deleteMulti" -> reply.run {
                val ids = a.optJSONArray("annotations")?.objects()?.map { it.optString("id") } ?: emptyList()
                val existing = ids.mapNotNull { polylineAnnotations.remove(it) }
                if (existing.isNotEmpty()) manager.delete(existing)
                null
            }
            "deleteAll" -> reply.run {
                manager.annotations.forEach { polylineAnnotations.remove(it.id) }
                manager.deleteAll()
                null
            }
            "setProperty", "getProperty" -> return layerProperty(managerId, name, a, reply)
            else -> return 2
        }
        return 0
    }

    private fun polylineOptions(d: JSONObject): PolylineAnnotationOptions {
        val o = PolylineAnnotationOptions()
        Mappers.lineString(d.optObject("geometry"))?.let { o.withGeometry(it) }
        d.optBooleanOrNull("isDraggable")?.let { o.withDraggable(it) }
        d.optDoubleOrNull("lineElevationGroundScale")?.let { o.withLineElevationGroundScale(it) }
        at(lineJoins, d.optIntOrNull("lineJoin"))?.let { o.withLineJoin(it) }
        d.optDoubleOrNull("lineSortKey")?.let { o.withLineSortKey(it) }
        d.optDoubleOrNull("lineZOffset")?.let { o.withLineZOffset(it) }
        d.optDoubleOrNull("lineBlur")?.let { o.withLineBlur(it) }
        d.optLongOrNull("lineBorderColor")?.let { o.withLineBorderColor(it.toInt()) }
        d.optDoubleOrNull("lineBorderWidth")?.let { o.withLineBorderWidth(it) }
        d.optLongOrNull("lineColor")?.let { o.withLineColor(it.toInt()) }
        d.optDoubleOrNull("lineEmissiveStrength")?.let { o.withLineEmissiveStrength(it) }
        d.optDoubleOrNull("lineGapWidth")?.let { o.withLineGapWidth(it) }
        d.optDoubleOrNull("lineOffset")?.let { o.withLineOffset(it) }
        d.optDoubleOrNull("lineOpacity")?.let { o.withLineOpacity(it) }
        d.optStringOrNull("linePattern")?.let { o.withLinePattern(it) }
        d.optDoubleOrNull("lineWidth")?.let { o.withLineWidth(it) }
        d.optObject("customData")?.let { o.withData(Mappers.gson.toJsonTree(fromJson(it))) }
        return o
    }

    private fun applyPolyline(a: PolylineAnnotation, d: JSONObject) {
        Mappers.lineString(d.optObject("geometry"))?.let { a.geometry = it }
        d.optDoubleOrNull("lineElevationGroundScale")?.let { a.lineElevationGroundScale = it }
        at(lineJoins, d.optIntOrNull("lineJoin"))?.let { a.lineJoin = it }
        d.optDoubleOrNull("lineSortKey")?.let { a.lineSortKey = it }
        d.optDoubleOrNull("lineZOffset")?.let { a.lineZOffset = it }
        d.optDoubleOrNull("lineBlur")?.let { a.lineBlur = it }
        d.optLongOrNull("lineBorderColor")?.let { a.lineBorderColorInt = it.toInt() }
        d.optDoubleOrNull("lineBorderWidth")?.let { a.lineBorderWidth = it }
        d.optLongOrNull("lineColor")?.let { a.lineColorInt = it.toInt() }
        d.optDoubleOrNull("lineEmissiveStrength")?.let { a.lineEmissiveStrength = it }
        d.optDoubleOrNull("lineGapWidth")?.let { a.lineGapWidth = it }
        d.optDoubleOrNull("lineOffset")?.let { a.lineOffset = it }
        d.optDoubleOrNull("lineOpacity")?.let { a.lineOpacity = it }
        d.optStringOrNull("linePattern")?.let { a.linePattern = it }
        d.optDoubleOrNull("lineWidth")?.let { a.lineWidth = it }
        d.optBooleanOrNull("isDraggable")?.let { a.isDraggable = it }
        d.optObject("customData")?.let { a.setData(Mappers.gson.toJsonTree(fromJson(it))) }
    }

    private fun polylineJson(a: PolylineAnnotation): JSONObject = JSONObject().apply {
        put("id", a.id)
        put("geometry", Mappers.geoJson(a.geometry))
        putOpt("lineElevationGroundScale", a.lineElevationGroundScale)
        putOpt("lineJoin", idx(lineJoins, a.lineJoin))
        putOpt("lineSortKey", a.lineSortKey)
        putOpt("lineZOffset", a.lineZOffset)
        putOpt("lineBlur", a.lineBlur)
        putOpt("lineBorderColor", a.lineBorderColorInt?.toUInt()?.toLong())
        putOpt("lineBorderWidth", a.lineBorderWidth)
        putOpt("lineColor", a.lineColorInt?.toUInt()?.toLong())
        putOpt("lineEmissiveStrength", a.lineEmissiveStrength)
        putOpt("lineGapWidth", a.lineGapWidth)
        putOpt("lineOffset", a.lineOffset)
        putOpt("lineOpacity", a.lineOpacity)
        putOpt("linePattern", a.linePattern)
        putOpt("lineWidth", a.lineWidth)
        put("isDraggable", a.isDraggable)
        putOpt("customData", a.getData()?.let { parseJson(it.toString()) })
    }
}
