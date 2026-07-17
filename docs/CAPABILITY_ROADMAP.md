# fluent_flutter — Capabilities

What the Flutter integration offers. For how it's wired see
[`ARCHITECTURE.md`](ARCHITECTURE.md); for maintenance recipes see
[`UPDATING.md`](UPDATING.md). Formatting fidelity is the backend's
concern — the family option matrix lives in
[`fluent_bundle/docs/CAPABILITY_ROADMAP.md`](../../fluent_bundle/docs/CAPABILITY_ROADMAP.md).

---

## Loaders

| Feature | Status |
|---|:---:|
| `FluentResourceLoader` interface (empty-for-unknown contract, evict seam) | ✓ |
| `AssetFluentLoader` — locales DISCOVERED from the AssetManifest | ✓ |
| Single-file (`{tag}.ftl`) + folder (`{tag}/*.ftl`) layouts, together | ✓ |
| `CompositeFluentLoader` — app + package FTL merged, earlier wins | ✓ |
| Custom loaders (network, disk, tests) via the interface | ✓ |

## Locale lifecycle

| Feature | Status |
|---|:---:|
| `FluentLocaleController.init` — async discovery once, sync after | ✓ |
| `setLocale` (negotiated through the core's `negotiateLocaleChain`) | ✓ |
| `useDeviceLocale` — keeps following system-settings changes until an explicit set | ✓ |
| Persistence seam: `initialLocale` + `onLocaleChanged`, no storage dependency (recipe in UPDATING §4) | ✓ |
| `flutterLocale` / `supportedLocales` for MaterialApp wiring | ✓ |
| `reload()` — evict + generation bump (delegates re-load) | ✓ |

## Widget-tree access

| Feature | Status |
|---|:---:|
| `FluentLocalizationsDelegate` — a real `LocalizationsDelegate`; composes with Material/Cupertino delegates and `Localizations.override` | ✓ |
| Bundle-chain locale fallback per message (`FluentBundleChain`) | ✓ |
| Empty-fallback-bundle debug assert (setup bugs are loud) | ✓ |
| `FluentLocalization.of` / `maybeOf` / `context.fluent` | ✓ |
| `TypedFluentDelegate<T>` — fluent_gen bridge, generated accessors gain chain fallback, zero fluent_gen import | ✓ |
| Backend choice per delegate (`FluentBackend` default; `IntlBackend` / `IcuBackend` plug in) | ✓ |

## Markup (`package:fluent_flutter/markup.dart`)

| Feature | Status |
|---|:---:|
| `fluentSpansToInline` — builders > styles > overlay rule (unknown-tag children render unstyled; assert-in-debug unless `onUnknownTag` opts out) | ✓ |
| `applyRecognizer` — taps on LEAF text spans (the only place Flutter fires them) | ✓ |
| `FluentText` — the `Localized`-component analog, attributes included | ✓ |
| `formatMessageAsSpans` extension on `FluentLocalization` (kept in this barrel so the main one never carries the HTML parser) | ✓ |

## Dev loop

| Feature | Status |
|---|:---:|
| `FluentHotReload` — edit `.ftl`, press `r`, strings update (reassemble → evict → re-load) | ✓ |

## Test coverage

| Coverage | Where |
|---|---|
| Widget suite, mirrors `lib/src` file-for-file (41 tests) | `test/` |
| The showcase driven end to end — locale strip, plural stepper, link tap through the real recognizer, device chip, three-rung chain | `example/test/journeys/` |
| Chain + negotiation semantics | fluent_bundle's own suites (`test/bundle/bundle_chain_test.dart`, `test/locale/negotiation_test.dart`) |

## Won't do

| Capability | Reason |
|---|---|
| A global `t` singleton | Explicit over implicit — hidden mutable globals are slang's biggest footgun. The two doors are the controller (verbs) and the context (reads). |
| `Text('key').tr()` string extensions | Stringly-typed; defeats fluent_gen's premise. |
| Built-in locale persistence | Would force a storage dependency on every consumer; the seam + a 6-line recipe (UPDATING §4) covers it. |
| A backend | fluent_icu / fluent_intl territory — this package formats nothing. |
| Codegen | fluent_gen territory — `TypedFluentDelegate` consumes its output generically. |
| ARB migration tooling | A future standalone `fluent_migrate` (same call as fluent_gen's won't-do row). |
| Message extraction from widget code | Not a v1 concern; fluent-react lists it as future work too. |
