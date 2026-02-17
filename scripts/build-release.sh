#!/bin/bash
# DCS Pro - Build and Deploy to Shared Location
# This script builds a Universal Binary and copies it to ~/Public/Builds

set -e

PROJECT_DIR="/Users/NineZeroSix/Source/DCS Pro"
BUILD_DIR="$PROJECT_DIR/build"
OUTPUT_DIR="$HOME/Public/Builds"
APP_NAME="DCS Pro"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "🧵 DCS Pro Build Script"
echo "========================"
echo ""

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf "$BUILD_DIR"

# Build Universal Binary
echo "🔨 Building Universal Binary (Intel + Apple Silicon)..."
cd "$PROJECT_DIR"
xcodebuild \
    -scheme "$APP_NAME" \
    -configuration Release \
    -arch x86_64 \
    -arch arm64 \
    ONLY_ACTIVE_ARCH=NO \
    -derivedDataPath "$BUILD_DIR" \
    -quiet

# Verify it's a Universal Binary
echo "✅ Verifying architectures..."
file "$BUILD_DIR/Build/Products/Release/$APP_NAME.app/Contents/MacOS/$APP_NAME"

# Copy to shared location
echo "📦 Copying to $OUTPUT_DIR..."
rm -rf "$OUTPUT_DIR/$APP_NAME.app"
cp -R "$BUILD_DIR/Build/Products/Release/$APP_NAME.app" "$OUTPUT_DIR/"

# Also create a timestamped zip for archiving
echo "🗜️  Creating zip archive..."
cd "$OUTPUT_DIR"
zip -r -q "$APP_NAME-$TIMESTAMP.zip" "$APP_NAME.app"

# Clean up old zips (keep last 5)
echo "🗑️  Cleaning old archives (keeping last 5)..."
ls -t "$OUTPUT_DIR"/*.zip 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true

echo ""
echo "========================"
echo "✨ Build complete!"
echo ""
echo "App location:  $OUTPUT_DIR/$APP_NAME.app"
echo "Zip archive:   $OUTPUT_DIR/$APP_NAME-$TIMESTAMP.zip"
echo ""
echo "On your Intel Mac:"
echo "  1. Connect to this Mac via Finder → Go → Connect to Server"
echo "  2. Enter: smb://$(hostname).local"
echo "  3. Navigate to Public/Builds"
echo "  4. Double-click '$APP_NAME.app' to run"
echo ""
