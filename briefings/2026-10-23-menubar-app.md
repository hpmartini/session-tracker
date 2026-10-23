# Briefing: Menubar-App für session-tracker

Quelle: https://github.com/hpmartini/session-tracker/issues/1 („Desktop-App“, Autor hpmartini).

## The Job
Eine native macOS-Menubar-App `session-menubar`, die mit `./install.sh` gebaut, installiert und per LaunchAgent beim Login gestartet wird. In der Menubar steht die heutige Gesamtzeit (z.B. `6:12 h`). Das Menü zeigt für heute: Gesamtzeit, Anzahl Sessions, Start (Beginn des ersten Blocks), Ende (Ende des letzten Blocks, oder „läuft“, solange der aktuelle Block offen ist). Ein Menüpunkt „Dashboard öffnen“ öffnet `http://127.0.0.1:8765` im Standardbrowser; ist das Dashboard nicht erreichbar, startet die App vorher den LaunchAgent `dev.hpmartini.session-dashboard` (`launchctl kickstart`). Dazu „Beenden“. Werte aktualisieren sich jede Minute und beim Öffnen des Menüs.

## Why
Hape will seine Arbeitszeit von heute auf einen Blick sehen, ohne Browser oder Terminal zu öffnen, und von dort mit einem Klick ins Dashboard springen. Die Menubar ist der schnellste Zugang zu einem Tool, das bisher nur als CLI und Weboberfläche existiert.

## Guardrails
- Swift-Einzeldatei wie `tracker/session-tracker.swift` (AppKit, `NSStatusItem`, `LSUIElement`-Verhalten per `NSApp.setActivationPolicy(.accessory)`), gebaut mit `swiftc` in `install.sh`. Keine Xcode-Projektdatei, keine Abhängigkeiten, weil das Repo bewusst dependency-frei ist.
- Zahlen nicht in Swift neu berechnen. Die Block-Logik (Intervalle, Pausen-Merge 5 min, Heartbeat-Lücken) lebt in `bin/session-report`; die App ruft eine neue maschinenlesbare Ausgabe davon auf, z.B. `session-report --heute --json` → `{"gesamt_s":…, "sessions":…, "start":…, "ende":…, "laeuft":…}`. So stimmen Menubar, CLI und Dashboard-„Heute“-Kachel überein.
- Neuer LaunchAgent `launchagents/dev.hpmartini.session-menubar.plist` nach Muster der vorhandenen zwei (`__HOME__`, `LimitLoadToSessionType Aqua`, `RunAtLoad`, `KeepAlive`); `install.sh`-Schleife und Uninstall-Abschnitt im README erweitern.
- Texte auf Deutsch, wie Report und Dashboard.
- Tracker, Dashboard-HTML und Backfill bleiben unverändert, außer was der JSON-Modus zwingend braucht.
- Annahme: „Sessions“ = Anzahl Blöcke nach Pausen-Merge (Standard 5 min), nicht rohe Unlock-Events.
- Annahme: Nur getrackte Daten von heute, ohne hergeleitete (`derived`).
- Annahme: Kein App-Bundle/Signing/Dock-Icon; reiner Hintergrundprozess wie der Tracker.

## Done means
- `./install.sh` läuft durch, Menubar zeigt die heutige Zeit; Menüwerte entsprechen `session-report` für heute.
- `session-report --selftest` deckt den JSON-Modus ab (offener Block, kein Event heute, mehrere Blöcke) und ist grün.
- CI grün: `swiftc -typecheck` für die neue Swift-Datei ergänzt, bestehende Checks und Playwright-Tests unverändert grün.
- Mit `SESSION_DB=/tmp/demo.sqlite` (aus `scripts/make-demo-db.py`; `session-report` kennt `SESSION_DB` bisher nicht, nur `session-dashboard` — Override analog ergänzen) lässt sich die App gegen Demo-Daten starten; Screenshot der Menubar mit Demo-Daten in `docs/screenshots/` und README-Abschnitt.
- PR gegen `main` mit `Closes https://github.com/hpmartini/session-tracker/issues/1` und `## Review-Anleitung`. Kein Merge.
- Stopp nur bei: fehlende Rechte für Menubar/launchctl, die sich nicht umgehen lassen. Sonst weiterarbeiten.
- Rückmeldung: kurzer Bericht, was gebaut wurde, welche Annahmen getroffen wurden.

## First on approval
`session-report` um den JSON-Modus für heute erweitern und im Selftest absichern.
