// Ornament, gesture and location component settings.
// Ported from mapbox_maps_flutter 2.31.0 (BSD-3, Mapbox).

part of '../mapbox_kit.dart';

enum OrnamentPosition {
  TOP_LEFT,
  TOP_RIGHT,
  BOTTOM_RIGHT,
  BOTTOM_LEFT,
}

/// Configures the directions in which the map is allowed to move during a scroll gesture.
enum ScrollMode {
  /// The map may only move horizontally.
  HORIZONTAL,

  /// The map may only move vertically.
  VERTICAL,

  /// The map may move both horizontally and vertically.
  HORIZONTAL_AND_VERTICAL,
}

/// The enum controls how the puck is oriented
enum PuckBearing {
  /// Orients the puck to match the direction in which the device is facing.
  HEADING,

  /// Orients the puck to match the direction in which the device is moving.
  COURSE,
}

/// Defines scaling mode. Only applies to location-indicator type layers.
enum ModelScaleMode {
  /// Model is scaled so that it's always the same size relative to other map features.
  MAP,

  /// Model is scaled so that it's always the same size on the screen.
  VIEWPORT,
}

/// Selects the base of the model.
enum ModelElevationReference {
  /// Elevated rendering is enabled. Use this mode to elevate lines relative to the sea level.
  SEA,

  /// Elevated rendering is enabled. Use this mode to elevate lines relative to the ground's height below them.
  GROUND,
}

/// Supported distance unit types.
enum DistanceUnits {
  /// Metric units using meters and kilometers.
  METRIC,

  /// Imperial units using feet for short distances and miles for longer distances.
  IMPERIAL,

  /// Nautical units using fathoms for short distances and nautical miles for longer distances.
  NAUTICAL,
}

/// Gesture configuration allows to control the user touch interaction.
class GesturesSettings {
  GesturesSettings({
    this.rotateEnabled,
    this.pinchToZoomEnabled,
    this.scrollEnabled,
    this.simultaneousRotateAndPinchToZoomEnabled,
    this.pitchEnabled,
    this.scrollMode,
    this.doubleTapToZoomInEnabled,
    this.doubleTouchToZoomOutEnabled,
    this.quickZoomEnabled,
    this.focalPoint,
    this.pinchToZoomDecelerationEnabled,
    this.rotateDecelerationEnabled,
    this.scrollDecelerationEnabled,
    this.increaseRotateThresholdWhenPinchingToZoom,
    this.increasePinchToZoomThresholdWhenRotating,
    this.zoomAnimationAmount,
    this.pinchPanEnabled,
  });

  /// Whether the rotate gesture is enabled. Default value: true.
  bool? rotateEnabled;

  /// Whether the pinch to zoom gesture is enabled. Default value: true.
  bool? pinchToZoomEnabled;

  /// Whether the single-touch scroll gesture is enabled. Default value: true.
  bool? scrollEnabled;

  /// Whether rotation is enabled for the pinch to zoom gesture. Default value: true.
  bool? simultaneousRotateAndPinchToZoomEnabled;

  /// Whether the pitch gesture is enabled. Default value: true.
  bool? pitchEnabled;

  /// Configures the directions in which the map is allowed to move during a scroll gesture.
  ScrollMode? scrollMode;

  /// Whether double tapping the map with one touch results in a zoom-in animation. Default value: true.
  bool? doubleTapToZoomInEnabled;

  /// Whether single tapping the map with two touches results in a zoom-out animation. Default value: true.
  bool? doubleTouchToZoomOutEnabled;

  /// Whether the quick zoom gesture is enabled. Default value: true.
  bool? quickZoomEnabled;

  /// By default, gestures rotate and zoom around the center of the gesture. Set this property to rotate and zoom around a fixed point instead.
  ScreenCoordinate? focalPoint;

  /// Whether a deceleration animation following a pinch-to-zoom gesture is enabled. True by default.
  bool? pinchToZoomDecelerationEnabled;

