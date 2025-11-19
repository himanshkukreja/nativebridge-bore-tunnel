#!/bin/bash
# Install NativeBridge bore client
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/nativebridge-bore-tunnel/main/install.sh | bash

set -e

VERSION="0.6.0-nativebridge"
REPO="YOUR_USERNAME/nativebridge-bore-tunnel"
INSTALL_DIR="/usr/local/bin"

echo "🚀 Installing NativeBridge bore v${VERSION}..."

# Detect platform
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Darwin)
        case "$ARCH" in
            arm64)
                PLATFORM="macos-arm64"
                ;;
            x86_64)
                PLATFORM="macos-x64"
                ;;
            *)
                echo "❌ Unsupported macOS architecture: $ARCH"
                exit 1
                ;;
        esac
        BINARY_NAME="bore"
        ;;
    Linux)
        case "$ARCH" in
            x86_64)
                PLATFORM="linux-x64"
                ;;
            *)
                echo "❌ Unsupported Linux architecture: $ARCH"
                exit 1
                ;;
        esac
        BINARY_NAME="bore"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        PLATFORM="windows-x64"
        BINARY_NAME="bore.exe"
        ;;
    *)
        echo "❌ Unsupported operating system: $OS"
        exit 1
        ;;
esac

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/bore-${VERSION}-${PLATFORM}"

echo "📥 Downloading bore for ${PLATFORM}..."
echo "   URL: ${DOWNLOAD_URL}"

# Create temp directory
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# Download binary
curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/bore"

# Make executable
chmod +x "$TMP_DIR/bore"

# Install to /usr/local/bin (or user's local bin if no sudo)
if [ -w "$INSTALL_DIR" ]; then
    mv "$TMP_DIR/bore" "$INSTALL_DIR/bore"
    echo "✅ Installed to $INSTALL_DIR/bore"
else
    echo "🔐 Need sudo to install to $INSTALL_DIR..."
    sudo mv "$TMP_DIR/bore" "$INSTALL_DIR/bore"
    echo "✅ Installed to $INSTALL_DIR/bore"
fi

# Verify installation
if command -v bore &> /dev/null; then
    echo ""
    echo "✅ NativeBridge bore installed successfully!"
    echo ""
    echo "📖 Usage:"
    echo "   export BORE_API_KEY='your_nativebridge_api_key'"
    echo "   bore local 5555 --to bore.nativebridge.io"
    echo ""
    echo "📚 Documentation: https://github.com/${REPO}"
else
    echo "❌ Installation failed. bore command not found."
    exit 1
fi
