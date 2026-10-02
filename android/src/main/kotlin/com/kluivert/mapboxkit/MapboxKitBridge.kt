package com.kluivert.mapboxkit

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import com.dartnative.DNAndroidPluginProvider
import com.dartnative.DNAppContext
import com.dartnative.DNPluginRegistry
import com.dartnative.DNViewRegistry
import com.mapbox.maps.MapInitOptions
import com.mapbox.maps.MapOptions
import com.mapbox.maps.MapView
import com.mapbox.maps.Style
import com.mapbox.maps.applyDefaultParams
import org.json.JSONArray
import org.json.JSONObject
import java.util.Collections
import java.util.WeakHashMap

private const val VIEW_TYPE_KEY = "com.kluivert.mapbox_kit/map" // must match Dart ViewType.claim key
private const val MUTATION_INIT = 1                             // must match Dart _MapMutation.init

/** The hosted view: holds the MapView and the controller driving it. */
class MapboxKitContainer(context: Context) : FrameLayout(context) {
    var controller: MapController? = null
}

/**
 * Kotlin side of mapbox_kit: the DartNative view provider plus the call and
 * stream router, called from mapbox_kit.cpp and answering through
 * [fireToDart]: one dispatcher pointer, one generation stamp checked before
 * every delivery, always on the main thread.
 */
object MapboxKitBridge : DNAndroidPluginProvider {
    private const val TAG = "MapboxKit"

    const val TYPE_SUCCESS = 0
    const val TYPE_ERROR = 1

    private val viewTypeIndex: Int by lazy { DNPluginRegistry.claimViewType(VIEW_TYPE_KEY) }

    /** Live controllers, for the hot-restart reset. */
    private val controllers: MutableSet<MapController> =
        Collections.newSetFromMap(WeakHashMap<MapController, Boolean>())

    /** The controller owning each active stream token. */
    private val streamOwners = HashMap<Long, MapController>()

    fun register() {
        DNPluginRegistry.register(this)
        Log.i(TAG, "map view provider registered")
    }

    // ── View provider ─────────────────────────────────────────────────────

    override fun createView(typeIndex: Int): View? {
        if (typeIndex != viewTypeIndex) return null
        val ctx = DNAppContext.activity() ?: DNAppContext.get() ?: return null
        return MapboxKitContainer(ctx).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            )
        }
    }

    override fun handleMutation(viewId: Long, eventTag: Int, data: ByteArray) {
        val container = DNViewRegistry.view(viewId) as? MapboxKitContainer ?: return
        when (eventTag) {
            MUTATION_INIT -> {
                val params = try { JSONObject(String(data, Charsets.UTF_8)) } catch (_: Exception) { JSONObject() }
                initialize(container, viewId, params)
            }
            else -> Log.w(TAG, "unknown eventTag=$eventTag")
        }
    }

    override fun disposeView(viewId: Long, view: View) {
        (view as? MapboxKitContainer)?.controller?.let {
            it.dispose()
            controllers.remove(it)
        }
        (view as? MapboxKitContainer)?.controller = null
    }

    private fun initialize(container: MapboxKitContainer, viewId: Long, params: JSONObject) {
        val reply = Reply(params.optLong("readyToken", 0L))
        if (container.controller != null) {
            reply.success(null)
            return
        }
        try {
            val context = container.context
            val mapOptions = params.optJSONObject("mapOptions")?.let { Mappers.mapOptions(it, context) }
                ?: MapOptions.Builder().applyDefaultParams(context).build()
            val initOptions = MapInitOptions(
                context = context,
                mapOptions = mapOptions,
                cameraOptions = params.optJSONObject("cameraOptions")?.let { Mappers.cameraOptions(it, context) },
                textureView = params.optBoolean("textureView", true),
                styleUri = params.optString("styleUri", Style.STANDARD).ifEmpty { Style.STANDARD },
            )
            val mapView = MapView(context, initOptions)
            container.addView(
                mapView,
                FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT),
            )
            val controller = MapController(mapView, viewId, context)
            container.controller = controller
            controllers.add(controller)
            params.optJSONArray("eventTypes")?.let { a ->
                controller.presubscribe((0 until a.length()).map { a.optInt(it) })
            }
            Log.i(TAG, "map view $viewId created")
            reply.success(null)
        } catch (e: Throwable) {
            Log.e(TAG, "map view $viewId failed: $e")
            reply.error("INIT", e.message, null)
        }
    }

    // ── Dispatcher slot ───────────────────────────────────────────────────

    @Volatile private var dispatcherPtr: Long = 0L
    @Volatile private var dispatcherGen: Long = 0L
    private val main = Handler(Looper.getMainLooper())
    private var hadSession = false

    /**
     * Called once per Dart session. A second call means the Dart side was
     * restarted: nothing listens to the old tokens any more, so every stream
     * is stopped first, before the new pointer is stored.
     */
    @JvmStatic
    fun setDispatcher(ptr: Long) {
        if (hadSession) resetAll()
        hadSession = true
        dispatcherPtr = ptr
        dispatcherGen = nativeIsolateGen() // capture the counter with the pointer
    }

    @JvmStatic external fun nativeIsolateGen(): Long
    @JvmStatic external fun nativeDeliver(ptr: Long, token: Long, type: Int, payload: ByteArray)

    fun fireToDart(token: Long, type: Int, payload: String) {
        main.post {
            if (dispatcherGen != nativeIsolateGen()) return@post // Dart restarted, drop it
            val ptr = dispatcherPtr
            if (ptr == 0L) return@post
            nativeDeliver(ptr, token, type, payload.toByteArray(Charsets.UTF_8))
        }
    }

    /** Stops every stream (new Dart session or engine detach). */
    fun resetAll() {
        for (controller in controllers.toList()) controller.cancelAllStreams()
        streamOwners.clear()
    }

    fun registerStream(token: Long, owner: MapController) { streamOwners[token] = owner }
    fun unregisterStream(token: Long) { streamOwners.remove(token) }

    // ── Calls (from mapbox_kit.cpp) ───────────────────────────────────────

    private fun controllerFor(args: JSONObject): MapController? {
        if (!args.has("viewId")) return null
        val viewId = args.optLong("viewId")
        return (DNViewRegistry.view(viewId) as? MapboxKitContainer)?.controller
    }

    /** Returns 0 when accepted (the reply arrives later), 2 for an unknown method. */
    @JvmStatic
    fun invoke(token: Long, method: ByteArray, argumentsJson: ByteArray): Int {
        val start = System.nanoTime()
        val name = String(method, Charsets.UTF_8)
        try {
            return invokeNamed(token, name, argumentsJson)
        } finally {
            MapboxKitPerf.record(name, System.nanoTime() - start)
        }
    }

    private fun invokeNamed(token: Long, name: String, argumentsJson: ByteArray): Int {
        val args = Reply.decodeObject(String(argumentsJson, Charsets.UTF_8))
        val reply = Reply(token)
        if (name.startsWith("options#")) {
            return MapboxKitOptions.invoke(name.removePrefix("options#"), args, reply)
        }
        val controller = controllerFor(args)
        if (controller == null) {
            reply.error("NO_MAP", "No map view for ${args.opt("viewId")}", null)
            return 0
        }
        return try {
            controller.invoke(name, args, reply)
        } catch (e: Throwable) {
            reply.error("0", e.message ?: e.toString(), null)
            0
        }
    }

    /** Returns 0 when the stream started, 2 for an unknown channel. */
    @JvmStatic
    fun listen(token: Long, channel: ByteArray, argumentsJson: ByteArray): Int {
        val name = String(channel, Charsets.UTF_8)
        val args = Reply.decodeObject(String(argumentsJson, Charsets.UTF_8))
        val reply = Reply(token)
        val controller = controllerFor(args)
        if (controller == null) {
            reply.error("NO_MAP", "No map view for ${args.opt("viewId")}", null)
            return 0
        }
        val rc = controller.listen(token, name, args, reply)
        if (rc == 0) registerStream(token, controller)
        return rc
    }

    @JvmStatic
    fun cancel(token: Long): Int {
        streamOwners.remove(token)?.cancelStream(token)
        return 0
    }
}

