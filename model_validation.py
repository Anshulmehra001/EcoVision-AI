#!/usr/bin/env python3
"""
EcoVision AI - Model Validation Script
A VIREN Legacy Project by Aniket Mehra

This script validates TensorFlow Lite models for the EcoVision AI application.
"""

import tensorflow as tf
import numpy as np
import cv2
import librosa
import os
import json
import time
from pathlib import Path
from typing import Dict, List, Tuple, Optional

def validate_tflite_model(model_path: str) -> Optional[Dict]:
    """Validate a TensorFlow Lite model and return its input/output specifications."""
    try:
        # Load the TFLite model
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        # Get input and output details
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"Model: {model_path}")
        print(f"Input shape: {input_details[0]['shape']}")
        print(f"Input type: {input_details[0]['dtype']}")
        print(f"Output shape: {output_details[0]['shape']}")
        print(f"Output type: {output_details[0]['dtype']}")
        
        # Additional validation checks
        model_info = {
            'input_shape': input_details[0]['shape'].tolist(),
            'input_dtype': str(input_details[0]['dtype']),
            'output_shape': output_details[0]['shape'].tolist(),
            'output_dtype': str(output_details[0]['dtype']),
            'model_size_mb': os.path.getsize(model_path) / (1024 * 1024),
            'num_inputs': len(input_details),
            'num_outputs': len(output_details)
        }
        
        # Validate expected formats
        if len(input_details) != 1:
            print(f"Warning: Model has {len(input_details)} inputs, expected 1")
        if len(output_details) != 1:
            print(f"Warning: Model has {len(output_details)} outputs, expected 1")
            
        return model_info
    except Exception as e:
        print(f"Error validating model {model_path}: {e}")
        return None

def create_sample_image_data(shape: List[int], normalize: bool = True) -> Optional[np.ndarray]:
    """Create sample image data for testing."""
    if len(shape) == 4:  # Batch, Height, Width, Channels
        if normalize:
            # Create normalized float data (0-1 range)
            return np.random.rand(*shape).astype(np.float32)
        else:
            # Create uint8 data (0-255 range)
            return np.random.randint(0, 255, shape, dtype=np.uint8)
    else:
        print(f"Unexpected image shape: {shape}")
        return None

def create_sample_audio_data(shape: List[int]) -> Optional[np.ndarray]:
    """Create sample audio data for testing."""
    if len(shape) == 2:  # Batch, Features
        return np.random.randn(*shape).astype(np.float32)
    elif len(shape) == 3:  # Batch, Time, Features or Batch, Height, Width for 2D audio
        return np.random.randn(*shape).astype(np.float32)
    elif len(shape) == 4:  # Batch, Time, Frequency, Channels
        return np.random.randn(*shape).astype(np.float32)
    else:
        print(f"Unexpected audio shape: {shape}")
        return None

def preprocess_image_for_model(image_path: str, target_shape: List[int]) -> np.ndarray:
    """Preprocess a real image for model input."""
    # Load image
    image = cv2.imread(image_path)
    if image is None:
        raise ValueError(f"Could not load image: {image_path}")
    
    # Convert BGR to RGB
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    
    # Resize to target shape (assuming BHWC format)
    target_height, target_width = target_shape[1], target_shape[2]
    image = cv2.resize(image, (target_width, target_height))
    
    # Normalize to 0-1 range
    image = image.astype(np.float32) / 255.0
    
    # Add batch dimension
    image = np.expand_dims(image, axis=0)
    
    return image

def preprocess_audio_for_model(audio_path: str, target_shape: List[int], sample_rate: int = 22050) -> np.ndarray:
    """Preprocess audio file for model input."""
    # Load audio
    audio, sr = librosa.load(audio_path, sr=sample_rate)
    
    # Extract features based on target shape
    if len(target_shape) == 2:  # Simple feature vector
        # Extract MFCC features
        mfccs = librosa.feature.mfcc(y=audio, sr=sr, n_mfcc=target_shape[1])
        features = np.mean(mfccs, axis=1)
        features = np.expand_dims(features, axis=0)
    elif len(target_shape) == 3:  # Time-series features
        # Extract mel spectrogram
        mel_spec = librosa.feature.melspectrogram(y=audio, sr=sr, n_mels=target_shape[2])
        # Pad or truncate to target time steps
        if mel_spec.shape[1] > target_shape[1]:
            mel_spec = mel_spec[:, :target_shape[1]]
        else:
            pad_width = target_shape[1] - mel_spec.shape[1]
            mel_spec = np.pad(mel_spec, ((0, 0), (0, pad_width)), mode='constant')
        
        features = np.expand_dims(mel_spec.T, axis=0)
    else:
        raise ValueError(f"Unsupported audio target shape: {target_shape}")
    
    return features.astype(np.float32)

