package com.arcademetrics.msupperlimbs

import android.content.Context
import android.graphics.Bitmap
import android.os.SystemClock
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker

class HandLandmarkDetector(private val context: Context) {
    private var handLandmarker: HandLandmarker? = null

    fun initialize() {
        if (handLandmarker != null) return
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath("hand_landmarker.task")
            .build()

        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setMinHandDetectionConfidence(0.5f)
            .setMinHandPresenceConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setNumHands(2)
            .setRunningMode(RunningMode.VIDEO)
            .build()

        handLandmarker = HandLandmarker.createFromOptions(context, options)
        Log.i(TAG, "HandLandmarker ready")
    }

    fun detectHandLandmarks(bitmap: Bitmap): List<Map<String, Any?>> {
        if (handLandmarker == null) initialize()

        val mpImage = BitmapImageBuilder(bitmap).build()
        val result = handLandmarker?.detectForVideo(mpImage, SystemClock.uptimeMillis())
            ?: return emptyList()

        val landmarks = mutableListOf<Map<String, Any?>>()
        for ((handIndex, hand) in result.landmarks().withIndex()) {
            for ((index, landmark) in hand.withIndex()) {
                landmarks.add(
                    mapOf(
                        "handIndex" to handIndex,
                        "index" to index,
                        "x" to landmark.x().toDouble(),
                        "y" to landmark.y().toDouble(),
                        "z" to landmark.z().toDouble(),
                        "visibility" to landmark.visibility().orElse(null)?.toDouble(),
                        "presence" to landmark.presence().orElse(null)?.toDouble(),
                    )
                )
            }
        }
        return landmarks
    }

    fun cleanup() {
        handLandmarker?.close()
        handLandmarker = null
    }

    companion object {
        private const val TAG = "HandLandmarkDetector"
    }
}
