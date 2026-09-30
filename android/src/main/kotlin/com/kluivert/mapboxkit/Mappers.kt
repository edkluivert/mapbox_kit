package com.kluivert.mapboxkit

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import com.google.gson.Gson
import com.mapbox.bindgen.Value
import com.mapbox.geojson.Feature
import com.mapbox.geojson.Geometry
import com.mapbox.geojson.GeometryCollection
import com.mapbox.geojson.LineString
import com.mapbox.geojson.MultiLineString
import com.mapbox.geojson.MultiPoint
import com.mapbox.geojson.MultiPolygon
import com.mapbox.geojson.Point
import com.mapbox.geojson.Polygon
import com.mapbox.maps.CameraBounds
import com.mapbox.maps.CameraBoundsOptions
import com.mapbox.maps.CameraOptions
import com.mapbox.maps.CameraState
import com.mapbox.maps.ConstrainMode
import com.mapbox.maps.ContextMode
import com.mapbox.maps.CoordinateBounds
import com.mapbox.maps.EdgeInsets
import com.mapbox.maps.GlyphsRasterizationMode
import com.mapbox.maps.GlyphsRasterizationOptions
import com.mapbox.maps.MapOptions
import com.mapbox.maps.NorthOrientation
import com.mapbox.maps.QueriedFeature
import com.mapbox.maps.ScreenBox
import com.mapbox.maps.ScreenCoordinate
import com.mapbox.maps.Size
import com.mapbox.maps.StylePropertyValue
import com.mapbox.maps.TransitionOptions
import com.mapbox.maps.ViewportMode
import com.mapbox.maps.applyDefaultParams
import com.mapbox.maps.extension.style.types.StyleTransition
import com.mapbox.maps.plugin.animation.MapAnimationOptions
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener
import java.io.ByteArrayOutputStream
import java.util.Date

// ── org.json helpers ─────────────────────────────────────────────────────

fun JSONObject.optStringOrNull(key: String): String? =
    if (isNull(key)) null else optString(key)

fun JSONObject.optDoubleOrNull(key: String): Double? =
    if (isNull(key)) null else optDouble(key).takeIf { !it.isNaN() }

fun JSONObject.optBooleanOrNull(key: String): Boolean? =
    if (isNull(key)) null else optBoolean(key)

fun JSONObject.optIntOrNull(key: String): Int? =
    if (isNull(key)) null else optInt(key)

fun JSONObject.optLongOrNull(key: String): Long? =
    if (isNull(key)) null else optLong(key)

fun JSONObject.optObject(key: String): JSONObject? =
    if (isNull(key)) null else optJSONObject(key)

fun JSONObject.doubleList(key: String): List<Double>? {
    val array = optJSONArray(key) ?: return null
    return (0 until array.length()).mapNotNull { i -> array.optDouble(i).takeIf { !it.isNaN() } }
}

fun JSONObject.stringList(key: String): List<String>? {
    val array = optJSONArray(key) ?: return null
    return (0 until array.length()).mapNotNull { i -> if (array.isNull(i)) null else array.optString(i) }
}

fun JSONArray.objects(): List<JSONObject> =
    (0 until length()).mapNotNull { optJSONObject(it) }

/** org.json → plain Kotlin values. */
fun fromJson(value: Any?): Any? = when (value) {
    null, JSONObject.NULL -> null
    is JSONObject -> value.keys().asSequence().associateWith { fromJson(value.opt(it)) }
    is JSONArray -> (0 until value.length()).map { fromJson(value.opt(it)) }
    else -> value
}

fun parseJson(text: String?): Any? {
    if (text.isNullOrEmpty()) return null
    return try { JSONTokener(text).nextValue() } catch (_: Exception) { null }
}

// ── Mapbox Value ─────────────────────────────────────────────────────────

