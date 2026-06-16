import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load the release signing credentials from android/key.properties. That file is
// gitignored — only a placeholder template is committed — so real passwords stay
// local. If it's absent (e.g. a fresh clone before keys are dropped in), the
// release signing config below resolves to nulls and the build still runs for
// debug/profile.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.rostrik_mvp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time.* which is API 26+;
        // desugaring back-fills it for our minSdk (21) so the alarm engine
        // works on older Android too.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.rostrik.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // google_mlkit_text_recognition (and uCrop via image_cropper) require
        // API 21+. Floor at 21 without downgrading a higher Flutter default.
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            // Signed with the upload keystore (credentials from key.properties).
            signingConfig = signingConfigs.getByName("release")
            // Feed R8 the ML Kit -dontwarn rules (the release build minifies with
            // R8; without these the google_mlkit_text_recognition CJK references
            // fail the build). Keeps the default optimized rules too.
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

dependencies {
    // Required by flutter_local_notifications via the core-library-desugaring
    // flag above. Version pinned per the plugin's README (>= 2.1.4).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // WorkManager — used by BootReceiver → AlarmSyncWorker to run a
    // headless Flutter engine on the boot path. The BroadcastReceiver
    // itself has a ~10s ANR budget which isn't enough to start an
    // engine, open Hive, and reconcile, so the receiver enqueues a
    // OneTimeWorkRequest and the Worker (off the main thread, no time
    // budget) does the real work. -ktx pulls in the suspend
    // CoroutineWorker API that AlarmSyncWorker extends.
    implementation("androidx.work:work-runtime-ktx:2.9.1")
}
