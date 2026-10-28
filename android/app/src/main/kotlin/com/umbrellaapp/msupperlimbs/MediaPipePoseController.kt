package com.umbrellaapp.msupperlimbs

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MediaPipePoseController(private val context: Context) {
    private var helper: PoseLandmarkerHelper? = null
    private var frameCounter: Int = 0

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val model = (call.argument<String>("model") ?: "lite").lowercase()
                val delegate = (call.argument<String>("delegate") ?: "cpu").lowercase()
                val det = (call.argument<Double>("detectionConfidence") ?: 0.1).toFloat()
                val trak = (call.argument<Double>("trackingConfidence") ?: 0.1).toFloat()
                val pres = (call.argument<Double>("presenceConfidence") ?: 0.1).toFloat()

                helper?.clearPoseLandmarker()
                helper = PoseLandmarkerHelper(
                    minPoseDetectionConfidence = det,
                    minPoseTrackingConfidence = trak,
                    minPosePresenceConfidence = pres,
                    currentModel = when (model) {
                        "lite" -> PoseLandmarkerHelper.MODEL_POSE_LANDMARKER_LITE
                        "heavy" -> PoseLandmarkerHelper.MODEL_POSE_LANDMARKER_HEAVY
                        else -> PoseLandmarkerHelper.MODEL_POSE_LANDMARKER_FULL
                    },
                    currentDelegate = when (delegate) {
                        "gpu" -> PoseLandmarkerHelper.DELEGATE_GPU
                        else -> PoseLandmarkerHelper.DELEGATE_CPU
                    },
                    // Use VIDEO for temporal tracking between frames (like HandLandmarkDetector)
                    runningMode = com.google.mediapipe.tasks.vision.core.RunningMode.VIDEO,
                    context = context,
                    poseLandmarkerHelperListener = null
                )
                result.success(true)
            }

            "processFrame" -> {
                val bytes = call.argument<ByteArray>("image")
                val width = call.argument<Int>("width") ?: 0
                val height = call.argument<Int>("height") ?: 0
                val rotationDegrees = call.argument<Int>("rotation") ?: 0
                val mirrorHorizontal = call.argument<Boolean>("mirrorHorizontal") ?: false
                val mirrorVertical = call.argument<Boolean>("mirrorVertical") ?: false
                
                if (bytes == null || width <= 0 || height <= 0) {
                    result.error("INVALID_ARGUMENT", "Invalid image input", null)
                    return
                }

                // Build ARGB_8888 bitmap from Y-plane grayscale
                var bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val pixels = IntArray(width * height)
                for (i in 0 until width * height) {
                    val y = bytes[i].toInt() and 0xFF
                    pixels[i] = -0x1000000 or (y shl 16) or (y shl 8) or y
                }
                bitmap.setPixels(pixels, 0, width, 0, 0, width, height)

                // Apply transformations (rotation + mirroring)
                bitmap = applyTransformations(bitmap, rotationDegrees, mirrorHorizontal, mirrorVertical)

                val bundle = helper?.detectVideo(bitmap)
                if (bundle == null || bundle.results.isEmpty()) {
                    result.success(emptyList<Any>())
                    return
                }

                val first = bundle.results.first()
                // Each pose returns a list of landmarks; we take the first pose
                val poses = first.landmarks()
                if (poses == null || poses.isEmpty()) {
                    result.success(emptyList<Any>())
                    return
                }
                val firstPose = poses[0]
                
                // Filter to only required landmarks: 0, 11-16, 19, 20
                val requiredIndices = setOf(0, 11, 12, 13, 14, 15, 16, 19, 20)
                val serialized = ArrayList<Map<String, Any>>()
                
                for (index in requiredIndices) {
                    if (index >= firstPose.size) continue
                    val lm = firstPose[index]
                    val x = try { lm.x().toDouble() } catch (e: Exception) { 0.0 }
                    val y = try { lm.y().toDouble() } catch (e: Exception) { 0.0 }
                    val z = try { lm.z().toDouble() } catch (e: Exception) { 0.0 }
                    val visibility = try {
                        val opt = lm.visibility()
                        when (opt) {
                            is java.util.Optional<*> -> (opt.orElse(0f) as Float).toDouble()
                            else -> 0.0
                        }
                    } catch (e: Exception) { 0.0 }
                    val map = hashMapOf<String, Any>(
                        "index" to index,
                        "x" to x,
                        "y" to y,
                        "z" to z,
                        "visibility" to visibility
                    )
                    serialized.add(map)
                }
                result.success(serialized)
            }

            "dispose" -> {
                helper?.clearPoseLandmarker()
                helper = null
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Apply rotation and mirroring transformations to bitmap
     */
    private fun applyTransformations(
        bitmap: Bitmap,
        rotationDegrees: Int,
        mirrorHorizontal: Boolean,
        mirrorVertical: Boolean
    ): Bitmap {
        // If no transformations needed, return original
        if (rotationDegrees == 0 && !mirrorHorizontal && !mirrorVertical) {
            return bitmap
        }

        val matrix = Matrix()

        // Apply mirroring first (scale -1 on respective axis)
        if (mirrorHorizontal || mirrorVertical) {
            matrix.preScale(
                if (mirrorHorizontal) -1f else 1f,
                if (mirrorVertical) -1f else 1f
            )
        }

        // Apply rotation
        if (rotationDegrees != 0) {
            matrix.postRotate(rotationDegrees.toFloat())
        }

        // Create transformed bitmap
        return Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true
        )
    }
}


