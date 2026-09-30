package com.kluivert.mapboxkit

import android.content.Context
import android.graphics.Bitmap
import android.util.Base64
import com.mapbox.android.gestures.MoveGestureDetector
import com.mapbox.android.gestures.StandardScaleGestureDetector
import com.mapbox.common.Cancelable
import com.mapbox.maps.ConstrainMode
import com.mapbox.maps.MapView
import com.mapbox.maps.MapboxMap
import com.mapbox.maps.NorthOrientation
import com.mapbox.maps.RenderedQueryGeometry
import com.mapbox.maps.RenderedQueryOptions
import com.mapbox.maps.SourceQueryOptions
import com.mapbox.maps.TileCacheBudget
import com.mapbox.maps.TileCacheBudgetInMegabytes
import com.mapbox.maps.TileCacheBudgetInTiles
import com.mapbox.maps.TileCoverOptions
import com.mapbox.maps.ViewportMode
import com.mapbox.maps.debugoptions.MapViewDebugOptions
import com.mapbox.maps.extension.observable.eventdata.MapLoadingErrorEventData
import com.mapbox.maps.plugin.animation.easeTo
import com.mapbox.maps.plugin.animation.flyTo
import com.mapbox.maps.plugin.animation.moveBy
import com.mapbox.maps.plugin.animation.pitchBy
import com.mapbox.maps.plugin.animation.rotateBy
import com.mapbox.maps.plugin.animation.scaleBy
import com.mapbox.maps.plugin.delegates.listeners.OnMapLoadErrorListener
import com.mapbox.maps.plugin.gestures.OnMapClickListener
import com.mapbox.maps.plugin.gestures.OnMapLongClickListener
import com.mapbox.maps.plugin.gestures.OnMoveListener
import com.mapbox.maps.plugin.gestures.OnScaleListener
import com.mapbox.maps.plugin.gestures.gestures
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream

/** One hosted map: routes the map#/style#/... calls and owns the streams. */
class MapController(val mapView: MapView, val viewId: Long, val context: Context) {
    val mapboxMap: MapboxMap = mapView.mapboxMap

    private var cameraAnimation: Cancelable? = null
    private val eventCancelables = ArrayList<Cancelable>()
    private var eventsToken = 0L
    private var gesturesToken = 0L
    private var gestureReply: Reply? = null
    private var onClick: OnMapClickListener? = null
    private var onLongClick: OnMapLongClickListener? = null
    private var onMove: OnMoveListener? = null
    private var onScale: OnScaleListener? = null

    val style by lazy { StyleHandler(this) }
    val settings by lazy { SettingsHandler(this) }
    val annotations by lazy { AnnotationHandler(this) }

    fun dispose() {
        cancelAllStreams()
        cameraAnimation?.cancel()
        mapView.onStop()
        mapView.onDestroy()
    }

    // ── Streams ───────────────────────────────────────────────────────────

    fun listen(token: Long, channel: String, args: JSONObject, reply: Reply): Int {
        when (channel) {
            "map#events" -> {
                if (eventsToken != 0L) cancelStream(eventsToken)
                eventsToken = token
                val types = args.optJSONArray("eventTypes")?.let { a -> (0 until a.length()).map { a.optInt(it) } } ?: emptyList()
                subscribeEvents(types) { reply.success(it) }
                // Replay whatever fired between map creation and this listen.
                val buffered = pendingEvents.toList()
                pendingEvents.clear()
                for (event in buffered) if (event.optInt("type", -1) in types) reply.success(event)
            }
            "map#gestures" -> {
                if (gesturesToken != 0L) cancelStream(gesturesToken)
                gesturesToken = token
                gestureReply = reply
                installGestureListeners()
            }
            "annotation#interactions" -> {
                val managerId = args.optStringOrNull("managerId")
                if (managerId == null) {
                    reply.error("ARGS", "managerId missing", null)
                    return 0
                }
                annotations.listen(token, managerId, reply)
            }
            else -> return 2
        }
        return 0
    }

    fun cancelStream(token: Long) {
        when (token) {
            eventsToken -> {
                eventCancelables.forEach { it.cancel() }
                eventCancelables.clear()
                eventsToken = 0L
            }
            gesturesToken -> {
                removeGestureListeners()
                gesturesToken = 0L
                gestureReply = null
            }
            else -> annotations.cancel(token)
        }
        MapboxKitBridge.unregisterStream(token)
    }

