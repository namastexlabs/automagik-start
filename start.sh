#!/bin/bash

# Automagik Start Script
# This script clones the automagik-start repository and runs the installation

set -e

echo "🚀 Starting Automagik installation..."

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