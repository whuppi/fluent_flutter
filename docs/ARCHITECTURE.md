# fluent_flutter — Architecture

How the Flutter integration satellite is wired. For capability status
see [`CAPABILITY_ROADMAP.md`](CAPABILITY_ROADMAP.md); for maintenance
recipes see [`UPDATING.md`](UPDATING.md).

fluent_flutter is an INTEGRATION satellite — it implements no
`FluentBackend` (that's fluent_icu / fluent_intl) and generates no code
(that's fluent_gen). Its job is everything between the core runtime and
a running Flutter app: where FTL comes from, which locale is active,
how the widget tree reads messages, and how markup becomes
`InlineSpan`s.

---

## 1. The structure

```
lib/
  fluent_flutter.dart          — MAIN barrel: re-exports fluent_bundle +
                                 loaders, controller, delegates, hot reload.
                                 Never carries package:html.
  markup.dart                  — OPT-IN barrel: fluentSpansToInline,
                                 applyRecognizer, FluentText, the AsSpans
                                 extension (imports the core markup barrel,
                                 which brings the HTML parser)
  src/
    common/
      locale_tags.dart         — localeFromTag: BCP47-ish tag → Locale
    controller/
      locale_controller.dart   — FluentLocaleController: init() discovers
                                 locales async, then all-sync; setLocale /
                                 useDeviceLocale (WidgetsBindingObserver) /
                                 reload; the persistence seam
                                 (initialLocale + onLocaleChanged)
    delegate/
      chain_builder.dart       — the ONE place a Locale becomes a loaded
                                 FluentBundleChain (both delegates build
                                 through it); the empty-fallback assert
      delegate.dart            — FluentLocalizationsDelegate
      localization.dart        — FluentLocalization + context.fluent
      typed_delegate.dart      — TypedFluentDelegate<T>: the fluent_gen
                                 bridge, no fluent_gen import
    loader/
      asset_loader.dart        — AssetFluentLoader: AssetManifest-discovered
                                 locales; {tag}.ftl + {tag}/*.ftl layouts
      composite_loader.dart    — CompositeFluentLoader: app + package FTL
      resource_loader.dart     — the loader interface (+ evict seam)
    markup/
      fluent_text.dart         — FluentText widget + the AsSpans extension
      inline_span_converter.dart — fluentSpansToInline + applyRecognizer
    reload/
      hot_reload.dart          — FluentHotReload: reassemble → evict + reload
test/                          — mirrors lib/src file-for-file
  _support/fakes.dart          — FakeFluentLoader + the standard fixture
example/
  lib/main.dart                — the showcase app: every surface, one file
  assets/i18n/{en,de,de-CH}.ftl — complete base / partial / one-line locales
  test/journeys/               — the showcase driven end to end (host VM)
Makefile                       — the gate: `make check` = analyze + floor +
                                 widget suite + example journeys
docs/                          — this trio
```

## 2. The data flow

```
FluentResourceLoader          which locales exist; FTL per locale
        │
FluentLocaleController        init() → availableLocales; the active
        │                     chain (negotiateLocaleChain from the
        │                     core); generation counter
        │
FluentLocalizationsDelegate   Flutter calls load(locale) →
  / TypedFluentDelegate<T>    chain_builder negotiates + loads one
        │                     FluentBundle per rung → FluentBundleChain
        │
FluentLocalization / T        what the tree reads via Localizations.of
        │
context.fluent / FluentText   formatMessage / span rendering
```

Locale switches flow the OTHER way: `controller.setLocale` →
`notifyListeners` → the app's `ListenableBuilder` rebuilds
`MaterialApp` with the new `locale` and fresh delegate instances →
Flutter's own machinery re-runs `load`. `shouldReload` compares
controller generations so an unchanged rebuild costs nothing and
`reload()` (hot reload / manual) forces a re-load.

## 3. The contracts that hold everything up

- **Loaders return empty for an unknown tag, never throw** — composite
  loaders and chain building rely on it.
- **The delegate serves ANY locale** (`isSupported` is always true):
  negotiation ends at the fallback, so there is no unservable locale.
- **The fallback bundle must have sources** — an empty one means every
  message can miss all the way through; the chain builder asserts loud
  in debug (release renders ids).
- **One rebuild mechanism**: `context.fluent` is sugar over
  `Localizations.of`, never a second InheritedWidget.
- **The main barrel never imports `package:html`** — everything
  markup-shaped lives behind `package:fluent_flutter/markup.dart`.
- **Recognizers go on leaf text spans** (`applyRecognizer`) — Flutter
  only fires a recognizer on the span owning the text.
- **The controller's init resolution does not fire `onLocaleChanged`**
  — a persistence callback must not re-save the locale it just fed in.

## 4. What lives elsewhere

| Concern | Home |
|---|---|
| FluentBundle, FluentBundleChain, negotiateLocaleChain | fluent_bundle |
| CLDR rendering | fluent_icu / fluent_intl (pass a `backend:` to the delegates) |
| Typed accessors + AppLocale enum codegen | fluent_gen (bridged by `TypedFluentDelegate`) |
| The FluentSpan tree + HTML5 markup parsing | fluent_bundle's markup barrel |

## 5. The one-line summary

> **Loader → controller → delegate → chain → context. Locales are
> discovered, negotiated through the core's one ladder, loaded as a
> FluentBundleChain, and served through Flutter's own Localizations
> machinery. Markup is a separate barrel; recognizers go on leaves;
> hot reload is an evict plus a generation bump.**