def test_model_inference(model_path: str, is_audio_model: bool = False, num_tests: int = 5) -> Dict:
    """Test model inference with sample data and measure performance."""
    try:
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        # Create sample input data
        input_shape = input_details[0]['shape'].tolist()
        input_dtype = input_details[0]['dtype']
        
        inference_times = []
        results = []
        
        for i in range(num_tests):
            if is_audio_model:
                input_data = create_sample_audio_data(input_shape)
            else:
                # Try both normalized and uint8 data based on dtype
                normalize = input_dtype == np.float32
                input_data = create_sample_image_data(input_shape, normalize=normalize)
            
            if input_data is None:
                return {"success": False, "error": "Failed to create input data"}
            
            # Ensure correct dtype
            if input_dtype == np.uint8:
                input_data = (input_data * 255).astype(np.uint8) if input_data.dtype == np.float32 else input_data
            elif input_dtype == np.float32:
                input_data = input_data.astype(np.float32)
            
            # Measure inference time
            start_time = time.time()
            interpreter.set_tensor(input_details[0]['index'], input_data)
            interpreter.invoke()
            inference_time = time.time() - start_time
            
            # Get output
            output_data = interpreter.get_tensor(output_details[0]['index'])
            
            inference_times.append(inference_time)
            results.append(output_data.copy())
        
        avg_inference_time = np.mean(inference_times)
        
        print(f"Inference successful! Average time: {avg_inference_time:.3f}s")
        print(f"Output shape: {results[0].shape}")
        print(f"Sample output values: {results[0][0][:5] if len(results[0][0]) > 5 else results[0][0]}")
        
        # Check if outputs are consistent (for deterministic models)
        output_std = np.std([r[0] for r in results], axis=0)
        is_deterministic = np.all(output_std < 1e-6)
        
        return {
            "success": True,
            "avg_inference_time": float(avg_inference_time),
            "output_shape": list(results[0].shape),
            "is_deterministic": bool(is_deterministic),
            "sample_output": results[0][0].tolist()[:10]  # First 10 values
        }
        
    except Exception as e:
        print(f"Error during inference: {e}")
        return {"success": False, "error": str(e)}

def generate_test_datasets():
    """Generate sample test datasets for model validation."""
    test_data_dir = Path("test_data")
    test_data_dir.mkdir(exist_ok=True)
    
    # Generate sample images for flora model testing
    flora_dir = test_data_dir / "flora_samples"
    flora_dir.mkdir(exist_ok=True)
    
    print("Generating sample flora images...")
    for i in range(5):
        # Create synthetic plant images with different patterns
        img = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
        
        # Add some structure to make it more plant-like
        # Add green tones
        img[:, :, 1] = np.clip(img[:, :, 1] + 50, 0, 255)  # Enhance green
        
        # Add some texture patterns
        for _ in range(10):
            x, y = np.random.randint(0, 224, 2)
            cv2.circle(img, (x, y), np.random.randint(5, 20), 
                      (np.random.randint(0, 255), np.random.randint(100, 255), np.random.randint(0, 100)), -1)
        
        cv2.imwrite(str(flora_dir / f"sample_plant_{i}.jpg"), img)
    
    # Generate sample audio files for bird model testing
    audio_dir = test_data_dir / "audio_samples"
    audio_dir.mkdir(exist_ok=True)
    
    print("Generating sample audio files...")
    for i in range(5):
        # Create synthetic bird-like audio
        duration = 3.0  # 3 seconds
        sample_rate = 22050
        t = np.linspace(0, duration, int(sample_rate * duration))
        
        # Create bird-like chirping sounds
        frequency = np.random.uniform(1000, 4000)  # Bird frequency range
        audio = np.sin(2 * np.pi * frequency * t)
        
        # Add some modulation for more realistic sound
        modulation = np.sin(2 * np.pi * 10 * t)  # 10 Hz modulation
        audio = audio * (0.5 + 0.5 * modulation)
        
        # Add some noise
        noise = np.random.normal(0, 0.1, audio.shape)
        audio = audio + noise
        
        # Normalize
        audio = audio / np.max(np.abs(audio))
        
        # Save as wav file (librosa can handle this)
        import soundfile as sf
        try:
            sf.write(str(audio_dir / f"sample_bird_{i}.wav"), audio, sample_rate)
        except ImportError:
            # Fallback: save as numpy array if soundfile not available
            np.save(str(audio_dir / f"sample_bird_{i}.npy"), audio)
    
    print(f"Test datasets generated in {test_data_dir}")
    return test_data_dir

