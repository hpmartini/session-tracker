# TASK: Menubar fehlt / zeigt 8:50 h statt ~5 h (2026-10-23)

## Issue
- Menubar-Eintrag nicht sichtbar, in Raycast nicht auffindbar.
- Vorher stand 8:50 h in der Menubar, Dashboard zeigte richtig ~5 h.

## Ursache
- Für Screenshots mit Demo-Daten wurde der LaunchAgent `dev.hpmartini.session-menubar` per `launchctl bootout` gestoppt und danach nicht wieder geladen; `pkill -f bin/session-menubar` traf zusätzlich das installierte Binary.
- 8:50 h kam von der Demo-Instanz (`SESSION_DB` = synthetische Demo-DB mit erfundenen Blöcken für heute), nicht von echten Daten.
- Raycast: indexiert nur `.app`-Bundles; `~/.local/bin/session-menubar` ist laut Briefing bewusst ein reines Binary ohne Bundle.

## Lösung
- `./install.sh` aus `feat/menubar-app` erneut: alle drei Agents `running`.
- Geprüft: Menubar 6:05 h / 3 Sessions / Start 09:25 = `session-report --heute --json` (21936 s) = Dashboard-API (21942 s, Sekunden später).
- Gleichzeitig ausgeliefert (Commit 19046a1): Infozeilen mit `labelColor` statt blassem Disabled-Grau, Zeile „Ende“ entfernt.

## Offen
- Screenshot `docs/screenshots/menubar.png` zeigt noch die alte Version mit „Ende“.
- Raycast-Fund nur mit `.app`-Wrapper (Entscheidung offen).