  /// Whether a deceleration animation following a rotate gesture is enabled. True by default.
  bool? rotateDecelerationEnabled;

  /// Whether a deceleration animation following a scroll gesture is enabled. True by default.
  bool? scrollDecelerationEnabled;

  /// Whether rotate threshold increases when pinching to zoom. true by default.
  bool? increaseRotateThresholdWhenPinchingToZoom;

  /// Whether pinch to zoom threshold increases when rotating. true by default.
  bool? increasePinchToZoomThresholdWhenRotating;

  /// The amount by which the zoom level increases or decreases during a double-tap-to-zoom-in or double-touch-to-zoom-out gesture. 1.0 by default.
  double? zoomAnimationAmount;

  /// Whether pan is enabled for the pinch gesture. Default value: true.
  bool? pinchPanEnabled;

  Map<String, dynamic> toJson() => _compact({
        'rotateEnabled': rotateEnabled,
        'pinchToZoomEnabled': pinchToZoomEnabled,
        'scrollEnabled': scrollEnabled,
        'simultaneousRotateAndPinchToZoomEnabled':
            simultaneousRotateAndPinchToZoomEnabled,
        'pitchEnabled': pitchEnabled,
        'scrollMode': scrollMode?.index,
        'doubleTapToZoomInEnabled': doubleTapToZoomInEnabled,
        'doubleTouchToZoomOutEnabled': doubleTouchToZoomOutEnabled,
        'quickZoomEnabled': quickZoomEnabled,
        'focalPoint': focalPoint?.toJson(),
        'pinchToZoomDecelerationEnabled': pinchToZoomDecelerationEnabled,
        'rotateDecelerationEnabled': rotateDecelerationEnabled,
        'scrollDecelerationEnabled': scrollDecelerationEnabled,
        'increaseRotateThresholdWhenPinchingToZoom':
            increaseRotateThresholdWhenPinchingToZoom,
        'increasePinchToZoomThresholdWhenRotating':
            increasePinchToZoomThresholdWhenRotating,
        'zoomAnimationAmount': zoomAnimationAmount,
        'pinchPanEnabled': pinchPanEnabled,
      });

  static GesturesSettings fromJson(Map<String, dynamic> json) =>
      GesturesSettings(
        rotateEnabled: json['rotateEnabled'] as bool?,
        pinchToZoomEnabled: json['pinchToZoomEnabled'] as bool?,
        scrollEnabled: json['scrollEnabled'] as bool?,
        simultaneousRotateAndPinchToZoomEnabled:
            json['simultaneousRotateAndPinchToZoomEnabled'] as bool?,
        pitchEnabled: json['pitchEnabled'] as bool?,
        scrollMode: _enumFromIndex(ScrollMode.values, json['scrollMode']),
        doubleTapToZoomInEnabled: json['doubleTapToZoomInEnabled'] as bool?,
        doubleTouchToZoomOutEnabled:
            json['doubleTouchToZoomOutEnabled'] as bool?,
        quickZoomEnabled: json['quickZoomEnabled'] as bool?,
        focalPoint: _asMap(json['focalPoint']) == null
            ? null
            : ScreenCoordinate.fromJson(_asMap(json['focalPoint'])!),
        pinchToZoomDecelerationEnabled:
            json['pinchToZoomDecelerationEnabled'] as bool?,
        rotateDecelerationEnabled: json['rotateDecelerationEnabled'] as bool?,
        scrollDecelerationEnabled: json['scrollDecelerationEnabled'] as bool?,
        increaseRotateThresholdWhenPinchingToZoom:
            json['increaseRotateThresholdWhenPinchingToZoom'] as bool?,
        increasePinchToZoomThresholdWhenRotating:
            json['increasePinchToZoomThresholdWhenRotating'] as bool?,
        zoomAnimationAmount: _asDouble(json['zoomAnimationAmount']),
        pinchPanEnabled: json['pinchPanEnabled'] as bool?,
      );
}

/// A 2D location puck.
class LocationPuck2D {
  LocationPuck2D({
    this.topImage,
    this.bearingImage,
    this.shadowImage,
    this.scaleExpression,
    this.opacity,
  });

