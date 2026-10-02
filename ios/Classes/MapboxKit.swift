// iOS entry points for mapbox_kit.
//
// Dart resolves these from the app binary. Every reply and stream event goes
// back through one dispatcher slot registered with the framework, always from
// the main thread and never from inside the Dart call itself.

import Foundation
import UIKit

func mapboxKitLog(_ msg: String) { print("[MapboxKit] \(msg)") }

// MARK: - Dispatcher slot

// Heap-allocated so its address never moves: the framework keeps a pointer
// to it and writes 0 into it when a hot restart begins.
private let _dispatcherSlot: UnsafeMutablePointer<Int64> = {
    let p = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
    p.pointee = 0
    return p
}()
private var _slotRegistered = false

private typealias Dispatch = @convention(c) (Int64, Int32, UnsafePointer<CChar>) -> Void

/// Delivers `(token, type, payload)` to Dart on the next main-loop turn,
/// reading the slot fresh so a hot restart drops the event instead of
/// invoking a deleted pointer.
func mapboxKitFireToDart(token: Int64, type: Int32, payload: String) {
    DispatchQueue.main.async {
        let addr = _dispatcherSlot.pointee   // read fresh every time, never cached
        guard addr != 0 else { return }      // a hot restart happened, drop it
        payload.withCString { cStr in
            unsafeBitCast(addr, to: Dispatch.self)(token, type, cStr)
        }
    }
}

/// Called once per Dart session. A second call means the Dart side was
/// restarted: nothing listens to the old tokens any more, so every stream is
/// stopped first, before the new pointer is stored.
@_cdecl("MapboxKitSetDispatcher")
public func MapboxKitSetDispatcher(_ callbackPtr: Int64) {
    if _slotRegistered {
        MapboxKitPlugin.shared.resetAll()
    }
    _dispatcherSlot.pointee = callbackPtr
    if !_slotRegistered {                       // register with the framework once
        _slotRegistered = true
        typealias RegFn = @convention(c) (UnsafeMutablePointer<Int64>) -> Void
        if let sym = dlsym(UnsafeMutableRawPointer(bitPattern: -2),
                           "DNRegisterAsyncDispatcherSlot") {
            unsafeBitCast(sym, to: RegFn.self)(_dispatcherSlot)
        } else {
            mapboxKitLog("DNRegisterAsyncDispatcherSlot not found; hot restart safety off")
        }
    }
}

// MARK: - Reply

/// The reply side of one Dart call or stream (Flutter's `FlutterResult` /
/// `FlutterEventSink` shape). Everything is JSON on the wire.
final class Reply {
    let token: Int64
    init(token: Int64) { self.token = token }

    func success(_ value: Any?) {
        mapboxKitFireToDart(token: token, type: 0, payload: Reply.encode(value))
    }

    func error(code: String, message: String?, details: Any? = nil) {
        let payload: [String: Any] = [
            "code": code,
            "message": message ?? NSNull(),
            "details": details ?? NSNull(),
        ]
        mapboxKitFireToDart(token: token, type: 1, payload: Reply.encode(payload))
    }

    func error(_ error: Error, code: String = "0") {
        self.error(code: code, message: "\(error)")
    }

    /// Runs [body] and replies with its value, or with the thrown error.
    func run(_ body: () throws -> Any?) {
        do {
            success(try body())
        } catch let e {
            error(e)
        }
    }

    static func encode(_ value: Any?) -> String {
        guard let value = value else { return "null" }
        let sanitized = sanitize(value)
        if let data = try? JSONSerialization.data(withJSONObject: sanitized, options: [.fragmentsAllowed]),
           let text = String(data: data, encoding: .utf8) {
            return text
        }
        return "null"
    }

    /// Makes a value JSON-serialisable: nested optionals, NSNull, non-finite
    /// doubles and unknown objects become something the serializer accepts.
    static func sanitize(_ value: Any) -> Any {
        switch value {
        case let dict as [String: Any?]:
            var out: [String: Any] = [:]
            for (k, v) in dict { out[k] = v.map(sanitize) ?? NSNull() }
            return out
        case let dict as [String: Any]:
            return dict.mapValues(sanitize)
        case let array as [Any?]:
            return array.map { $0.map(sanitize) ?? NSNull() }
        case let array as [Any]:
            return array.map(sanitize)
        case let d as Double:
            return d.isFinite ? d : NSNull()
        case let f as Float:
            return f.isFinite ? f : NSNull()
        case is String, is Bool, is Int, is Int64, is Int32, is UInt, is NSNumber, is NSNull:
            return value
        default:
            return String(describing: value)
        }
    }

    static func decode(_ json: String?) -> [String: Any]? {
        guard let json = json, !json.isEmpty, json != "null",
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        else { return nil }
        return object as? [String: Any]
    }
}

