package com.kluivert.mapboxkit

import android.view.Gravity
import com.mapbox.maps.ImageHolder
import com.mapbox.maps.ScreenCoordinate
import com.mapbox.maps.plugin.LocationPuck2D
import com.mapbox.maps.plugin.LocationPuck3D
import com.mapbox.maps.plugin.ModelElevationReference
import com.mapbox.maps.plugin.ModelScaleMode
import com.mapbox.maps.plugin.PuckBearing
import com.mapbox.maps.plugin.ScrollMode
import com.mapbox.maps.plugin.attribution.attribution
import com.mapbox.maps.plugin.compass.compass
import com.mapbox.maps.plugin.gestures.gestures
import com.mapbox.maps.plugin.locationcomponent.createDefault2DPuck
import com.mapbox.maps.plugin.locationcomponent.location
import com.mapbox.maps.plugin.logo.logo
import com.mapbox.maps.plugin.scalebar.scalebar
import org.json.JSONObject

/** location#, gestures#, logo#, compass#, scaleBar#, attribution# calls. */
class SettingsHandler(private val map: MapController) {
    private val mapView get() = map.mapView
    private val context get() = map.context

    private var cachedPuck2D: LocationPuck2D? = null
    private var cachedPuck3D: LocationPuck3D? = null

    private fun px(v: Double) = Mappers.px(v, context).toFloat()
    private fun dp(v: Float) = Mappers.dp(v.toDouble(), context)

    private fun gravity(index: Int?): Int? = when (index) {
        0 -> Gravity.TOP or Gravity.START
        1 -> Gravity.TOP or Gravity.END
        2 -> Gravity.BOTTOM or Gravity.END
        3 -> Gravity.BOTTOM or Gravity.START
        else -> null
    }

    private fun positionIndex(gravity: Int): Int = when (gravity) {
        Gravity.BOTTOM or Gravity.START -> 3
        Gravity.BOTTOM or Gravity.END -> 2
        Gravity.TOP or Gravity.START -> 0
        else -> 1
    }