  /// PNG bytes of the image to use as the top of the location indicator.
  Uint8List? topImage;

  /// PNG bytes of the image to use as the middle of the location indicator.
  Uint8List? bearingImage;

  /// PNG bytes of the image to use as the background of the location indicator.
  Uint8List? shadowImage;

  /// The scale expression of the images. If defined, it will be applied to all the three images.
  String? scaleExpression;

  /// The opacity of the entire location puck. Default value: 1. Value range: [0, 1]
  double? opacity;

  Map<String, dynamic> toJson() => _compact({
        'topImage': _bytesToJson(topImage),
        'bearingImage': _bytesToJson(bearingImage),
        'shadowImage': _bytesToJson(shadowImage),
        'scaleExpression': scaleExpression,
        'opacity': opacity,
      });

  static LocationPuck2D fromJson(Map<String, dynamic> json) => LocationPuck2D(
        topImage: _bytesFromJson(json['topImage']),
        bearingImage: _bytesFromJson(json['bearingImage']),
        shadowImage: _bytesFromJson(json['shadowImage']),
        scaleExpression: json['scaleExpression'] as String?,
        opacity: _asDouble(json['opacity']),
      );
}

/// A 3D location puck.
class LocationPuck3D {
  LocationPuck3D({
    this.modelUri,
    this.position,
    this.modelOpacity,
    this.modelScale,
    this.modelScaleExpression,
    this.modelTranslation,
    this.modelRotation,
    this.modelCastShadows,
    this.modelReceiveShadows,
    this.modelScaleMode,
    this.modelEmissiveStrength,
    this.modelEmissiveStrengthExpression,
    this.modelElevationReference,
  });

  /// An URL for the model file in gltf format.
  String? modelUri;

  /// The position of the model. Default value: [0,0].
  List<double?>? position;

  /// The opacity of the model. Default value: 1. Value range: [0, 1]
  double? modelOpacity;

  /// The scale of the model. Default value: [1,1,1].
  List<double?>? modelScale;

  /// The scale expression of the model, which will overwrite the default scale expression that keeps the model size constant during zoom.
  String? modelScaleExpression;

  /// The translation of the model [lon, lat, z]. Default value: [0,0,0].
  List<double?>? modelTranslation;

  /// The rotation of the model. Default value: [0,0,90].
  List<double?>? modelRotation;

  /// Enable/Disable shadow casting for the 3D location puck. Default value: true.
  bool? modelCastShadows;

  /// Enable/Disable shadow receiving for the 3D location puck. Default value: true.
  bool? modelReceiveShadows;

  /// Defines scaling mode. Only applies to location-indicator type layers. Default value: "viewport".
  ModelScaleMode? modelScaleMode;

  /// Strength of the emission. Default value: 1. Value range: [0, 5]
  double? modelEmissiveStrength;

  /// The emissive strength expression of the model, which will overwrite the default model emissive strength.
  String? modelEmissiveStrengthExpression;

  /// Selects the base of the model. Default value: "ground".
  ModelElevationReference? modelElevationReference;

  Map<String, dynamic> toJson() => _compact({
        'modelUri': modelUri,
        'position': position,
        'modelOpacity': modelOpacity,
        'modelScale': modelScale,
        'modelScaleExpression': modelScaleExpression,
        'modelTranslation': modelTranslation,
        'modelRotation': modelRotation,
        'modelCastShadows': modelCastShadows,
        'modelReceiveShadows': modelReceiveShadows,
        'modelScaleMode': modelScaleMode?.index,
        'modelEmissiveStrength': modelEmissiveStrength,
        'modelEmissiveStrengthExpression': modelEmissiveStrengthExpression,
        'modelElevationReference': modelElevationReference?.index,
      });

