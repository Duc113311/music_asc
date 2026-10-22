package com.asctechsoft.muvik

import android.media.audiofx.BassBoost
import android.media.audiofx.DynamicsProcessing
import android.os.Build
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
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
    private var loudness: LoudnessEnhancer? = null
    private var dynamics: DynamicsProcessing? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "attach" -> result.success(attach(call.argument<Int>("sessionId") ?: 0))
                "apply" -> {
                    apply(
                        call.argument<Boolean>("enabled") ?: false,
                        call.argument<List<Int>>("bandLevelsMb") ?: emptyList(),
                        call.argument<Int>("bassStrength") ?: 0,
                        call.argument<Int>("virtualizerStrength") ?: 0,
                        call.argument<Int>("loudnessGainMb") ?: 0,
                        call.argument<Boolean>("loudMode") ?: false
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
        if (id != sessionId || equalizer == null && bass == null && virtualizer == null && loudness == null && dynamics == null) {
            release()
            sessionId = id
            equalizer = try { Equalizer(0, id) } catch (_: Exception) { null }
            bass = try { BassBoost(0, id).takeIf { it.strengthSupported } } catch (_: Exception) { null }
            virtualizer = try { Virtualizer(0, id).takeIf { it.strengthSupported } } catch (_: Exception) { null }
            loudness = try { LoudnessEnhancer(id) } catch (_: Exception) { null }
            dynamics = createDynamics(id)
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
            "virtualizerSupported" to (virtualizer != null),
            "loudnessSupported" to (loudness != null),
            "dynamicsSupported" to (dynamics != null)
        )
    }

    private fun apply(
        enabled: Boolean,
        levelsMb: List<Int>,
        bassStrength: Int,
        virtStrength: Int,
        loudnessGainMb: Int,
        loudMode: Boolean
    ) {
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
        // "Loud mode": compressor + limiter, so quiet tracks come up and
        // loud ones never clip (TikTok-style dense, even sound).
        dynamics?.let { it.enabled = loudMode }

        // Loudness boost is independent of the EQ switch: 0 mB means off.
        loudness?.let {
            val gain = loudnessGainMb.coerceIn(0, 1000)
            it.setTargetGain(gain)
            it.enabled = gain > 0
        }
    }

    private fun release() {
        try { equalizer?.release() } catch (_: Exception) {}
        try { bass?.release() } catch (_: Exception) {}
        try { virtualizer?.release() } catch (_: Exception) {}
        try { loudness?.release() } catch (_: Exception) {}
        try { dynamics?.release() } catch (_: Exception) {}
        equalizer = null
        bass = null
        virtualizer = null
        loudness = null
        dynamics = null
    }

    private fun createDynamics(id: Int): DynamicsProcessing? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return null
        return try {
            val channels = 2
            val config = DynamicsProcessing.Config.Builder(
                DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION,
                channels,
                false, 0, // pre-EQ
                true, 1, // one multiband-compressor band = a plain compressor
                false, 0, // post-EQ
                true, // limiter
            ).build()
            val dp = DynamicsProcessing(0, id, config)
            for (ch in 0 until channels) {
                dp.setMbcBandByChannelIndex(
                    ch, 0,
                    DynamicsProcessing.MbcBand(
                        true, 20000f,
                        10f, 150f, // attack / release ms
                        3f, -26f, 8f, // ratio, threshold dB, knee
                        -90f, 1f, 0f, 9f, // gate, expander, pre-gain, make-up gain
                    ),
                )
                dp.setLimiterByChannelIndex(
                    ch,
                    DynamicsProcessing.Limiter(
                        true, true, 0,
                        1f, 60f, 12f, -1.5f, 0f,
                    ),
                )
            }
            dp.enabled = false
            dp
        } catch (_: Throwable) {
            null
        }
    }
}
