# Security Policy

## Supported versions

Only the latest commit on `main` is supported.

## Reporting a vulnerability

Please do not open a public issue. Use GitHub's private vulnerability reporting: **Security → Report a vulnerability** on https://github.com/hpmartini/session-tracker. Include the affected file, steps to reproduce and the impact you expect.

You can expect a first reply within a week.

## Scope notes

- The dashboard listens on `127.0.0.1` only and has no authentication. Anything that lets another host or a website reach it, or lets a request read or write outside `events.sqlite`, is in scope.
- `session-backfill` reads browser, shell and system history locally and stores timestamps only. Anything that stores or transmits URLs, commands or file contents is in scope.
