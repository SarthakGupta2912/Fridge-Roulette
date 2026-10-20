# Fridge Roulette release rules.
# The Ultralytics plugin also ships its own consumer rules. These extra rules keep
# the on-device model engine safe when R8 shrinks and renames the app.

# Newer Flutter plugins (shared_preferences, path_provider) call Kotlin suspend
# functions through JNI. JNI looks methods up by their exact descriptor, so R8
# must not rename Continuation or the plugin classes. Without this the release
# build fails at startup with "NoSuchMethodError ... getAll(...Continuation;)".
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result** { *; }
-keep class kotlin.Unit { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class com.bbflight.background_downloader.** { *; }

# The YOLO plugin talks to native code through JNI.
-keep class com.ultralytics.yolo.** { *; }
-keep interface com.ultralytics.yolo.** { *; }

# LiteRT runs model methods through JNI and reflection.
-keep class com.google.ai.edge.litert.** { *; }
-keep interface com.google.ai.edge.litert.** { *; }
-dontwarn com.google.ai.edge.litert.**

# LiteRT pulls in Play Asset Delivery, which pulls in WorkManager. WorkManager
# opens its Room database by name at startup, so R8 must not rename these.
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.WorkDatabase_Impl$* { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keepclassmembers class * extends androidx.room.RoomDatabase {
    <init>();
}

# Older TensorFlow Lite metadata readers use reflection.
-keep class org.tensorflow.** { *; }
-keep interface org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# The plugin reads model metadata with SnakeYAML.
-keep class org.yaml.snakeyaml.** { *; }
-dontwarn org.yaml.snakeyaml.**

# ML Kit finds its component registrars by name from AndroidManifest metadata.
# They are never referenced from Java/Kotlin, so R8 removes their constructors
# unless we keep them. Without these rules OCR fails in release builds with
# "Invalid component registrar".
-keep class com.google.mlkit.common.internal.CommonComponentRegistrar { *; }
-keep class com.google.mlkit.vision.common.internal.VisionCommonRegistrar { *; }
-keep class com.google.mlkit.vision.text.internal.TextRegistrar { *; }

# Fridge Roulette bundles only ML Kit's Latin text model. The OCR plugin also
# mentions the Chinese, Devanagari, Japanese and Korean options, but those
# classes are not part of this build, so R8 should not look for them.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Every JNI entry point must keep its name.
-keepclasseswithmembernames class * {
    native <methods>;
}