/** A JSON value (org.json or Kotlin) → [Value]. */
fun toValue(value: Any?): Value = when (value) {
    null, JSONObject.NULL -> Value.nullValue()
    is Value -> value
    is Boolean -> Value.valueOf(value)
    is Int -> Value.valueOf(value.toLong())
    is Long -> Value.valueOf(value)
    is Float -> Value.valueOf(value.toDouble())
    is Double -> Value.valueOf(value)
    is Number -> Value.valueOf(value.toDouble())
    is String -> Value.valueOf(value)
    is JSONArray -> Value.valueOf(ArrayList((0 until value.length()).map { toValue(value.opt(it)) }))
    is JSONObject -> Value.valueOf(HashMap(value.keys().asSequence().associateWith { toValue(value.opt(it)) }))
    is Map<*, *> -> Value.valueOf(HashMap(value.entries.associate { it.key.toString() to toValue(it.value) }))
    is Iterable<*> -> Value.valueOf(ArrayList(value.map { toValue(it) }))
    else -> Value.valueOf(value.toString())
}

/** Expression strings from the generated layer code become arrays/objects. */
fun styleValue(value: Any?): Value {
    if (value is String && (value.startsWith("[") || value.startsWith("{"))) {
        val parsed = parseJson(value)
        if (parsed != null) return toValue(parsed)
    }
    return toValue(value)
}

/** A JSON text of style properties → [Value]. */
fun propertiesValue(text: String?): Value =
    Value.fromJson(text ?: "{}").value ?: Value.valueOf(HashMap<String, Value>())

/** [Value] → org.json value. */
fun valueToJson(value: Value?): Any = value?.let { parseJson(it.toJson()) } ?: JSONObject.NULL

fun stylePropertyValueJson(v: StylePropertyValue): JSONObject = JSONObject().apply {
    put("value", valueToJson(v.value))
    put("kind", v.kind.ordinal)
}

fun expectedError(error: String?): Nothing = throw RuntimeException(error ?: "Mapbox error")

// ── Geometry ─────────────────────────────────────────────────────────────

object Mappers {
    fun point(v: Any?): Point? {
        val o = v as? JSONObject ?: return null
        val coords = o.optJSONArray("coordinates") ?: return null
        if (coords.length() < 2) return null
        return Point.fromLngLat(coords.optDouble(0), coords.optDouble(1))
    }

    fun points(array: JSONArray?): List<Point> = array?.objects()?.mapNotNull { point(it) } ?: emptyList()

    fun lineString(v: Any?): LineString? {
        val o = v as? JSONObject ?: return null
        return try { LineString.fromJson(o.toString()) } catch (_: Exception) { null }
    }

    fun geometry(v: Any?): Geometry? {
        val o = v as? JSONObject ?: return null
        val text = o.toString()
        return try {
            when (o.optString("type")) {
                "Point" -> Point.fromJson(text)
                "LineString" -> LineString.fromJson(text)
                "Polygon" -> Polygon.fromJson(text)
                "MultiPoint" -> MultiPoint.fromJson(text)
                "MultiLineString" -> MultiLineString.fromJson(text)
                "MultiPolygon" -> MultiPolygon.fromJson(text)
                "GeometryCollection" -> GeometryCollection.fromJson(text)
                else -> null
            }
        } catch (_: Exception) { null }
    }

    fun feature(v: Any?): Feature? {
        val o = v as? JSONObject ?: return null
        return try { Feature.fromJson(o.toString()) } catch (_: Exception) { null }
    }

    fun geoJson(geometry: Geometry): JSONObject = JSONObject(geometry.toJson())
    fun geoJson(feature: Feature): JSONObject = JSONObject(feature.toJson())
    fun pointJson(p: Point): JSONObject = JSONObject(p.toJson())

    // ── Pixels ───────────────────────────────────────────────────────────

    fun density(context: Context): Float = context.resources.displayMetrics.density
    fun px(v: Double, context: Context): Double = v * density(context)
    fun dp(v: Double, context: Context): Double = v / density(context)

