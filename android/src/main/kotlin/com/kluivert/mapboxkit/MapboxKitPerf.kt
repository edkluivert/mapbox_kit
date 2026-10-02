package com.kluivert.mapboxkit

import org.json.JSONObject

/**
 * The time each method spends on the main thread inside [MapboxKitBridge.invoke]
 * (decoding its arguments and running it), summed per method until Dart's
 * `options#perfReport` reads and resets it. Dart prints it next to its own
 * figures while `mapboxKitPerfLogs` is on.
 */
object MapboxKitPerf {
    private class Stats(var count: Int = 0, var micros: Long = 0, var maxMicros: Long = 0)

    private val stats = HashMap<String, Stats>()

    fun record(method: String, nanos: Long) {
        if (method == "options#perfReport") return
        val micros = nanos / 1000
        val s = stats.getOrPut(method) { Stats() }
        s.count++
        s.micros += micros
        if (micros > s.maxMicros) s.maxMicros = micros
    }

    fun report(): JSONObject {
        val out = JSONObject()
        for ((method, s) in stats) {
            out.put(method, JSONObject().put("count", s.count).put("micros", s.micros).put("maxMicros", s.maxMicros))
        }
        stats.clear()
        return out
    }
}
