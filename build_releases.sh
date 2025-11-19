#!/bin/bash
# Build bore binaries for multiple platforms

set -e

VERSION="0.6.0-nativebridge"

echo "🔨 Building bore v${VERSION} for multiple platforms..."

# Create releases directory
mkdir -p releases

# macOS (ARM64 - M1/M2)
echo "📦 Building for macOS ARM64..."
cargo build --release --target aarch64-apple-darwin
cp target/aarch64-apple-darwin/release/bore releases/bore-${VERSION}-macos-arm64
chmod +x releases/bore-${VERSION}-macos-arm64

# macOS (x86_64 - Intel)
echo "📦 Building for macOS x86_64..."
cargo build --release --target x86_64-apple-darwin
cp target/x86_64-apple-darwin/release/bore releases/bore-${VERSION}-macos-x64
chmod +x releases/bore-${VERSION}-macos-x64

# Linux (x86_64) - for EC2 server
echo "📦 Building for Linux x86_64..."
cargo build --release --target x86_64-unknown-linux-musl
cp target/x86_64-unknown-linux-musl/release/bore releases/bore-${VERSION}-linux-x64
chmod +x releases/bore-${VERSION}-linux-x64

# Windows (x86_64)
echo "📦 Building for Windows x86_64..."
cargo build --release --target x86_64-pc-windows-gnu
cp target/x86_64-pc-windows-gnu/release/bore.exe releases/bore-${VERSION}-windows-x64.exe

echo "✅ All binaries built successfully!"
echo ""
echo "📁 Binaries available in releases/:"
ls -lh releases/

echo ""
echo "📤 Next steps:"
echo "1. Create a GitHub release with these binaries"
echo "2. Users can download with:"
echo "   curl -L https://github.com/himanshkukreja/nativebridge-bore-tunnel/releases/download/v${VERSION}/bore-${VERSION}-macos-arm64 -o bore"
