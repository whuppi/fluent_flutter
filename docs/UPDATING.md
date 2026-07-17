# Updating fluent_flutter

Maintenance recipes for the Flutter integration satellite. For how it's
wired see [`ARCHITECTURE.md`](ARCHITECTURE.md); for capability status
see [`CAPABILITY_ROADMAP.md`](CAPABILITY_ROADMAP.md).

This package tracks two upstreams:

| Source | Why |
|---|---|
| `fluent_bundle` | The runtime it re-exports; `FluentBundleChain` + `negotiateLocaleChain` are the load-bearing primitives |
| Flutter itself | `LocalizationsDelegate`, `AssetManifest`, `WidgetsBindingObserver`, `TextSpan.recognizer` — framework-API moves land here first |

---

## When to update

| Trigger | Recipe |
|---|---|
| `fluent_bundle` changes the bundle or negotiation surface | §1 |
| A Flutter stable bumps the framework APIs this package sits on | §2 |
| Adding a loader | §3 |
| A consumer asks for locale persistence | §4 (recipe, not code) |

---

## §1 — Sync with fluent_bundle

1. `fvm flutter pub get`, run `make check`.
2. Chain semantics (which member formats, attribute-miss behavior,
   read-only view) are the CORE's contract — proven by its
   `bundle_chain_test.dart`. This package only re-tests what it adds
   on top (delegate loading, widget access). Don't duplicate the
   core's suites here.
3. If `negotiateLocaleChain`'s ladder changes, the controller and the
   chain builder pick it up automatically — re-run the journeys and
   re-read the Fallback card's pinned chain.

## §2 — A Flutter stable bump

The framework surfaces this package leans on, and what to re-verify:

| API | Used by | Re-verify |
|---|---|---|
| `AssetManifest.loadFromAssetBundle` | `AssetFluentLoader` | locale discovery on a real app + the fake-bundle suite |
| `LocalizationsDelegate.load/shouldReload` | both delegates | locale switch + `reload()` journeys |
| `WidgetsBindingObserver.didChangeLocales` | the controller | the device-chip journey |
| `State.reassemble` + asset re-sync on hot `r` | `FluentHotReload` | the live loop: `flutter run` the example, edit an `.ftl`, press `r` |
| `TextSpan.recognizer` leaf-only firing | `applyRecognizer` | the link-tap journey |

`make check` covers all but the live hot-reload loop — that one is a
manual step on Flutter bumps.

## §3 — Add a loader

Implement `FluentResourceLoader` (three members). The contract that
must hold: `load` returns EMPTY for an unknown tag (never throws), and
`evict` drops any cache (default no-op). Add a suite mirroring
`test/loader/`, and if the loader caches, test that `evict` really
drops it — the hot-reload path depends on it.

## §4 — The locale-persistence recipe

Deliberately not in the package (no storage dependency). The seam:

```dart
final prefs = await SharedPreferences.getInstance();
final controller = await FluentLocaleController.init(
  loader: AssetFluentLoader(),
  fallbackLocale: 'en',
  initialLocale: prefs.getString('locale'),
  onLocaleChanged: (tag) => prefs.setString('locale', tag),
);
```

The controller never fires `onLocaleChanged` for the init resolution,
so feeding the saved value back doesn't rewrite it.

---

## Reading the failure modes

| Failure | First check |
|---|---|
| Every message renders as its id | The fallback bundle loaded zero sources — asset folder not declared in `pubspec.yaml`, or `fallbackLocale` doesn't match a served tag. Debug builds assert with exactly this. |
| A locale never shows up in the strip / supportedLocales | The AssetManifest doesn't list it — folder-layout locales need their subfolder declared too (`assets/i18n/de/`). |
| `setLocale` does nothing on screen | The `MaterialApp` isn't rebuilt under a `ListenableBuilder` on the controller — `shouldReload` only runs when Flutter sees a NEW delegate instance. |
| A markup link doesn't tap | The recognizer sits on a wrapper span — run the children through `applyRecognizer` (Flutter fires recognizers only on the span owning the text). |
| A tag renders unstyled + a debug assert | Translator tag with no builder/style — add it, or accept unknown tags via `onUnknownTag`. Also check the tag isn't an HTML5 VOID name (`link`, `br`, `img`) — those parse childless. |
| FTL edits don't show on hot reload | `FluentHotReload` not in the tree, or the app runs a custom loader whose `evict` doesn't drop its cache. |
| Widget tests hang loading FTL from assets | Per-test fake-async zones can't drive fresh asset-channel loads after the first test — snapshot the FTL once in `setUpAll` (see the example journeys' header). |

---

## The canonical-doc contract

Three living docs, no fourth: this file, `ARCHITECTURE.md`,
`CAPABILITY_ROADMAP.md`. Design history lives in git; per-file notes
live in code comments.