    fun screenCoordinate(v: Any?, context: Context): ScreenCoordinate? {
        val o = v as? JSONObject ?: return null
        return ScreenCoordinate(px(o.optDouble("x", 0.0), context), px(o.optDouble("y", 0.0), context))
    }

    fun screenCoordinateJson(c: ScreenCoordinate, context: Context): JSONObject = JSONObject().apply {
        put("x", dp(c.x, context)); put("y", dp(c.y, context))
    }

    fun screenBox(v: Any?, context: Context): ScreenBox? {
        val o = v as? JSONObject ?: return null
        val min = screenCoordinate(o.optObject("min"), context) ?: return null
        val max = screenCoordinate(o.optObject("max"), context) ?: return null
        return ScreenBox(min, max)
    }

    fun edgeInsets(v: Any?, context: Context): EdgeInsets? {
        val o = v as? JSONObject ?: return null
        return EdgeInsets(
            px(o.optDouble("top", 0.0), context), px(o.optDouble("left", 0.0), context),
            px(o.optDouble("bottom", 0.0), context), px(o.optDouble("right", 0.0), context),
        )
    }

    fun edgeInsetsJson(i: EdgeInsets, context: Context): JSONObject = JSONObject().apply {
        put("top", dp(i.top, context)); put("left", dp(i.left, context))
        put("bottom", dp(i.bottom, context)); put("right", dp(i.right, context))
    }

    fun sizeJson(s: Size, context: Context): JSONObject = JSONObject().apply {
        put("width", dp(s.width.toDouble(), context)); put("height", dp(s.height.toDouble(), context))
    }

    // ── Camera ───────────────────────────────────────────────────────────

    fun cameraOptions(o: JSONObject, context: Context): CameraOptions = CameraOptions.Builder()
        .center(point(o.optObject("center")))
        .padding(edgeInsets(o.optObject("padding"), context))
        .anchor(screenCoordinate(o.optObject("anchor"), context))
        .zoom(o.optDoubleOrNull("zoom"))
        .bearing(o.optDoubleOrNull("bearing"))
        .pitch(o.optDoubleOrNull("pitch"))
        .build()

    fun cameraOptionsJson(c: CameraOptions, context: Context): JSONObject = JSONObject().apply {
        put("center", c.center?.let { pointJson(it) } ?: JSONObject.NULL)
        put("padding", c.padding?.let { edgeInsetsJson(it, context) } ?: JSONObject.NULL)
        put("anchor", c.anchor?.let { screenCoordinateJson(it, context) } ?: JSONObject.NULL)
        put("zoom", c.zoom ?: JSONObject.NULL)
        put("bearing", c.bearing ?: JSONObject.NULL)
        put("pitch", c.pitch ?: JSONObject.NULL)
    }

    fun cameraStateJson(s: CameraState, context: Context): JSONObject = JSONObject().apply {
        put("center", pointJson(s.center))
        put("padding", edgeInsetsJson(s.padding, context))
        put("zoom", s.zoom); put("bearing", s.bearing); put("pitch", s.pitch)
    }

    fun coordinateBounds(v: Any?): CoordinateBounds? {
        val o = v as? JSONObject ?: return null
        val sw = point(o.optObject("southwest")) ?: return null
        val ne = point(o.optObject("northeast")) ?: return null
        return CoordinateBounds(sw, ne, o.optBoolean("infiniteBounds", false))
    }

    fun coordinateBoundsJson(b: CoordinateBounds): JSONObject = JSONObject().apply {
        put("southwest", pointJson(b.southwest)); put("northeast", pointJson(b.northeast))
        put("infiniteBounds", b.infiniteBounds)
    }

