// The DartNative view provider: creates the container the framework lays
// out, and builds the MapView inside it when the INIT mutation arrives.

import Foundation
import UIKit
@_spi(Experimental) import MapboxMaps

private let VIEW_TYPE_KEY = "com.kluivert.mapbox_kit/map"   // must match Dart ViewType.claim key
private let MUTATION_INIT: Int32 = 1                        // must match Dart _MapMutation.init

/// Claimed lazily on first use. Same key as the Dart side → same index,
/// assigned by the framework at runtime.
private let VIEW_TYPE_INDEX: Int32 = {
    typealias ClaimFn = @convention(c) (UnsafePointer<CChar>) -> Int32
    guard let s = dlsym(dlopen(nil, RTLD_NOLOAD), "DNViewTypeClaim") else { return -1 }
    return VIEW_TYPE_KEY.withCString { unsafeBitCast(s, to: ClaimFn.self)($0) }
}()

/// The hosted view: pins the MapView to its own bounds and owns the
/// controller, so both go away with the view.
final class MapboxKitContainerView: UIView {
    var controller: MapController?

    override func layoutSubviews() {
        super.layoutSubviews()
        subviews.first?.frame = bounds
    }

    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        if bounds.width > 0 || bounds.height > 0 { subview.frame = bounds }
    }

    deinit {
        controller?.dispose()
    }
}

private let _createView: @convention(c) (Int32) -> Int64 = { typeIndex in
    guard typeIndex == VIEW_TYPE_INDEX else { return 0 }
    let view = MapboxKitContainerView()
    view.clipsToBounds = true
    return Int64(Int(bitPattern: Unmanaged.passRetained(view).toOpaque()))
}

private let _handleMutation: @convention(c)
    (Int64, Int32, UnsafePointer<UInt8>?, Int32) -> Void =
{ viewId, eventTag, dataPtr, dataLen in
    guard let view = MapboxKitProvider.view(forViewId: viewId) else { return }
    switch eventTag {
    case MUTATION_INIT:
        guard let dataPtr, dataLen > 0 else { return }
        let data = Data(bytes: dataPtr, count: Int(dataLen))
        let params = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        MapboxKitProvider.initialize(view: view, viewId: viewId, params: params)
    default:
        mapboxKitLog("unknown eventTag=\(eventTag)")
    }
}

// ── Plumbing ──────────────────────────────────────────────────────────────
private typealias _GetViewFn = @convention(c) (Int64) -> Int64
private let _dnGetView: _GetViewFn? = {
    guard let s = dlsym(dlopen(nil, RTLD_NOLOAD), "DNViewRegistryGetView") else { return nil }
    return unsafeBitCast(s, to: _GetViewFn.self)
}()

enum MapboxKitProvider {
    static func view(forViewId id: Int64) -> MapboxKitContainerView? {
        guard let fn = _dnGetView else { return nil }
        let p = fn(id); guard p != 0 else { return nil }
        return Unmanaged<UIView>.fromOpaque(UnsafeRawPointer(bitPattern: Int(p))!)
            .takeUnretainedValue() as? MapboxKitContainerView
    }

    static func controller(forViewId id: Int64) -> MapController? {
        view(forViewId: id)?.controller
    }

    static func initialize(view: MapboxKitContainerView, viewId: Int64, params: [String: Any]) {
        let readyToken = (params["readyToken"] as? NSNumber)?.int64Value ?? 0
        let reply = Reply(token: readyToken)
        if view.controller != nil {
            reply.success(nil)
            return
        }
        let styleURI = (params["styleUri"] as? String).flatMap(StyleURI.init(rawValue:)) ?? .standard
        let mapOptions = (params["mapOptions"] as? [String: Any]).map(Mappers.mapOptions) ?? MapOptions()
        let cameraOptions = (params["cameraOptions"] as? [String: Any]).map(Mappers.cameraOptions)
        let initOptions = MapInitOptions(mapOptions: mapOptions,
                                         cameraOptions: cameraOptions,
                                         styleURI: styleURI)
        let mapView = MapView(frame: view.bounds, mapInitOptions: initOptions)
        mapView.isOpaque = (params["isOpaque"] as? Bool) ?? true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        let controller = MapController(mapView: mapView, viewId: viewId)
        view.controller = controller
        MapboxKitPlugin.shared.register(controller)
        if let types = (params["eventTypes"] as? [Any])?.compactMap({ ($0 as? NSNumber)?.intValue }) {
            controller.presubscribe(types: types)
        }
        mapboxKitLog("map view \(viewId) created")
        reply.success(nil)
    }
}

@_cdecl("MapboxKitRegisterProvider")
public func MapboxKitRegisterProvider() {
    guard let s = dlsym(dlopen(nil, RTLD_NOLOAD), "DNRegisterPluginProvider") else {
        mapboxKitLog("dlsym DNRegisterPluginProvider FAILED — is dartnative_ios linked?"); return
    }
    typealias _RegFn = @convention(c) (Int64, Int64) -> Void
    let reg = unsafeBitCast(s, to: _RegFn.self)
    reg(
        unsafeBitCast(_createView as @convention(c) (Int32) -> Int64, to: Int64.self),
        unsafeBitCast(_handleMutation as @convention(c)
            (Int64, Int32, UnsafePointer<UInt8>?, Int32) -> Void, to: Int64.self)
    )
}
