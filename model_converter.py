#!/usr/bin/env python3
"""
EcoVision AI - Model Conversion Utilities
A VIREN Legacy Project by Aniket Mehra

This script provides utilities for converting various model formats to TensorFlow Lite.
"""

import tensorflow as tf
import numpy as np
import argparse
import os
from pathlib import Path
from typing import Optional, List


class ModelConverter:
    """Utility class for converting models to TensorFlow Lite format."""
    
    def __init__(self):
        self.supported_formats = ['.h5', '.keras', '.pb', '.savedmodel']
    
    def convert_keras_model(self, model_path: str, output_path: str, 
                          quantize: bool = True, optimize_for_size: bool = True) -> bool:
        """Convert Keras model to TFLite."""
        try:
            print(f"Loading Keras model from {model_path}...")
            model = tf.keras.models.load_model(model_path)
            
            # Print model summary
            print("Model summary:")
            model.summary()
            
            # Create converter
            converter = tf.lite.TFLiteConverter.from_keras_model(model)
            
            # Apply optimizations
            if quantize:
                print("Applying quantization optimizations...")
                converter.optimizations = [tf.lite.Optimize.DEFAULT]
                
                if optimize_for_size:
                    # Use float16 quantization for smaller size
                    converter.target_spec.supported_types = [tf.float16]
            
            # Convert
            print("Converting to TFLite...")
            tflite_model = converter.convert()
            
            # Save
            with open(output_path, 'wb') as f:
                f.write(tflite_model)
            
            # Get file sizes
            original_size = os.path.getsize(model_path) / (1024 * 1024)
            tflite_size = os.path.getsize(output_path) / (1024 * 1024)
            
            print(f"✅ Conversion successful!")
            print(f"   Original size: {original_size:.2f} MB")
            print(f"   TFLite size: {tflite_size:.2f} MB")
            print(f"   Size reduction: {((original_size - tflite_size) / original_size * 100):.1f}%")
            
            return True
            
        except Exception as e:
            print(f"❌ Error converting Keras model: {e}")
            return False
    
    def convert_savedmodel(self, model_path: str, output_path: str, 
                          quantize: bool = True) -> bool:
        """Convert SavedModel to TFLite."""
        try:
            print(f"Loading SavedModel from {model_path}...")
            
            # Create converter
            converter = tf.lite.TFLiteConverter.from_saved_model(model_path)
            
            # Apply optimizations
            if quantize:
                print("Applying quantization optimizations...")
                converter.optimizations = [tf.lite.Optimize.DEFAULT]
            
            # Convert
            print("Converting to TFLite...")
            tflite_model = converter.convert()
            
            # Save
            with open(output_path, 'wb') as f:
                f.write(tflite_model)
            
            print(f"✅ SavedModel conversion successful!")
            return True
            
        except Exception as e:
            print(f"❌ Error converting SavedModel: {e}")
            return False
    
    def create_representative_dataset(self, input_shape: List[int], 
                                    is_audio: bool = False, num_samples: int = 100):
        """Create representative dataset for quantization."""
        def representative_data_gen():
            for _ in range(num_samples):
                if is_audio:
                    # Generate audio-like data
                    data = np.random.randn(*input_shape).astype(np.float32)
                else:
                    # Generate image-like data
                    data = np.random.rand(*input_shape).astype(np.float32)
                yield [data]
        
        return representative_data_gen
    
    def convert_with_full_quantization(self, model_path: str, output_path: str,
                                     input_shape: List[int], is_audio: bool = False) -> bool:
        """Convert model with full integer quantization."""
        try:
            print(f"Converting {model_path} with full integer quantization...")
            
            # Load model
            if model_path.endswith('.h5') or model_path.endswith('.keras'):
                model = tf.keras.models.load_model(model_path)
                converter = tf.lite.TFLiteConverter.from_keras_model(model)
            else:
                converter = tf.lite.TFLiteConverter.from_saved_model(model_path)
            
            # Set up full integer quantization
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            converter.representative_dataset = self.create_representative_dataset(
                input_shape, is_audio)
            converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
            converter.inference_input_type = tf.uint8
            converter.inference_output_type = tf.uint8
            
            # Convert
            tflite_model = converter.convert()
            
            # Save
            with open(output_path, 'wb') as f:
                f.write(tflite_model)
            
            print(f"✅ Full integer quantization successful!")
            return True
            
        except Exception as e:
            print(f"❌ Error with full quantization: {e}")
            return False
    
    def batch_convert(self, input_dir: str, output_dir: str, 
                     quantize: bool = True) -> List[str]:
        """Convert all supported models in a directory."""
        input_path = Path(input_dir)
        output_path = Path(output_dir)
        output_path.mkdir(exist_ok=True)
        
        converted_files = []
        
        for ext in self.supported_formats:
            for model_file in input_path.glob(f"*{ext}"):
                output_file = output_path / f"{model_file.stem}.tflite"
                
                print(f"\nConverting {model_file.name}...")
                
                if ext in ['.h5', '.keras']:
                    success = self.convert_keras_model(str(model_file), 
                                                     str(output_file), quantize)
                elif ext in ['.pb', '.savedmodel']:
                    success = self.convert_savedmodel(str(model_file), 
                                                    str(output_file), quantize)
                
                if success:
                    converted_files.append(str(output_file))
        
        return converted_files


def main():
    """Main conversion function."""
    parser = argparse.ArgumentParser(description='Convert models to TensorFlow Lite')
    parser.add_argument('--input', '-i', required=True, 
                       help='Input model file or directory')
    parser.add_argument('--output', '-o', required=True,
                       help='Output TFLite file or directory')
    parser.add_argument('--quantize', '-q', action='store_true', default=True,
                       help='Apply quantization (default: True)')
    parser.add_argument('--full-quantization', '-fq', action='store_true',
                       help='Apply full integer quantization')
    parser.add_argument('--input-shape', nargs='+', type=int,
                       help='Input shape for full quantization (e.g., 1 224 224 3)')
    parser.add_argument('--audio-model', action='store_true',
                       help='Specify if this is an audio model')
    parser.add_argument('--batch', '-b', action='store_true',
                       help='Batch convert all models in input directory')
    
    args = parser.parse_args()
    
    converter = ModelConverter()
    
    if args.batch:
        print("Batch converting models...")
        converted = converter.batch_convert(args.input, args.output, args.quantize)
        print(f"\nConverted {len(converted)} models:")
        for file in converted:
            print(f"  {file}")
    else:
        input_path = Path(args.input)
        output_path = Path(args.output)
        
        if args.full_quantization:
            if not args.input_shape:
                print("Error: --input-shape required for full quantization")
                return
            
            success = converter.convert_with_full_quantization(
                str(input_path), str(output_path), 
                args.input_shape, args.audio_model)
        else:
            if input_path.suffix in ['.h5', '.keras']:
                success = converter.convert_keras_model(
                    str(input_path), str(output_path), args.quantize)
            elif input_path.suffix in ['.pb'] or input_path.is_dir():
                success = converter.convert_savedmodel(
                    str(input_path), str(output_path), args.quantize)
            else:
                print(f"Unsupported model format: {input_path.suffix}")
                return
        
        if success:
            print(f"\n✅ Model successfully converted to {output_path}")
        else:
            print(f"\n❌ Conversion failed")


if __name__ == "__main__":
    main()