// MARK: - Plugin

/// Routes calls and streams to the map controller of the addressed view, and
/// the process-wide options calls to [MapboxKitOptions].
final class MapboxKitPlugin {
    static let shared = MapboxKitPlugin()

    /// Live controllers, for the hot-restart reset.
    private let controllers = NSHashTable<MapController>.weakObjects()
    /// The controller owning each active stream token.
    private var streamOwners: [Int64: MapController] = [:]

    func register(_ controller: MapController) {
        controllers.add(controller)
    }

    func registerStream(token: Int64, owner: MapController) {
        streamOwners[token] = owner
    }

    func unregisterStream(token: Int64) {
        streamOwners[token] = nil
    }

    /// Stops every stream (new Dart session).
    func resetAll() {
        for controller in controllers.allObjects {
            controller.cancelAllStreams()
        }
        streamOwners.removeAll()
    }

    private func controller(for arguments: [String: Any]?) -> MapController? {
        guard let viewId = arguments?["viewId"] as? NSNumber else { return nil }
        return MapboxKitProvider.controller(forViewId: viewId.int64Value)
    }

    /// Returns 0 when the call was accepted (the reply arrives later), 2 for
    /// an unknown method, 3 when the map view is not there (yet).
    func invoke(token: Int64, method: String, arguments: [String: Any]?) -> Int32 {
        let reply = Reply(token: token)
        if method.hasPrefix("options#") {
            return MapboxKitOptions.invoke(method: String(method.dropFirst("options#".count)),
                                           arguments: arguments ?? [:], reply: reply)
        }
        guard let controller = controller(for: arguments) else {
            reply.error(code: "NO_MAP", message: "No map view for \(arguments?["viewId"] ?? "nil")")
            return 0
        }
        return controller.invoke(method: method, arguments: arguments ?? [:], reply: reply)
    }

    /// Returns 0 when the stream started, 2 for an unknown channel.
    func listen(token: Int64, channel: String, arguments: [String: Any]?) -> Int32 {
        let reply = Reply(token: token)
        guard let controller = controller(for: arguments) else {
            reply.error(code: "NO_MAP", message: "No map view for \(arguments?["viewId"] ?? "nil")")
            return 0
        }
        let rc = controller.listen(token: token, channel: channel, arguments: arguments ?? [:], reply: reply)
        if rc == 0 { registerStream(token: token, owner: controller) }
        return rc
    }

    func cancel(token: Int64) -> Int32 {
        if let owner = streamOwners.removeValue(forKey: token) {
            owner.cancelStream(token: token)
        }
        return 0
    }
}

// MARK: - C entry points

@_cdecl("MapboxKitInvoke")
public func MapboxKitInvoke(_ token: Int64,
                            _ method: UnsafePointer<CChar>,
                            _ argumentsJson: UnsafePointer<CChar>?) -> Int32 {
    let start = DispatchTime.now().uptimeNanoseconds
    let name = String(cString: method)
    let arguments = Reply.decode(argumentsJson.map { String(cString: $0) })
    let rc = MapboxKitPlugin.shared.invoke(token: token, method: name, arguments: arguments)
    MapboxKitPerf.record(name, nanos: DispatchTime.now().uptimeNanoseconds - start)
    return rc
}

// MARK: - Diagnostics

/// The time each method spends on the main thread inside `MapboxKitInvoke`
/// (decoding its arguments and running it), summed per method until Dart's
/// `options#perfReport` reads and resets it. Dart prints it next to its own
/// figures while `mapboxKitPerfLogs` is on.
enum MapboxKitPerf {
    private static var stats: [String: (count: Int, micros: Int, maxMicros: Int)] = [:]

    static func record(_ method: String, nanos: UInt64) {
        guard method != "options#perfReport" else { return }
        let micros = Int(nanos / 1000)
        let s = stats[method] ?? (0, 0, 0)
        stats[method] = (s.count + 1, s.micros + micros, max(s.maxMicros, micros))
    }

    static func report() -> [String: Any] {
        defer { stats.removeAll() }
        return stats.mapValues { ["count": $0.count, "micros": $0.micros, "maxMicros": $0.maxMicros] }
    }
}

@_cdecl("MapboxKitListen")
public func MapboxKitListen(_ token: Int64,
                            _ channel: UnsafePointer<CChar>,
                            _ argumentsJson: UnsafePointer<CChar>?) -> Int32 {
    let name = String(cString: channel)
    let arguments = Reply.decode(argumentsJson.map { String(cString: $0) })
    return MapboxKitPlugin.shared.listen(token: token, channel: name, arguments: arguments)
}

@_cdecl("MapboxKitCancel")
public func MapboxKitCancel(_ token: Int64) -> Int32 {
    return MapboxKitPlugin.shared.cancel(token: token)
}
