#!/usr/bin/env bash
# POP Flow — cosmic-blackhole: a "black hole" on the desktop. Loose files that
# land there (downloads, screenshots, saves) are moved into one folder; the
# folders and launchers you put there stay.
#
#   ./install.sh                  # the folder is "CAOS" on the desktop
#   ./install.sh --folder NAME    # another name (or an absolute path)
#   ./install.sh --no-icon        # keep the folder's current icon
#
# 1. Installs the mover to ~/.local/bin/pop-flow-blackhole.
# 2. Creates the folder and gives it the black hole icon (the folder's
#    metadata::custom-icon, which POP Flow's cosmic-files shows; Nautilus too).
# 3. Installs systemd user units: .path runs the mover on every change to the
#    desktop, .timer every 2 min as a safety net.
#
# All per user, no sudo. Re-run it to change the folder (files already moved
# stay where they are). ./uninstall.sh takes it all out and keeps the folder
# and everything in it.
set -euo pipefail
cd "$(dirname "$0")"

BIN=$HOME/.local/bin/pop-flow-blackhole
ICON_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/icons/pop-flow
ICON=$ICON_DIR/blackhole.svg
UNIT_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user

usage() { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

folder=CAOS icon=1
while [ $# -gt 0 ]; do
    case $1 in
        --folder) folder=${2:?--folder needs a name}; shift 2 ;;
        --no-icon) icon=0; shift ;;
        -h|--help) usage ;;
        *) echo "!! unknown option: $1"; usage 1 ;;
    esac
done
if [ "$EUID" = 0 ]; then
    echo "!! run it as your user (it is a per-user service)."
    exit 1
fi
if [[ $folder != /* && ( $folder == */* || $folder == . || $folder == .. ) ]]; then
    echo "!! --folder: a name, or an absolute path"; exit 1
fi

desk=$(xdg-user-dir DESKTOP 2>/dev/null || true)
[ -n "$desk" ] && [ "$desk" != "$HOME" ] || desk=$HOME/Desktop
case $folder in /*) hole=$folder ;; *) hole=$desk/$folder ;; esac
if [ "$(realpath -m "$hole")" = "$(realpath -m "$desk")" ]; then
    echo "!! the folder can't be the desktop itself"; exit 1
fi
# A "%" in a unit file starts a specifier: double it. "|" and "&" would
# break the sed in step 3, "\"" the quoted Environment= line.
for p in "$desk" "$hole"; do
    case $p in *[\|\&\"]*) echo "!! paths with | & or \" are not supported: $p"; exit 1 ;; esac
done

# --- 0. A hand-made version of this (caos-blackhole) gives way ----------------
for unit in caos-blackhole.path caos-blackhole.timer; do
    if [ -e "$UNIT_DIR/$unit" ]; then
        systemctl --user disable --now "$unit" 2>/dev/null || true
        rm -f "$UNIT_DIR/$unit"
        echo "==> Replaced the older $unit"
    fi
done
rm -f "$UNIT_DIR/caos-blackhole.service" "$HOME/.local/bin/caos-blackhole"

# --- 1. The mover ---------------------------------------------------------------
install -Dm 0755 bin/pop-flow-blackhole "$BIN"
echo "==> Installed $BIN"

# --- 2. The folder and its icon -------------------------------------------------
mkdir -p "$hole"
if [ "$icon" = 1 ]; then
    install -Dm 0644 data/blackhole.svg "$ICON"
    if gio set "$hole" metadata::custom-icon "file://$ICON" 2>/dev/null; then
        echo "==> \"$hole\" has the black hole icon"
    else
        echo "!! could not set the folder icon (no gio?); the rest works"
    fi
fi

# --- 3. systemd user units ------------------------------------------------------
mkdir -p "$UNIT_DIR"
unit_desk=${desk//\%/%%} unit_hole=${hole//\%/%%}
for f in systemd/pop-flow-blackhole.*; do
    sed -e "s|@DESKTOP@|$unit_desk|g" -e "s|@FOLDER@|$unit_hole|g" "$f" > "$UNIT_DIR/$(basename "$f")"
done
systemctl --user daemon-reload
systemctl --user enable --now pop-flow-blackhole.path pop-flow-blackhole.timer >/dev/null
systemctl --user start pop-flow-blackhole.service || true
echo "==> Loose files on the desktop now go to \"$hole\""
