-dontwarn javax.lang.model.**
-dontwarn com.google.mediapipe.proto.**

# Keep MediaPipe classes and native methods
-keep class com.google.mediapipe.** { *; }
-keepclassmembers class com.google.mediapipe.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep protobuf classes used by MediaPipe
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Keep TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

