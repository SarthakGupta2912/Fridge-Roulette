import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The signing key lives on this computer only. It is listed in .gitignore.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKey = keystorePropertiesFile.exists()
if (hasReleaseKey) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sarthakgupta.fridgeroulette"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sarthakgupta.fridgeroulette"
        // Android 7.0. Flutter's current minimum is API 24, and the model
        // engine needs at least API 23.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use the real upload key when key.properties exists.
            // Otherwise a debug key is used so the project still builds for testing.
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true

            // Native debug symbol files added about 65 MB to the raw AAB.
            // They are not part of the installed app; keep them out of the
            // Play bundle so the upload stays small.
            ndk {
                debugSymbolLevel = "none"
            }

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    packaging {
        jniLibs {
            // Compress the native libraries in the APK. Android extracts them
            // once at install time. This cuts the download size roughly in half
            // without removing any device support.
            useLegacyPackaging = true

            // The MediaPipe image generator is not used: the app only runs the
            // text recipe model and the YOLO food detector. Its three native
            // libraries are large and would otherwise be shipped for nothing.
            excludes += setOf(
                "lib/**/libimagegenerator_gpu.so",
                "lib/**/libmediapipe_tasks_vision_jni.so",
                "lib/**/libmediapipe_tasks_vision_image_generator_jni.so",

                // Phones and tablets use ARM. x86_64 libraries are only for
                // desktop emulators and are the largest ABI in the bundle.
                // Both 64-bit and 32-bit ARM devices stay supported.
                "lib/x86_64/**",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
