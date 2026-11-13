# MediaPipe Tasks uses protobuf-lite, which reads message fields by
# reflection (e.g. "platform_"). R8 renames/strips them in release builds,
# causing PlatformException(INIT_ERROR, Field platform_ ... not found).
-keep class com.google.mediapipe.** { *; }
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.mediapipe.**
-dontwarn com.google.protobuf.**
