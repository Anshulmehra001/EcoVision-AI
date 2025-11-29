#!/usr/bin/env python3
"""
EcoVision AI - Model Environment Setup
A VIREN Legacy Project by Aniket Mehra

This script sets up the Python environment for AI model preparation and validation.
"""

import subprocess
import sys
import os
from pathlib import Path


def check_python_version():
    """Check if Python version is compatible."""
    version = sys.version_info
    if version.major != 3 or version.minor < 8:
        print(f"❌ Python 3.8+ required, found {version.major}.{version.minor}")
        return False
    print(f"✅ Python {version.major}.{version.minor}.{version.micro}")
    return True


def setup_virtual_environment():
    """Set up Python virtual environment."""
    venv_path = Path("venv")
    
    if venv_path.exists():
        print("✅ Virtual environment already exists")
        return True
    
    try:
        print("Creating virtual environment...")
        subprocess.run([sys.executable, "-m", "venv", "venv"], check=True)
        print("✅ Virtual environment created")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to create virtual environment: {e}")
        return False


def get_pip_executable():
    """Get the pip executable path for the virtual environment."""
    if os.name == 'nt':  # Windows
        return Path("venv/Scripts/pip.exe")
    else:  # Unix-like
        return Path("venv/bin/pip")


def install_requirements():
    """Install required packages."""
    pip_exe = get_pip_executable()
    
    if not pip_exe.exists():
        print(f"❌ Pip executable not found: {pip_exe}")
        return False
    
    requirements_file = Path("requirements.txt")
    if not requirements_file.exists():
        print("❌ requirements.txt not found")
        return False
    
    try:
        print("Installing requirements...")
        subprocess.run([str(pip_exe), "install", "-r", "requirements.txt"], check=True)
        print("✅ Requirements installed")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install requirements: {e}")
        return False


def install_additional_packages():
    """Install additional packages for model testing."""
    pip_exe = get_pip_executable()
    
    additional_packages = [
        "psutil",  # For memory monitoring
        "matplotlib",  # For visualization
        "soundfile",  # For audio file handling
    ]
    
    for package in additional_packages:
        try:
            print(f"Installing {package}...")
            subprocess.run([str(pip_exe), "install", package], check=True)
            print(f"✅ {package} installed")
        except subprocess.CalledProcessError as e:
            print(f"⚠️  Failed to install {package}: {e}")


def create_directory_structure():
    """Create necessary directory structure."""
    directories = [
        "assets/models",
        "test_data",
        "test_data/flora_samples",
        "test_data/audio_samples",
        "model_reports"
    ]
    
    for dir_path in directories:
        Path(dir_path).mkdir(parents=True, exist_ok=True)
        print(f"✅ Created directory: {dir_path}")


def verify_installation():
    """Verify that all packages are properly installed."""
    python_exe = Path("venv/Scripts/python.exe") if os.name == 'nt' else Path("venv/bin/python")
    
    test_imports = [
        "tensorflow",
        "numpy", 
        "opencv-python",
        "librosa"
    ]
    
    print("\nVerifying installation...")
    for package in test_imports:
        try:
            # Import the actual module name (opencv-python -> cv2)
            module_name = "cv2" if package == "opencv-python" else package
            subprocess.run([str(python_exe), "-c", f"import {module_name}; print(f'{package}: OK')"], 
                         check=True, capture_output=True)
            print(f"✅ {package}")
        except subprocess.CalledProcessError:
            print(f"❌ {package}")
            return False
    
    return True


def create_sample_models():
    """Create sample TensorFlow models for testing."""
    python_exe = Path("venv/Scripts/python.exe") if os.name == 'nt' else Path("venv/bin/python")
    
    sample_model_script = '''
import tensorflow as tf
import numpy as np
from pathlib import Path

# Create sample flora classification model
def create_flora_model():
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(224, 224, 3)),
        tf.keras.layers.Conv2D(32, 3, activation='relu'),
        tf.keras.layers.MaxPooling2D(),
        tf.keras.layers.Conv2D(64, 3, activation='relu'),
        tf.keras.layers.MaxPooling2D(),
        tf.keras.layers.Flatten(),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dense(10, activation='softmax')  # 10 plant disease classes
    ])
    
    model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
    
    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    # Save
    Path("assets/models").mkdir(parents=True, exist_ok=True)
    with open("assets/models/flora_model.tflite", "wb") as f:
        f.write(tflite_model)
    
    print("Created flora_model.tflite")

# Create sample bird classification model  
def create_bird_model():
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(128,)),  # Audio features (1D)
        tf.keras.layers.Dense(256, activation='relu'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(50, activation='softmax')  # 50 bird species
    ])
    
    model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
    
    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    # Save
    with open("assets/models/bird_model.tflite", "wb") as f:
        f.write(tflite_model)
    
    print("Created bird_model.tflite")

if __name__ == "__main__":
    create_flora_model()
    create_bird_model()
    print("Sample models created successfully!")
'''
    
    try:
        print("Creating sample models for testing...")
        result = subprocess.run([str(python_exe), "-c", sample_model_script], 
                              check=True, capture_output=True, text=True)
        print("✅ Sample models created")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to create sample models: {e}")
        print(f"Error output: {e.stderr}")
        return False


def main():
    """Main setup function."""
    print("EcoVision AI - Model Environment Setup")
    print("A VIREN Legacy Project by Aniket Mehra")
    print("=" * 50)
    
    # Check Python version
    if not check_python_version():
        return False
    
    # Set up virtual environment
    if not setup_virtual_environment():
        return False
    
    # Install requirements
    if not install_requirements():
        return False
    
    # Install additional packages
    install_additional_packages()
    
    # Create directory structure
    create_directory_structure()
    
    # Verify installation
    if not verify_installation():
        print("❌ Installation verification failed")
        return False
    
    # Create sample models for testing
    if not create_sample_models():
        print("⚠️  Sample model creation failed, but environment is ready")
    
    print("\n" + "=" * 50)
    print("✅ Environment setup complete!")
    print("\nNext steps:")
    print("1. Activate virtual environment:")
    if os.name == 'nt':
        print("   venv\\Scripts\\activate")
    else:
        print("   source venv/bin/activate")
    print("2. Run model validation:")
    print("   python model_validation.py")
    print("3. Test individual models:")
    print("   python model_tester.py --model assets/models/flora_model.tflite")
    
    return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)