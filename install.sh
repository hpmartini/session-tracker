#!/bin/sh
# Installs session-tracker for the current user: CLI tools, dashboard, tracker and menubar binaries, three LaunchAgents.
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
swiftc -O -o "$bin/session-menubar" "$here/tracker/session-menubar.swift"
"$bin/session-report" --selftest

for name in session-tracker session-dashboard session-menubar; do
  label="dev.hpmartini.$name"
  sed "s|__HOME__|$HOME|g" "$here/launchagents/$label.plist" > "$agents/$label.plist"
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  # bootout returns before the old job is gone; bootstrapping too early fails with "5: Input/output error"
  i=0; while launchctl print "gui/$(id -u)/$label" >/dev/null 2>&1 && [ $i -lt 10 ]; do sleep 1; i=$((i + 1)); done
  launchctl bootstrap "gui/$(id -u)" "$agents/$label.plist"
done
echo "Dashboard: http://127.0.0.1:8765"
