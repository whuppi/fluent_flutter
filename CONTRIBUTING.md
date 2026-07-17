# Contributing

Contributions are welcome.

---

## Setup

```bash
git clone https://github.com/whuppi/fluent_flutter.git
cd fluent_flutter
make hooks               # activates commit-msg + pre-commit (run once)
fvm install              # downloads the SDK version pinned in .fvmrc
fvm dart pub get

# The family is pre-release: the pubspec resolves sibling repos by path.
# Clone them NEXT TO this checkout (same parent directory):
#   ../fluent_bundle     https://github.com/whuppi/fluent_bundle
#   ../fluent_intl       https://github.com/whuppi/fluent_intl (example backend)
fvm flutter test
```

**Requires:** [FVM](https://fvm.app) (`.fvmrc` pins the exact SDK
version).

**Without FVM:** all Makefile commands accept `DART` and `FLUTTER`
overrides:

```bash
make check DART=dart FLUTTER=flutter
```

---

## Before submitting a PR

```bash
make check
```

Runs `lint-shell` + `analyze` (package + example app, each from its
own root) + `analyze-floor` + `test` (the widget suite, host VM) +
`test-example` (the example app's journeys through the real delegates).
The `platforms` gate is blocked-loud pre-release.
Must pass. Don't suppress with `// ignore:` — fix the underlying
issue.

---

## PR workflow

All PRs target `dev`. That's the only branch contributors touch.

```
your fork / feature branch ──PR──► dev
                                    ↓ CI: make targets via the make-target action
                                    ↓ PR title: Conventional Commits (feat: / fix: / etc.)
                                    ↓ squash-merge when green
                                    ↓ Full test suite via "ready-to-test" label
                                      (suites × OS matrix)
```

CI calls Makefile targets — same commands locally and in CI.

You don't write changelog entries, bump versions, or touch `prod`.
The maintainer handles releases.

---

## Code style

- Match existing code in the repo.
- No `fluent_gen` import anywhere — the typed delegate consumes
  generated classes through the `create` callback seam only.
- Loaders return an EMPTY list for an unknown locale, never throw —
  negotiation owns fallback.
- Widget tests drive the real delegates; asset-dependent suites
  snapshot FTL in `setUpAll` (fake-async zones can't serve fresh
  asset loads mid-test).

---

## Maintenance recipes

Step-by-step recipes (Flutter-behavior watchlist) live in
[`docs/UPDATING.md`](docs/UPDATING.md).

---

## Releases

Handled by the maintainer, via the family release checklist
(the fluent_bundle repo's `docs/UPDATING.md`).
