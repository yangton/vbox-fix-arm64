#!/bin/bash

LOGFILE="$HOME/vbox_fix.log"
SCRIPT_PATH="$(realpath "$0")"
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/vboxfix.desktop"

log() {
    echo "[$(date '+%H:%M:%S')] [$1] ${*:2}" | tee -a "$LOGFILE"
}

echo -e "\n=== 🚀 Ultimate VBox Fix ARM64 Started: $(date) ===" >> "$LOGFILE"

if [ ! -f "$AUTOSTART_FILE" ]; then
    log "INFO" "Setting up autostart..."
    mkdir -p "$AUTOSTART_DIR"
    cat > "$AUTOSTART_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Ultimate VBox Fix
Comment=Automatically fixes VirtualBox resolution & clipboard on ARM64
Exec=$SCRIPT_PATH
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
    log "OK" "Added to autostart: $AUTOSTART_FILE"
fi

if ! command -v VBoxClient &>/dev/null; then
    log "ERROR" "VBoxClient not found. Install virtualbox-guest-utils."
    exit 1
fi

if ! lsmod | grep -q "vboxvideo"; then
    log "INFO" "vboxvideo module missing. Attempting to load..."
    sudo modprobe vboxvideo >> "$LOGFILE" 2>&1 || log "WARN" "Failed to load vboxvideo (might be built-in)."
fi

log "INFO" "Nuking existing/hanging VBoxClient processes..."
pkill -f VBoxClient >> "$LOGFILE" 2>&1 || true
sleep 1

start_service() {
    VBoxClient "$2" >> "$LOGFILE" 2>&1 &
    sleep 0.5
    if pgrep -f "VBoxClient $2" > /dev/null 2>&1; then
        log "OK" "$1 started successfully (PID: $(pgrep -f "VBoxClient $2" | tail -1))"
    else
        log "ERROR" "$1 failed to start. Check logs."
    fi
}

export DISPLAY="${DISPLAY:-:0}"

log "INFO" "Igniting VBoxClient services..."

start_service "Resolution (VMSVGA)" "--vmsvga-session"
start_service "Clipboard"           "--clipboard"
start_service "Drag & Drop"         "--draganddrop"

if command -v notify-send &>/dev/null; then
    notify-send "🚀 Ultimate VBox Fix" "Screen scaling & Clipboard are now working!" \
        --icon=preferences-system --urgency=low 2>/dev/null || true
fi

log "DONE" "All tasks completed! Log: $LOGFILE"