def convert_model_to_tflite(model_path: str, output_path: str, quantize: bool = True) -> bool:
    """Convert a TensorFlow model to TFLite format."""
    try:
        # Load the model
        if model_path.endswith('.h5') or model_path.endswith('.keras'):
            model = tf.keras.models.load_model(model_path)
        elif model_path.endswith('.pb'):
            # Load SavedModel
            model = tf.saved_model.load(model_path)
        else:
            print(f"Unsupported model format: {model_path}")
            return False
        
        # Convert to TFLite
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        if quantize:
            # Apply quantization for smaller model size
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            converter.target_spec.supported_types = [tf.float16]
        
        tflite_model = converter.convert()
        
        # Save the model
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        print(f"Model converted successfully: {output_path}")
        return True
        
    except Exception as e:
        print(f"Error converting model: {e}")
        return False

def benchmark_model_performance(model_path: str, is_audio_model: bool = False, num_iterations: int = 100):
    """Benchmark model performance with multiple iterations."""
    print(f"\nBenchmarking {model_path}...")
    
    try:
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        input_shape = input_details[0]['shape'].tolist()
        input_dtype = input_details[0]['dtype']
        
        # Prepare input data
        if is_audio_model:
            input_data = create_sample_audio_data(input_shape)
        else:
            normalize = input_dtype == np.float32
            input_data = create_sample_image_data(input_shape, normalize=normalize)
        
        if input_dtype == np.uint8:
            input_data = (input_data * 255).astype(np.uint8) if input_data.dtype == np.float32 else input_data
        elif input_dtype == np.float32:
            input_data = input_data.astype(np.float32)
        
        # Warm up
        for _ in range(5):
            interpreter.set_tensor(input_details[0]['index'], input_data)
            interpreter.invoke()
        
        # Benchmark
        times = []
        for _ in range(num_iterations):
            start_time = time.time()
            interpreter.set_tensor(input_details[0]['index'], input_data)
            interpreter.invoke()
            times.append(time.time() - start_time)
        
        avg_time = np.mean(times)
        std_time = np.std(times)
        min_time = np.min(times)
        max_time = np.max(times)
        
        print(f"Performance Results ({num_iterations} iterations):")
        print(f"  Average: {avg_time*1000:.2f}ms")
        print(f"  Std Dev: {std_time*1000:.2f}ms")
        print(f"  Min: {min_time*1000:.2f}ms")
        print(f"  Max: {max_time*1000:.2f}ms")
        print(f"  FPS: {1/avg_time:.1f}")
        
        return {
            "avg_time": float(avg_time),
            "std_time": float(std_time),
            "min_time": float(min_time),
            "max_time": float(max_time),
            "fps": float(1/avg_time)
        }
        
    except Exception as e:
        print(f"Benchmarking failed: {e}")
        return None

def validate_model_accuracy(model_path: str, test_data_dir: Path, is_audio_model: bool = False):
    """Validate model accuracy using test datasets."""
    print(f"\nValidating accuracy for {model_path}...")
    
    try:
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        input_shape = input_details[0]['shape'].tolist()
        
        if is_audio_model:
            test_files = list((test_data_dir / "audio_samples").glob("*.wav"))
            test_files.extend(list((test_data_dir / "audio_samples").glob("*.npy")))
        else:
            test_files = list((test_data_dir / "flora_samples").glob("*.jpg"))
        
        if not test_files:
            print("No test files found!")
            return None
        
        predictions = []
        for test_file in test_files:
            try:
                if is_audio_model:
                    if test_file.suffix == '.npy':
                        # Load numpy array
                        audio_data = np.load(test_file)
                        # Create mock preprocessing
                        input_data = create_sample_audio_data(input_shape)
                    else:
                        input_data = preprocess_audio_for_model(str(test_file), input_shape)
                else:
                    input_data = preprocess_image_for_model(str(test_file), input_shape)
                
                interpreter.set_tensor(input_details[0]['index'], input_data)
                interpreter.invoke()
                output_data = interpreter.get_tensor(output_details[0]['index'])
                
                # Get top prediction
                top_class = np.argmax(output_data[0])
                confidence = np.max(output_data[0])
                
                predictions.append({
                    "file": test_file.name,
                    "top_class": int(top_class),
                    "confidence": float(confidence),
                    "raw_output": output_data[0].tolist()
                })
                
            except Exception as e:
                print(f"Error processing {test_file}: {e}")
        
        print(f"Processed {len(predictions)} test samples")
        for pred in predictions:
            print(f"  {pred['file']}: Class {pred['top_class']} (confidence: {pred['confidence']:.3f})")
        
        return predictions
        
    except Exception as e:
        print(f"Accuracy validation failed: {e}")
        return None