/**
 * The reply side of one Dart call or stream. Everything is JSON on the wire.
 */
class Reply(private val token: Long) {
    fun success(value: Any?) {
        val payload = try {
            encode(value)
        } catch (e: Exception) {
            error("ENCODE", "Could not encode the native reply: ${e.message}", null)
            return
        }
        MapboxKitBridge.fireToDart(token, MapboxKitBridge.TYPE_SUCCESS, payload)
    }

    fun error(code: String, message: String?, details: Any?) {
        val payload = JSONObject()
        payload.put("code", code)
        payload.put("message", message ?: JSONObject.NULL)
        payload.put("details", details ?: JSONObject.NULL)
        MapboxKitBridge.fireToDart(token, MapboxKitBridge.TYPE_ERROR, payload.toString())
    }

    fun error(e: Throwable, code: String = "0") = error(code, e.message ?: e.toString(), null)

    /** Runs [body] and replies with its value, or with the thrown error. */
    inline fun run(body: () -> Any?) {
        try {
            success(body())
        } catch (e: Throwable) {
            error(e)
        }
    }

    companion object {
        fun encode(value: Any?): String = when (val v = toJson(value)) {
            is JSONObject, is JSONArray -> v.toString()
            JSONObject.NULL -> "null"
            is String -> JSONObject.quote(v)
            else -> v.toString()
        }

        /** Kotlin maps/lists/primitives → org.json values (NaN → null). */
        fun toJson(value: Any?): Any = when (value) {
            null -> JSONObject.NULL
            is JSONObject, is JSONArray -> value
            is Map<*, *> -> JSONObject().also { o -> value.forEach { (k, v) -> o.put(k.toString(), toJson(v)) } }
            is Iterable<*> -> JSONArray().also { a -> value.forEach { a.put(toJson(it)) } }
            is Array<*> -> JSONArray().also { a -> value.forEach { a.put(toJson(it)) } }
            is Double -> if (value.isFinite()) value else JSONObject.NULL
            is Float -> if (value.isFinite()) value.toDouble() else JSONObject.NULL
            is Boolean, is Number, is String -> value
            is Enum<*> -> value.ordinal
            else -> value.toString()
        }

        fun decodeObject(json: String?): JSONObject {
            if (json.isNullOrEmpty() || json == "null") return JSONObject()
            return try { JSONObject(json) } catch (_: Exception) { JSONObject() }
        }
    }
}