    fun cameraBoundsOptions(o: JSONObject): CameraBoundsOptions = CameraBoundsOptions.Builder()
        .bounds(coordinateBounds(o.optObject("bounds")))
        .maxZoom(o.optDoubleOrNull("maxZoom"))
        .minZoom(o.optDoubleOrNull("minZoom"))
        .maxPitch(o.optDoubleOrNull("maxPitch"))
        .minPitch(o.optDoubleOrNull("minPitch"))
        .build()

    fun cameraBoundsJson(b: CameraBounds): JSONObject = JSONObject().apply {
        put("bounds", coordinateBoundsJson(b.bounds))
        put("maxZoom", b.maxZoom); put("minZoom", b.minZoom)
        put("maxPitch", b.maxPitch); put("minPitch", b.minPitch)
    }

    fun animationOptions(v: Any?): MapAnimationOptions? {
        val o = v as? JSONObject ?: return null
        val builder = MapAnimationOptions.Builder()
        o.optLongOrNull("duration")?.let { builder.duration(it) }
        o.optLongOrNull("startDelay")?.let { builder.startDelay(it) }
        return builder.build()
    }

    // ── Map options ──────────────────────────────────────────────────────

    fun mapOptions(o: JSONObject, context: Context): MapOptions {
        val builder = MapOptions.Builder().applyDefaultParams(context)
        o.optIntOrNull("contextMode")?.let { builder.contextMode(ContextMode.values()[it.coerceIn(0, 1)]) }
        o.optIntOrNull("constrainMode")?.let { builder.constrainMode(ConstrainMode.values()[it.coerceIn(0, 2)]) }
        o.optIntOrNull("viewportMode")?.let { builder.viewportMode(ViewportMode.values()[it.coerceIn(0, 1)]) }
        o.optIntOrNull("orientation")?.let { builder.orientation(NorthOrientation.values()[it.coerceIn(0, 3)]) }
        o.optBooleanOrNull("crossSourceCollisions")?.let { builder.crossSourceCollisions(it) }
        o.optObject("size")?.let {
            builder.size(Size(px(it.optDouble("width", 0.0), context).toFloat(), px(it.optDouble("height", 0.0), context).toFloat()))
        }
        o.optDoubleOrNull("pixelRatio")?.let { builder.pixelRatio(it.toFloat()) }
        o.optObject("glyphsRasterizationOptions")?.let { g ->
            builder.glyphsRasterizationOptions(
                GlyphsRasterizationOptions.Builder()
                    .rasterizationMode(GlyphsRasterizationMode.values()[g.optInt("rasterizationMode", 0).coerceIn(0, 2)])
                    .fontFamily(g.optStringOrNull("fontFamily"))
                    .build(),
            )
        }
        return builder.build()
    }

    fun mapOptionsJson(o: MapOptions, context: Context): JSONObject = JSONObject().apply {
        put("contextMode", o.contextMode?.ordinal ?: JSONObject.NULL)
        put("constrainMode", o.constrainMode?.ordinal ?: JSONObject.NULL)
        put("viewportMode", o.viewportMode?.ordinal ?: JSONObject.NULL)
        put("orientation", o.orientation?.ordinal ?: JSONObject.NULL)
        put("crossSourceCollisions", o.crossSourceCollisions ?: JSONObject.NULL)
        put("size", o.size?.let { sizeJson(it, context) } ?: JSONObject.NULL)
        put("pixelRatio", o.pixelRatio.toDouble())
        put("glyphsRasterizationOptions", o.glyphsRasterizationOptions?.let {
            JSONObject().apply {
                put("rasterizationMode", it.rasterizationMode.ordinal)
                put("fontFamily", it.fontFamily ?: JSONObject.NULL)
            }
        } ?: JSONObject.NULL)
    }

    // ── Style values ─────────────────────────────────────────────────────

    fun transitionOptions(o: JSONObject): TransitionOptions = TransitionOptions.Builder()
        .duration(o.optLongOrNull("duration"))
        .delay(o.optLongOrNull("delay"))
        .enablePlacementTransitions(o.optBooleanOrNull("enablePlacementTransitions"))
        .build()

