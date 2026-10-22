package com.asctechsoft.muvik

import android.content.Context
import android.net.Uri
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.charset.Charset

/**
 * Reads lyrics embedded in an audio file's tags: ID3v2 USLT (mp3), Vorbis
 * comment LYRICS / UNSYNCEDLYRICS (flac) and the iTunes ©lyr atom (m4a/mp4).
 * Returns null when the file carries none. Text may be plain or LRC with
 * `[mm:ss.xx]` stamps; the Dart side decides which.
 */
object LyricsReader {
    private const val MAX_TEXT = 1 shl 20 // 1 MB of lyrics is already absurd

    fun read(context: Context, uri: Uri): String? {
        val pfd = context.contentResolver.openFileDescriptor(uri, "r") ?: return null
        pfd.use {
            FileInputStream(it.fileDescriptor).use { stream ->
                val ch = stream.channel
                val head = readAt(ch, 0, 12) ?: return null
                return try {
                    when {
                        head[0] == 'I'.code.toByte() && head[1] == 'D'.code.toByte() &&
                            head[2] == '3'.code.toByte() -> readId3(ch)
                        head[0] == 'f'.code.toByte() && head[1] == 'L'.code.toByte() &&
                            head[2] == 'a'.code.toByte() && head[3] == 'C'.code.toByte() -> readFlac(ch)
                        head[4] == 'f'.code.toByte() && head[5] == 't'.code.toByte() &&
                            head[6] == 'y'.code.toByte() && head[7] == 'p'.code.toByte() -> readMp4(ch)
                        else -> null
                    }?.trim()?.takeIf { s -> s.isNotEmpty() }
                } catch (_: Exception) {
                    null
                }
            }
        }
    }

    private fun readAt(ch: FileChannel, pos: Long, len: Int): ByteArray? {
        if (len < 0 || pos < 0 || pos + len > ch.size()) return null
        val buf = ByteBuffer.allocate(len)
        var off = pos
        while (buf.hasRemaining()) {
            val n = ch.read(buf, off)
            if (n <= 0) return null
            off += n
        }
        return buf.array()
    }

    private fun be32(b: ByteArray, o: Int) =
        ((b[o].toInt() and 0xFF) shl 24) or ((b[o + 1].toInt() and 0xFF) shl 16) or
            ((b[o + 2].toInt() and 0xFF) shl 8) or (b[o + 3].toInt() and 0xFF)

    private fun syncsafe(b: ByteArray, o: Int) =
        ((b[o].toInt() and 0x7F) shl 21) or ((b[o + 1].toInt() and 0x7F) shl 14) or
            ((b[o + 2].toInt() and 0x7F) shl 7) or (b[o + 3].toInt() and 0x7F)

    // ---- ID3v2 -----------------------------------------------------------

    private fun readId3(ch: FileChannel): String? {
        val h = readAt(ch, 0, 10) ?: return null
        val version = h[3].toInt()
        if (version < 3) return null // v2.2 uses 3-char frame ids; not handled
        val flags = h[5].toInt()
        val tagSize = syncsafe(h, 6)
        var pos = 10L
        val end = 10L + tagSize
        if (flags and 0x40 != 0) { // extended header
            val e = readAt(ch, pos, 4) ?: return null
            pos += if (version == 4) syncsafe(e, 0) else be32(e, 0) + 4
        }
        while (pos + 10 <= end) {
            val fh = readAt(ch, pos, 10) ?: return null
            if (fh[0].toInt() == 0) break // padding
            val id = String(fh, 0, 4, Charsets.ISO_8859_1)
            val size = if (version == 4) syncsafe(fh, 4) else be32(fh, 4)
            if (size < 0) return null
            val body = pos + 10
            if (id == "USLT" && size in 5..MAX_TEXT) {
                val data = readAt(ch, body, size) ?: return null
                return parseUslt(data)
            }
            pos = body + size
        }
        return null
    }