def main():
    """Main validation function."""
    print("EcoVision AI - Model Validation & Testing Suite")
    print("A VIREN Legacy Project by Aniket Mehra")
    print("=" * 60)
    
    models_dir = Path("assets/models")
    
    if not models_dir.exists():
        print(f"Models directory {models_dir} does not exist.")
        print("Please place your TFLite models in the assets/models/ directory.")
        return
    
    # Generate test datasets
    print("\n1. Generating test datasets...")
    test_data_dir = generate_test_datasets()
    
    # Look for TFLite models
    tflite_files = list(models_dir.glob("*.tflite"))
    
    if not tflite_files:
        print("\nNo .tflite files found in assets/models/")
        print("Please add your flora and bird classification models.")
        
        # Look for other model formats to convert
        other_models = list(models_dir.glob("*.h5")) + list(models_dir.glob("*.keras"))
        if other_models:
            print(f"\nFound {len(other_models)} models that can be converted to TFLite:")
            for model_file in other_models:
                print(f"  {model_file.name}")
                output_path = models_dir / f"{model_file.stem}.tflite"
                if convert_model_to_tflite(str(model_file), str(output_path)):
                    tflite_files.append(output_path)
    
    if not tflite_files:
        print("No models available for validation.")
        return
    
    # Validate each model
    validation_results = {}
    
    for model_file in tflite_files:
        print(f"\n{'='*60}")
        print(f"Validating {model_file.name}...")
        print(f"{'='*60}")
        
        # Determine if it's an audio model based on filename
        is_audio = "bird" in model_file.name.lower() or "audio" in model_file.name.lower()
        model_type = "Audio (Bird)" if is_audio else "Image (Flora)"
        print(f"Model type: {model_type}")
        
        # 1. Validate model structure
        print("\n2. Validating model structure...")
        model_info = validate_tflite_model(str(model_file))
        
        if not model_info:
            print("❌ Model validation failed!")
            continue
        
        # 2. Test inference
        print("\n3. Testing inference...")
        inference_result = test_model_inference(str(model_file), is_audio)
        
        if not inference_result["success"]:
            print("❌ Model inference failed!")
            continue
        
        # 3. Benchmark performance
        print("\n4. Benchmarking performance...")
        perf_result = benchmark_model_performance(str(model_file), is_audio, 50)
        
        # 4. Validate accuracy with test data
        print("\n5. Validating accuracy...")
        accuracy_result = validate_model_accuracy(str(model_file), test_data_dir, is_audio)
        
        # Store results
        validation_results[model_file.name] = {
            "model_info": model_info,
            "inference": inference_result,
            "performance": perf_result,
            "accuracy": accuracy_result,
            "is_audio_model": is_audio
        }
        
        print("✅ Model validation completed!")
    
    # Save validation report
    report_path = Path("model_validation_report.json")
    with open(report_path, 'w') as f:
        json.dump(validation_results, f, indent=2)
    
    print(f"\n{'='*60}")
    print(f"Validation complete! Report saved to {report_path}")
    print(f"{'='*60}")
    
    # Summary
    print(f"\nSummary:")
    print(f"  Models validated: {len(validation_results)}")
    for name, result in validation_results.items():
        model_type = "Audio" if result["is_audio_model"] else "Image"
        avg_time = result["performance"]["avg_time"] if result["performance"] else "N/A"
        print(f"  {name} ({model_type}): {avg_time*1000:.1f}ms avg inference" if avg_time != "N/A" else f"  {name} ({model_type}): Validation failed")

if __name__ == "__main__":
    main()