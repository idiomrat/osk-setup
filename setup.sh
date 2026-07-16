#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Creating Distrobox container 'a' with Ubuntu 24.04..."
distrobox create -n a -i ubuntu:24.04 -y

echo "Installing 'onboard' inside container 'a'..."
# Distrobox shares your user privileges, but apt requires root within the container
distrobox enter a -- sudo apt update && distrobox enter a -- sudo apt install -y onboard

echo "Ensuring target directories exist..."
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.config/fish"

echo "Downloading the desktop entry file..."
RAW_DESKTOP_URL="https://raw.githubusercontent.com/idiomrat/osk-setup/main/a-onboard.desktop"
DESKTOP_DEST="$HOME/.local/share/applications/a-onboard.desktop"
curl -sSL "$RAW_DESKTOP_URL" -o "$DESKTOP_DEST"
chmod +x "$DESKTOP_DEST"

echo "Downloading the Fish shell configuration..."
FISH_URL="https://raw.githubusercontent.com/idiomrat/osk-setup/refs/heads/main/config.fish"
FISH_DEST="$HOME/.config/fish/config.fish"
curl -sSL "$FISH_URL" -o "$FISH_DEST"

echo "Setup complete! Both files have been successfully downloaded and configured."
