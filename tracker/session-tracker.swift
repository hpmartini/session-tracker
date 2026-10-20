// Schreibt Anwesenheits-Events (Login, Sperre, Ruhezustand, Display) nach SQLite.
// Build: swiftc -O -o ~/.local/bin/session-tracker session-tracker.swift
import AppKit
import SQLite3

let dbPath = NSHomeDirectory() + "/.local/share/session-tracker/events.sqlite"
var db: OpaquePointer?
guard sqlite3_open(dbPath, &db) == SQLITE_OK else { exit(1) }
sqlite3_busy_timeout(db, 5000)
sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS events(ts INTEGER NOT NULL DEFAULT (strftime('%s','now')), event TEXT NOT NULL)", nil, nil, nil)

// Event-Namen sind Konstanten aus diesem File, daher kein Binding nötig.
func log(_ event: String) {
    sqlite3_exec(db, "INSERT INTO events(event) VALUES ('\(event)')", nil, nil, nil)
}

func screenLocked() -> Bool {
    (CGSessionCopyCurrentDictionary() as? [String: Any])?["CGSSessionScreenIsLocked"] as? Bool ?? false
}

// Wake/Display-an auf dem Sperrbildschirm ist keine Anwesenheit.
func logUnlessLocked(_ event: String) { log(screenLocked() ? event + "_locked" : event) }

let ws = NSWorkspace.shared.notificationCenter
let workspaceEvents: [(Notification.Name, () -> Void)] = [
    (NSWorkspace.willSleepNotification, { log("sleep") }),
    (NSWorkspace.didWakeNotification, { logUnlessLocked("wake") }),
    (NSWorkspace.screensDidSleepNotification, { log("display_off") }),
    (NSWorkspace.screensDidWakeNotification, { logUnlessLocked("display_on") }),
    (NSWorkspace.willPowerOffNotification, { log("logout") }),
]
for (name, handler) in workspaceEvents {
    ws.addObserver(forName: name, object: nil, queue: .main) { _ in handler() }
}
let dnc = DistributedNotificationCenter.default()
dnc.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: .main) { _ in log("lock") }
dnc.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { _ in log("unlock") }

// launchd beendet den Agent beim Logout mit SIGTERM.
signal(SIGTERM, SIG_IGN)
let term = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
term.setEventHandler { log("stop"); exit(0) }
term.resume()

// Heartbeat: nach Absturz oder hartem Ausschalten endet die offene Sitzung beim letzten Lebenszeichen.
Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in log("alive") }

logUnlessLocked("start")
NSApplication.shared.setActivationPolicy(.prohibited)
NSApp.run()
