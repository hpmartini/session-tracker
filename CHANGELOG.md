# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Menubar app (`tracker/session-menubar.swift`, LaunchAgent `dev.hpmartini.session-menubar`): today's total in the menu bar, a menu with total, sessions, start and end, and "Dashboard öffnen" (starts the dashboard agent if it is not reachable).
- `session-report --heute --json`: today's numbers as JSON; `session-report` honours `SESSION_DB` like the dashboard.

## [0.1.1] - 2026-10-21

### Changed
- Dashboard caches the derived blocks per pause threshold (`gap`); the cache is dropped when the `derived` table changes (backfill) or the first tracked event moves. Tracked blocks are never cached, so new events show up immediately. Warm `/api/data?derived=1` computation dropped from about 0.3 s to about 0.07 s.

## [0.1.0] - 2026-10-21

First public version.

### Added
- Tracker (`tracker/session-tracker.swift`): LaunchAgent that writes login, lock, sleep, wake, display and heartbeat events to a local SQLite file.
- `session-report`: presence blocks, pauses under a threshold merged (default 5 min), per-day totals and a per-year table (average, days under a threshold, average without them). `--zeitraum` selects one of 13 periods shared with the dashboard.
- `session-dashboard` on `127.0.0.1:8765`: blocks and raw events, filters, CSV export, a "today" tile that refreshes every minute, 13 period selectors and a threshold field for short days. Blocks are split at local midnight and the year table follows the selected period, matching `session-report`.
- `session-backfill` (optional): estimated working times from before tracking started, stored separately and marked as derived. Derived data is off by default.
- `install.sh`, MIT license, README with screenshots (synthetic demo data), `scripts/make-demo-db.py` for fake data.
- `session-report --selftest`, Playwright browser tests for the dashboard (period filter, midnight split, year table, threshold field) and a CI workflow.
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, issue and pull request templates.

### Changed
- LaunchAgent labels are `dev.hpmartini.*` (earlier development builds used `de.martini-labs.*`). An existing install under the old labels keeps running next to a new one: remove the old agents first (`launchctl bootout gui/$(id -u)/de.martini-labs.session-tracker`, same for `session-dashboard`, then delete their plists in `~/Library/LaunchAgents`).

[Unreleased]: https://github.com/hpmartini/session-tracker/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/hpmartini/session-tracker/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/hpmartini/session-tracker/releases/tag/v0.1.0
