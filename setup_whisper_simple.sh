#!/bin/bash

# Simplified setup script for whisper.cpp integration with Murmur
# This script builds whisper.cpp and downloads models

set -e

echo "🎙️  Setting up whisper.cpp for Murmur..."

# Create directories
mkdir -p Murmur/Resources/Models
mkdir -p Murmur/Resources/Binaries

# Check if whisper.cpp was already cloned
if [ -d "whisper.cpp" ]; then
    echo "📁 whisper.cpp directory exists, updating..."
    cd whisper.cpp
    git pull
else
    echo "📥 Cloning whisper.cpp repository..."
    git clone https://github.com/ggerganov/whisper.cpp.git
    cd whisper.cpp
fi

# Simple build - just build the main executable
echo "🔨 Building whisper.cpp..."
make

# Check if build succeeded - modern whisper.cpp uses CMake
if [ -f "build/bin/main" ]; then
    echo "✅ Build succeeded - found build/bin/main"
    cp build/bin/main ../Murmur/Resources/Binaries/whisper
elif [ -f "build/main" ]; then
    echo "✅ Build succeeded - found build/main"
    cp build/main ../Murmur/Resources/Binaries/whisper
elif [ -f "main" ]; then
    echo "✅ Build succeeded - found main"
    cp main ../Murmur/Resources/Binaries/whisper
else
    echo "❌ Build failed - main executable not found"
    echo "Looking for executable in build directory..."
    find build -name "main" -type f 2>/dev/null || echo "No main executable found"
    find build -name "*main*" -type f 2>/dev/null || echo "No main-like executables found"
    exit 1
fi

# Copy binary to app resources
echo "📦 Copying binary to app resources..."
chmod +x ../Murmur/Resources/Binaries/whisper

# Download models
echo "📦 Downloading Whisper models..."

# Make sure models directory exists
mkdir -p models

# Download tiny model (required)
if [ ! -f "models/ggml-tiny.bin" ]; then
    echo "Downloading tiny model..."
    bash ./models/download-ggml-model.sh tiny
fi

# Download base model (recommended)
if [ ! -f "models/ggml-base.bin" ]; then
    echo "Downloading base model..."
    bash ./models/download-ggml-model.sh base
fi

# Copy models to app resources
echo "📦 Copying models to app resources..."
cp models/ggml-tiny.bin ../Murmur/Resources/Models/ 2>/dev/null || true
cp models/ggml-base.bin ../Murmur/Resources/Models/ 2>/dev/null || true

# Copy small model if it exists
if [ -f "models/ggml-small.bin" ]; then
    cp models/ggml-small.bin ../Murmur/Resources/Models/
fi

cd ..

# Create model info file
echo "📄 Creating model info file..."
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
        }
    ]
}
EOF

# Verify setup
echo "🔍 Verifying setup..."

# Check binary
if [ -f "Murmur/Resources/Binaries/whisper" ]; then
    echo "✅ Binary: Murmur/Resources/Binaries/whisper"
else
    echo "❌ Binary missing: Murmur/Resources/Binaries/whisper"
    exit 1
fi

# Check models
model_count=0
for model in tiny base small; do
    if [ -f "Murmur/Resources/Models/ggml-${model}.bin" ]; then
        echo "✅ Model: ggml-${model}.bin"
        model_count=$((model_count + 1))
    fi
done

if [ $model_count -eq 0 ]; then
    echo "❌ No models found!"
    exit 1
fi

echo ""
echo "✅ whisper.cpp setup complete!"
echo ""
echo "📁 Files created:"
echo "  - Murmur/Resources/Binaries/whisper"
echo "  - Murmur/Resources/Models/ggml-*.bin ($model_count models)"
echo "  - Murmur/Resources/Models/model_info.json"
echo ""
echo "🎯 Next steps:"
echo "  1. Open Murmur.xcodeproj in Xcode"
echo "  2. Verify Resources folders are in project navigator"
echo "  3. Set your development team in project settings"
echo "  4. Build and run the project"
echo ""
echo "💡 Note: The whisper binary should work on your current architecture"