    fun invoke(group: String, name: String, a: JSONObject, reply: Reply): Int {
        val s = a.optObject("settings") ?: JSONObject()
        when ("$group#$name") {
            "location#getSettings" -> reply.run { locationSettings() }
            "location#updateSettings" -> reply.run { updateLocation(s, a.optBoolean("useDefaultPuck2DIfNeeded", false)); null }
            "gestures#getSettings" -> reply.run { gesturesSettings() }
            "gestures#updateSettings" -> reply.run { updateGestures(s); null }
            "logo#getSettings" -> reply.run {
                val o = mapView.logo
                JSONObject().apply {
                    put("enabled", o.enabled); put("position", positionIndex(o.position))
                    put("marginLeft", dp(o.marginLeft)); put("marginTop", dp(o.marginTop))
                    put("marginRight", dp(o.marginRight)); put("marginBottom", dp(o.marginBottom))
                }
            }
            "logo#updateSettings" -> reply.run {
                mapView.logo.updateSettings {
                    s.optBooleanOrNull("enabled")?.let { enabled = it }
                    gravity(s.optIntOrNull("position"))?.let { position = it }
                    s.optDoubleOrNull("marginLeft")?.let { marginLeft = px(it) }
                    s.optDoubleOrNull("marginTop")?.let { marginTop = px(it) }
                    s.optDoubleOrNull("marginRight")?.let { marginRight = px(it) }
                    s.optDoubleOrNull("marginBottom")?.let { marginBottom = px(it) }
                }
                null
            }
            "attribution#getSettings" -> reply.run {
                val o = mapView.attribution
                JSONObject().apply {
                    put("enabled", o.enabled); put("iconColor", o.iconColor.toUInt().toLong()); put("position", positionIndex(o.position))
                    put("marginLeft", dp(o.marginLeft)); put("marginTop", dp(o.marginTop))
                    put("marginRight", dp(o.marginRight)); put("marginBottom", dp(o.marginBottom))
                    put("clickable", o.clickable)
                }
            }
            "attribution#updateSettings" -> reply.run {
                mapView.attribution.updateSettings {
                    s.optBooleanOrNull("enabled")?.let { enabled = it }
                    s.optLongOrNull("iconColor")?.let { iconColor = it.toInt() }
                    gravity(s.optIntOrNull("position"))?.let { position = it }
                    s.optDoubleOrNull("marginLeft")?.let { marginLeft = px(it) }
                    s.optDoubleOrNull("marginTop")?.let { marginTop = px(it) }
                    s.optDoubleOrNull("marginRight")?.let { marginRight = px(it) }
                    s.optDoubleOrNull("marginBottom")?.let { marginBottom = px(it) }
                    s.optBooleanOrNull("clickable")?.let { clickable = it }
                }
                null
            }
            "compass#getSettings" -> reply.run {
                val o = mapView.compass
                JSONObject().apply {
                    put("enabled", o.enabled); put("position", positionIndex(o.position))
                    put("marginLeft", dp(o.marginLeft)); put("marginTop", dp(o.marginTop))
                    put("marginRight", dp(o.marginRight)); put("marginBottom", dp(o.marginBottom))
                    put("opacity", o.opacity.toDouble()); put("rotation", o.rotation.toDouble())
                    put("visibility", o.visibility); put("fadeWhenFacingNorth", o.fadeWhenFacingNorth)
                    put("clickable", o.clickable); put("image", Mappers.base64(o.image?.bitmap) ?: JSONObject.NULL)
                }
            }
            "compass#updateSettings" -> reply.run {
                mapView.compass.updateSettings {
                    s.optBooleanOrNull("enabled")?.let { enabled = it }
                    gravity(s.optIntOrNull("position"))?.let { position = it }
                    s.optDoubleOrNull("marginLeft")?.let { marginLeft = px(it) }
                    s.optDoubleOrNull("marginTop")?.let { marginTop = px(it) }
                    s.optDoubleOrNull("marginRight")?.let { marginRight = px(it) }
                    s.optDoubleOrNull("marginBottom")?.let { marginBottom = px(it) }
                    s.optDoubleOrNull("opacity")?.let { opacity = it.toFloat() }
                    s.optDoubleOrNull("rotation")?.let { rotation = it.toFloat() }
                    s.optBooleanOrNull("visibility")?.let { visibility = it }
                    s.optBooleanOrNull("fadeWhenFacingNorth")?.let { fadeWhenFacingNorth = it }
                    s.optBooleanOrNull("clickable")?.let { clickable = it }
                    s.optStringOrNull("image")?.let { data -> image = Mappers.bitmap(data)?.let { ImageHolder.from(it) } }
                }
                null
            }
            "scaleBar#getSettings" -> reply.run {
                val o = mapView.scalebar
                JSONObject().apply {
                    put("enabled", o.enabled); put("position", positionIndex(o.position))
                    put("marginLeft", dp(o.marginLeft)); put("marginTop", dp(o.marginTop))
                    put("marginRight", dp(o.marginRight)); put("marginBottom", dp(o.marginBottom))
                    put("textColor", o.textColor.toUInt().toLong()); put("primaryColor", o.primaryColor.toUInt().toLong())
                    put("secondaryColor", o.secondaryColor.toUInt().toLong())
                    put("borderWidth", dp(o.borderWidth)); put("height", dp(o.height))
                    put("textBarMargin", dp(o.textBarMargin)); put("textBorderWidth", dp(o.textBorderWidth))
                    put("textSize", o.textSize.toDouble()); put("isMetricUnits", o.isMetricUnits)
                    put("distanceUnits", o.distanceUnits.ordinal); put("refreshInterval", o.refreshInterval)
                    put("showTextBorder", o.showTextBorder); put("ratio", o.ratio.toDouble())
                    put("useContinuousRendering", o.useContinuousRendering)
                }
            }
            "scaleBar#updateSettings" -> reply.run {
                mapView.scalebar.updateSettings {
                    s.optBooleanOrNull("enabled")?.let { enabled = it }
                    gravity(s.optIntOrNull("position"))?.let { position = it }
                    s.optDoubleOrNull("marginLeft")?.let { marginLeft = px(it) }
                    s.optDoubleOrNull("marginTop")?.let { marginTop = px(it) }
                    s.optDoubleOrNull("marginRight")?.let { marginRight = px(it) }
                    s.optDoubleOrNull("marginBottom")?.let { marginBottom = px(it) }
                    s.optLongOrNull("textColor")?.let { textColor = it.toInt() }
                    s.optLongOrNull("primaryColor")?.let { primaryColor = it.toInt() }
                    s.optLongOrNull("secondaryColor")?.let { secondaryColor = it.toInt() }
                    s.optDoubleOrNull("borderWidth")?.let { borderWidth = px(it) }
                    s.optDoubleOrNull("height")?.let { height = px(it) }
                    s.optDoubleOrNull("textBarMargin")?.let { textBarMargin = px(it) }
                    s.optDoubleOrNull("textBorderWidth")?.let { textBorderWidth = px(it) }
                    s.optDoubleOrNull("textSize")?.let { textSize = it.toFloat() }
                    s.optBooleanOrNull("isMetricUnits")?.let { isMetricUnits = it }
                    s.optIntOrNull("distanceUnits")?.let { distanceUnits = com.mapbox.maps.plugin.DistanceUnits.values()[it.coerceIn(0, 2)] }
                    s.optLongOrNull("refreshInterval")?.let { refreshInterval = it }
                    s.optBooleanOrNull("showTextBorder")?.let { showTextBorder = it }
                    s.optDoubleOrNull("ratio")?.let { ratio = it.toFloat() }
                    s.optBooleanOrNull("useContinuousRendering")?.let { useContinuousRendering = it }
                }
                null
            }
            else -> return 2
        }
        return 0
    }