  static LocationPuck3D fromJson(Map<String, dynamic> json) => LocationPuck3D(
        modelUri: json['modelUri'] as String?,
        position: _asDoubleList(json['position']),
        modelOpacity: _asDouble(json['modelOpacity']),
        modelScale: _asDoubleList(json['modelScale']),
        modelScaleExpression: json['modelScaleExpression'] as String?,
        modelTranslation: _asDoubleList(json['modelTranslation']),
        modelRotation: _asDoubleList(json['modelRotation']),
        modelCastShadows: json['modelCastShadows'] as bool?,
        modelReceiveShadows: json['modelReceiveShadows'] as bool?,
        modelScaleMode:
            _enumFromIndex(ModelScaleMode.values, json['modelScaleMode']),
        modelEmissiveStrength: _asDouble(json['modelEmissiveStrength']),
        modelEmissiveStrengthExpression:
            json['modelEmissiveStrengthExpression'] as String?,
        modelElevationReference: _enumFromIndex(
            ModelElevationReference.values, json['modelElevationReference']),
      );
}

/// Defines what the customised look of the location puck.
class LocationPuck {
  LocationPuck({this.locationPuck2D, this.locationPuck3D});

  LocationPuck2D? locationPuck2D;
  LocationPuck3D? locationPuck3D;

  Map<String, dynamic> toJson() => _compact({
        'locationPuck2D': locationPuck2D?.toJson(),
        'locationPuck3D': locationPuck3D?.toJson(),
      });

  static LocationPuck fromJson(Map<String, dynamic> json) => LocationPuck(
        locationPuck2D: _asMap(json['locationPuck2D']) == null
            ? null
            : LocationPuck2D.fromJson(_asMap(json['locationPuck2D'])!),
        locationPuck3D: _asMap(json['locationPuck3D']) == null
            ? null
            : LocationPuck3D.fromJson(_asMap(json['locationPuck3D'])!),
      );
}

/// Shows a location puck on the map.
class LocationComponentSettings {
  LocationComponentSettings({
    this.enabled,
    this.pulsingEnabled,
    this.pulsingColor,
    this.pulsingMaxRadius,
    this.showAccuracyRing,
    this.accuracyRingColor,
    this.accuracyRingBorderColor,
    this.layerAbove,
    this.layerBelow,
    this.puckBearingEnabled,
    this.puckBearing,
    this.slot,
    this.locationPuck,
  });

  /// Whether the user location is visible on the map. Default value: false.
  bool? enabled;

  /// Whether the location puck is pulsing on the map. Works for 2D location puck only. Default value: false.
  bool? pulsingEnabled;

  /// The color of the pulsing circle. Works for 2D location puck only. Default value: "#4A90E2".
  int? pulsingColor;

  /// The maximum radius of the pulsing circle. Works for 2D location puck only. Default value: 10.
  double? pulsingMaxRadius;

  /// Whether show accuracy ring with location puck. Works for 2D location puck only. Default value: false.
  bool? showAccuracyRing;

  /// The color of the accuracy ring. Works for 2D location puck only. Default value: "#4d89cff0".
  int? accuracyRingColor;

  /// The color of the accuracy ring border. Works for 2D location puck only. Default value: "#4d89cff0".
  int? accuracyRingBorderColor;

  /// Sets the id of the layer that's added above to when placing the component on the map.
  String? layerAbove;

  /// Sets the id of the layer that's added below to when placing the component on the map.
  String? layerBelow;

  /// Whether the puck rotates to track the bearing source. Default value: false.
  bool? puckBearingEnabled;

  /// The enum controls how the puck is oriented. Default value: "heading".
  PuckBearing? puckBearing;

  /// The slot this layer is assigned to.
  String? slot;

  /// Defines what the customised look of the location puck.
  LocationPuck? locationPuck;

  Map<String, dynamic> toJson() => _compact({
        'enabled': enabled,
        'pulsingEnabled': pulsingEnabled,
        'pulsingColor': pulsingColor,
        'pulsingMaxRadius': pulsingMaxRadius,
        'showAccuracyRing': showAccuracyRing,
        'accuracyRingColor': accuracyRingColor,
        'accuracyRingBorderColor': accuracyRingBorderColor,
        'layerAbove': layerAbove,
        'layerBelow': layerBelow,
        'puckBearingEnabled': puckBearingEnabled,
        'puckBearing': puckBearing?.index,
        'slot': slot,
        'locationPuck': locationPuck?.toJson(),
      });

