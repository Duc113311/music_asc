package com.asctechsoft.muvik

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteOrder
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min

/**
 * "Cắt nhạc chuông": draws a waveform, cuts a range of any local audio file
 * into an AAC (.m4a) clip, saves it in the Ringtones / Notifications / Alarms
 * folder through MediaStore and can make it the default sound.
 *
 * Everything runs on the device; nothing is uploaded. The work is done with
 * the platform codecs (MediaExtractor -> MediaCodec decode -> trim + fade ->
 * MediaCodec AAC encode -> MediaMuxer), so no extra library is shipped.
 * Uses the application context and a daemon pool on purpose: it must keep
 * working if the activity goes away (it is not tied to the activity).
 */
class RingtoneHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.asctechsoft.muvik/ringtone"
        private const val AAC_BITRATE = 128_000
        private const val FADE_MS = 200L
    }

    private val io: ExecutorService = Executors.newFixedThreadPool(2) { r ->
        Thread(r, "muvik-ringtone").apply { isDaemon = true }
    }
    private val main = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canWriteSettings" -> result.success(Settings.System.canWrite(context))
            "openWriteSettings" -> {
                val intent = Intent(
                    Settings.ACTION_MANAGE_WRITE_SETTINGS,
                    Uri.parse("package:${context.packageName}"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                result.success(null)
            }
            "waveform" -> async(result) {
                waveform(
                    Uri.parse(call.argument<String>("uri")!!),
                    call.argument<Int>("buckets") ?: 160,
                )
            }
            "cut" -> async(result) {
                cut(
                    uri = Uri.parse(call.argument<String>("uri")!!),
                    startMs = (call.argument<Number>("startMs") ?: 0).toLong(),
                    endMs = (call.argument<Number>("endMs") ?: 0).toLong(),
                    name = call.argument<String>("name") ?: "Muvik",
                    type = call.argument<String>("type") ?: "ringtone",
                )
            }
            "setDefault" -> async(result) {
                setDefault(
                    Uri.parse(call.argument<String>("uri")!!),
                    call.argument<String>("type") ?: "ringtone",
                )
            }
            else -> result.notImplemented()
        }
    }

    private fun async(result: MethodChannel.Result, block: () -> Any?) {
        io.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: SecurityException) {
                main.post { result.error("permission_denied", e.message, null) }
            } catch (e: Throwable) {
                main.post { result.error("ringtone_failed", e.message ?: e.javaClass.simpleName, null) }
            }
        }
    }

    // ------------------------------------------------------------ decoding

    /**
     * Decodes [uri] to 16-bit PCM from [startUs] (0 = from the beginning) and
     * hands every decoded buffer to [onPcm] (presentation time of its first
     * frame, interleaved samples). [onFormat] is called once, before the first
     * buffer. [onPcm] returns false to stop early.
     */
    private fun decode(
        uri: Uri,
        startUs: Long,
        endUs: Long,
        onFormat: (sampleRate: Int, channels: Int) -> Unit,
        onPcm: (ptsUs: Long, pcm: ShortArray) -> Boolean,
    ) {
        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null
        try {
            extractor.setDataSource(context, uri, null)
            var track = -1
            var format: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                if (f.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) {
                    track = i
                    format = f
                    break
                }
            }
            if (track < 0 || format == null) throw IllegalStateException("no audio track")
            extractor.selectTrack(track)
            if (startUs > 0) extractor.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)

            val dec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
            decoder = dec
            dec.configure(format, null, null, 0)
            dec.start()

            val info = MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false
            var formatSent = false
            // Guard against a decoder that never produces output.
            var idleRounds = 0

            while (!outputDone) {
                if (!inputDone) {
                    val inIdx = dec.dequeueInputBuffer(10_000)
                    if (inIdx >= 0) {
                        val buf = dec.getInputBuffer(inIdx)!!
                        val size = extractor.readSampleData(buf, 0)
                        val t = extractor.sampleTime
                        if (size < 0 || (endUs > 0 && t > endUs)) {
                            dec.queueInputBuffer(inIdx, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            dec.queueInputBuffer(inIdx, 0, size, t, 0)
                            extractor.advance()
                        }
                    }
                }
                val outIdx = dec.dequeueOutputBuffer(info, 10_000)
                when {
                    outIdx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        val f = dec.outputFormat
                        onFormat(
                            f.getInteger(MediaFormat.KEY_SAMPLE_RATE),
                            f.getInteger(MediaFormat.KEY_CHANNEL_COUNT),
                        )
                        formatSent = true
                        idleRounds = 0
                    }
                    outIdx >= 0 -> {
                        idleRounds = 0
                        if (info.size > 0) {
                            if (!formatSent) {
                                val f = dec.outputFormat
                                onFormat(
                                    f.getInteger(MediaFormat.KEY_SAMPLE_RATE),
                                    f.getInteger(MediaFormat.KEY_CHANNEL_COUNT),
                                )
                                formatSent = true
                            }
                            val out = dec.getOutputBuffer(outIdx)!!
                            out.position(info.offset)
                            out.limit(info.offset + info.size)
                            val shorts = ShortArray(info.size / 2)
                            out.order(ByteOrder.nativeOrder()).asShortBuffer().get(shorts)
                            if (!onPcm(info.presentationTimeUs, shorts)) outputDone = true
                        }
                        dec.releaseOutputBuffer(outIdx, false)
                        if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
                    }
                    else -> {
                        // INFO_TRY_AGAIN_LATER: input may still be draining.
                        if (inputDone && ++idleRounds > 500) throw IllegalStateException("decoder stalled")
                    }
                }
            }
        } finally {
            runCatching { decoder?.stop() }
            runCatching { decoder?.release() }
            extractor.release()
        }
    }

    private fun durationMs(uri: Uri): Long {
        val r = MediaMetadataRetriever()
        return try {
            r.setDataSource(context, uri)
            r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
        } finally {
            r.release()
        }
    }

    // ------------------------------------------------------------ waveform

    /** [buckets] peak values (0..1) over the whole file, plus its duration. */
    private fun waveform(uri: Uri, buckets: Int): Map<String, Any> {
        val durMs = durationMs(uri)
        val peaks = FloatArray(buckets)
        val durUs = max(1L, durMs * 1000)
        var channels = 2
        decode(
            uri, 0, 0,
            onFormat = { _, ch -> channels = max(1, ch) },
            onPcm = { pts, pcm ->
                val idx = min(buckets - 1, max(0, (pts * buckets / durUs).toInt()))
                var peak = 0
                for (s in pcm) {
                    val a = abs(s.toInt())
                    if (a > peak) peak = a
                }
                val p = peak / 32768f
                if (p > peaks[idx]) peaks[idx] = p
                true
            },
        )
        val top = peaks.maxOrNull() ?: 0f
        val norm = if (top > 0f) peaks.map { (it / top).toDouble() } else peaks.map { 0.0 }
        return mapOf("durationMs" to durMs, "peaks" to norm)
    }

    // ------------------------------------------------------------ cutting

    private class AacWriter(path: String, private val sampleRate: Int, private val channels: Int) {
        private val encoder: MediaCodec
        private val muxer = MediaMuxer(path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        private val info = MediaCodec.BufferInfo()
        private var track = -1
        private var muxerStarted = false
        private var samplesIn = 0L

        init {
            val format = MediaFormat.createAudioFormat(
                MediaFormat.MIMETYPE_AUDIO_AAC, sampleRate, channels,
            ).apply {
                setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                setInteger(MediaFormat.KEY_BIT_RATE, AAC_BITRATE)
                setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 65_536)
            }
            encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
            encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            encoder.start()
        }

        /** [pcm] holds interleaved 16-bit samples for [channels] channels. */
        fun write(pcm: ShortArray, count: Int) {
            var offset = 0
            while (offset < count) {
                val idx = encoder.dequeueInputBuffer(10_000)
                if (idx >= 0) {
                    val buf = encoder.getInputBuffer(idx)!!
                    buf.clear()
                    val n = min(count - offset, buf.remaining() / 2)
                    buf.order(ByteOrder.nativeOrder()).asShortBuffer().put(pcm, offset, n)
                    val ptsUs = samplesIn * 1_000_000L / (sampleRate.toLong() * channels)
                    encoder.queueInputBuffer(idx, 0, n * 2, ptsUs, 0)
                    samplesIn += n
                    offset += n
                }
                drain(false)
            }
        }

        fun finish() {
            var queued = false
            while (!queued) {
                val idx = encoder.dequeueInputBuffer(10_000)
                if (idx >= 0) {
                    val ptsUs = samplesIn * 1_000_000L / (sampleRate.toLong() * channels)
                    encoder.queueInputBuffer(idx, 0, 0, ptsUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                    queued = true
                } else {
                    drain(false)
                }
            }
            drain(true)
            runCatching { encoder.stop() }
            encoder.release()
            if (muxerStarted) muxer.stop()
            muxer.release()
        }

        fun abort() {
            runCatching { encoder.stop() }
            runCatching { encoder.release() }
            runCatching { if (muxerStarted) muxer.stop() }
            runCatching { muxer.release() }
        }

        private fun drain(untilEos: Boolean) {
            while (true) {
                val outIdx = encoder.dequeueOutputBuffer(info, if (untilEos) 10_000 else 0)
                when {
                    outIdx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        track = muxer.addTrack(encoder.outputFormat)
                        muxer.start()
                        muxerStarted = true
                    }
                    outIdx >= 0 -> {
                        if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) info.size = 0
                        if (info.size > 0 && muxerStarted) {
                            val buf = encoder.getOutputBuffer(outIdx)!!
                            buf.position(info.offset)
                            buf.limit(info.offset + info.size)
                            muxer.writeSampleData(track, buf, info)
                        }
                        encoder.releaseOutputBuffer(outIdx, false)
                        if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) return
                    }
                    else -> if (!untilEos) return
                }
            }
        }
    }

    /**
     * Cuts [startMs, endMs) of [uri] into a new AAC clip with a short fade in
     * and out, saves it for [type] ("ringtone", "notification" or "alarm") and
     * returns its content Uri and display name.
     */
    private fun cut(uri: Uri, startMs: Long, endMs: Long, name: String, type: String): Map<String, Any> {
        require(endMs > startMs) { "empty range" }
        val tmp = File(context.cacheDir, "muvik_cut_${System.nanoTime()}.m4a")
        val startUs = startMs * 1000
        val endUs = endMs * 1000
        var writer: AacWriter? = null
        var outChannels = 2
        var rate = 44_100
        var inChannels = 2
        var written = 0L // frames
        try {
            decode(
                uri, startUs, endUs,
                onFormat = { sampleRate, channels ->
                    rate = sampleRate
                    inChannels = max(1, channels)
                    outChannels = min(inChannels, 2)
                    writer = AacWriter(tmp.absolutePath, rate, outChannels)
                },
                onPcm = { pts, pcm ->
                    val w = writer ?: return@decode true
                    val frames = pcm.size / inChannels
                    // Frames of this buffer that fall inside [startUs, endUs).
                    val first = max(0, ceil((startUs - pts) * rate / 1_000_000.0).toInt())
                    val last = min(frames, floor((endUs - pts) * rate / 1_000_000.0).toInt())
                    if (pts >= endUs) return@decode false
                    // Nothing of this buffer is in range: keep going while it is still
                    // before the start (seek lands on an earlier sync point), stop if
                    // the end of the range was inside it.
                    if (first >= last) return@decode last == frames
                    val totalFrames = ((endUs - startUs) * rate / 1_000_000L).coerceAtLeast(1)
                    val fadeFrames = max(1L, FADE_MS * rate / 1000)
                    val count = last - first
                    val out = ShortArray(count * outChannels)
                    for (f in 0 until count) {
                        val frameNo = written + f
                        val gainIn = min(1.0, (frameNo + 1).toDouble() / fadeFrames)
                        val gainOut = min(1.0, (totalFrames - frameNo).toDouble() / fadeFrames)
                        val g = max(0.0, min(gainIn, gainOut))
                        for (c in 0 until outChannels) {
                            val s = pcm[(first + f) * inChannels + c]
                            out[f * outChannels + c] = (s * g).toInt().toShort()
                        }
                    }
                    w.write(out, out.size)
                    written += count
                    last == frames // false once the end of the range was inside this buffer
                },
            )
            val w = writer ?: throw IllegalStateException("nothing decoded")
            if (written <= 0) {
                w.abort()
                throw IllegalStateException("empty clip")
            }
            w.finish()
            val displayName = safeName(name)
            val saved = saveToMediaStore(tmp, displayName, type)
            return mapOf("uri" to saved.toString(), "name" to displayName)
        } catch (e: Throwable) {
            writer?.abort()
            throw e
        } finally {
            tmp.delete()
        }
    }

    private fun safeName(raw: String): String {
        val cleaned = raw.replace(Regex("[\\\\/:*?\"<>|\\u0000-\\u001F]"), " ").trim()
        return cleaned.ifEmpty { "Muvik" }.take(80)
    }

    // ------------------------------------------------------------ saving

    private fun saveToMediaStore(file: File, displayName: String, type: String): Uri {
        val dir = when (type) {
            "notification" -> Environment.DIRECTORY_NOTIFICATIONS
            "alarm" -> Environment.DIRECTORY_ALARMS
            else -> Environment.DIRECTORY_RINGTONES
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "$displayName.m4a")
            put(MediaStore.MediaColumns.TITLE, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, "audio/mp4")
            put(MediaStore.Audio.Media.IS_MUSIC, 0)
            put(MediaStore.Audio.Media.IS_RINGTONE, if (type == "ringtone") 1 else 0)
            put(MediaStore.Audio.Media.IS_NOTIFICATION, if (type == "notification") 1 else 0)
            put(MediaStore.Audio.Media.IS_ALARM, if (type == "alarm") 1 else 0)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, dir)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            } else {
                // Android 9 and older: the file lives at a real path (needs the
                // legacy storage write permission, requested by the app).
                val folder = Environment.getExternalStoragePublicDirectory(dir)
                folder.mkdirs()
                put(MediaStore.MediaColumns.DATA, File(folder, "$displayName.m4a").absolutePath)
            }
        }
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }
        val resolver = context.contentResolver
        val uri = resolver.insert(collection, values) ?: throw IllegalStateException("insert failed")
        try {
            resolver.openOutputStream(uri)!!.use { out ->
                file.inputStream().use { it.copyTo(out) }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                resolver.update(
                    uri,
                    ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
                    null,
                    null,
                )
            }
        } catch (e: Throwable) {
            runCatching { resolver.delete(uri, null, null) }
            throw e
        }
        return uri
    }

    /** Makes the saved clip the default phone ringtone / notification / alarm. */
    private fun setDefault(uri: Uri, type: String): Boolean {
        if (!Settings.System.canWrite(context)) {
            throw SecurityException("write settings not granted")
        }
        val kind = when (type) {
            "notification" -> RingtoneManager.TYPE_NOTIFICATION
            "alarm" -> RingtoneManager.TYPE_ALARM
            else -> RingtoneManager.TYPE_RINGTONE
        }
        RingtoneManager.setActualDefaultRingtoneUri(context, kind, uri)
        return true
    }
}