    private fun parseUslt(d: ByteArray): String? {
        val enc = d[0].toInt()
        // d[1..3] = language; then a descriptor ended by a (double) null.
        var i = 4
        val wide = enc == 1 || enc == 2
        if (wide) {
            while (i + 1 < d.size && !(d[i].toInt() == 0 && d[i + 1].toInt() == 0)) i += 2
            i += 2
        } else {
            while (i < d.size && d[i].toInt() != 0) i++
            i += 1
        }
        if (i >= d.size) return null
        val cs: Charset = when (enc) {
            0 -> Charsets.ISO_8859_1
            1 -> Charsets.UTF_16 // BOM-aware
            2 -> Charsets.UTF_16BE
            else -> Charsets.UTF_8
        }
        return String(d, i, d.size - i, cs)
    }

    // ---- FLAC ------------------------------------------------------------

    private fun readFlac(ch: FileChannel): String? {
        var pos = 4L
        while (true) {
            val h = readAt(ch, pos, 4) ?: return null
            val last = h[0].toInt() and 0x80 != 0
            val type = h[0].toInt() and 0x7F
            val len = ((h[1].toInt() and 0xFF) shl 16) or ((h[2].toInt() and 0xFF) shl 8) or
                (h[3].toInt() and 0xFF)
            if (type == 4 && len in 8..(8 shl 20)) {
                val d = readAt(ch, pos + 4, len) ?: return null
                return parseVorbisLyrics(d)
            }
            if (last) return null
            pos += 4L + len
        }
    }

    private fun le32(b: ByteArray, o: Int) =
        (b[o].toInt() and 0xFF) or ((b[o + 1].toInt() and 0xFF) shl 8) or
            ((b[o + 2].toInt() and 0xFF) shl 16) or ((b[o + 3].toInt() and 0xFF) shl 24)

    private fun parseVorbisLyrics(d: ByteArray): String? {
        var p = 0
        val vendor = le32(d, p)
        p += 4 + vendor
        if (p + 4 > d.size) return null
        val count = le32(d, p)
        p += 4
        repeat(count) {
            if (p + 4 > d.size) return null
            val n = le32(d, p)
            p += 4
            if (n < 0 || p + n > d.size) return null
            val s = String(d, p, n, Charsets.UTF_8)
            p += n
            val eq = s.indexOf('=')
            if (eq > 0) {
                val key = s.substring(0, eq).uppercase()
                if (key == "LYRICS" || key == "UNSYNCEDLYRICS" || key == "SYNCEDLYRICS") {
                    return s.substring(eq + 1)
                }
            }
        }
        return null
    }

    // ---- MP4 / M4A ---------------------------------------------------------

    private fun readMp4(ch: FileChannel): String? =
        walkAtoms(ch, 0, ch.size(), 0)

    private fun walkAtoms(ch: FileChannel, start: Long, end: Long, depth: Int): String? {
        if (depth > 6) return null
        var pos = start
        while (pos + 8 <= end) {
            val h = readAt(ch, pos, 8) ?: return null
            var size = (be32(h, 0).toLong() and 0xFFFFFFFFL)
            val type = String(h, 4, 4, Charsets.ISO_8859_1)
            var header = 8L
            if (size == 1L) {
                val ext = readAt(ch, pos + 8, 8) ?: return null
                size = (be32(ext, 0).toLong() shl 32) or (be32(ext, 4).toLong() and 0xFFFFFFFFL)
                header = 16
            } else if (size == 0L) {
                size = end - pos
            }
            if (size < header) return null
            val bodyStart = pos + header
            val bodyEnd = minOf(pos + size, end)
            when (type) {
                "moov", "udta", "ilst" -> walkAtoms(ch, bodyStart, bodyEnd, depth + 1)?.let { return it }
                "meta" -> walkAtoms(ch, bodyStart + 4, bodyEnd, depth + 1)?.let { return it }
                "©lyr" -> {
                    // child "data" atom: size, "data", 4 bytes type/flags, 4 bytes locale, text.
                    val len = (bodyEnd - bodyStart - 16).toInt()
                    if (len in 1..MAX_TEXT) {
                        val t = readAt(ch, bodyStart + 16, len) ?: return null
                        return String(t, Charsets.UTF_8)
                    }
                }
            }
            pos += size
        }
        return null
    }
}