  static LocationComponentSettings fromJson(Map<String, dynamic> json) =>
      LocationComponentSettings(
        enabled: json['enabled'] as bool?,
        pulsingEnabled: json['pulsingEnabled'] as bool?,
        pulsingColor: _asInt(json['pulsingColor']),
        pulsingMaxRadius: _asDouble(json['pulsingMaxRadius']),
        showAccuracyRing: json['showAccuracyRing'] as bool?,
        accuracyRingColor: _asInt(json['accuracyRingColor']),
        accuracyRingBorderColor: _asInt(json['accuracyRingBorderColor']),
        layerAbove: json['layerAbove'] as String?,
        layerBelow: json['layerBelow'] as String?,
        puckBearingEnabled: json['puckBearingEnabled'] as bool?,
        puckBearing: _enumFromIndex(PuckBearing.values, json['puckBearing']),
        slot: json['slot'] as String?,
        locationPuck: _asMap(json['locationPuck']) == null
            ? null
            : LocationPuck.fromJson(_asMap(json['locationPuck'])!),
      );
}

/// Shows the scale bar on the map.
class ScaleBarSettings {
  ScaleBarSettings({
    this.enabled,
    this.position,
    this.marginLeft,
    this.marginTop,
    this.marginRight,
    this.marginBottom,
    this.textColor,
    this.primaryColor,
    this.secondaryColor,
    this.borderWidth,
    this.height,
    this.textBarMargin,
    this.textBorderWidth,
    this.textSize,
    this.isMetricUnits,
    this.distanceUnits,
    this.refreshInterval,
    this.showTextBorder,
    this.ratio,
    this.useContinuousRendering,
  });

  /// Whether the scale is visible on the map. Default value: true.
  bool? enabled;

  /// Defines where the scale bar is positioned on the map. Default value: "top-left".
  OrnamentPosition? position;

  /// Defines the margin to the left that the scale bar honors. Default value: 4.
  double? marginLeft;

  /// Defines the margin to the top that the scale bar honors. Default value: 4.
  double? marginTop;

  /// Defines the margin to the right that the scale bar honors. Default value: 4.
  double? marginRight;

  /// Defines the margin to the bottom that the scale bar honors. Default value: 4.
  double? marginBottom;

  /// Defines text color of the scale bar. Default value: "black". Android only.
  int? textColor;

  /// Defines primary color of the scale bar. Default value: "black". Android only.
  int? primaryColor;

  /// Defines secondary color of the scale bar. Default value: "white". Android only.
  int? secondaryColor;

  /// Defines width of the border for the scale bar. Default value: 2. Android only.
  double? borderWidth;

  /// Defines height of the scale bar. Default value: 2. Android only.
  double? height;

  /// Defines margin of the text bar of the scale bar. Default value: 8. Android only.
  double? textBarMargin;

  /// Defines text border width of the scale bar. Default value: 2. Android only.
  double? textBorderWidth;

  /// Defines text size of the scale bar. Default value: 8. Android only.
  double? textSize;

  /// Whether the scale bar is using metric unit. Default value: true.
  bool? isMetricUnits;

  /// Supported distance unit types. Default value: "metric".
  DistanceUnits? distanceUnits;

  /// Configures minimum refresh interval, in millisecond, default is 15. Android only.
  int? refreshInterval;

  /// Configures whether to show the text border or not, default is true. Android only.
  bool? showTextBorder;

  /// configures ratio of scale bar max width compared with MapView width, default is 0.5. Android only.
  double? ratio;

  /// If set to True scale bar will be triggering onDraw depending on [refreshInterval] even if actual data did not change. Android only.
  bool? useContinuousRendering;

