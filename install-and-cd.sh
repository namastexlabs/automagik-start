#!/bin/bash

# Automagik Install and Change Directory Script
# This script installs Automagik and changes to the directory

# Function to detect if we're being sourced
is_sourced() {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

# Main installation function
install_automagik() {
    echo "🚀 Starting Automagik installation..."

    # Check if git is installed, install if not
    if ! command -v git &> /dev/null; then
        echo "📦 Git not found, installing..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y git
        elif command -v yum &> /dev/null; then
            sudo yum install -y git
        elif command -v brew &> /dev/null; then
            brew install git
        else
            echo "❌ Cannot install git. Please install git manually and try again."
            return 1
        fi
        echo "✅ Git installed successfully"
    fi

    # Clone the repository
    if [ -d "automagik" ]; then
        echo "📁 automagik directory already exists, removing it..."
        rm -rf automagik
    fi

    echo "📥 Cloning automagik-start repository..."
    git clone https://github.com/namastexlabs/automagik-start automagik

    # Navigate to the directory
    cd automagik

    # Make install.sh executable and run it
    echo "🔧 Running installation..."
    chmod +x install.sh
    ./install.sh

    echo "✅ Automagik installation completed!"
    echo ""
    echo "📁 Current directory: $(pwd)"
    echo "🚀 To start all services: make start"
    echo "🛑 To stop all services: make stop"
    echo "📊 To check service status: make status"
    echo "💡 To see all available commands: make help"
    
    return 0
}

# Check how the script is being run
if is_sourced; then
    # Script is being sourced, cd will work
    echo "🎯 Running in sourced mode - directory changes will persist"
    install_automagik
else
    # Script is being executed, provide instructions
    echo "🎯 For directory changes to persist, run this script with:"
    echo "   source <(curl -sSL https://raw.githubusercontent.com/namastexlabs/automagik-start/main/install-and-cd.sh)"
    echo ""
    echo "🔄 Running installation anyway..."
    install_automagik
    echo ""
    echo "⚠️  You'll need to manually run: cd automagik"
fi