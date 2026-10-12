package com.asctechsoft.muvik

import android.content.Intent
import android.os.Build
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Extends AudioServiceActivity so the single audio_service handler is shared by
 * UI, notification, lock screen and headset buttons.
 */
class MainActivity : AudioServiceActivity() {
    companion object {
        const val SYSTEM_UI_CHANNEL = "com.asctechsoft.muvik/system_ui"
        const val NUDGE_CHANNEL = "com.asctechsoft.muvik/nudge"
    }

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

        MethodChannel(messenger, NUDGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    NudgeScheduler.schedule(
                        this,
                        call.argument<Int>("hour") ?: 19,
                        call.argument<String>("title") ?: "",
                        call.argument<String>("body") ?: "",
                    )
                    result.success(null)
                }
                "cancel" -> {
                    NudgeScheduler.cancel(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Dart re-hides after changing the system UI mode at startup.
        MethodChannel(messenger, SYSTEM_UI_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "hideNavigationBar") {
                hideNavigationBar()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    // Immersive: the device navigation bar stays hidden; a swipe from the
    // bottom shows it briefly. Re-applied after Flutter restores its own
    // system UI flags on resume, and after system dialogs take the focus.
    override fun onPostResume() {
        super.onPostResume()
        hideNavigationBar()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideNavigationBar()
    }

    private fun hideNavigationBar() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let {
                it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                it.hide(WindowInsets.Type.navigationBars())
            }
        } else {
            val decor = window.decorView
            @Suppress("DEPRECATION")
            decor.systemUiVisibility = decor.systemUiVisibility or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        }
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
