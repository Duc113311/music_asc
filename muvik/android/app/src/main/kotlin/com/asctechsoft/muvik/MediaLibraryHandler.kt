package com.asctechsoft.muvik

import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.storage.StorageManager
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.util.Size
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Reads local audio through MediaStore (volumes) and the Storage Access
 * Framework (picked folders). All IO runs off the main thread.
 */
class MediaLibraryHandler(private val activity: Activity) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.asctechsoft.muvik/media_library"
        private const val REQUEST_PICK_TREE = 7311
        private val AUDIO_EXTENSIONS = setOf(
            "mp3", "m4a", "aac", "flac", "wav", "ogg", "oga", "opus", "wma", "amr", "3gp", "mka", "mid", "midi"
        )
    }

    private val context: Context get() = activity.applicationContext
    private val io: ExecutorService = Executors.newFixedThreadPool(2)
    private val main = Handler(Looper.getMainLooper())
    private var pendingPick: MethodChannel.Result? = null

    fun dispose() {
        io.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(result)
            else -> io.execute {
                try {
                    val value = handleBackground(call)
                    main.post { result.success(value) }
                } catch (e: NotImplementedError) {
                    main.post { result.notImplemented() }
                } catch (e: SecurityException) {
                    main.post { result.error("permission_denied", e.message, null) }
                } catch (e: Exception) {
                    main.post { result.error("media_error", e.message, null) }
                }
            }
        }
    }

    private fun handleBackground(call: MethodCall): Any? = when (call.method) {
        "sdkInt" -> Build.VERSION.SDK_INT
        "getVolumes" -> getVolumes()
        "countVolume" -> countVolume(call.argument<String>("volume")!!)
        "queryVolume" -> queryVolume(
            call.argument<String>("volume")!!,
            call.argument<Int>("offset") ?: 0,
            call.argument<Int>("limit") ?: 300
        )
        "hasTreePermission" -> hasTreePermission(call.argument<String>("uri")!!)
        "releaseTree" -> releaseTree(call.argument<String>("uri")!!)
        "listTree" -> listTree(call.argument<String>("uri")!!)
        "readMetadata" -> readMetadata(call.argument<List<String>>("uris") ?: emptyList())
        "getArtwork" -> getArtwork(call.argument<String>("uri")!!, call.argument<Int>("size") ?: 256)
        "getAudioFormat" -> getAudioFormat(call.argument<String>("uri")!!)
        "existing" -> existing(call.argument<List<String>>("uris") ?: emptyList())
        else -> throw NotImplementedError()
    }

    // ---------------- volumes (MediaStore) ----------------

    private fun getVolumes(): List<Map<String, Any?>> {
        val sm = context.getSystemService(Context.STORAGE_SERVICE) as StorageManager
        val out = mutableListOf<Map<String, Any?>>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val mediaVolumes = MediaStore.getExternalVolumeNames(context)
            for (v in sm.storageVolumes) {
                val name = v.mediaStoreVolumeName ?: continue
                if (!mediaVolumes.contains(name)) continue
                val free = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) v.directory?.freeSpace else null
                out.add(
                    mapOf(
                        "name" to name,
                        "description" to v.getDescription(context),
                        "isPrimary" to v.isPrimary,
                        "isRemovable" to v.isRemovable,
                        "mounted" to (v.state == Environment.MEDIA_MOUNTED || v.state == Environment.MEDIA_MOUNTED_READ_ONLY),
                        "freeBytes" to free
                    )
                )
            }
        } else {
            out.add(
                mapOf(
                    "name" to MediaStore.VOLUME_EXTERNAL,
                    "description" to "Internal storage",
                    "isPrimary" to true,
                    "isRemovable" to false,
                    "mounted" to (Environment.getExternalStorageState() == Environment.MEDIA_MOUNTED),
                    "freeBytes" to null
                )
            )
        }
        return out
    }

    private fun audioUri(volume: String): Uri =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) MediaStore.Audio.Media.getContentUri(volume)
        else MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

    private val audioSelection =
        "${MediaStore.Audio.Media.IS_ALARM} = 0 AND ${MediaStore.Audio.Media.IS_NOTIFICATION} = 0 AND " +
            "${MediaStore.Audio.Media.IS_RINGTONE} = 0"

    private fun countVolume(volume: String): Int {
        context.contentResolver.query(
            audioUri(volume), arrayOf(MediaStore.Audio.Media._ID), audioSelection, null, null
        )?.use { return it.count }
        return 0
    }

    @Suppress("DEPRECATION")
    private fun queryVolume(volume: String, offset: Int, limit: Int): List<Map<String, Any?>> {
        val uri = audioUri(volume)
        val cols = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.MIME_TYPE,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.DATE_ADDED
        )
        val hasRelative = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
        cols.add(if (hasRelative) MediaStore.Audio.Media.RELATIVE_PATH else MediaStore.Audio.Media.DATA)

        val out = mutableListOf<Map<String, Any?>>()
        context.contentResolver.query(
            uri, cols.toTypedArray(), audioSelection, null, "${MediaStore.Audio.Media._ID} ASC"
        )?.use { c ->
            if (!c.moveToPosition(offset)) return out
            val iId = c.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val iTitle = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val iArtist = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val iAlbum = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val iAlbumId = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val iDur = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val iSize = c.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val iMime = c.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)
            val iName = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val iAdded = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val iPath = c.getColumnIndexOrThrow(cols.last())
            do {
                val id = c.getLong(iId)
                val name = c.getString(iName) ?: ""
                val rawPath = c.getString(iPath) ?: ""
                val relative = if (hasRelative) rawPath else legacyRelativePath(rawPath, name)
                out.add(
                    mapOf(
                        "uri" to ContentUris.withAppendedId(uri, id).toString(),
                        "mediaId" to id,
                        "title" to c.getString(iTitle),
                        "artist" to c.getString(iArtist),
                        "album" to c.getString(iAlbum),
                        "albumId" to c.getLong(iAlbumId),
                        "durationMs" to c.getLong(iDur),
                        "size" to c.getLong(iSize),
                        "mime" to c.getString(iMime),
                        "displayName" to name,
                        "relativePath" to relative,
                        "dateAddedMs" to c.getLong(iAdded) * 1000L
                    )
                )
            } while (out.size < limit && c.moveToNext())
        }
        return out
    }

    @Suppress("DEPRECATION")
    private fun legacyRelativePath(data: String, name: String): String {
        val root = Environment.getExternalStorageDirectory().absolutePath.trimEnd('/') + "/"
        var dir = if (data.endsWith(name)) data.substring(0, data.length - name.length) else data
        if (dir.startsWith(root)) dir = dir.substring(root.length)
        return if (dir.isEmpty() || dir.endsWith("/")) dir else "$dir/"
    }

    // ---------------- SAF trees ----------------

    private fun pickFolder(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "Folder picker already open", null)
            return
        }
        pendingPick = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            )
        }
        try {
            @Suppress("DEPRECATION")
            activity.startActivityForResult(intent, REQUEST_PICK_TREE)
        } catch (e: Exception) {
            pendingPick = null
            result.error("no_picker", e.message, null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK_TREE) return false
        val result = pendingPick ?: return true
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        try {
            context.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } catch (_: SecurityException) {
            // Some providers do not offer persistable grants; access lasts for this session.
        }
        result.success(mapOf("uri" to uri.toString(), "name" to treeDisplayName(uri)))
        return true
    }

    private fun treeDisplayName(tree: Uri): String {
        val docUri = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        try {
            context.contentResolver.query(
                docUri, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null
            )?.use { c -> if (c.moveToFirst()) return c.getString(0) ?: "" }
        } catch (_: Exception) {
        }
        return DocumentsContract.getTreeDocumentId(tree).substringAfterLast(':')
    }

    private fun hasTreePermission(uri: String): Boolean =
        context.contentResolver.persistedUriPermissions.any { it.uri.toString() == uri && it.isReadPermission }

    private fun releaseTree(uri: String): Boolean {
        try {
            context.contentResolver.releasePersistableUriPermission(Uri.parse(uri), Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } catch (_: SecurityException) {
        }
        return true
    }

    private fun listTree(treeUri: String): List<Map<String, Any?>> {
        val tree = Uri.parse(treeUri)
        val out = mutableListOf<Map<String, Any?>>()
        val stack = ArrayDeque<Pair<String, String>>() // documentId, relative path
        stack.add(DocumentsContract.getTreeDocumentId(tree) to "")
        val cols = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED
        )
        while (stack.isNotEmpty()) {
            val (docId, rel) = stack.removeFirst()
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, docId)
            context.contentResolver.query(children, cols, null, null, null)?.use { c ->
                while (c.moveToNext()) {
                    val id = c.getString(0)
                    val name = c.getString(1) ?: ""
                    val mime = c.getString(2) ?: ""
                    if (mime == DocumentsContract.Document.MIME_TYPE_DIR) {
                        if (!name.startsWith(".")) stack.add(id to "$rel$name/")
                        continue
                    }
                    val ext = name.substringAfterLast('.', "").lowercase()
                    if (!mime.startsWith("audio/") && ext !in AUDIO_EXTENSIONS) continue
                    out.add(
                        mapOf(
                            "uri" to DocumentsContract.buildDocumentUriUsingTree(tree, id).toString(),
                            "displayName" to name,
                            "mime" to mime,
                            "size" to (if (c.isNull(3)) 0L else c.getLong(3)),
                            "dateAddedMs" to (if (c.isNull(4)) 0L else c.getLong(4)),
                            "relativePath" to rel
                        )
                    )
                }
            }
        }
        return out
    }

    private fun readMetadata(uris: List<String>): Map<String, Map<String, Any?>> {
        val out = mutableMapOf<String, Map<String, Any?>>()
        for (u in uris) {
            val r = MediaMetadataRetriever()
            try {
                r.setDataSource(context, Uri.parse(u))
                out[u] = mapOf(
                    "title" to r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE),
                    "artist" to r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST),
                    "album" to r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM),
                    "durationMs" to (r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L)
                )
            } catch (_: Exception) {
                // unreadable / unsupported: omitted so Dart reports it as skipped
            } finally {
                try { r.release() } catch (_: Exception) {}
            }
        }
        return out
    }

    // ---------------- artwork / format ----------------

    private fun getArtwork(uri: String, size: Int): ByteArray? {
        val u = Uri.parse(uri)
        var bmp: Bitmap? = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && u.authority == MediaStore.AUTHORITY) {
            bmp = try { context.contentResolver.loadThumbnail(u, Size(size, size), null) } catch (_: Exception) { null }
        }
        if (bmp == null) {
            val r = MediaMetadataRetriever()
            try {
                r.setDataSource(context, u)
                val bytes = r.embeddedPicture
                if (bytes != null) {
                    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
                    var sample = 1
                    while (bounds.outWidth / (sample * 2) >= size && bounds.outHeight / (sample * 2) >= size) sample *= 2
                    bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, BitmapFactory.Options().apply { inSampleSize = sample })
                }
            } catch (_: Exception) {
            } finally {
                try { r.release() } catch (_: Exception) {}
            }
        }
        val b = bmp ?: return null
        val scaled = if (b.width > size || b.height > size) {
            val ratio = size.toFloat() / maxOf(b.width, b.height)
            Bitmap.createScaledBitmap(b, (b.width * ratio).toInt().coerceAtLeast(1), (b.height * ratio).toInt().coerceAtLeast(1), true)
        } else b
        val os = ByteArrayOutputStream()
        scaled.compress(Bitmap.CompressFormat.JPEG, 85, os)
        if (scaled !== b) scaled.recycle()
        b.recycle()
        return os.toByteArray()
    }

    private fun getAudioFormat(uri: String): Map<String, Any?>? {
        val ex = MediaExtractor()
        try {
            ex.setDataSource(context, Uri.parse(uri), null)
            for (i in 0 until ex.trackCount) {
                val f = ex.getTrackFormat(i)
                val mime = f.getString(MediaFormat.KEY_MIME) ?: continue
                if (!mime.startsWith("audio/")) continue
                fun int(key: String): Int? = if (f.containsKey(key)) f.getInteger(key) else null
                return mapOf(
                    "mime" to mime,
                    "sampleRate" to int(MediaFormat.KEY_SAMPLE_RATE),
                    "channels" to int(MediaFormat.KEY_CHANNEL_COUNT),
                    "bitrate" to int(MediaFormat.KEY_BIT_RATE)
                )
            }
            return null
        } catch (_: Exception) {
            return null
        } finally {
            ex.release()
        }
    }

    private fun existing(uris: List<String>): List<String> = uris.filter { u ->
        try {
            context.contentResolver.openFileDescriptor(Uri.parse(u), "r")?.use { true } ?: false
        } catch (_: Exception) {
            false
        }
    }
}
