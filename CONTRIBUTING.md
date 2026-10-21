# Contributing

Thanks for helping. This is a small project, so the process is small too.

## Before you start

- Open an issue for anything bigger than a bug fix or a doc change, so we agree on the direction first.
- The project is macOS-only on purpose. Linux or Windows ports are out of scope for this repo.

## Development

```sh
git clone https://github.com/hpmartini/session-tracker.git
cd session-tracker
bin/session-report --selftest        # must print "selftest ok"
npm ci && npx playwright test        # dashboard browser tests (needs Node 18+ and Google Chrome)
python3 -I -m unittest discover -s tests   # derived-block cache
swiftc -typecheck tracker/session-tracker.swift
sh -n install.sh
python3 scripts/make-demo-db.py /tmp/demo.sqlite   # fake data for the dashboard, see README
```

## Pull requests

- One topic per pull request, branched from `main`.
- Logic changes in `bin/session-report` come with an assert in its `selftest()`. The dashboard imports that module, so the report and the dashboard stay in sync.
- No real working times, browser history or personal paths in code, tests, fixtures or screenshots. Use `scripts/make-demo-db.py`.
- Keep the code in the style of the surrounding file: short functions, comments only for the why, no new dependencies (the tools use the Python standard library only).
- Commit messages: `type: short summary` (`feat`, `fix`, `docs`, `refactor`, `chore`).

By contributing you agree that your contribution is licensed under the [MIT License](LICENSE).