    fun transitionOptionsJson(t: TransitionOptions): JSONObject = JSONObject().apply {
        put("duration", t.duration ?: JSONObject.NULL)
        put("delay", t.delay ?: JSONObject.NULL)
        put("enablePlacementTransitions", t.enablePlacementTransitions ?: JSONObject.NULL)
    }

    fun styleTransition(v: Any?): StyleTransition? {
        val o = v as? JSONObject ?: return null
        val builder = StyleTransition.Builder()
        o.optLongOrNull("duration")?.let { builder.duration(it) }
        o.optLongOrNull("delay")?.let { builder.delay(it) }
        return builder.build()
    }

    fun infoJson(id: String, type: String): JSONObject = JSONObject().apply { put("id", id); put("type", type) }

    fun layerPosition(v: Any?): com.mapbox.maps.LayerPosition? {
        val o = v as? JSONObject ?: return null
        return com.mapbox.maps.LayerPosition(o.optStringOrNull("above"), o.optStringOrNull("below"), o.optIntOrNull("at"))
    }

    fun importPosition(v: Any?): com.mapbox.maps.ImportPosition? {
        val o = v as? JSONObject ?: return null
        return com.mapbox.maps.ImportPosition(o.optStringOrNull("above"), o.optStringOrNull("below"), o.optIntOrNull("at"))
    }

    fun configValues(v: Any?): HashMap<String, Value>? {
        val o = v as? JSONObject ?: return null
        return HashMap(o.keys().asSequence().associateWith { styleValue(o.opt(it)) })
    }

    // ── Images ───────────────────────────────────────────────────────────

    fun bitmap(base64: String?): Bitmap? {
        if (base64.isNullOrEmpty()) return null
        val bytes = try { Base64.decode(base64, Base64.DEFAULT) } catch (_: Exception) { return null }
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
    }

    fun base64(bitmap: Bitmap?): String? {
        if (bitmap == null) return null
        val stream = ByteArrayOutputStream(bitmap.byteCount)
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    }

    /** {width, height, data} JSON → premultiplied RGBA [com.mapbox.maps.Image]. */
    fun image(o: JSONObject?): com.mapbox.maps.Image? {
        val bitmap = bitmap(o?.optStringOrNull("data")) ?: return null
        val argb = if (bitmap.config != Bitmap.Config.ARGB_8888) bitmap.copy(Bitmap.Config.ARGB_8888, false) else bitmap
        val buffer = java.nio.ByteBuffer.allocateDirect(argb.byteCount)
        argb.copyPixelsToBuffer(buffer)
        return com.mapbox.maps.Image(argb.width, argb.height, com.mapbox.bindgen.DataRef(buffer))
    }

    fun imageJson(image: com.mapbox.maps.Image): JSONObject {
        val buffer = image.data.buffer.also { it.rewind() }
        val bitmap = Bitmap.createBitmap(image.width, image.height, Bitmap.Config.ARGB_8888)
        bitmap.copyPixelsFromBuffer(buffer)
        return JSONObject().apply {
            put("width", image.width); put("height", image.height); put("data", base64(bitmap))
        }
    }

    // ── Queries ──────────────────────────────────────────────────────────

    fun queriedFeatureJson(f: QueriedFeature): JSONObject = JSONObject().apply {
        put("feature", geoJson(f.feature))
        put("source", f.source)
        put("sourceLayer", f.sourceLayer ?: JSONObject.NULL)
        put("state", f.state.toJson())
    }

    fun gestureContextJson(pixel: ScreenCoordinate, point: Point, state: Int, context: Context): JSONObject =
        JSONObject().apply {
            put("touchPosition", screenCoordinateJson(pixel, context))
            put("point", pointJson(point))
            put("gestureState", state)
        }

    val gson: Gson by lazy { Gson() }
}

val Date.micros: Long get() = time * 1000
