package com.virenlegacy.ecovisionai

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import kotlin.math.cos
import kotlin.math.sqrt
import kotlin.math.PI
import kotlin.math.min

class MainActivity: FlutterActivity() {
    private val FILE_PICKER_CHANNEL = "ecovisionai/file_picker"
    private val TFLITE_CHANNEL = "ecovisionai/tflite"
    private val PICK_AUDIO_REQUEST = 1
    private var pendingResult: MethodChannel.Result? = null
    private var tfliteInterpreter: Interpreter? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // File picker channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_PICKER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickAudioFile") {
                pendingResult = result
                pickAudioFile()
            } else {
                result.notImplemented()
            }
        }
        
        // TFLite channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TFLITE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    try {
                        loadTFLiteModel()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOAD_ERROR", e.message, null)
                    }
                }
                "runInference" -> {
                    val audioPath = call.argument<String>("audioPath")
                    if (audioPath != null) {
                        try {
                            val results = runBirdInference(audioPath)
                            result.success(results)
                        } catch (e: Exception) {
                            result.error("INFERENCE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "audioPath is required", null)
                    }
                }
                "dispose" -> {
                    tfliteInterpreter?.close()
                    tfliteInterpreter = null
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun loadTFLiteModel() {
        val assetManager = assets
        val modelBuffer = loadModelFile(assetManager, "models/bird_model.tflite")
        val options = Interpreter.Options()
        options.setNumThreads(4)
        tfliteInterpreter = Interpreter(modelBuffer, options)
    }
    
    private fun loadModelFile(assetManager: android.content.res.AssetManager, modelPath: String): ByteBuffer {
        val fileDescriptor = assetManager.openFd(modelPath)
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }
    
    private fun runBirdInference(audioPath: String): List<Map<String, Any>> {
        if (tfliteInterpreter == null) {
            throw Exception("Model not loaded")
        }
        
        // Read audio file
        val audioBytes = java.io.File(audioPath).readBytes()
        
        // Preprocess audio to mel spectrogram
        val inputTensor = preprocessAudio(audioBytes)
        
        // Prepare output
        val outputShape = tfliteInterpreter!!.getOutputTensor(0).shape()
        val numClasses = outputShape[outputShape.size - 1]
        val output = Array(1) { FloatArray(numClasses) }
        
        // Run inference
        tfliteInterpreter!!.run(inputTensor, output)
        
        // Parse results
        return parseResults(output[0])
    }
    
    private fun preprocessAudio(audioBytes: ByteArray): Array<Array<Array<FloatArray>>> {
        // BirdNET expects: [1, 144, 80, 1] (batch, time_frames, mel_bins, channels)
        val timeFrames = 144
        val melBins = 80
        
        // Convert bytes to float samples
        val samples = ArrayList<Float>()
        var i = 0
        while (i < audioBytes.size - 1) {
            val sample = (audioBytes[i].toInt() and 0xFF) or ((audioBytes[i + 1].toInt() and 0xFF) shl 8)
            val normalized = sample.toFloat() / 32768.0f
            val clamped = if (normalized < -1.0f) -1.0f else if (normalized > 1.0f) 1.0f else normalized
            samples.add(clamped)
            i += 2
        }
        
        // Compute mel spectrogram
        val melSpectrogram = computeMelSpectrogram(samples, timeFrames, melBins)
        
        // Reshape to [1, 144, 80, 1]
        return Array(1) {
            Array(timeFrames) { t ->
                Array(melBins) { m ->
                    floatArrayOf(melSpectrogram[t][m])
                }
            }
        }
    }
    
    private fun computeMelSpectrogram(samples: List<Float>, timeFrames: Int, melBins: Int): Array<FloatArray> {
        val spectrogram = Array(timeFrames) { FloatArray(melBins) }
        val hopLength = samples.size / timeFrames
        val fftSize = 2048
        
        for (frame in 0 until timeFrames) {
            val start = frame * hopLength
            val end = min(start + fftSize, samples.size)
            
            // Extract and window frame
            val frameSamples = samples.subList(start, end).toFloatArray()
            val windowed = applyHammingWindow(frameSamples)
            
            // Compute power spectrum
            val powerSpectrum = computePowerSpectrum(windowed, fftSize)
            
            // Convert to mel scale
            spectrogram[frame] = convertToMelScale(powerSpectrum, melBins)
        }
        
        return spectrogram
    }
    
    private fun applyHammingWindow(samples: FloatArray): FloatArray {
        val windowed = FloatArray(samples.size)
        for (i in samples.indices) {
            val window = 0.54 - 0.46 * cos(2.0 * PI * i / (samples.size - 1))
            windowed[i] = (samples[i] * window).toFloat()
        }
        return windowed
    }
    
    private fun computePowerSpectrum(samples: FloatArray, fftSize: Int): FloatArray {
        val spectrum = FloatArray(fftSize / 2)
        
        for (k in 0 until fftSize / 2) {
            var real = 0.0
            var imag = 0.0
            
            for (n in samples.indices) {
                val angle = -2.0 * PI * k * n / fftSize
                real += samples[n] * cos(angle)
                imag += samples[n] * kotlin.math.sin(angle)
            }
            
            spectrum[k] = sqrt(real * real + imag * imag).toFloat()
        }
        
        return spectrum
    }
    
    private fun convertToMelScale(powerSpectrum: FloatArray, melBins: Int): FloatArray {
        val melSpectrum = FloatArray(melBins)
        val binSize = powerSpectrum.size.toFloat() / melBins
        
        for (i in 0 until melBins) {
            val start = (i * binSize).toInt()
            val end = min(((i + 1) * binSize).toInt(), powerSpectrum.size)
            
            var sum = 0.0f
            for (j in start until end) {
                sum += powerSpectrum[j]
            }
            
            melSpectrum[i] = if (end > start) sum / (end - start) else 0.0f
        }
        
        return melSpectrum
    }
    
    private fun parseResults(output: FloatArray): List<Map<String, Any>> {
        val results = ArrayList<Map<String, Any>>()
        
        // Get top 5 predictions
        val indexed = output.mapIndexed { index, confidence -> Pair(index, confidence) }
            .sortedByDescending { it.second }
            .take(5)
        
        for ((index, confidence) in indexed) {
            if (confidence > 0.4f) {
                val resultMap = HashMap<String, Any>()
                resultMap["index"] = index
                resultMap["confidence"] = confidence.toDouble()
                results.add(resultMap)
            }
        }
        
        return results
    }

    private fun pickAudioFile() {
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "audio/*"
            addCategory(Intent.CATEGORY_OPENABLE)
        }
        startActivityForResult(Intent.createChooser(intent, "Select Audio File"), PICK_AUDIO_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == PICK_AUDIO_REQUEST) {
            if (resultCode == RESULT_OK && data != null) {
                val uri: Uri? = data.data
                if (uri != null) {
                    val filePath = getRealPathFromURI(uri)
                    pendingResult?.success(filePath)
                } else {
                    pendingResult?.success(null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }

    private fun getRealPathFromURI(uri: Uri): String? {
        val cursor = contentResolver.query(uri, null, null, null, null)
        return cursor?.use {
            if (it.moveToFirst()) {
                val columnIndex = it.getColumnIndex("_data")
                if (columnIndex != -1) {
                    it.getString(columnIndex)
                } else {
                    // For content:// URIs, copy to cache
                    val inputStream = contentResolver.openInputStream(uri)
                    val cacheFile = java.io.File(cacheDir, "temp_audio_${System.currentTimeMillis()}.mp3")
                    inputStream?.use { input ->
                        cacheFile.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                    cacheFile.absolutePath
                }
            } else {
                null
            }
        }
    }
}