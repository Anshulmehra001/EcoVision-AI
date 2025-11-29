#!/usr/bin/env python3
"""
EcoVision AI - Model Testing Utilities
A VIREN Legacy Project by Aniket Mehra

This script provides comprehensive testing utilities for TensorFlow Lite models.
"""

import tensorflow as tf
import numpy as np
import cv2
import librosa
import json
import time
import argparse
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import matplotlib.pyplot as plt


class ModelTester:
    """Comprehensive testing utilities for TFLite models."""
    
    def __init__(self, model_path: str):
        self.model_path = model_path
        self.interpreter = tf.lite.Interpreter(model_path=model_path)
        self.interpreter.allocate_tensors()
        
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
        
        print(f"Loaded model: {model_path}")
        print(f"Input shape: {self.input_details[0]['shape']}")
        print(f"Output shape: {self.output_details[0]['shape']}")
    
    def get_model_info(self) -> Dict:
        """Get comprehensive model information."""
        return {
            'model_path': self.model_path,
            'input_shape': self.input_details[0]['shape'].tolist(),
            'input_dtype': str(self.input_details[0]['dtype']),
            'output_shape': self.output_details[0]['shape'].tolist(),
            'output_dtype': str(self.output_details[0]['dtype']),
            'model_size_mb': Path(self.model_path).stat().st_size / (1024 * 1024),
            'num_inputs': len(self.input_details),
            'num_outputs': len(self.output_details)
        }
    
    def test_inference_speed(self, num_iterations: int = 100, 
                           warmup_iterations: int = 10) -> Dict:
        """Test inference speed with multiple iterations."""
        input_shape = self.input_details[0]['shape']
        input_dtype = self.input_details[0]['dtype']
        
        # Create sample input
        if input_dtype == np.float32:
            test_input = np.random.rand(*input_shape).astype(np.float32)
        else:
            test_input = np.random.randint(0, 255, input_shape, dtype=np.uint8)
        
        # Warmup
        for _ in range(warmup_iterations):
            self.interpreter.set_tensor(self.input_details[0]['index'], test_input)
            self.interpreter.invoke()
        
        # Benchmark
        times = []
        for _ in range(num_iterations):
            start_time = time.perf_counter()
            self.interpreter.set_tensor(self.input_details[0]['index'], test_input)
            self.interpreter.invoke()
            end_time = time.perf_counter()
            times.append(end_time - start_time)
        
        times = np.array(times)
        
        return {
            'num_iterations': num_iterations,
            'mean_time_ms': float(np.mean(times) * 1000),
            'std_time_ms': float(np.std(times) * 1000),
            'min_time_ms': float(np.min(times) * 1000),
            'max_time_ms': float(np.max(times) * 1000),
            'median_time_ms': float(np.median(times) * 1000),
            'fps': float(1.0 / np.mean(times)),
            'percentile_95_ms': float(np.percentile(times, 95) * 1000),
            'percentile_99_ms': float(np.percentile(times, 99) * 1000)
        }
    
    def test_input_variations(self) -> Dict:
        """Test model with various input variations."""
        input_shape = self.input_details[0]['shape']
        input_dtype = self.input_details[0]['dtype']
        
        results = {}
        
        # Test different input patterns
        test_patterns = {
            'zeros': np.zeros(input_shape, dtype=input_dtype),
            'ones': np.ones(input_shape, dtype=input_dtype),
            'random_uniform': np.random.rand(*input_shape).astype(input_dtype),
            'random_normal': np.clip(np.random.randn(*input_shape), 0, 1).astype(input_dtype)
        }
        
        if input_dtype == np.uint8:
            test_patterns['max_values'] = np.full(input_shape, 255, dtype=input_dtype)
            test_patterns['random_uniform'] = np.random.randint(0, 256, input_shape, dtype=input_dtype)
        else:
            test_patterns['max_values'] = np.ones(input_shape, dtype=input_dtype)
        
        for pattern_name, test_input in test_patterns.items():
            try:
                self.interpreter.set_tensor(self.input_details[0]['index'], test_input)
                self.interpreter.invoke()
                output = self.interpreter.get_tensor(self.output_details[0]['index'])
                
                results[pattern_name] = {
                    'success': True,
                    'output_shape': output.shape,
                    'output_mean': float(np.mean(output)),
                    'output_std': float(np.std(output)),
                    'output_min': float(np.min(output)),
                    'output_max': float(np.max(output)),
                    'top_class': int(np.argmax(output[0])) if len(output.shape) > 1 else None,
                    'top_confidence': float(np.max(output[0])) if len(output.shape) > 1 else None
                }
            except Exception as e:
                results[pattern_name] = {
                    'success': False,
                    'error': str(e)
                }
        
        return results
    
    def test_memory_usage(self) -> Dict:
        """Test memory usage during inference."""
        import psutil
        import os
        
        process = psutil.Process(os.getpid())
        
        # Baseline memory
        baseline_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        input_shape = self.input_details[0]['shape']
        input_dtype = self.input_details[0]['dtype']
        
        # Create test input
        if input_dtype == np.float32:
            test_input = np.random.rand(*input_shape).astype(np.float32)
        else:
            test_input = np.random.randint(0, 255, input_shape, dtype=np.uint8)
        
        # Run multiple inferences and monitor memory
        memory_usage = []
        for i in range(50):
            self.interpreter.set_tensor(self.input_details[0]['index'], test_input)
            self.interpreter.invoke()
            
            if i % 10 == 0:  # Sample every 10 iterations
                current_memory = process.memory_info().rss / 1024 / 1024  # MB
                memory_usage.append(current_memory)
        
        return {
            'baseline_memory_mb': baseline_memory,
            'peak_memory_mb': max(memory_usage),
            'memory_increase_mb': max(memory_usage) - baseline_memory,
            'memory_samples': memory_usage
        }
    
    def test_numerical_stability(self, num_tests: int = 10) -> Dict:
        """Test numerical stability with repeated inferences."""
        input_shape = self.input_details[0]['shape']
        input_dtype = self.input_details[0]['dtype']
        
        # Create fixed test input
        np.random.seed(42)  # Fixed seed for reproducibility
        if input_dtype == np.float32:
            test_input = np.random.rand(*input_shape).astype(np.float32)
        else:
            test_input = np.random.randint(0, 255, input_shape, dtype=np.uint8)
        
        outputs = []
        for _ in range(num_tests):
            self.interpreter.set_tensor(self.input_details[0]['index'], test_input)
            self.interpreter.invoke()
            output = self.interpreter.get_tensor(self.output_details[0]['index'])
            outputs.append(output.copy())
        
        # Analyze stability
        outputs = np.array(outputs)
        
        # Calculate variance across runs
        output_variance = np.var(outputs, axis=0)
        max_variance = np.max(output_variance)
        mean_variance = np.mean(output_variance)
        
        # Check if outputs are identical (deterministic)
        is_deterministic = np.allclose(outputs[0], outputs[1:], rtol=1e-7, atol=1e-7)
        
        return {
            'num_tests': num_tests,
            'is_deterministic': bool(is_deterministic),
            'max_variance': float(max_variance),
            'mean_variance': float(mean_variance),
            'output_std': float(np.std(outputs)),
            'coefficient_of_variation': float(np.std(outputs) / np.mean(outputs)) if np.mean(outputs) != 0 else 0
        }
    
    def generate_test_report(self, output_path: str = None) -> Dict:
        """Generate comprehensive test report."""
        print("Generating comprehensive test report...")
        
        report = {
            'model_info': self.get_model_info(),
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
            'tests': {}
        }
        
        # Speed test
        print("Running speed test...")
        report['tests']['speed'] = self.test_inference_speed()
        
        # Input variations test
        print("Testing input variations...")
        report['tests']['input_variations'] = self.test_input_variations()
        
        # Memory usage test
        print("Testing memory usage...")
        try:
            report['tests']['memory'] = self.test_memory_usage()
        except ImportError:
            report['tests']['memory'] = {'error': 'psutil not available'}
        
        # Numerical stability test
        print("Testing numerical stability...")
        report['tests']['stability'] = self.test_numerical_stability()
        
        # Save report
        if output_path:
            with open(output_path, 'w') as f:
                json.dump(report, f, indent=2)
            print(f"Report saved to {output_path}")
        
        return report
    
    def visualize_performance(self, report: Dict, save_path: str = None):
        """Create performance visualization."""
        try:
            import matplotlib.pyplot as plt
            
            fig, axes = plt.subplots(2, 2, figsize=(12, 10))
            fig.suptitle(f'Model Performance Report\n{Path(self.model_path).name}', fontsize=14)
            
            # Speed distribution
            if 'speed' in report['tests']:
                speed_data = report['tests']['speed']
                ax1 = axes[0, 0]
                ax1.bar(['Mean', 'Min', 'Max', '95th %ile'], 
                       [speed_data['mean_time_ms'], speed_data['min_time_ms'], 
                        speed_data['max_time_ms'], speed_data['percentile_95_ms']])
                ax1.set_title('Inference Time (ms)')
                ax1.set_ylabel('Time (ms)')
            
            # Memory usage
            if 'memory' in report['tests'] and 'memory_samples' in report['tests']['memory']:
                ax2 = axes[0, 1]
                memory_data = report['tests']['memory']['memory_samples']
                ax2.plot(memory_data, 'b-o')
                ax2.set_title('Memory Usage During Inference')
                ax2.set_xlabel('Sample')
                ax2.set_ylabel('Memory (MB)')
            
            # Input variation results
            if 'input_variations' in report['tests']:
                ax3 = axes[1, 0]
                variations = report['tests']['input_variations']
                pattern_names = []
                confidences = []
                
                for pattern, result in variations.items():
                    if result.get('success') and result.get('top_confidence') is not None:
                        pattern_names.append(pattern)
                        confidences.append(result['top_confidence'])
                
                if pattern_names:
                    ax3.bar(pattern_names, confidences)
                    ax3.set_title('Top Confidence by Input Pattern')
                    ax3.set_ylabel('Confidence')
                    ax3.tick_params(axis='x', rotation=45)
            
            # Model info
            ax4 = axes[1, 1]
            ax4.axis('off')
            info_text = f"""Model Information:
Size: {report['model_info']['model_size_mb']:.2f} MB
Input: {report['model_info']['input_shape']}
Output: {report['model_info']['output_shape']}
FPS: {report['tests']['speed']['fps']:.1f}
Deterministic: {report['tests']['stability']['is_deterministic']}"""
            ax4.text(0.1, 0.5, info_text, fontsize=10, verticalalignment='center')
            
            plt.tight_layout()
            
            if save_path:
                plt.savefig(save_path, dpi=300, bbox_inches='tight')
                print(f"Performance visualization saved to {save_path}")
            else:
                plt.show()
                
        except ImportError:
            print("Matplotlib not available for visualization")