    fun cancelAllStreams() {
        if (eventsToken != 0L) cancelStream(eventsToken)
        if (gesturesToken != 0L) cancelStream(gesturesToken)
        annotations.cancelAll()
    }

    // ── Events (indices match Dart _MapEvent) ─────────────────────────────

    /** Events that fired before Dart listened on `map#events` (bounded). */
    private val pendingEvents = ArrayList<JSONObject>()

    /**
     * Subscribes at map creation (event types come with INIT) and buffers
     * events until the Dart stream attaches, so an early styleLoaded on a
     * slow launch is not lost.
     */
    fun presubscribe(types: List<Int>) {
        subscribeEvents(types) { if (pendingEvents.size < 256) pendingEvents.add(it) }
    }

    private fun subscribeEvents(types: List<Int>, emit: (JSONObject) -> Unit) {
        eventCancelables.forEach { it.cancel() }
        eventCancelables.clear()
        fun send(type: Int, data: JSONObject) {
            emit(JSONObject().apply { put("type", type); put("data", data) })
        }
        fun interval(i: com.mapbox.maps.EventTimeInterval) = JSONObject().apply {
            put("begin", i.begin.micros); put("end", i.end.micros)
        }
        fun tile(t: com.mapbox.maps.CanonicalTileID?): Any =
            t?.let { JSONObject().apply { put("x", it.x); put("y", it.y); put("z", it.z.toInt()) } } ?: JSONObject.NULL
        for (type in types) {
            val c: Cancelable? = when (type) {
                0 -> mapboxMap.subscribeMapLoaded { send(0, JSONObject().apply { put("timeInterval", interval(it.timeInterval)) }) }
                1 -> mapboxMap.subscribeMapLoadingError { e ->
                    send(1, JSONObject().apply {
                        put("type", e.type.ordinal); put("message", e.message)
                        put("sourceId", e.sourceId ?: JSONObject.NULL); put("tileId", tile(e.tileId))
                        put("timestamp", e.timestamp.micros)
                    })
                }
                2 -> mapboxMap.subscribeStyleLoaded { send(2, JSONObject().apply { put("timeInterval", interval(it.timeInterval)) }) }
                3 -> mapboxMap.subscribeStyleDataLoaded { e ->
                    send(3, JSONObject().apply { put("type", e.type.ordinal); put("timeInterval", interval(e.timeInterval)) })
                }
                4 -> mapboxMap.subscribeCameraChanged { e ->
                    send(4, JSONObject().apply {
                        put("timestamp", e.timestamp.micros); put("cameraState", Mappers.cameraStateJson(e.cameraState, context))
                    })
                }
                5 -> mapboxMap.subscribeMapIdle { send(5, JSONObject().apply { put("timestamp", it.timestamp.micros) }) }
                6 -> mapboxMap.subscribeSourceAdded { send(6, JSONObject().apply { put("sourceId", it.sourceId); put("timestamp", it.timestamp.micros) }) }
                7 -> mapboxMap.subscribeSourceRemoved { send(7, JSONObject().apply { put("sourceId", it.sourceId); put("timestamp", it.timestamp.micros) }) }
                8 -> mapboxMap.subscribeSourceDataLoaded { e ->
                    send(8, JSONObject().apply {
                        put("sourceId", e.sourceId); put("type", e.type.ordinal); put("loaded", e.loaded ?: JSONObject.NULL)
                        put("tileId", tile(e.tileId)); put("dataId", e.dataId ?: JSONObject.NULL)
                        put("timeInterval", interval(e.timeInterval))
                    })
                }
                9 -> mapboxMap.subscribeStyleImageMissing { send(9, JSONObject().apply { put("imageId", it.imageId); put("timestamp", it.timestamp.micros) }) }
                10 -> mapboxMap.subscribeStyleImageRemoveUnused { send(10, JSONObject().apply { put("imageId", it.imageId); put("timestamp", it.timestamp.micros) }) }
                11 -> mapboxMap.subscribeRenderFrameStarted { send(11, JSONObject().apply { put("timestamp", it.timestamp.micros) }) }
                12 -> mapboxMap.subscribeRenderFrameFinished { e ->
                    send(12, JSONObject().apply {
                        put("renderMode", e.renderMode.ordinal); put("timeInterval", interval(e.timeInterval))
                        put("needsRepaint", e.needsRepaint); put("placementChanged", e.placementChanged)
                    })
                }
                13 -> mapboxMap.subscribeResourceRequest { e ->
                    val response = e.response?.let { r ->
                        JSONObject().apply {
                            put("noContent", r.noContent); put("notModified", r.notModified); put("mustRevalidate", r.mustRevalidate)
                            put("source", r.source.ordinal); put("size", r.size)
                            put("modified", r.modified?.micros ?: JSONObject.NULL); put("expires", r.expires?.micros ?: JSONObject.NULL)
                            put("etag", r.etag ?: JSONObject.NULL)
                            put("error", r.error?.let { JSONObject().apply { put("reason", it.reason.ordinal); put("message", it.message) } } ?: JSONObject.NULL)
                        }
                    } ?: JSONObject.NULL
                    send(13, JSONObject().apply {
                        put("source", e.source.ordinal)
                        put("request", JSONObject().apply {
                            put("url", e.request.url); put("resource", e.request.resource.ordinal)
                            put("priority", e.request.priority.ordinal)
                            put("loadingMethod", JSONArray(e.request.loadingMethod.map { it.ordinal }))
                        })
                        put("response", response); put("cancelled", e.cancelled)
                        put("timeInterval", interval(e.timeInterval))
                    })
                }
                else -> null
            }
            c?.let { eventCancelables.add(it) }
        }
    }

