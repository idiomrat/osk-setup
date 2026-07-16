#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Creating Distrobox container 'a' with Ubuntu 24.04..."
distrobox create -n a -i ubuntu:24.04 -y

echo "Installing 'onboard' inside container 'a'..."
# Distrobox shares your user privileges, but apt requires root within the container
distrobox enter a -- sudo apt update && distrobox enter a -- sudo apt install -y onboard

echo "Ensuring the local applications directory exists..."
mkdir -p "$HOME/.local/share/applications"

echo "Downloading the desktop entry file..."
# Using the raw GitHub URL to get the actual file content
RAW_URL="https://raw.githubusercontent.com/idiomrat/osk-setup/main/a-onboard.desktop"
DEST_FILE="$HOME/.local/share/applications/a-onboard.desktop"

curl -sSL "$RAW_URL" -o "$DEST_FILE"

echo "Making the desktop file executable..."
chmod +x "$DEST_FILE"

echo "Setup complete! You should now see the 'a-onboard' application in your launcher."
