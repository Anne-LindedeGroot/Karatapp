#!/bin/bash

# 🚀 SETUP FRUN - Easy Flutter Fast Run
# Makes 'frun' command globally available

echo "⚡ Setting up FRUN - Fast Flutter Run..."
echo ""

PROJECT_ROOT="$(pwd)"
FRUN_SCRIPT="$PROJECT_ROOT/frun"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if frun script exists
if [ ! -f "$FRUN_SCRIPT" ]; then
    echo -e "${RED}❌ Error: frun script not found at $FRUN_SCRIPT${NC}"
    exit 1
fi

# Try to install globally
GLOBAL_SUCCESS=false

# Option 1: /usr/local/bin (requires sudo)
if [ -w "/usr/local/bin" ] 2>/dev/null || sudo -n true 2>/dev/null; then
    echo -e "${BLUE}📦 Installing frun to /usr/local/bin...${NC}"
    sudo ln -sf "$FRUN_SCRIPT" "/usr/local/bin/frun" 2>/dev/null
    if [ $? -eq 0 ]; then
        GLOBAL_SUCCESS=true
        echo -e "${GREEN}✅ frun installed globally!${NC}"
    fi
fi

# Option 2: ~/bin directory
if [ "$GLOBAL_SUCCESS" = false ]; then
    USER_BIN="$HOME/bin"
    if [ ! -d "$USER_BIN" ]; then
        mkdir -p "$USER_BIN"
    fi

    if ln -sf "$FRUN_SCRIPT" "$USER_BIN/frun" 2>/dev/null; then
        GLOBAL_SUCCESS=true
        echo -e "${GREEN}✅ frun installed to ~/bin!${NC}"

        # Check if ~/bin is in PATH
        if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
            echo -e "${YELLOW}⚠️  Add ~/bin to your PATH:${NC}"
            echo -e "${YELLOW}   echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.zshrc${NC}"
            echo -e "${YELLOW}   source ~/.zshrc${NC}"
        fi
    fi
fi

# Option 3: Add to shell profile
if [ "$GLOBAL_SUCCESS" = false ]; then
    SHELL_RC=""
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [ -n "$SHELL_RC" ] && [ -w "$SHELL_RC" ]; then
        echo -e "${BLUE}📝 Adding frun alias to $SHELL_RC...${NC}"

        # Remove existing alias if it exists
        sed -i.bak "/alias frun=/d" "$SHELL_RC" 2>/dev/null || true

        # Add new alias
        echo "alias frun='$FRUN_SCRIPT'" >> "$SHELL_RC"

        GLOBAL_SUCCESS=true
        echo -e "${GREEN}✅ frun alias added to $SHELL_RC!${NC}"
        echo -e "${YELLOW}🔄 Run: source $SHELL_RC${NC}"
    fi
fi

# Final instructions
echo ""
echo -e "${GREEN}🎉 FRUN SETUP COMPLETE!${NC}"
echo ""
echo -e "${BLUE}USAGE:${NC}"
echo -e "  ${YELLOW}frun${NC}                    # Fast flutter run (default device)"
echo -e "  ${YELLOW}frun --device-id=emulator-5554${NC}  # Specific device"
echo -e "  ${YELLOW}frun --release${NC}          # Release mode"
echo -e "  ${YELLOW}frun --profile${NC}          # Profile mode"
echo ""
echo -e "${BLUE}EXAMPLES:${NC}"
echo -e "  frun                          # 🚀 Ultra fast development"
echo -e "  frun --device-id=iPhone       # 📱 Specific iOS device"
echo -e "  frun --no-daemon              # ⚡ Skip build daemon"
echo ""
echo -e "${GREEN}💡 PRO TIP: Use 'frun' instead of 'flutter run' for 3x faster development!${NC}"

