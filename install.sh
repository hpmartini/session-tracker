#!/bin/sh
# Installs session-tracker for the current user: CLI tools, dashboard, tracker binary, two LaunchAgents.
# Needs macOS, python3 and the Xcode command line tools (swiftc). Re-running updates an existing install.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
bin="$HOME/.local/bin"
share="$HOME/.local/share/session-tracker"
agents="$HOME/Library/LaunchAgents"
mkdir -p "$bin" "$share" "$agents"

install -m 755 "$here"/bin/session-* "$bin/"
install -m 644 "$here/dashboard/dashboard.html" "$share/"
swiftc -O -o "$bin/session-tracker" "$here/tracker/session-tracker.swift"
"$bin/session-report" --selftest

for name in session-tracker session-dashboard; do
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