  Map<String, dynamic> toJson() => _compact({
        'enabled': enabled,
        'position': position?.index,
        'marginLeft': marginLeft,
        'marginTop': marginTop,
        'marginRight': marginRight,
        'marginBottom': marginBottom,
        'textColor': textColor,
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'borderWidth': borderWidth,
        'height': height,
        'textBarMargin': textBarMargin,
        'textBorderWidth': textBorderWidth,
        'textSize': textSize,
        'isMetricUnits': isMetricUnits,
        'distanceUnits': distanceUnits?.index,
        'refreshInterval': refreshInterval,
        'showTextBorder': showTextBorder,
        'ratio': ratio,
        'useContinuousRendering': useContinuousRendering,
      });

  static ScaleBarSettings fromJson(Map<String, dynamic> json) =>
      ScaleBarSettings(
        enabled: json['enabled'] as bool?,
        position: _enumFromIndex(OrnamentPosition.values, json['position']),
        marginLeft: _asDouble(json['marginLeft']),
        marginTop: _asDouble(json['marginTop']),
        marginRight: _asDouble(json['marginRight']),
        marginBottom: _asDouble(json['marginBottom']),
        textColor: _asInt(json['textColor']),
        primaryColor: _asInt(json['primaryColor']),
        secondaryColor: _asInt(json['secondaryColor']),
        borderWidth: _asDouble(json['borderWidth']),
        height: _asDouble(json['height']),
        textBarMargin: _asDouble(json['textBarMargin']),
        textBorderWidth: _asDouble(json['textBorderWidth']),
        textSize: _asDouble(json['textSize']),
        isMetricUnits: json['isMetricUnits'] as bool?,
        distanceUnits:
            _enumFromIndex(DistanceUnits.values, json['distanceUnits']),
        refreshInterval: _asInt(json['refreshInterval']),
        showTextBorder: json['showTextBorder'] as bool?,
        ratio: _asDouble(json['ratio']),
        useContinuousRendering: json['useContinuousRendering'] as bool?,
      );
}

/// Shows the compass on the map.
class CompassSettings {
  CompassSettings({
    this.enabled,
    this.position,
    this.marginLeft,
    this.marginTop,
    this.marginRight,
    this.marginBottom,
    this.opacity,
    this.rotation,
    this.visibility,
    this.fadeWhenFacingNorth,
    this.clickable,
    this.image,
  });

  /// Whether the compass is visible on the map. Default value: true.
  bool? enabled;

  /// Defines where the compass is positioned on the map. Default value: "top-right".
  OrnamentPosition? position;

  /// Defines the margin to the left that the compass icon honors. Default value: 4.
  double? marginLeft;

  /// Defines the margin to the top that the compass icon honors. Default value: 4.
  double? marginTop;

  /// Defines the margin to the right that the compass icon honors. Default value: 4.
  double? marginRight;

  /// Defines the margin to the bottom that the compass icon honors. Default value: 4.
  double? marginBottom;

  /// The alpha channel value of the compass image. Default value: 1. Android only.
  double? opacity;

  /// The clockwise rotation value in degrees of the compass. Default value: 0. Android only.
  double? rotation;

  /// Whether the compass is displayed. Default value: true.
  bool? visibility;

  /// Whether the compass fades out to invisible when facing north direction. Default value: true.
  bool? fadeWhenFacingNorth;

  /// Whether the compass can be clicked and click events can be registered. Default value: true.
  bool? clickable;

  /// The compass image, as PNG bytes.
  Uint8List? image;

  Map<String, dynamic> toJson() => _compact({
        'enabled': enabled,
        'position': position?.index,
        'marginLeft': marginLeft,
        'marginTop': marginTop,
        'marginRight': marginRight,
        'marginBottom': marginBottom,
        'opacity': opacity,
        'rotation': rotation,
        'visibility': visibility,
        'fadeWhenFacingNorth': fadeWhenFacingNorth,
        'clickable': clickable,
        'image': _bytesToJson(image),
      });

