package com.arcademetrics.msupperlimbs

import android.content.Context
import android.graphics.Bitmap
import android.os.SystemClock
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

class PoseLandmarkerHelper(
    private val context: Context,
    private val minPoseDetectionConfidence: Float = 0.5f,
    private val minPoseTrackingConfidence: Float = 0.5f,
    private val minPosePresenceConfidence: Float = 0.5f,
) {
    private var poseLandmarker: PoseLandmarker? = null

    fun setup() {
        clear()
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath("pose_landmarker_lite.task")
            .setDelegate(Delegate.CPU)
            .build()

        val options = PoseLandmarker.PoseLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setMinPoseDetectionConfidence(minPoseDetectionConfidence)
            .setMinTrackingConfidence(minPoseTrackingConfidence)
            .setMinPosePresenceConfidence(minPosePresenceConfidence)
            .setRunningMode(RunningMode.VIDEO)
            .build()

        poseLandmarker = PoseLandmarker.createFromOptions(context, options)
        Log.i(TAG, "PoseLandmarker ready")
    }

    fun detectVideo(image: Bitmap): PoseLandmarkerResult? {
        val landmarker = poseLandmarker ?: run {
            setup()
            poseLandmarker
        } ?: return null

        val mpImage = BitmapImageBuilder(image).build()
        return landmarker.detectForVideo(mpImage, SystemClock.uptimeMillis())
    }

    fun clear() {
        poseLandmarker?.close()
        poseLandmarker = null
    }

    companion object {
        private const val TAG = "PoseLandmarkerHelper"
    }
}