    // ── Gestures ──────────────────────────────────────────────────────────

    private fun updateGestures(s: JSONObject) {
        mapView.gestures.updateSettings {
            s.optBooleanOrNull("rotateEnabled")?.let { rotateEnabled = it }
            s.optBooleanOrNull("pinchToZoomEnabled")?.let { pinchToZoomEnabled = it }
            s.optBooleanOrNull("scrollEnabled")?.let { scrollEnabled = it }
            s.optBooleanOrNull("simultaneousRotateAndPinchToZoomEnabled")?.let { simultaneousRotateAndPinchToZoomEnabled = it }
            s.optBooleanOrNull("pitchEnabled")?.let { pitchEnabled = it }
            s.optIntOrNull("scrollMode")?.let { scrollMode = ScrollMode.values()[it.coerceIn(0, 2)] }
            s.optBooleanOrNull("doubleTapToZoomInEnabled")?.let { doubleTapToZoomInEnabled = it }
            s.optBooleanOrNull("doubleTouchToZoomOutEnabled")?.let { doubleTouchToZoomOutEnabled = it }
            s.optBooleanOrNull("quickZoomEnabled")?.let { quickZoomEnabled = it }
            s.optObject("focalPoint")?.let { focalPoint = ScreenCoordinate(Mappers.px(it.optDouble("x", 0.0), context), Mappers.px(it.optDouble("y", 0.0), context)) }
            s.optBooleanOrNull("pinchToZoomDecelerationEnabled")?.let { pinchToZoomDecelerationEnabled = it }
            s.optBooleanOrNull("rotateDecelerationEnabled")?.let { rotateDecelerationEnabled = it }
            s.optBooleanOrNull("scrollDecelerationEnabled")?.let { scrollDecelerationEnabled = it }
            s.optBooleanOrNull("increaseRotateThresholdWhenPinchingToZoom")?.let { increaseRotateThresholdWhenPinchingToZoom = it }
            s.optBooleanOrNull("increasePinchToZoomThresholdWhenRotating")?.let { increasePinchToZoomThresholdWhenRotating = it }
            s.optDoubleOrNull("zoomAnimationAmount")?.let { zoomAnimationAmount = it.toFloat() }
            s.optBooleanOrNull("pinchPanEnabled")?.let { pinchScrollEnabled = it }
        }
    }

