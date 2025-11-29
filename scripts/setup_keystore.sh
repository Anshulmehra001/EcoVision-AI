#!/bin/bash

# EcoVision AI - Keystore Setup Script
# This script helps create a keystore for signing Android release builds

echo "=========================================="
echo "EcoVision AI - Keystore Setup"
echo "=========================================="
echo ""

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "Error: keytool not found. Please install Java JDK."
    exit 1
fi

# Create keystore directory if it doesn't exist
mkdir -p android/keystore

# Check if keystore already exists
if [ -f "android/keystore/ecovisionai-release.jks" ]; then
    echo "Warning: Keystore already exists at android/keystore/ecovisionai-release.jks"
    read -p "Do you want to create a new one? This will overwrite the existing keystore. (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Existing keystore preserved."
        exit 0
    fi
fi

echo "Creating Android keystore for EcoVision AI..."
echo ""
echo "You will be prompted to enter:"
echo "  1. Keystore password (remember this!)"
echo "  2. Key password (remember this!)"
echo "  3. Your name and organization details"
echo ""
echo "IMPORTANT: Store these passwords securely!"
echo ""

# Generate keystore
keytool -genkey -v \
    -keystore android/keystore/ecovisionai-release.jks \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias ecovisionai-release

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Keystore created successfully!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Copy android/key.properties.template to android/key.properties"
    echo "2. Edit android/key.properties with your keystore passwords"
    echo "3. NEVER commit key.properties or the keystore to version control"
    echo "4. Keep a secure backup of your keystore file"
    echo ""
    echo "To verify your keystore:"
    echo "  keytool -list -v -keystore android/keystore/ecovisionai-release.jks"
    echo ""
else
    echo ""
    echo "Error: Failed to create keystore"
    exit 1
fi