def main():
    """Main testing function."""
    parser = argparse.ArgumentParser(description='Test TensorFlow Lite models')
    parser.add_argument('--model', '-m', required=True,
                       help='Path to TFLite model file')
    parser.add_argument('--output', '-o', 
                       help='Output path for test report (JSON)')
    parser.add_argument('--visualize', '-v', action='store_true',
                       help='Create performance visualization')
    parser.add_argument('--iterations', '-i', type=int, default=100,
                       help='Number of iterations for speed test')
    
    args = parser.parse_args()
    
    if not Path(args.model).exists():
        print(f"Error: Model file {args.model} not found")
        return
    
    # Create tester
    tester = ModelTester(args.model)
    
    # Generate report
    output_path = args.output or f"{Path(args.model).stem}_test_report.json"
    report = tester.generate_test_report(output_path)
    
    # Print summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    print(f"Model: {Path(args.model).name}")
    print(f"Size: {report['model_info']['model_size_mb']:.2f} MB")
    print(f"Average inference time: {report['tests']['speed']['mean_time_ms']:.2f} ms")
    print(f"FPS: {report['tests']['speed']['fps']:.1f}")
    print(f"Deterministic: {report['tests']['stability']['is_deterministic']}")
    
    if 'memory' in report['tests'] and 'peak_memory_mb' in report['tests']['memory']:
        print(f"Peak memory: {report['tests']['memory']['peak_memory_mb']:.2f} MB")
    
    # Create visualization
    if args.visualize:
        viz_path = f"{Path(args.model).stem}_performance.png"
        tester.visualize_performance(report, viz_path)


if __name__ == "__main__":
    main()