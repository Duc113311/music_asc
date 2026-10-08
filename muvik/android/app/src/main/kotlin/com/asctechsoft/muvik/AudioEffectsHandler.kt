package com.asctechsoft.muvik

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.Virtualizer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Binds Android audio effects to the player's audio session. Each effect is
 * optional: devices that refuse one report it as unsupported instead of failing.
 */
class AudioEffectsHandler : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.asctechsoft.muvik/audio_effects"
    }

    private var sessionId: Int = 0
    private var equalizer: Equalizer? = null
    private var bass: BassBoost? = null
    private var virtualizer: Virtualizer? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "attach" -> result.success(attach(call.argument<Int>("sessionId") ?: 0))
                "apply" -> {
                    apply(
                        call.argument<Boolean>("enabled") ?: false,
                        call.argument<List<Int>>("bandLevelsMb") ?: emptyList(),
                        call.argument<Int>("bassStrength") ?: 0,
                        call.argument<Int>("virtualizerStrength") ?: 0
                    )
                    result.success(null)
                }
                "release" -> {
                    release()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("effects_error", e.message, null)
        }
    }

    private fun attach(id: Int): Map<String, Any?> {
        if (id != sessionId || equalizer == null && bass == null && virtualizer == null) {
            release()
            sessionId = id
            equalizer = try { Equalizer(0, id) } catch (_: Exception) { null }
            bass = try { BassBoost(0, id).takeIf { it.strengthSupported } } catch (_: Exception) { null }
            virtualizer = try { Virtualizer(0, id).takeIf { it.strengthSupported } } catch (_: Exception) { null }
        }
        val eq = equalizer
        val centers = mutableListOf<Double>()
        var minMb = -1500
        var maxMb = 1500
        if (eq != null) {
            for (b in 0 until eq.numberOfBands) centers.add(eq.getCenterFreq(b.toShort()) / 1000.0)
            val range = eq.bandLevelRange
            minMb = range[0].toInt()
            maxMb = range[1].toInt()
        }
        return mapOf(
            "eqSupported" to (eq != null),
            "bandCentersHz" to centers,
            "minLevelMb" to minMb,
            "maxLevelMb" to maxMb,
            "bassSupported" to (bass != null),
            "virtualizerSupported" to (virtualizer != null)
        )
    }

    private fun apply(enabled: Boolean, levelsMb: List<Int>, bassStrength: Int, virtStrength: Int) {
        equalizer?.let { eq ->
            val range = eq.bandLevelRange
            for (b in 0 until minOf(eq.numberOfBands.toInt(), levelsMb.size)) {
                val level = levelsMb[b].coerceIn(range[0].toInt(), range[1].toInt())
                eq.setBandLevel(b.toShort(), level.toShort())
            }
            eq.enabled = enabled
        }
        bass?.let {
            it.setStrength(bassStrength.coerceIn(0, 1000).toShort())
            it.enabled = enabled && bassStrength > 0
        }
        virtualizer?.let {
            it.setStrength(virtStrength.coerceIn(0, 1000).toShort())
            it.enabled = enabled && virtStrength > 0
        }
    }

    private fun release() {
        try { equalizer?.release() } catch (_: Exception) {}
        try { bass?.release() } catch (_: Exception) {}
        try { virtualizer?.release() } catch (_: Exception) {}
        equalizer = null
        bass = null
        virtualizer = null
    }
}
