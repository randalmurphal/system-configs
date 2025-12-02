#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Building sysinfo-daemon..."
cd "$SCRIPT_DIR"
cargo build --release

echo "Installing binary..."
mkdir -p ~/.local/bin
cp target/release/sysinfo-daemon ~/.local/bin/

echo "Installing systemd service..."
mkdir -p ~/.config/systemd/user
cp sysinfo.service ~/.config/systemd/user/

echo "Enabling and starting service..."
systemctl --user daemon-reload
systemctl --user enable --now sysinfo

echo "Verifying..."
sleep 0.5
cat /tmp/sysinfo

echo ""
echo "Done! sysinfo-daemon is running."
