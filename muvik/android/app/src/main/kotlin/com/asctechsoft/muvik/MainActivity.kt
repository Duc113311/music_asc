package com.asctechsoft.muvik

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Extends AudioServiceActivity so the single audio_service handler is shared by
 * UI, notification, lock screen and headset buttons.
 */
class MainActivity : AudioServiceActivity() {
    private var mediaLibrary: MediaLibraryHandler? = null
    private var audioEffects: AudioEffectsHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        val library = MediaLibraryHandler(this)
        MethodChannel(messenger, MediaLibraryHandler.CHANNEL).setMethodCallHandler(library)
        mediaLibrary = library

        val effects = AudioEffectsHandler()
        MethodChannel(messenger, AudioEffectsHandler.CHANNEL).setMethodCallHandler(effects)
        audioEffects = effects
    }

    @Deprecated("Uses the classic result API to stay dependency-free")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (mediaLibrary?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        mediaLibrary?.dispose()
        super.onDestroy()
    }
}