  static CompassSettings fromJson(Map<String, dynamic> json) => CompassSettings(
        enabled: json['enabled'] as bool?,
        position: _enumFromIndex(OrnamentPosition.values, json['position']),
        marginLeft: _asDouble(json['marginLeft']),
        marginTop: _asDouble(json['marginTop']),
        marginRight: _asDouble(json['marginRight']),
        marginBottom: _asDouble(json['marginBottom']),
        opacity: _asDouble(json['opacity']),
        rotation: _asDouble(json['rotation']),
        visibility: json['visibility'] as bool?,
        fadeWhenFacingNorth: json['fadeWhenFacingNorth'] as bool?,
        clickable: json['clickable'] as bool?,
        image: _bytesFromJson(json['image']),
      );
}

/// Shows the attribution icon on the map.
class AttributionSettings {
  AttributionSettings({
    this.enabled,
    this.iconColor,
    this.position,
    this.marginLeft,
    this.marginTop,
    this.marginRight,
    this.marginBottom,
    this.clickable,
  });

  /// Whether the attribution icon is visible on the map. Default value: true.
  /// Restricted API. Please contact Mapbox to discuss your use case if you intend to use this property.
  bool? enabled;

  /// Defines text color of the attribution icon. Default value: "#FF1E8CAB".
  int? iconColor;

  /// Defines where the attribution icon is positioned on the map. Default value: "bottom-left".
  OrnamentPosition? position;

  /// Defines the margin to the left that the attribution icon honors. Default value: 92.
  double? marginLeft;

  /// Defines the margin to the top that the attribution icon honors. Default value: 4.
  double? marginTop;

  /// Defines the margin to the right that the attribution icon honors. Default value: 4.
  double? marginRight;

  /// Defines the margin to the bottom that the attribution icon honors. Default value: 4.
  double? marginBottom;

  /// Whether the attribution can be clicked and click events can be registered. Default value: true.
  bool? clickable;

  Map<String, dynamic> toJson() => _compact({
        'enabled': enabled,
        'iconColor': iconColor,
        'position': position?.index,
        'marginLeft': marginLeft,
        'marginTop': marginTop,
        'marginRight': marginRight,
        'marginBottom': marginBottom,
        'clickable': clickable,
      });

  static AttributionSettings fromJson(Map<String, dynamic> json) =>
      AttributionSettings(
        enabled: json['enabled'] as bool?,
        iconColor: _asInt(json['iconColor']),
        position: _enumFromIndex(OrnamentPosition.values, json['position']),
        marginLeft: _asDouble(json['marginLeft']),
        marginTop: _asDouble(json['marginTop']),
        marginRight: _asDouble(json['marginRight']),
        marginBottom: _asDouble(json['marginBottom']),
        clickable: json['clickable'] as bool?,
      );
}

/// Shows the Mapbox logo on the map.
class LogoSettings {
  LogoSettings({
    this.enabled,
    this.position,
    this.marginLeft,
    this.marginTop,
    this.marginRight,
    this.marginBottom,
  });

  /// Whether the logo is visible on the map. Default value: true.
  /// Restricted API. Please contact Mapbox to discuss your use case if you intend to use this property.
  bool? enabled;

  /// Defines where the logo is positioned on the map. Default value: "bottom-left".
  OrnamentPosition? position;

  /// Defines the margin to the left that the attribution icon honors. Default value: 4.
  double? marginLeft;

  /// Defines the margin to the top that the attribution icon honors. Default value: 4.
  double? marginTop;

  /// Defines the margin to the right that the attribution icon honors. Default value: 4.
  double? marginRight;

  /// Defines the margin to the bottom that the attribution icon honors. Default value: 4.
  double? marginBottom;

  Map<String, dynamic> toJson() => _compact({
        'enabled': enabled,
        'position': position?.index,
        'marginLeft': marginLeft,
        'marginTop': marginTop,
        'marginRight': marginRight,
        'marginBottom': marginBottom,
      });