    // ── Gestures ──────────────────────────────────────────────────────────

    private fun sendGesture(type: String, pixel: com.mapbox.maps.ScreenCoordinate, state: Int) {
        val reply = gestureReply ?: return
        val point = mapboxMap.coordinateForPixel(pixel)
        reply.success(JSONObject().apply {
            put("type", type); put("context", Mappers.gestureContextJson(pixel, point, state, context))
        })
    }

    private fun installGestureListeners() {
        removeGestureListeners()
        onClick = OnMapClickListener { point ->
            val pixel = mapboxMap.pixelForCoordinate(point)
            gestureReply?.success(JSONObject().apply {
                put("type", "tap"); put("context", Mappers.gestureContextJson(pixel, point, 2, context))
            })
            false
        }.also { mapView.gestures.addOnMapClickListener(it) }
        onLongClick = OnMapLongClickListener { point ->
            val pixel = mapboxMap.pixelForCoordinate(point)
            gestureReply?.success(JSONObject().apply {
                put("type", "longTap"); put("context", Mappers.gestureContextJson(pixel, point, 2, context))
            })
            false
        }.also { mapView.gestures.addOnMapLongClickListener(it) }
        onMove = object : OnMoveListener {
            override fun onMoveBegin(detector: MoveGestureDetector) = sendGesture("scroll", detector.pixel(), 0)
            override fun onMove(detector: MoveGestureDetector): Boolean { sendGesture("scroll", detector.pixel(), 1); return false }
            override fun onMoveEnd(detector: MoveGestureDetector) = sendGesture("scroll", detector.pixel(), 2)
        }.also { mapView.gestures.addOnMoveListener(it) }
        onScale = object : OnScaleListener {
            override fun onScaleBegin(detector: StandardScaleGestureDetector) = sendGesture("zoom", detector.pixel(), 0)
            override fun onScale(detector: StandardScaleGestureDetector) = sendGesture("zoom", detector.pixel(), 1)
            override fun onScaleEnd(detector: StandardScaleGestureDetector) = sendGesture("zoom", detector.pixel(), 2)
        }.also { mapView.gestures.addOnScaleListener(it) }
    }

    private fun MoveGestureDetector.pixel() =
        com.mapbox.maps.ScreenCoordinate(currentEvent.x.toDouble(), currentEvent.y.toDouble())

    private fun StandardScaleGestureDetector.pixel() =
        com.mapbox.maps.ScreenCoordinate(currentEvent.x.toDouble(), currentEvent.y.toDouble())

    private fun removeGestureListeners() {
        onClick?.let { mapView.gestures.removeOnMapClickListener(it) }
        onLongClick?.let { mapView.gestures.removeOnMapLongClickListener(it) }
        onMove?.let { mapView.gestures.removeOnMoveListener(it) }
        onScale?.let { mapView.gestures.removeOnScaleListener(it) }
        onClick = null; onLongClick = null; onMove = null; onScale = null
    }

    // ── Calls ─────────────────────────────────────────────────────────────

