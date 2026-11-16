#!/usr/bin/env bash
# POP Flow — cosmic-blackhole: take out what install.sh put in.
#
# Stops the units and removes them, the mover and the icon. The folder and
# every file in it stay where they are; it just goes back to a plain folder
# icon.
set -euo pipefail

BIN=$HOME/.local/bin/pop-flow-blackhole
ICON=${XDG_DATA_HOME:-$HOME/.local/share}/icons/pop-flow/blackhole.svg
UNIT_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
SERVICE=$UNIT_DIR/pop-flow-blackhole.service

# The folder the service was moving files into, to take its icon off.
hole=""
if [ -f "$SERVICE" ]; then
    hole=$(sed -n 's/^Environment="POP_FLOW_BLACKHOLE_DIR=\(.*\)"$/\1/p' "$SERVICE")
    hole=${hole//%%/%}
fi

systemctl --user disable --now pop-flow-blackhole.path pop-flow-blackhole.timer 2>/dev/null || true
rm -f "$UNIT_DIR"/pop-flow-blackhole.{path,timer,service}
systemctl --user daemon-reload
rm -f "$BIN"
echo "==> The desktop is no longer swept"

if [ -n "$hole" ] && [ -d "$hole" ] \
    && gio info -a metadata::custom-icon "$hole" 2>/dev/null | grep -qF "$ICON"; then
    gio set -t unset "$hole" metadata::custom-icon
    echo "==> \"$hole\" kept, with a plain folder icon"
fi
rm -f "$ICON"
rmdir "$(dirname "$ICON")" 2>/dev/null || true

echo "==> cosmic-blackhole removed (your files were not touched)"