  static LogoSettings fromJson(Map<String, dynamic> json) => LogoSettings(
        enabled: json['enabled'] as bool?,
        position: _enumFromIndex(OrnamentPosition.values, json['position']),
        marginLeft: _asDouble(json['marginLeft']),
        marginTop: _asDouble(json['marginTop']),
        marginRight: _asDouble(json['marginRight']),
        marginBottom: _asDouble(json['marginBottom']),
      );
}

/// Gesture configuration allows to control the user touch interaction.
class GesturesSettingsInterface {
  GesturesSettingsInterface._(this._channel);
  final _MapChannel _channel;

  /// Returns the currently applied settings, populated with default
  /// values for any fields not explicitly modified via [updateSettings].
  Future<GesturesSettings> getSettings() async => GesturesSettings.fromJson(
      _requireMap(await _channel.invoke('gestures#getSettings')));

  /// Partially updates the configuration, modifying only explicitly provided fields in [settings] while preserving the rest.
  Future<void> updateSettings(GesturesSettings settings) =>
      _channel.invoke('gestures#updateSettings', {'settings': settings.toJson()});
}

class _LocationComponentSettingsInterface {
  _LocationComponentSettingsInterface(this._channel);
  final _MapChannel _channel;

  Future<LocationComponentSettings> getSettings() async =>
      LocationComponentSettings.fromJson(
          _requireMap(await _channel.invoke('location#getSettings')));

  Future<void> updateSettings(
          LocationComponentSettings settings, bool useDefaultPuck2DIfNeeded) =>
      _channel.invoke('location#updateSettings', {
        'settings': settings.toJson(),
        'useDefaultPuck2DIfNeeded': useDefaultPuck2DIfNeeded,
      });
}

/// Shows the scale bar on the map.
class ScaleBarSettingsInterface {
  ScaleBarSettingsInterface._(this._channel);
  final _MapChannel _channel;

  /// Returns the currently applied settings.
  Future<ScaleBarSettings> getSettings() async => ScaleBarSettings.fromJson(
      _requireMap(await _channel.invoke('scaleBar#getSettings')));

  /// Partially updates the configuration, modifying only explicitly provided fields in [settings] while preserving the rest.
  Future<void> updateSettings(ScaleBarSettings settings) =>
      _channel.invoke('scaleBar#updateSettings', {'settings': settings.toJson()});
}

/// Shows the compass on the map.
class CompassSettingsInterface {
  CompassSettingsInterface._(this._channel);
  final _MapChannel _channel;

  /// Returns the currently applied settings.
  Future<CompassSettings> getSettings() async => CompassSettings.fromJson(
      _requireMap(await _channel.invoke('compass#getSettings')));

  /// Partially updates the configuration, modifying only explicitly provided fields in [settings] while preserving the rest.
  Future<void> updateSettings(CompassSettings settings) =>
      _channel.invoke('compass#updateSettings', {'settings': settings.toJson()});
}

/// Shows the attribution icon on the map.
class AttributionSettingsInterface {
  AttributionSettingsInterface._(this._channel);
  final _MapChannel _channel;

  /// Returns the currently applied settings.
  Future<AttributionSettings> getSettings() async =>
      AttributionSettings.fromJson(
          _requireMap(await _channel.invoke('attribution#getSettings')));

  /// Partially updates the configuration, modifying only explicitly provided fields in [settings] while preserving the rest.
  Future<void> updateSettings(AttributionSettings settings) => _channel
      .invoke('attribution#updateSettings', {'settings': settings.toJson()});
}

/// Shows the Mapbox logo on the map.
class LogoSettingsInterface {
  LogoSettingsInterface._(this._channel);
  final _MapChannel _channel;

  /// Returns the currently applied settings.
  Future<LogoSettings> getSettings() async => LogoSettings.fromJson(
      _requireMap(await _channel.invoke('logo#getSettings')));

  /// Partially updates the configuration, modifying only explicitly provided fields in [settings] while preserving the rest.
  Future<void> updateSettings(LogoSettings settings) =>
      _channel.invoke('logo#updateSettings', {'settings': settings.toJson()});
}
