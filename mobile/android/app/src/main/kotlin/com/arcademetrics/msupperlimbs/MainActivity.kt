package com.arcademetrics.msupperlimbs

import android.graphics.Bitmap
import android.graphics.Matrix
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.arcademetrics.msupperlimbs/mediapipe"
    private lateinit var handDetector: HandLandmarkDetector
    private var poseHelper: PoseLandmarkerHelper? = null

    // Reused to cut GC pressure on the hot path.
    private var pixelBuffer: IntArray = IntArray(0)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        handDetector = HandLandmarkDetector(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        try {
                            val mode = (call.argument<String>("mode") ?: "both").lowercase()
                            if (mode == "pose" || mode == "both") {
                                poseHelper?.clear()
                                poseHelper = PoseLandmarkerHelper(this).also { it.setup() }
                            }
                            if (mode == "hands" || mode == "both") {
                                handDetector.initialize()
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INIT_ERROR", e.message, null)
                        }
                    }

                    "detectFrame" -> {
                        try {
                            val args = call.arguments as? Map<*, *>
                            val bitmap = bitmapFromCall(args)
                                ?: run {
                                    result.error("INVALID_ARGUMENT", "Invalid image", null)
                                    return@setMethodCallHandler
                                }
                            val wantPose = args?.get("pose") as? Boolean ?: true
                            val wantHands = args?.get("hands") as? Boolean ?: true

                            val pose = if (wantPose) serializePose(bitmap) else emptyList()
                            val hands = if (wantHands) {
                                handDetector.detectHandLandmarks(bitmap)
                            } else {
                                emptyList()
                            }
                            result.success(mapOf("pose" to pose, "hands" to hands))
                        } catch (e: Exception) {
                            result.error("FRAME_ERROR", e.message, null)
                        }
                    }

                    "detectPose" -> {
                        try {
                            val bitmap = bitmapFromCall(call.arguments as? Map<*, *>)
                                ?: run {
                                    result.error("INVALID_ARGUMENT", "Invalid image", null)
                                    return@setMethodCallHandler
                                }
                            result.success(serializePose(bitmap))
                        } catch (e: Exception) {
                            result.error("POSE_ERROR", e.message, null)
                        }
                    }

                    "detectHands" -> {
                        try {
                            val bitmap = bitmapFromCall(call.arguments as? Map<*, *>)
                                ?: run {
                                    result.error("INVALID_ARGUMENT", "Invalid image", null)
                                    return@setMethodCallHandler
                                }
                            result.success(handDetector.detectHandLandmarks(bitmap))
                        } catch (e: Exception) {
                            result.error("HANDS_ERROR", e.message, null)
                        }
                    }

                    "dispose" -> {
                        poseHelper?.clear()
                        poseHelper = null
                        handDetector.cleanup()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun serializePose(bitmap: Bitmap): List<Map<String, Any?>> {
        val detection = poseHelper?.detectVideo(bitmap) ?: return emptyList()
        if (detection.landmarks().isEmpty()) return emptyList()
        val pose = detection.landmarks()[0]
        val required = setOf(0, 11, 12, 13, 14, 15, 16, 19, 20)
        return required.mapNotNull { index ->
            if (index >= pose.size) return@mapNotNull null
            val lm = pose[index]
            val visibility = lm.visibility().orElse(null)?.toDouble()
            val presence = lm.presence().orElse(null)?.toDouble()
            mapOf(
                "index" to index,
                "x" to lm.x().toDouble(),
                "y" to lm.y().toDouble(),
                "z" to lm.z().toDouble(),
                "visibility" to visibility,
                "presence" to presence,
            )
        }
    }

    private fun bitmapFromCall(args: Map<*, *>?): Bitmap? {
        if (args == null) return null
        val bytes = args["image"] as? ByteArray ?: return null
        val width = args["width"] as? Int ?: return null
        val height = args["height"] as? Int ?: return null
        if (width <= 0 || height <= 0 || bytes.size < width * height) return null

        val rotation = args["rotation"] as? Int ?: 0
        val mirrorHorizontal = args["mirrorHorizontal"] as? Boolean ?: false
        val mirrorVertical = args["mirrorVertical"] as? Boolean ?: false

        val needed = width * height
        if (pixelBuffer.size < needed) {
            pixelBuffer = IntArray(needed)
        }
        for (i in 0 until needed) {
            val y = bytes[i].toInt() and 0xFF
            pixelBuffer[i] = -0x1000000 or (y shl 16) or (y shl 8) or y
        }
        var bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bitmap.setPixels(pixelBuffer, 0, width, 0, 0, width, height)
        return applyTransformations(bitmap, rotation, mirrorHorizontal, mirrorVertical)
    }

    private fun applyTransformations(
        bitmap: Bitmap,
        rotationDegrees: Int,
        mirrorHorizontal: Boolean,
        mirrorVertical: Boolean,
    ): Bitmap {
        if (rotationDegrees == 0 && !mirrorHorizontal && !mirrorVertical) return bitmap
        val matrix = Matrix()
        if (mirrorHorizontal || mirrorVertical) {
            matrix.preScale(
                if (mirrorHorizontal) -1f else 1f,
                if (mirrorVertical) -1f else 1f,
            )
        }
        if (rotationDegrees != 0) {
            matrix.postRotate(rotationDegrees.toFloat())
        }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }
}
