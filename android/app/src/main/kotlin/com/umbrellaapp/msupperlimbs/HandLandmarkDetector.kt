package com.umbrellaapp.msupperlimbs

import android.content.Context
import android.graphics.Bitmap
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult

class HandLandmarkDetector(private val context: Context) {
    private var handLandmarker: HandLandmarker? = null
    
    fun initialize() {
        try {
            println("Inicializando HandLandmarkDetector")
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()
                
        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setMinHandDetectionConfidence(0.1f)  // Lowest value to maximise detection
            .setMinHandPresenceConfidence(0.1f)   // Lowest value to maximise detection
            .setMinTrackingConfidence(0.1f)       // Lowest value to maximise detection
            .setNumHands(2)                       // Detect up to 2 hands
            .setRunningMode(RunningMode.VIDEO)
            .build()
                
            handLandmarker = HandLandmarker.createFromOptions(context, options)
            println("[SUCCESS] HandLandmarker inicialised")
        } catch (e: Exception) {
            println("[ERROR] Inicialise HandLandmarker: ${e.message}")
            e.printStackTrace()
        }
    }
    
    fun detectHandLandmarks(bitmap: Bitmap): List<Map<String, Float>> {
        if (handLandmarker == null) {
            initialize()
        }
        
        try {
            println("image processing: ${bitmap.width}x${bitmap.height}, format: ${bitmap.config}")
            
            val mpImage = BitmapImageBuilder(bitmap).build()
            println("[SUCCESS] MPImage created")
            
            // Usar detectForVideo em vez de detect para modo VIDEO
            val result = handLandmarker?.detectForVideo(mpImage, System.currentTimeMillis())
            println("Detection completed: ${result != null}")
            
            val landmarks = mutableListOf<Map<String, Float>>()
            
            result?.let { handResult ->
                println("N detected hands: ${handResult.landmarks().size}")
                for (i in 0 until handResult.landmarks().size) {
                    val hand = handResult.landmarks()[i]
                    println("Hand ${i+1}: ${hand.size} landmarks")
                    for (landmark in hand) {
                        landmarks.add(mapOf(
                            "x" to landmark.x(),
                            "y" to landmark.y(),
                            "z" to landmark.z()
                        ))
                    }
                }
            }
            
            return landmarks
        } catch (e: Exception) {
            println("[ERROR] Detecting landmarks: ${e.message}")
            e.printStackTrace()
            return emptyList()
        }
    }
    
    fun cleanup() {
        handLandmarker?.close()
        handLandmarker = null
    }
}
