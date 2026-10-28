package com.umbrellaapp.msupperlimbs

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import java.io.ByteArrayOutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example/native"
    private val POSE_CHANNEL = "com.msupperlimbs/mediapipe_pose"
    private lateinit var handDetector: HandLandmarkDetector
    private var poseController: MediaPipePoseController? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        handDetector = HandLandmarkDetector(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "test" -> {
                        println("Native Android method called successfully!")
                        result.success("Success from Android")
                    }
                    "detectHands" -> {
                        val imageBytes = call.argument<ByteArray>("image")
                        val width = call.argument<Int>("width") ?: 0
                        val height = call.argument<Int>("height") ?: 0
                        
                        if (imageBytes != null && width > 0 && height > 0) {
                            try {
                                // Log the received data
                                println("Received image: ${imageBytes.size} bytes, ${width}x${height}")
                                
                                // Convert grayscale Y-plane to Bitmap
                                println("Processing grayscale image: ${width}x${height}")
                                
                                // Create a grayscale bitmap
                                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                                
                                // Fill bitmap with grayscale data
                                val pixels = IntArray(width * height)
                                for (i in 0 until width * height) {
                                    val y = imageBytes[i].toInt() and 0xFF
                                    pixels[i] = -0x1000000 or (y shl 16) or (y shl 8) or y
                                }
                                bitmap.setPixels(pixels, 0, width, 0, 0, width, height)
                                
                                // Detect landmarks
                                val landmarks = handDetector.detectHandLandmarks(bitmap)
                                println("Detected ${landmarks.size} hand landmarks")
                                result.success(landmarks)
                            } catch (e: Exception) {
                                println("Error processing image: ${e.message}")
                                e.printStackTrace()
                                result.error("PROCESSING_ERROR", "Error processing image: ${e.message}", null)
                            }
                        } else {
                            result.error("INVALID_ARGUMENT", "Invalid image data or dimensions", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // MediaPipe Pose MethodChannel
        poseController = MediaPipePoseController(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, POSE_CHANNEL)
            .setMethodCallHandler { call, result ->
                poseController?.handle(call, result)
            }
    }
}
