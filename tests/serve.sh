#!/bin/sh
# Starts the dashboard from this checkout on port 8792 with a throw-away HOME and the synthetic demo database.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
h=$(mktemp -d)
trap 'rm -rf "$h"' EXIT
mkdir -p "$h/.local/bin" "$h/.local/share/session-tracker"
cp "$here"/bin/session-* "$h/.local/bin/"
cp "$here/dashboard/dashboard.html" "$h/.local/share/session-tracker/"
export HOME="$h" TZ=Europe/Berlin SESSION_DB="$h/events.sqlite"
python3 -I "$here/scripts/make-demo-db.py" "$SESSION_DB" >/dev/null
python3 -I "$h/.local/bin/session-dashboard" 8792