    private fun gesturesSettings(): JSONObject {
        val g = mapView.gestures
        return JSONObject().apply {
            put("rotateEnabled", g.rotateEnabled); put("pinchToZoomEnabled", g.pinchToZoomEnabled)
            put("scrollEnabled", g.scrollEnabled); put("simultaneousRotateAndPinchToZoomEnabled", g.simultaneousRotateAndPinchToZoomEnabled)
            put("pitchEnabled", g.pitchEnabled); put("scrollMode", g.scrollMode.ordinal)
            put("doubleTapToZoomInEnabled", g.doubleTapToZoomInEnabled); put("doubleTouchToZoomOutEnabled", g.doubleTouchToZoomOutEnabled)
            put("quickZoomEnabled", g.quickZoomEnabled)
            put("focalPoint", g.focalPoint?.let { Mappers.screenCoordinateJson(it, context) } ?: JSONObject.NULL)
            put("pinchToZoomDecelerationEnabled", g.pinchToZoomDecelerationEnabled); put("rotateDecelerationEnabled", g.rotateDecelerationEnabled)
            put("scrollDecelerationEnabled", g.scrollDecelerationEnabled)
            put("increaseRotateThresholdWhenPinchingToZoom", g.increaseRotateThresholdWhenPinchingToZoom)
            put("increasePinchToZoomThresholdWhenRotating", g.increasePinchToZoomThresholdWhenRotating)
            put("zoomAnimationAmount", g.zoomAnimationAmount.toDouble()); put("pinchPanEnabled", g.pinchScrollEnabled)
        }
    }

    // ── Location ──────────────────────────────────────────────────────────

    private fun updateLocation(s: JSONObject, useDefaultPuck2D: Boolean) {
        val location = mapView.location
        location.updateSettings {
            s.optBooleanOrNull("enabled")?.let { enabled = it }
            s.optBooleanOrNull("pulsingEnabled")?.let { pulsingEnabled = it }
            s.optLongOrNull("pulsingColor")?.let { pulsingColor = it.toInt() }
            s.optDoubleOrNull("pulsingMaxRadius")?.let { pulsingMaxRadius = it.toFloat() }
            s.optBooleanOrNull("showAccuracyRing")?.let { showAccuracyRing = it }
            s.optLongOrNull("accuracyRingColor")?.let { accuracyRingColor = it.toInt() }
            s.optLongOrNull("accuracyRingBorderColor")?.let { accuracyRingBorderColor = it.toInt() }
            s.optStringOrNull("layerAbove")?.let { layerAbove = it }
            s.optStringOrNull("layerBelow")?.let { layerBelow = it }
            s.optBooleanOrNull("puckBearingEnabled")?.let { puckBearingEnabled = it }
            s.optIntOrNull("puckBearing")?.let { puckBearing = PuckBearing.values()[it.coerceIn(0, 1)] }
            s.optStringOrNull("slot")?.let { slot = it }
            s.optObject("locationPuck")?.let { puck ->
                val puck2D = puck.optObject("locationPuck2D")
                val puck3D = puck.optObject("locationPuck3D")
                locationPuck = if (puck3D != null) {
                    val existing = locationPuck as? LocationPuck3D ?: cachedPuck3D
                    val uri = puck3D.optStringOrNull("modelUri") ?: existing?.modelUri
                        ?: throw IllegalArgumentException("modelUri must be provided the first time a 3D puck is configured.")
                    (existing ?: LocationPuck3D(uri)).apply {
                        puck3D.optStringOrNull("modelUri")?.let { modelUri = it }
                        puck3D.doubleList("position")?.let { position = it.map { v -> v.toFloat() } }
                        puck3D.optDoubleOrNull("modelOpacity")?.let { modelOpacity = it.toFloat() }
                        puck3D.doubleList("modelScale")?.let { modelScale = it.map { v -> v.toFloat() } }
                        puck3D.optStringOrNull("modelScaleExpression")?.let { modelScaleExpression = it }
                        puck3D.doubleList("modelTranslation")?.let { modelTranslation = it.map { v -> v.toFloat() } }
                        puck3D.doubleList("modelRotation")?.let { modelRotation = it.map { v -> v.toFloat() } }
                        puck3D.optBooleanOrNull("modelCastShadows")?.let { modelCastShadows = it }
                        puck3D.optBooleanOrNull("modelReceiveShadows")?.let { modelReceiveShadows = it }
                        puck3D.optIntOrNull("modelScaleMode")?.let { modelScaleMode = ModelScaleMode.values()[it.coerceIn(0, 1)] }
                        puck3D.optDoubleOrNull("modelEmissiveStrength")?.let { modelEmissiveStrength = it.toFloat() }
                        puck3D.optStringOrNull("modelEmissiveStrengthExpression")?.let { modelEmissiveStrengthExpression = it }
                        puck3D.optIntOrNull("modelElevationReference")?.let { modelElevationReference = ModelElevationReference.values()[it.coerceIn(0, 1)] }
                    }
                } else {
                    (
                        if (useDefaultPuck2D) createDefault2DPuck(withBearing = s.optBooleanOrNull("puckBearingEnabled") == true)
                        else locationPuck as? LocationPuck2D ?: cachedPuck2D ?: LocationPuck2D()
                        ).apply {
                        puck2D?.optStringOrNull("topImage")?.let { data -> topImage = Mappers.bitmap(data)?.let { ImageHolder.from(it) } }
                        puck2D?.optStringOrNull("bearingImage")?.let { data -> bearingImage = Mappers.bitmap(data)?.let { ImageHolder.from(it) } }
                        puck2D?.optStringOrNull("shadowImage")?.let { data -> shadowImage = Mappers.bitmap(data)?.let { ImageHolder.from(it) } }
                        puck2D?.optStringOrNull("scaleExpression")?.let { scaleExpression = it }
                        puck2D?.optDoubleOrNull("opacity")?.let { opacity = it.toFloat() }
                    }
                }
            }
        }
        (location.locationPuck as? LocationPuck2D)?.let { cachedPuck2D = it }
        (location.locationPuck as? LocationPuck3D)?.let { cachedPuck3D = it }
    }

