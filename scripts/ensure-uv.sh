#!/bin/bash
# Helper script to ensure UV is available in PATH

# Try to find UV in common locations
if command -v uv &> /dev/null; then
    # UV is already in PATH
    uv "$@"
elif [ -x "$HOME/.local/bin/uv" ]; then
    # UV is in ~/.local/bin
    "$HOME/.local/bin/uv" "$@"
elif [ -x "$HOME/.cargo/bin/uv" ]; then
    # UV might be in cargo bin
    "$HOME/.cargo/bin/uv" "$@"
else
    echo "Error: UV not found. Please install UV first:"
    echo "curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo "Then run: source ~/.bashrc"
    exit 1
fi