#!/bin/bash

# Setup script for whisper.cpp integration with Murmur
# This script downloads, builds, and configures whisper.cpp for local use

set -e

echo "🎙️  Setting up whisper.cpp for Murmur..."

# Create directories
mkdir -p whisper.cpp
mkdir -p Murmur/Resources/Models
mkdir -p Murmur/Resources/Binaries

# Clone whisper.cpp if not already present
if [ ! -d "whisper.cpp/.git" ]; then
    echo "📥 Cloning whisper.cpp repository..."
    git clone https://github.com/ggerganov/whisper.cpp.git whisper.cpp
fi

cd whisper.cpp

# Build whisper.cpp
echo "🔨 Building whisper.cpp..."
rm -f main main_arm64 main_x86_64 main_universal
make

# Build universal binary for both Intel and Apple Silicon
echo "🔨 Building universal binary..."
rm -f main main_arm64 main_x86_64 main_universal

# Build for Apple Silicon
echo "Building for Apple Silicon..."
make CC=clang CXX=clang++ CFLAGS="-arch arm64" CXXFLAGS="-arch arm64" LDFLAGS="-arch arm64"
mv main main_arm64

# Build for Intel
echo "Building for Intel..."
make CC=clang CXX=clang++ CFLAGS="-arch x86_64" CXXFLAGS="-arch x86_64" LDFLAGS="-arch x86_64"
mv main main_x86_64

# Create universal binary
echo "Creating universal binary..."
lipo -create main_arm64 main_x86_64 -output main_universal

# Copy binary to app resources
cp main_universal ../Murmur/Resources/Binaries/whisper
chmod +x ../Murmur/Resources/Binaries/whisper

# Download models
echo "📦 Downloading Whisper models..."

# Make models directory
mkdir -p models

# Download tiny model (fastest, good for real-time)
if [ ! -f "models/ggml-tiny.bin" ]; then
    echo "Downloading tiny model..."
    bash ./models/download-ggml-model.sh tiny
fi

# Download base model (balanced)
if [ ! -f "models/ggml-base.bin" ]; then
    echo "Downloading base model..."
    bash ./models/download-ggml-model.sh base
fi

# Download small model (better accuracy)
if [ ! -f "models/ggml-small.bin" ]; then
    echo "Downloading small model..."
    bash ./models/download-ggml-model.sh small
fi

# Copy models to app resources
cp models/ggml-tiny.bin ../Murmur/Resources/Models/
cp models/ggml-base.bin ../Murmur/Resources/Models/
cp models/ggml-small.bin ../Murmur/Resources/Models/

# Copy medium and large models if they exist (optional)
if [ -f "models/ggml-medium.bin" ]; then
    cp models/ggml-medium.bin ../Murmur/Resources/Models/
fi

if [ -f "models/ggml-large.bin" ]; then
    cp models/ggml-large.bin ../Murmur/Resources/Models/
fi

cd ..

# Create model info file
cat > Murmur/Resources/Models/model_info.json << EOF
{
    "models": [
        {
            "name": "tiny",
            "filename": "ggml-tiny.bin",
            "size": "39MB",
            "description": "Fastest model, good for real-time transcription",
            "speed": "very fast",
            "accuracy": "good"
        },
        {
            "name": "base",
            "filename": "ggml-base.bin",
            "size": "142MB",
            "description": "Balanced speed and accuracy",
            "speed": "fast",
            "accuracy": "better"
        },
        {
            "name": "small",
            "filename": "ggml-small.bin",
            "size": "244MB",
            "description": "Better accuracy, slower processing",
            "speed": "medium",
            "accuracy": "good"
        }
    ]
}
EOF

echo "✅ whisper.cpp setup complete!"
echo ""
echo "📁 Files created:"
echo "  - Murmur/Resources/Binaries/whisper (universal binary)"
echo "  - Murmur/Resources/Models/ggml-*.bin (model files)"
echo "  - Murmur/Resources/Models/model_info.json (model metadata)"
echo ""
echo "🎯 Next steps:"
echo "  1. Add the Resources folder to your Xcode project"
echo "  2. Ensure binaries have execute permissions"
echo "  3. Test the integration with the updated WhisperService"
echo ""
echo "💡 Note: The whisper binary is a universal binary that works on both Intel and Apple Silicon Macs"