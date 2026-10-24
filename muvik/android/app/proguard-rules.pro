# R8 rules for release builds (flavor product / any --release).
# Flutter's own rules are added by the Flutter Gradle plugin; these cover the
# parts that are reached only by name (manifest, platform channels, plugins).

# Muvik native handlers (MethodChannel handlers, notification, receivers).
-keep class com.asctechsoft.muvik.** { *; }

# audio_service: media session, browser service and button receiver are
# declared in the manifest and talk to the Dart side by reflection-like callbacks.
-keep class com.ryanheise.audioservice.** { *; }
-keep class androidx.media.** { *; }
-keep class android.support.v4.media.** { *; }

# just_audio / ExoPlayer (Media3).
-keep class com.ryanheise.just_audio.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Crashlytics: keep file names and line numbers so reports stay readable.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