    /** Returns 0 when accepted, 2 for an unknown method. */
    fun invoke(method: String, a: JSONObject, reply: Reply): Int {
        val hash = method.indexOf('#')
        if (hash < 0) return 2
        val group = method.substring(0, hash)
        val name = method.substring(hash + 1)
        return when (group) {
            "map" -> invokeMap(name, a, reply)
            "style" -> style.invoke(name, a, reply)
            "location", "gestures", "logo", "compass", "scaleBar", "attribution" -> settings.invoke(group, name, a, reply)
            "annotation", "pointAnnotation", "polylineAnnotation" -> annotations.invoke(group, name, a, reply)
            else -> 2
        }
    }

    private fun camera(a: JSONObject, key: String) = Mappers.cameraOptions(a.optObject(key) ?: JSONObject(), context)

    private fun invokeMap(name: String, a: JSONObject, reply: Reply): Int {
        when (name) {
            // Camera
            "cameraForCoordinatesPadding" -> reply.run {
                Mappers.cameraOptionsJson(
                    mapboxMap.cameraForCoordinates(
                        Mappers.points(a.optJSONArray("coordinates")), camera(a, "camera"),
                        Mappers.edgeInsets(a.optObject("coordinatesPadding"), context), a.optDoubleOrNull("maxZoom"),
                        Mappers.screenCoordinate(a.optObject("offset"), context),
                    ),
                    context,
                )
            }
            "cameraForCoordinateBounds" -> reply.run {
                val bounds = Mappers.coordinateBounds(a.optObject("bounds")) ?: throw IllegalArgumentException("bounds missing")
                Mappers.cameraOptionsJson(
                    mapboxMap.cameraForCoordinateBounds(
                        bounds, Mappers.edgeInsets(a.optObject("padding"), context), a.optDoubleOrNull("bearing"),
                        a.optDoubleOrNull("pitch"), a.optDoubleOrNull("maxZoom"), Mappers.screenCoordinate(a.optObject("offset"), context),
                    ),
                    context,
                )
            }
            "cameraForCoordinates" -> reply.run {
                Mappers.cameraOptionsJson(
                    mapboxMap.cameraForCoordinates(
                        Mappers.points(a.optJSONArray("coordinates")), Mappers.edgeInsets(a.optObject("padding"), context),
                        a.optDoubleOrNull("bearing"), a.optDoubleOrNull("pitch"),
                    ),
                    context,
                )
            }
            "cameraForCoordinatesCameraOptions" -> reply.run {
                val box = Mappers.screenBox(a.optObject("box"), context) ?: throw IllegalArgumentException("box missing")
                Mappers.cameraOptionsJson(
                    mapboxMap.cameraForCoordinates(Mappers.points(a.optJSONArray("coordinates")), camera(a, "camera"), box), context,
                )
            }
            "cameraForGeometry" -> reply.run {
                val geometry = Mappers.geometry(a.optObject("geometry")) ?: throw IllegalArgumentException("geometry invalid")
                Mappers.cameraOptionsJson(
                    mapboxMap.cameraForGeometry(
                        geometry, Mappers.edgeInsets(a.optObject("padding"), context), a.optDoubleOrNull("bearing"), a.optDoubleOrNull("pitch"),
                    ),
                    context,
                )
            }
            "coordinateBoundsForCamera" -> reply.run { Mappers.coordinateBoundsJson(mapboxMap.coordinateBoundsForCamera(camera(a, "camera"))) }
            "coordinateBoundsForCameraUnwrapped" -> reply.run { Mappers.coordinateBoundsJson(mapboxMap.coordinateBoundsForCameraUnwrapped(camera(a, "camera"))) }
            "coordinateBoundsZoomForCamera" -> reply.run {
                val r = mapboxMap.coordinateBoundsZoomForCamera(camera(a, "camera"))
                JSONObject().apply { put("bounds", Mappers.coordinateBoundsJson(r.bounds)); put("zoom", r.zoom) }
            }
            "coordinateBoundsZoomForCameraUnwrapped" -> reply.run {
                val r = mapboxMap.coordinateBoundsZoomForCameraUnwrapped(camera(a, "camera"))
                JSONObject().apply { put("bounds", Mappers.coordinateBoundsJson(r.bounds)); put("zoom", r.zoom) }
            }
            "pixelForCoordinate" -> reply.run {
                val point = Mappers.point(a.optObject("coordinate")) ?: throw IllegalArgumentException("coordinate missing")
                Mappers.screenCoordinateJson(mapboxMap.pixelForCoordinate(point), context)
            }
            "coordinateForPixel" -> reply.run {
                val pixel = Mappers.screenCoordinate(a.optObject("pixel"), context) ?: throw IllegalArgumentException("pixel missing")
                Mappers.pointJson(mapboxMap.coordinateForPixel(pixel))
            }
            "pixelsForCoordinates" -> reply.run {
                JSONArray(mapboxMap.pixelsForCoordinates(Mappers.points(a.optJSONArray("coordinates"))).map { Mappers.screenCoordinateJson(it, context) })
            }
            "coordinatesForPixels" -> reply.run {
                val pixels = a.optJSONArray("pixels")?.objects()?.mapNotNull { Mappers.screenCoordinate(it, context) } ?: emptyList()
                JSONArray(mapboxMap.coordinatesForPixels(pixels).map { Mappers.pointJson(it) })
            }
            "setCamera" -> reply.run { mapboxMap.setCamera(camera(a, "cameraOptions")); null }
            "getCameraState" -> reply.run { Mappers.cameraStateJson(mapboxMap.cameraState, context) }
            "setBounds" -> reply.run { mapboxMap.setBounds(Mappers.cameraBoundsOptions(a.optObject("options") ?: JSONObject())); null }
            "getBounds" -> reply.run { Mappers.cameraBoundsJson(mapboxMap.getBounds()) }

            // Animation
            "easeTo" -> reply.run { cameraAnimation = mapboxMap.easeTo(camera(a, "cameraOptions"), Mappers.animationOptions(a.optObject("mapAnimationOptions"))); null }
            "flyTo" -> reply.run { cameraAnimation = mapboxMap.flyTo(camera(a, "cameraOptions"), Mappers.animationOptions(a.optObject("mapAnimationOptions"))); null }
            "pitchBy" -> reply.run { cameraAnimation = mapboxMap.pitchBy(a.optDouble("pitch", 0.0), Mappers.animationOptions(a.optObject("mapAnimationOptions"))); null }
            "scaleBy" -> reply.run {
                cameraAnimation = mapboxMap.scaleBy(
                    a.optDouble("amount", 1.0), Mappers.screenCoordinate(a.optObject("screenCoordinate"), context),
                    Mappers.animationOptions(a.optObject("mapAnimationOptions")),
                )
                null
            }
            "moveBy" -> reply.run {
                val c = Mappers.screenCoordinate(a.optObject("screenCoordinate"), context) ?: throw IllegalArgumentException("screenCoordinate missing")
                cameraAnimation = mapboxMap.moveBy(c, Mappers.animationOptions(a.optObject("mapAnimationOptions")))
                null
            }
            "rotateBy" -> reply.run {
                val first = Mappers.screenCoordinate(a.optObject("first"), context) ?: throw IllegalArgumentException("first missing")
                val second = Mappers.screenCoordinate(a.optObject("second"), context) ?: throw IllegalArgumentException("second missing")
                cameraAnimation = mapboxMap.rotateBy(first, second, Mappers.animationOptions(a.optObject("mapAnimationOptions")))
                null
            }
            "cancelCameraAnimation" -> reply.run { cameraAnimation?.cancel(); null }

            // Map interface
            "loadStyleURI" -> mapboxMap.loadStyleUri(
                a.optString("styleURI"),
                { reply.success(null) },
                object : OnMapLoadErrorListener {
                    override fun onMapLoadError(eventData: MapLoadingErrorEventData) {
                        reply.error("loadStyleUriError", eventData.message, null)
                    }
                },
            )
            "loadStyleJson" -> mapboxMap.loadStyleJson(
                a.optString("styleJson", "{}"),
                { reply.success(null) },
                object : OnMapLoadErrorListener {
                    override fun onMapLoadError(eventData: MapLoadingErrorEventData) {
                        reply.error("loadStyleUriError", eventData.message, null)
                    }
                },
            )
            "clearData" -> MapboxMap.clearData { if (it.isError) reply.error("clearDataError", it.error, null) else reply.success(null) }
            "setTileCacheBudget" -> reply.run {
                a.optObject("tileCacheBudgetInMegabytes")?.let {
                    mapboxMap.setTileCacheBudget(TileCacheBudget.valueOf(TileCacheBudgetInMegabytes(it.optLong("size"))))
                } ?: a.optObject("tileCacheBudgetInTiles")?.let {
                    mapboxMap.setTileCacheBudget(TileCacheBudget.valueOf(TileCacheBudgetInTiles(it.optLong("size"))))
                }
                null
            }
            "getSize" -> reply.run { Mappers.sizeJson(mapboxMap.getSize(), context) }
            "triggerRepaint" -> reply.run { mapboxMap.triggerRepaint(); null }
            "setGestureInProgress" -> reply.run { mapboxMap.setGestureInProgress(a.optBoolean("inProgress")); null }
            "isGestureInProgress" -> reply.run { mapboxMap.isGestureInProgress() }
            "setUserAnimationInProgress" -> reply.run { mapboxMap.setUserAnimationInProgress(a.optBoolean("inProgress")); null }
            "isUserAnimationInProgress" -> reply.run { mapboxMap.isUserAnimationInProgress() }
            "setPrefetchZoomDelta" -> reply.run { mapboxMap.setPrefetchZoomDelta(a.optInt("delta", 4).toByte()); null }
            "getPrefetchZoomDelta" -> reply.run { mapboxMap.getPrefetchZoomDelta().toInt() }
            "setNorthOrientation" -> reply.run { mapboxMap.setNorthOrientation(NorthOrientation.values()[a.optInt("orientation", 0).coerceIn(0, 3)]); null }
            "setConstrainMode" -> reply.run { mapboxMap.setConstrainMode(ConstrainMode.values()[a.optInt("mode", 1).coerceIn(0, 2)]); null }
            "setViewportMode" -> reply.run { mapboxMap.setViewportMode(ViewportMode.values()[a.optInt("mode", 0).coerceIn(0, 1)]); null }
            "getMapOptions" -> reply.run { Mappers.mapOptionsJson(mapboxMap.getMapOptions(), context) }
            "styleGlyphURL" -> reply.run { mapboxMap.getStyleGlyphURL() }
            "setStyleGlyphURL" -> reply.run { mapboxMap.setStyleGlyphURL(a.optString("glyphURL")); null }
            "getDebugOptions" -> reply.run {
                JSONArray(mapView.debugOptions.mapNotNull { debugOptionIndex(it) })
            }
            "setDebugOptions" -> reply.run {
                val indices = a.optJSONArray("debugOptions")?.let { arr -> (0 until arr.length()).map { arr.optInt(it) } } ?: emptyList()
                mapView.debugOptions = indices.mapNotNull { debugOption(it) }.toSet()
                null
            }
            "queryRenderedFeatures" -> {
                val geometry = a.optObject("geometry") ?: JSONObject()
                val options = a.optObject("options") ?: JSONObject()
                val value = parseJson(geometry.optString("value"))
                val queryGeometry = try {
                    when (geometry.optInt("type", 2)) {
                        0 -> RenderedQueryGeometry.valueOf(Mappers.screenBox(value, context)!!)
                        1 -> RenderedQueryGeometry.valueOf(Mappers.screenCoordinate(value, context)!!)
                        else -> RenderedQueryGeometry.valueOf((value as JSONArray).objects().mapNotNull { Mappers.screenCoordinate(it, context) })
                    }
                } catch (e: Exception) {
                    reply.error("0", "Geometry format error", null)
                    return 0
                }
                val queryOptions = RenderedQueryOptions(options.stringList("layerIds"), options.optStringOrNull("filter")?.let { styleValue(it) })
                mapboxMap.queryRenderedFeatures(queryGeometry, queryOptions) { expected ->
                    if (expected.isError) reply.error("0", expected.error, null)
                    else reply.success(JSONArray(expected.value!!.map { f ->
                        JSONObject().apply {
                            put("queriedFeature", Mappers.queriedFeatureJson(f.queriedFeature)); put("layers", JSONArray(f.layers))
                        }
                    }))
                }
            }
            "querySourceFeatures" -> {
                val options = a.optObject("options") ?: JSONObject()
                val queryOptions = SourceQueryOptions(options.stringList("sourceLayerIds"), styleValue(options.optString("filter", "")))
                mapboxMap.querySourceFeatures(a.optString("sourceId"), queryOptions) { expected ->
                    if (expected.isError) reply.error("0", expected.error, null)
                    else reply.success(JSONArray(expected.value!!.map { f ->
                        JSONObject().apply { put("queriedFeature", Mappers.queriedFeatureJson(f.queriedFeature)) }
                    }))
                }
            }
            "getGeoJsonClusterLeaves", "getGeoJsonClusterChildren", "getGeoJsonClusterExpansionZoom" -> {
                val feature = Mappers.feature(a.optObject("cluster"))
                if (feature == null) {
                    reply.error("0", "Feature format error", null)
                    return 0
                }
                val sourceId = a.optString("sourceIdentifier")
                val callback = com.mapbox.maps.QueryFeatureExtensionCallback { expected ->
                    if (expected.isError) reply.error("0", expected.error, null)
                    else {
                        val v = expected.value!!
                        reply.success(JSONObject().apply {
                            put("value", v.value?.toJson() ?: JSONObject.NULL)
                            put("featureCollection", v.featureCollection?.let { JSONArray(it.map { f -> Mappers.geoJson(f) }) } ?: JSONObject.NULL)
                        })
                    }
                }
                when (name) {
                    "getGeoJsonClusterLeaves" -> mapboxMap.getGeoJsonClusterLeaves(sourceId, feature, a.optLong("limit", 10), a.optLong("offset", 0), callback)
                    "getGeoJsonClusterChildren" -> mapboxMap.getGeoJsonClusterChildren(sourceId, feature, callback)
                    else -> mapboxMap.getGeoJsonClusterExpansionZoom(sourceId, feature, callback)
                }
            }
            "setFeatureState" -> mapboxMap.setFeatureState(
                a.optString("sourceId"), a.optStringOrNull("sourceLayerId"), a.optString("featureId"), styleValue(a.optString("state", "{}")),
            ) { if (it.isError) reply.error("0", it.error, null) else reply.success(null) }
            "getFeatureState" -> mapboxMap.getFeatureState(
                a.optString("sourceId"), a.optStringOrNull("sourceLayerId"), a.optString("featureId"),
            ) { if (it.isError) reply.error("0", it.error, null) else reply.success(it.value!!.toJson()) }
            "removeFeatureState" -> mapboxMap.removeFeatureState(
                a.optString("sourceId"), a.optStringOrNull("sourceLayerId"), a.optString("featureId"), a.optStringOrNull("stateKey"),
            ) { if (it.isError) reply.error("0", it.error, null) else reply.success(null) }
            "reduceMemoryUse" -> reply.run { mapboxMap.reduceMemoryUse(); null }
            "getElevation" -> reply.run {
                val point = Mappers.point(a.optObject("coordinate")) ?: throw IllegalArgumentException("coordinate missing")
                mapboxMap.getElevation(point)
            }
            "tileCover" -> reply.run {
                val o = a.optObject("options") ?: JSONObject()
                val options = TileCoverOptions.Builder()
                    .tileSize(o.optIntOrNull("tileSize")?.toShort())
                    .minZoom(o.optIntOrNull("minZoom")?.toByte())
                    .maxZoom(o.optIntOrNull("maxZoom")?.toByte())
                    .roundZoom(o.optBooleanOrNull("roundZoom"))
                    .build()
                JSONArray(mapboxMap.tileCover(options, null).map {
                    JSONObject().apply { put("z", it.canonical.z.toInt()); put("x", it.canonical.x); put("y", it.canonical.y) }
                })
            }
            "snapshot" -> reply.run {
                val bitmap = mapView.snapshot() ?: throw RuntimeException("Failed to create snapshot: snapshotting timed out.")
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
            }
            else -> return 2
        }
        return 0
    }

    private val debugOptions = listOf(
        MapViewDebugOptions.TILE_BORDERS, MapViewDebugOptions.PARSE_STATUS, MapViewDebugOptions.TIMESTAMPS,
        MapViewDebugOptions.COLLISION, MapViewDebugOptions.OVERDRAW, MapViewDebugOptions.STENCIL_CLIP,
        MapViewDebugOptions.DEPTH_BUFFER, MapViewDebugOptions.MODEL_BOUNDS, MapViewDebugOptions.TERRAIN_WIREFRAME,
        MapViewDebugOptions.LAYERS2_DWIREFRAME, MapViewDebugOptions.LAYERS3_DWIREFRAME, MapViewDebugOptions.LIGHT,
        MapViewDebugOptions.CAMERA, MapViewDebugOptions.PADDING,
    )

    private fun debugOption(index: Int): MapViewDebugOptions? = debugOptions.getOrNull(index)
    private fun debugOptionIndex(option: MapViewDebugOptions): Int? = debugOptions.indexOf(option).takeIf { it >= 0 }
}
