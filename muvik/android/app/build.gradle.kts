import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Optional store signing (git-ignored): android/key.properties with keyAlias,
// keyPassword, storeFile (relative to android/) and storePassword. Without it
// every build is signed with the debug key, so a fresh clone or CI still builds.
val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    FileInputStream(keyPropertiesFile).use { keyProperties.load(it) }
}

android {
    namespace = "com.asctechsoft.muvik"
    // permission_handler_android 14 (via asc_common) needs compileSdk 37; it is
    // backward compatible, so pin it instead of trusting Flutter's default.
    // Same value as smart_drink.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.asctechsoft.muvik"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // API 24+: StorageVolume and stable MediaStore features used by the library scan.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("store") {
            if (keyPropertiesFile.exists()) {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = rootProject.file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    // Flavor names are read in Dart by asc_common AscBuildFlavor (`appFlavor`),
    // same four names and same dimension as smart_drink.
    // alpha = no ads + debug screens + test options, dev = test options/logs,
    // product = store build, claude = builds driven by Claude Code.
    // Same applicationId for all, so google-services.json matches every flavor.
    flavorDimensions += "environment"
    productFlavors {
        create("alpha") {
            dimension = "environment"
            versionNameSuffix = "-alpha"
        }
        create("dev") {
            dimension = "environment"
            versionNameSuffix = "-dev"
        }
        create("product") {
            dimension = "environment"
        }
        create("claude") {
            dimension = "environment"
            versionNameSuffix = "-claude"
        }
    }

    buildTypes {
        release {
            // Store key when android/key.properties exists, else the debug key
            // so `flutter run --release` works without secrets.
            signingConfig = if (keyPropertiesFile.exists()) {
                signingConfigs.getByName("store")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8 shrinks and obfuscates release builds; proguard-rules.pro
            // keeps what is only reached by name (audio_service, just_audio,
            // the native handlers).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
