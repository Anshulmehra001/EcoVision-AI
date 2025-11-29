#!/usr/bin/env python3
"""Check if TFLite models are valid and get their details"""

import os
import sys

def check_tflite_model(model_path):
    """Check if a TFLite model is valid"""
    try:
        import tensorflow as tf
        
        print(f"\nChecking: {model_path}")
        print("=" * 60)
        
        # Check if file exists
        if not os.path.exists(model_path):
            print(f"ERROR: File not found: {model_path}")
            return False
        
        # Get file size
        file_size = os.path.getsize(model_path)
        print(f"File size: {file_size:,} bytes ({file_size / 1024 / 1024:.2f} MB)")
        
        # Try to load the model
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        # Get input details
        input_details = interpreter.get_input_details()
        print(f"\nInput Details:")
        for i, detail in enumerate(input_details):
            print(f"  Input {i}:")
            print(f"    Name: {detail['name']}")
            print(f"    Shape: {detail['shape']}")
            print(f"    Type: {detail['dtype']}")
        
        # Get output details
        output_details = interpreter.get_output_details()
        print(f"\nOutput Details:")
        for i, detail in enumerate(output_details):
            print(f"  Output {i}:")
            print(f"    Name: {detail['name']}")
            print(f"    Shape: {detail['shape']}")
            print(f"    Type: {detail['dtype']}")
        
        print(f"\nStatus: VALID TFLite model")
        return True
        
    except ImportError:
        print("ERROR: TensorFlow not installed")
        print("Install with: pip install tensorflow")
        return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False

def main():
    print("=" * 60)
    print("TFLite Model Validation")
    print("=" * 60)
    
    models = [
        "assets/models/flora_model.tflite",
        "assets/models/bird_model.tflite"
    ]
    
    results = {}
    for model in models:
        results[model] = check_tflite_model(model)
    
    print("\n" + "=" * 60)
    print("Summary")
    print("=" * 60)
    for model, valid in results.items():
        status = "VALID" if valid else "INVALID"
        print(f"{model}: {status}")
    
    all_valid = all(results.values())
    if all_valid:
        print("\nAll models are valid TFLite models!")
    else:
        print("\nSome models are invalid or could not be validated.")
    
    return 0 if all_valid else 1

if __name__ == "__main__":
    sys.exit(main())