    private fun locationSettings(): JSONObject {
        val l = mapView.location
        return JSONObject().apply {
            put("enabled", l.enabled); put("pulsingEnabled", l.pulsingEnabled)
            put("pulsingColor", l.pulsingColor.toUInt().toLong()); put("pulsingMaxRadius", l.pulsingMaxRadius.toDouble())
            put("showAccuracyRing", l.showAccuracyRing); put("accuracyRingColor", l.accuracyRingColor.toUInt().toLong())
            put("accuracyRingBorderColor", l.accuracyRingBorderColor.toUInt().toLong())
            put("layerAbove", l.layerAbove ?: JSONObject.NULL); put("layerBelow", l.layerBelow ?: JSONObject.NULL)
            put("puckBearingEnabled", l.puckBearingEnabled); put("puckBearing", l.puckBearing.ordinal)
            put("slot", l.slot ?: JSONObject.NULL)
            val puck = JSONObject()
            (l.locationPuck as? LocationPuck2D)?.let { p ->
                puck.put("locationPuck2D", JSONObject().apply {
                    put("topImage", Mappers.base64(p.topImage?.bitmap) ?: JSONObject.NULL)
                    put("bearingImage", Mappers.base64(p.bearingImage?.bitmap) ?: JSONObject.NULL)
                    put("shadowImage", Mappers.base64(p.shadowImage?.bitmap) ?: JSONObject.NULL)
                    put("scaleExpression", p.scaleExpression ?: JSONObject.NULL); put("opacity", p.opacity.toDouble())
                })
            }
            (l.locationPuck as? LocationPuck3D)?.let { p ->
                puck.put("locationPuck3D", JSONObject().apply {
                    put("modelUri", p.modelUri); put("position", org.json.JSONArray(p.position.map { it.toDouble() }))
                    put("modelOpacity", p.modelOpacity.toDouble()); put("modelScale", org.json.JSONArray(p.modelScale.map { it.toDouble() }))
                    put("modelScaleExpression", p.modelScaleExpression ?: JSONObject.NULL)
                    put("modelTranslation", org.json.JSONArray(p.modelTranslation.map { it.toDouble() }))
                    put("modelRotation", org.json.JSONArray(p.modelRotation.map { it.toDouble() }))
                    put("modelCastShadows", p.modelCastShadows); put("modelReceiveShadows", p.modelReceiveShadows)
                    put("modelScaleMode", p.modelScaleMode.ordinal); put("modelEmissiveStrength", p.modelEmissiveStrength.toDouble())
                    put("modelEmissiveStrengthExpression", p.modelEmissiveStrengthExpression ?: JSONObject.NULL)
                    put("modelElevationReference", p.modelElevationReference.ordinal)
                })
            }
            put("locationPuck", puck)
        }
    }
}
