# Fridge Roulette release rules.
# The Ultralytics plugin also ships its own consumer rules. These extra rules keep
# the on-device model engine safe when R8 shrinks and renames the app.

# The YOLO plugin talks to native code through JNI.
-keep class com.ultralytics.yolo.** { *; }
-keep interface com.ultralytics.yolo.** { *; }

# LiteRT runs model methods through JNI and reflection.
-keep class com.google.ai.edge.litert.** { *; }
-keep interface com.google.ai.edge.litert.** { *; }
-dontwarn com.google.ai.edge.litert.**

# Older TensorFlow Lite metadata readers use reflection.
-keep class org.tensorflow.** { *; }
-keep interface org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# The plugin reads model metadata with SnakeYAML.
-keep class org.yaml.snakeyaml.** { *; }
-dontwarn org.yaml.snakeyaml.**

# Every JNI entry point must keep its name.
-keepclasseswithmembernames class * {
    native <methods>;
}
