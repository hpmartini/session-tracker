# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). No tagged releases yet.

## [Unreleased]

### Added
- README with screenshots (synthetic demo data), badges, uninstall steps and example output.
- `scripts/make-demo-db.py` writes a fake database for demos and screenshots.
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, issue and pull request templates, CI workflow.

### Changed
- LaunchAgent labels renamed from `de.martini-labs.*` to `dev.hpmartini.*`. An existing install under the old labels keeps running next to a new one: remove the old agents first (`launchctl bootout gui/$(id -u)/de.martini-labs.session-tracker`, same for `session-dashboard`, then delete their plists in `~/Library/LaunchAgents`).

## 2026-10-19

### Added
- Initial public version: tracker, `session-report`, dashboard, `session-backfill`, installer, MIT license.
- `session-report --zeitraum` with the 13 periods shared with the dashboard.

### Changed
- Derived data is off by default in the dashboard.
- Dashboard blocks are split at local midnight and the year table follows the selected period, matching `session-report`.
