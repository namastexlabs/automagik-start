#!/bin/bash

# Automagik Start Script
# This script clones the automagik-start repository and runs the installation

set -e

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
        exit 1
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
echo "📁 Installation directory: $(pwd)"
echo "🚀 To start all services:"
echo "   cd automagik && make start"
echo "🛑 To stop all services:"
echo "   cd automagik && make stop"
echo "📊 To check service status:"
echo "   cd automagik && make status"
echo "💡 To see all available commands:"
echo "   cd automagik && make help"
echo ""
echo "🎯 Quick start:"
echo "   cd automagik"
echo "   make start"