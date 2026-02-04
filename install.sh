#!/bin/bash
# tmux-ghostcomplete installer

set -e

INSTALL_DIR="${HOME}/.zsh/plugins/tmux-ghostcomplete"
BIN_DIR="${HOME}/.local/bin"

echo "Installing tmux-ghostcomplete..."

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# Copy files
cp tmux-ghostcomplete.plugin.zsh "$INSTALL_DIR/"
cp bin/tmux-ghostcomplete "$BIN_DIR/"
chmod +x "$BIN_DIR/tmux-ghostcomplete"

echo ""
echo "Installation complete!"
echo ""
echo "Add this line to your ~/.zshrc:"
echo ""
echo "  source $INSTALL_DIR/tmux-ghostcomplete.plugin.zsh"
echo ""
echo "Then reload your shell: source ~/.zshrc"
echo ""
echo "Usage: Press Ctrl+n in a tmux session to trigger autocomplete"
