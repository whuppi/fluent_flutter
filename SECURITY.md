# Security Policy

## Reporting a vulnerability

Report privately via [GitHub Security Advisories](https://github.com/whuppi/fluent_flutter/security/advisories/new). Do not open a public issue.

## What's in scope

- **Markup rendering attaching gestures the caller didn't wire** — translator-authored tags map to spans through the caller's `styles` / `tags` / `applyRecognizer` only. A message that gets a recognizer or builder attached to content the caller didn't opt in for is a security report (translations are often the least-reviewed strings in an app).

- **Loader scope escapes** — `AssetFluentLoader` reads only the declared asset tree via the manifest. A locale tag crafted to reach assets outside the base path got past a control.

## What's NOT in scope

- **Untrusted-FTL parsing and resolution** — [fluent_bundle's scope](https://github.com/whuppi/fluent_bundle/blob/dev/SECURITY.md).

- **Your custom loader's transport** — a server-delivered-translations loader owns its own TLS, authenticity, and rollback story; this package consumes what it returns.

- **Formatting fidelity** — backend concerns; report to the backend package.

## Response

Valid reports are fixed and shipped as patch versions.
