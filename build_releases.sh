#!/bin/bash
# Build bore binaries for multiple platforms

VERSION="0.6.0-nativebridge"

echo "🔨 Building bore v${VERSION} for multiple platforms..."
echo ""

# Create releases directory
mkdir -p releases

# Detect current platform
CURRENT_ARCH=$(uname -m)
CURRENT_OS=$(uname -s)

echo "🖥️  Current platform: $CURRENT_OS $CURRENT_ARCH"
echo ""

# Build for current platform (already built by cargo build --release)
if [ "$CURRENT_OS" = "Darwin" ] && [ "$CURRENT_ARCH" = "arm64" ]; then
    echo "📦 Building for macOS ARM64 (your platform)..."
    cargo build --release
    cp target/release/bore releases/bore-${VERSION}-macos-arm64
    chmod +x releases/bore-${VERSION}-macos-arm64
    echo "✅ macOS ARM64 build complete"
    echo ""
fi

if [ "$CURRENT_OS" = "Darwin" ] && [ "$CURRENT_ARCH" = "x86_64" ]; then
    echo "📦 Building for macOS x86_64 (your platform)..."
    cargo build --release
    cp target/release/bore releases/bore-${VERSION}-macos-x64
    chmod +x releases/bore-${VERSION}-macos-x64
    echo "✅ macOS x86_64 build complete"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 Successfully Built:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh releases/ 2>/dev/null || echo "No binaries yet"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Other Platforms:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "❌ macOS Intel (x86_64) - Cross-compile not supported on Apple Silicon"
echo "   → Build on Intel Mac or use GitHub Actions"
echo ""
echo "❌ Linux (x86_64) - Needs musl-gcc tools"
echo "   → Build directly on EC2 (see below)"
echo ""
echo "❌ Windows (x86_64) - Needs MinGW"
echo "   → Use GitHub Actions"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Option 1: Start with macOS binary (for testing)"
echo "  1. Create GitHub release:"
echo "     https://github.com/himanshkukreja/nativebridge-bore-tunnel/releases/new"
echo ""
echo "  2. Tag: v${VERSION}"
echo ""
echo "  3. Upload: releases/bore-${VERSION}-macos-arm64"
echo ""
echo "  4. Test with macOS users first!"
echo ""
echo "Option 2: Build Linux binary on EC2"
echo "  Run this on your EC2 server (3.6.53.225):"
echo ""
echo "  ssh ec2-user@3.6.53.225"
echo "  git clone https://github.com/himanshkukreja/nativebridge-bore-tunnel.git"
echo "  cd nativebridge-bore-tunnel"
echo "  cargo build --release"
echo "  # Binary at: target/release/bore"
echo "  # Download it and add to GitHub release as: bore-${VERSION}-linux-x64"
echo ""
echo "Option 3: Use GitHub Actions (automated)"
echo "  See: .github/workflows/release.yml (not created yet)"
echo "  This will auto-build for all platforms when you create a release"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ You can start with just the macOS ARM64 binary for now!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
