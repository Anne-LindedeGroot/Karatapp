#!/bin/bash

# 🚀 SETUP FAST FLUTTER RUN
# Adds flutter-run-fast to your PATH for global usage

echo "⚡ Setting up Flutter-Run-Fast globally..."
echo ""

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/flutter-run-fast"
ALIAS_NAME="flutter-run-fast"

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: flutter-run-fast script not found at $SCRIPT_PATH"
    exit 1
fi

# Create symlink in /usr/local/bin if possible (requires sudo)
if [ -w "/usr/local/bin" ] || sudo -n true 2>/dev/null; then
    echo "📦 Installing to /usr/local/bin (requires sudo)..."
    sudo ln -sf "$SCRIPT_PATH" "/usr/local/bin/$ALIAS_NAME"
    if [ $? -eq 0 ]; then
        echo "✅ Successfully installed!"
        echo "🎉 You can now use '$ALIAS_NAME' from anywhere in your project!"
        echo ""
        echo "Usage examples:"
        echo "  $ALIAS_NAME                    # Default device"
        echo "  $ALIAS_NAME --device-id=emulator-5554"
        echo "  $ALIAS_NAME --release"
        echo "  $ALIAS_NAME --profile"
        exit 0
    fi
fi

# Fallback: Add to ~/.bashrc or ~/.zshrc
SHELL_RC=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ] && [ -w "$SHELL_RC" ]; then
    echo "📝 Adding alias to $SHELL_RC..."

    # Remove existing alias if it exists
    sed -i.bak "/alias $ALIAS_NAME=/d" "$SHELL_RC" 2>/dev/null || true

    # Add new alias
    echo "alias $ALIAS_NAME='$SCRIPT_PATH'" >> "$SHELL_RC"

    echo "✅ Alias added to $SHELL_RC"
    echo "🔄 Run 'source $SHELL_RC' or restart your terminal"
    echo ""
    echo "Usage examples:"
    echo "  $ALIAS_NAME                    # Default device"
    echo "  $ALIAS_NAME --device-id=emulator-5554"
    echo "  $ALIAS_NAME --release"
    echo "  $ALIAS_NAME --profile"
    exit 0
fi

# Last resort: Manual instructions
echo "📋 Manual setup required:"
echo ""
echo "Add this to your ~/.bashrc, ~/.zshrc, or equivalent:"
echo "alias $ALIAS_NAME='$SCRIPT_PATH'"
echo ""
echo "Or run it directly:"
echo "$SCRIPT_PATH [arguments]"
echo ""
echo "Usage examples:"
echo "  $SCRIPT_PATH                    # Default device"
echo "  $SCRIPT_PATH --device-id=emulator-5554"
echo "  $SCRIPT_PATH --release"

