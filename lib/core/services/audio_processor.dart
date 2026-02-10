import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:fftea/fftea.dart';

/// Audio preprocessing service for BirdNET model
/// Converts audio to mel spectrogram format required by BirdNET
class AudioProcessor {
  // BirdNET model requirements
  static const int sampleRate = 48000; // 48kHz
  static const int chunkDuration = 3; // 3 seconds
  static const int chunkSamples = sampleRate * chunkDuration; // 144000 samples
  static const int nMels = 128; // Number of mel bands
  static const int nFft = 2048; // FFT window size
  static const int hopLength = 512; // Hop length for STFT
  
  /// Process audio file for BirdNET inference
  /// Returns mel spectrogram as 2D array
  Future<List<List<double>>> processAudioFile(String audioPath) async {
    try {
      // Read audio file
      final audioFile = File(audioPath);
      final audioBytes = await audioFile.readAsBytes();
      
      // Parse WAV file and extract audio samples
      final samples = _parseWavFile(audioBytes);
      
      // Resample to 48kHz if needed
      final resampledSamples = _resampleTo48kHz(samples);
      
      // Extract 3-second chunk (or pad if shorter)
      final chunk = _extractChunk(resampledSamples, chunkSamples);
      
      // Normalize audio
      final normalized = _normalizeAudio(chunk);
      
      // Compute mel spectrogram
      final melSpectrogram = _computeMelSpectrogram(normalized);
      
      return melSpectrogram;
    } catch (e) {
      print('[AudioProcessor] Error processing audio: $e');
      rethrow;
    }
  }
  
  /// Parse WAV file and extract PCM samples
  List<double> _parseWavFile(Uint8List bytes) {
    // Simple WAV parser (assumes 16-bit PCM)
    // Skip WAV header (44 bytes)
    final dataStart = 44;
    
    if (bytes.length < dataStart) {
      throw Exception('Invalid WAV file');
    }
    
    final samples = <double>[];
    
    // Read 16-bit samples
    for (int i = dataStart; i < bytes.length - 1; i += 2) {
      // Convert 16-bit little-endian to signed integer
      final sample = (bytes[i] | (bytes[i + 1] << 8));
      final signedSample = sample > 32767 ? sample - 65536 : sample;
      
      // Normalize to [-1, 1]
      samples.add(signedSample / 32768.0);
    }
    
    return samples;
  }
  
  /// Resample audio to 48kHz (simplified version)
  List<double> _resampleTo48kHz(List<double> samples) {
    // For simplicity, assume input is already close to 48kHz
    // In production, use proper resampling algorithm (sinc interpolation)
    
    // If we have roughly the right number of samples, return as-is
    if (samples.length >= chunkSamples * 0.8 && 
        samples.length <= chunkSamples * 1.2) {
      return samples;
    }
    
    // Simple linear interpolation resampling
    final targetLength = chunkSamples;
    final ratio = samples.length / targetLength;
    final resampled = <double>[];
    
    for (int i = 0; i < targetLength; i++) {
      final srcIndex = i * ratio;
      final index1 = srcIndex.floor();
      final index2 = (index1 + 1).clamp(0, samples.length - 1);
      final fraction = srcIndex - index1;
      
      // Linear interpolation
      final value = samples[index1] * (1 - fraction) + 
                    samples[index2] * fraction;
      resampled.add(value);
    }
    
    return resampled;
  }
  
  /// Extract 3-second chunk or pad if shorter
  List<double> _extractChunk(List<double> samples, int targetLength) {
    if (samples.length >= targetLength) {
      // Take first 3 seconds
      return samples.sublist(0, targetLength);
    } else {
      // Pad with zeros
      return List<double>.from(samples)
        ..addAll(List.filled(targetLength - samples.length, 0.0));
    }
  }
  
  /// Normalize audio to [-1, 1] range
  List<double> _normalizeAudio(List<double> samples) {
    if (samples.isEmpty) return samples;
    
    // Find max absolute value
    double maxAbs = 0.0;
    for (final sample in samples) {
      final abs = sample.abs();
      if (abs > maxAbs) maxAbs = abs;
    }
    
    if (maxAbs == 0.0) return samples;
    
    // Normalize
    return samples.map((s) => s / maxAbs).toList();
  }
  
  /// Compute mel spectrogram using FFT
  List<List<double>> _computeMelSpectrogram(List<double> samples) {
    // Number of frames
    final numFrames = ((samples.length - nFft) / hopLength).floor() + 1;
    
    // Initialize mel spectrogram
    final melSpec = List.generate(
      nMels, 
      (_) => List.filled(numFrames, 0.0)
    );
    
    // Create FFT instance
    final fft = FFT(nFft);
    
    // Hanning window
    final window = _hanningWindow(nFft);
    
    // Mel filterbank
    final melFilters = _createMelFilterbank(nMels, nFft, sampleRate);
    
    // Process each frame
    for (int frame = 0; frame < numFrames; frame++) {
      final start = frame * hopLength;
      final end = start + nFft;
      
      if (end > samples.length) break;
      
      // Extract frame and apply window
      final frameData = <double>[];
      for (int i = start; i < end; i++) {
        frameData.add(samples[i] * window[i - start]);
      }
      
      // Compute FFT
      final fftResult = fft.realFft(frameData);
      
      // Compute power spectrum
      final powerSpectrum = <double>[];
      for (final complex in fftResult) {
        final magnitude = sqrt(complex.real * complex.real + 
                              complex.imaginary * complex.imaginary);
        powerSpectrum.add(magnitude * magnitude);
      }
      
      // Apply mel filterbank
      for (int mel = 0; mel < nMels; mel++) {
        double melValue = 0.0;
        for (int i = 0; i < powerSpectrum.length && i < melFilters[mel].length; i++) {
          melValue += powerSpectrum[i] * melFilters[mel][i];
        }
        
        // Convert to log scale (dB)
        melSpec[mel][frame] = log(melValue + 1e-10) / ln10 * 10;
      }
    }
    
    return melSpec;
  }
  
  /// Create Hanning window
  List<double> _hanningWindow(int size) {
    return List.generate(size, (i) {
      return 0.5 * (1 - cos(2 * pi * i / (size - 1)));
    });
  }
  
  /// Create mel filterbank
  List<List<double>> _createMelFilterbank(int nMels, int nFft, int sampleRate) {
    // Mel scale conversion
    double hzToMel(double hz) => 2595 * log(1 + hz / 700) / ln10;
    double melToHz(double mel) => 700 * (pow(10, mel / 2595) - 1);
    
    // Frequency range
    final minMel = hzToMel(0);
    final maxMel = hzToMel(sampleRate / 2);
    
    // Mel points
    final melPoints = List.generate(nMels + 2, (i) {
      return melToHz(minMel + (maxMel - minMel) * i / (nMels + 1));
    });
    
    // Convert to FFT bin numbers
    final fftBins = melPoints.map((hz) {
      return ((nFft + 1) * hz / sampleRate).floor();
    }).toList();
    
    // Create filterbank
    final filterbank = List.generate(nMels, (i) {
      final filter = List.filled(nFft ~/ 2 + 1, 0.0);
      
      final left = fftBins[i];
      final center = fftBins[i + 1];
      final right = fftBins[i + 2];
      
      // Rising slope
      for (int j = left; j < center; j++) {
        if (center > left) {
          filter[j] = (j - left) / (center - left);
        }
      }
      
      // Falling slope
      for (int j = center; j < right; j++) {
        if (right > center) {
          filter[j] = (right - j) / (right - center);
        }
      }
      
      return filter;
    });
    
    return filterbank;
  }
}
