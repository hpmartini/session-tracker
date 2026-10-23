#!/bin/sh
# Installs session-tracker for the current user: CLI tools, dashboard, tracker binary, menubar app, three LaunchAgents.
# Needs macOS, python3 and the Xcode command line tools (swiftc). Re-running updates an existing install.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
bin="$HOME/.local/bin"
share="$HOME/.local/share/session-tracker"
agents="$HOME/Library/LaunchAgents"
app="$HOME/Applications/Session Tracker.app"  # a bundle, so Raycast and Spotlight find the menubar
mkdir -p "$bin" "$share" "$agents" "$app/Contents/MacOS"

install -m 755 "$here"/bin/session-* "$bin/"
install -m 644 "$here/dashboard/dashboard.html" "$share/"
swiftc -O -o "$bin/session-tracker" "$here/tracker/session-tracker.swift"
install -m 644 "$here/tracker/session-menubar-Info.plist" "$app/Contents/Info.plist"
swiftc -O -o "$app/Contents/MacOS/session-menubar" "$here/tracker/session-menubar.swift"
rm -f "$bin/session-menubar"  # lived here before the app bundle
mdimport "$app" 2>/dev/null || true  # Spotlight/Raycast find it right away instead of at the next index run
"$bin/session-report" --selftest

for name in session-tracker session-dashboard session-menubar; do
  label="dev.hpmartini.$name"
  sed "s|__HOME__|$HOME|g" "$here/launchagents/$label.plist" > "$agents/$label.plist"
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  # bootstrap can fail with "Input/output error" while the old job is still being removed
  n=0
  until launchctl bootstrap "gui/$(id -u)" "$agents/$label.plist"; do
    n=$((n + 1))
    [ "$n" -lt 5 ] || { echo "bootstrap of $label failed after $n attempts" >&2; exit 1; }
    sleep 1
  done
done
echo "Dashboard: http://127.0.0.1:8765"
