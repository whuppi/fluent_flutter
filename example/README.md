# fluent_flutter example

A Flutter app exercising every fluent_flutter surface. A locale strip
switches between English, German, and a deliberately tiny Swiss German
live; the cards below re-render in the picked locale — real CLDR
plurals, currency, and dates through `IntlBackend`, translator-authored
inline markup with a tappable link, per-attribute rendering, and the
bundle-chain fallback made visible (the loaded chain plus a message
that only exists in English). Editing any `.ftl` under `assets/i18n/`
and pressing `r` updates the strings live (`FluentHotReload`).

## Run

```bash
cd example

# the repo ships no platform folders (nothing in this demo is
# platform-specific) — generate them once for the target you want:
fvm flutter create --platforms=macos .

fvm flutter run -d macos
```

## Tests

```bash
# from the package root
make test-example

# or directly
cd example
fvm flutter test test/journeys
```

The journeys drive this exact UI end to end — the locale strip, the
plural stepper, the link tap (fired through the span tree's real
recognizer), the device-locale chip, and the three-rung fallback chain
on one screen — through the real delegates, the real `IntlBackend`,
and the real bundled FTL (snapshotted once in `setUpAll`, because
per-test fake-async zones can't drive fresh asset-channel loads).
There is no integration_test lane on purpose: nothing here is native
(the demo uses `IntlBackend` precisely so it needs no Rust build);
host-VM journeys are the whole proof.

## What's inside

| Card | Surface | What it covers |
|---|---|---|
| **Locale strip** | `FluentLocaleController` | `setLocale` per available tag (discovered from the AssetManifest, never hand-listed), `useDeviceLocale` chip that keeps following system-settings changes |
| **Messages** | `FluentLocalization` / `context.fluent` | Arguments, a plural stepper driving real CLDR categories, `NUMBER` currency (USD → EUR per locale), `DATETIME` |
| **Markup** | `package:fluent_flutter/markup.dart` | `FluentText` with a `styles:` bold and a `tags:` link builder — `applyRecognizer` puts the tap on the leaf spans; attribute rendering (`login.title`) |
| **Fallback** | `FluentBundleChain` | The loaded chain rendered live; `de-CH` shows a greeting from de-CH, plurals from de, and an English-only string from en — three rungs on one screen |

## One file on purpose

The whole app lives in `lib/main.dart` because pub.dev renders that
file as the package's Example tab — splitting it would hide everything
else from that page.

## Two FTL layout notes worth stealing

The assets demonstrate both loader layouts (`{tag}.ftl` files under
one declared folder), and `de-CH.ftl` is deliberately one line — a
locale can start that small because the chain covers the rest. Tag
names in markup avoid HTML5 VOID elements (`link`, `br`, `img`) — the
parser follows the HTML5 grammar, so a void tag loses its children;
this demo uses `<a>`.
