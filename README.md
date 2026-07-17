<!--
  Banner stays <picture> for GitHub's dark/light. pub.dev strips <picture>
  when sanitizing the README, so the publish step flattens it to the inner
  <img> via the release tool's --stamp-readme (the repo copy is untouched).
  Drop both once pub.dev renders <picture>. Tracking:
  dart-lang/pub-dev#5923, dart-lang/pub-dev#6363, google/dart-neats#383.
-->
<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)"  srcset="assets/banner_dark-web-min.webp">
    <source media="(prefers-color-scheme: light)" srcset="assets/banner_light-web-min.webp">
    <img alt="fluent_flutter — Project Fluent, wired into Flutter"
         src="assets/banner_light-web-min.webp" width="100%">
  </picture>
</p>

<p align="center">
  <a href="https://pub.dev/packages/fluent_flutter"><img src="https://img.shields.io/pub/v/fluent_flutter.svg" alt="pub package"></a>
  <a href="https://pub.dev/packages/fluent_flutter/score"><img src="https://img.shields.io/pub/likes/fluent_flutter" alt="likes"></a>
  <a href="https://pub.dev/packages/fluent_flutter/score"><img src="https://img.shields.io/pub/points/fluent_flutter" alt="pub points"></a>
  <a href="https://github.com/whuppi/fluent_flutter"><img src="https://img.shields.io/github/stars/whuppi/fluent_bundle?style=flat&logo=github" alt="GitHub stars"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license: MIT"></a>
</p>

[`fluent_bundle`](https://pub.dev/packages/fluent_bundle), wired into Flutter the way Flutter expects: FTL files load from assets and are discovered automatically, a controller owns the locale lifecycle (device-following or user-picked, switchable live), a `LocalizationsDelegate` plugs into `MaterialApp` like any other, `context.fluent` reads messages anywhere in the tree, translator-authored markup renders as styled + tappable `InlineSpan`s, and editing an `.ftl` file shows up on hot reload.

Every piece is a seam you can replace — bring your own loader, your own backend, your own generated accessor class — and every piece works without the others.

> **This is the front door for Flutter apps.** Building pure Dart — a CLI, a server? [`fluent_bundle`](https://pub.dev/packages/fluent_bundle) alone is the runtime; everything here is Flutter wiring on top of it.

> **Status:** 0.x. The API can change between minor versions until `1.0.0` — pre-1.0, the minor is the breaking axis, so pin `^0.N.0` and read the changelog on minor bumps.

> like it? a [⭐ star](https://github.com/whuppi/fluent_flutter) or [👍 like](https://pub.dev/packages/fluent_flutter) is the entire marketing budget. [Bugs & features →](https://github.com/whuppi/fluent_flutter/issues)

---

<details>
<summary><b>👀 Peek inside</b></summary>

- [Install](#install)
- [Quick start](#quick-start)
- [The controller](#the-controller)
- [Usage](#usage)
  - [Loaders](#loaders)
  - [Reading messages](#reading-messages)
  - [Markup — styled and tappable text](#markup--styled-and-tappable-text)
  - [Typed access with fluent_gen](#typed-access-with-fluent_gen)
  - [Hot reload](#hot-reload)
- [Error handling](#error-handling)
- [Platform support](#platform-support)
- [Not in the box](#not-in-the-box)
- [Docs](#docs)
- [License](#license)

</details>

---

## Install

```yaml
dependencies:
  fluent_flutter:
  fluent_intl:        # or fluent_icu — the formatting backend (see below)

flutter:
  assets:
    - assets/i18n/
```

Put one `.ftl` per locale in the asset folder — `assets/i18n/en.ftl`, `assets/i18n/de.ftl` — and that's the whole setup. (Multi-file locales work too: `assets/i18n/de/*.ftl`.)

The backend choice — [`fluent_intl`](https://pub.dev/packages/fluent_intl) (zero-setup, pure Dart) vs [`fluent_icu`](https://pub.dev/packages/fluent_icu) (full ECMA-402, every locale) — is [the core's decision table](https://pub.dev/packages/fluent_bundle#the-backend-seam); this package works identically with either.

---

## Quick start

Boot the controller, hand the delegate to `MaterialApp`, read messages off the context — the whole wiring:

```dart
import 'package:fluent_flutter/fluent_flutter.dart';
import 'package:fluent_intl/fluent_intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Discovers the .ftl assets, resolves the device locale against them,
  // loads the fallback chain. One await, at startup.
  final controller = await FluentLocaleController.init(
    loader: AssetFluentLoader(),
    fallbackLocale: 'en',
  );

  runApp(MyApp(controller));
}

class MyApp extends StatelessWidget {
  const MyApp(this.controller, {super.key});
  final FluentLocaleController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => MaterialApp(
      locale: controller.flutterLocale,
      supportedLocales: controller.supportedLocales,
      localizationsDelegates: [
        FluentLocalizationsDelegate(controller, backend: IntlBackend()),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: const HomePage(),
    ),
  );
}
```

```dart
// Anywhere below MaterialApp:
Text(context.fluent.formatMessage('greet', args: {'name': 'Aria'}))
```

That's the shape of the whole package: the controller owns *which* locale, the delegate owns *building the localization for it*, and `context.fluent` is how widgets read it.

---

## The controller

`FluentLocaleController` is a `ChangeNotifier` holding one piece of state: the resolved locale chain. Everything else follows from it.

```dart
controller.currentLocale;             // 'de-CH' — the resolved head
controller.localeChain;               // ['de-CH', 'de', 'en'] — what actually loaded
controller.availableLocales;          // every tag the loader discovered
controller.followingDeviceLocale;     // true until the user picks one

await controller.setLocale('de');     // user picked — rebuilds the app in de
await controller.useDeviceLocale();   // back to following the OS setting
```

Two behaviors worth knowing, both visible in the [example app](example/):

- **Device-following is live.** While no explicit locale is set, an OS-level language change re-resolves and rebuilds the app — the controller watches `didChangeLocales`, you write nothing.
- **Resolution is a chain, not a pick.** `de-CH` requested loads `de-CH` → `de` → `en` as a [`FluentBundleChain`](https://pub.dev/packages/fluent_bundle#locale-negotiation-and-bundle-chains): a message missing from Swiss German falls back to German, then English, each formatting in its own locale's context.

---

## Usage

### Loaders

`FluentResourceLoader` is the seam between "the controller wants locale `de`" and "here are FTL sources." Three implementations ship:

```dart
// The one most apps use — discovers .ftl files from the asset bundle:
AssetFluentLoader()                                  // assets/i18n/ by default
AssetFluentLoader(basePath: 'assets/translations')   // or wherever yours live

// Compose sources — merged per locale, earlier loaders winning
// duplicate message ids:
CompositeFluentLoader([downloadedLoader, AssetFluentLoader()])
```

`AssetFluentLoader` reads the `AssetManifest`, so discovery is free: every `{tag}.ftl` file and `{tag}/*.ftl` folder under the base path becomes an available locale, no registry to maintain. Adding Portuguese to your app is `git add assets/i18n/pt.ftl`.

<details>
<summary><b>🧩 writing your own loader (server-delivered translations)</b></summary>

<br>

The interface is two methods — return FTL sources for a tag (empty list for an unknown one, never a throw), and evict any cache when asked:

```dart
class ServerFluentLoader extends FluentResourceLoader {
  @override
  Future<List<String>> load(String localeTag) async {
    final res = await http.get(Uri.parse('$cdn/$localeTag.ftl'));
    return res.statusCode == 200 ? [res.body] : const [];
  }

  @override
  Future<List<String>> availableLocales() async => fetchManifest();
}
```

Compose it in front of the asset loader and you have over-the-air translation updates over a bundled baseline: `CompositeFluentLoader([ServerFluentLoader(), AssetFluentLoader()])` — the server's message ids win, everything it doesn't override still comes from the assets.

</details>

### Reading messages

`context.fluent` (or `FluentLocalization.of(context)`) is the per-locale surface — the delegate rebuilds it on every locale change, so widgets that read it re-render with the right strings automatically:

```dart
final fluent = context.fluent;

fluent.formatMessage('greet', args: {'name': 'Aria'});      // "Hallo, Aria!"
fluent.formatMessage('login', attribute: 'title');          // attributes too
fluent.formatMessageAsSpans('banner');                      // the markup tree
fluent.localeChain;                                         // ['de', 'en']
```

It's the full `fluent_bundle` formatting surface — selectors, plurals, NUMBER / DATETIME through your chosen backend — scoped to the active chain.

### Markup — styled and tappable text

Translators author inline structure in the FTL; `package:fluent_flutter/markup.dart` renders it. `FluentText` is the one-widget path:

```ftl
banner = Read <bold>the guide</bold> — then <a>tap here</a>!
```

```dart
FluentText(
  'banner',
  styles: const {'bold': TextStyle(fontWeight: FontWeight.bold)},
  tags: {
    'a': (node, children) => TextSpan(
      style: const TextStyle(decoration: TextDecoration.underline),
      // The recognizer goes on the LEAF text spans — Flutter only fires
      // a recognizer on the span that owns text, so one on the wrapper
      // would never fire. applyRecognizer handles that for you:
      children: applyRecognizer(_linkTap, children),
    ),
  },
)
```

`styles` covers the common case (a tag is just a `TextStyle`); `tags` builders get the node (attributes included — `<a href="...">` arrives parsed) and the already-built children, and return any `InlineSpan` — links, `WidgetSpan` icons, whatever the design needs. Under the widget sits `fluentSpansToInline(...)`, the same conversion as a plain function for when you're composing `Text.rich` yourself.

A tag with no style and no builder is a translator/developer mismatch — debug builds assert on it (loudly, with the tag and message id), release builds render the children unstyled. Pass `onUnknownTag` to handle it yourself instead.

### Typed access with fluent_gen

Using [`fluent_gen`](https://pub.dev/packages/fluent_gen)'s generated accessor class? `TypedFluentDelegate` bridges it — same controller, same lifecycle, typed reads:

```dart
localizationsDelegates: [
  TypedFluentDelegate<AppMessages>(
    controller,
    backend: IntlBackend(),
    // The loaded chain IS a FluentBundle — the generated constructor
    // takes it unchanged, and every typed accessor gains fallback:
    create: (bundle, tag) => AppMessages(bundle),
  ),
  ...GlobalMaterialLocalizations.delegates,
],

// then, in widgets:
Localizations.of<AppMessages>(context, AppMessages)!.welcome(name: 'Aria');
```

This package has no dependency on `fluent_gen` — the bridge is a `create` callback, so the generated class stays a `dev_dependency` product and the seam stays open for hand-written wrappers too.

### Hot reload

Wrap your app once and edited `.ftl` assets show up on hot reload — evicted, re-discovered, re-resolved, rebuilt:

```dart
runApp(FluentHotReload(controller: controller, child: MyApp(controller)));
```

Debug-only by construction (`kDebugMode` gates it); in release builds it's an inert pass-through. Translation iteration becomes: edit the FTL, press `r`, read the screen.

---

## Error handling

The package inherits [`fluent_bundle`'s contract](https://pub.dev/packages/fluent_bundle#error-handling) — formatting never throws, failures are inert values — and adds the same temperament at its own seams:

- **A locale the loader doesn't have** never crashes resolution — the negotiation chain just lands on the fallback. `fallbackLocale` must exist in the loader, and that *is* asserted in debug builds, because an app whose fallback can't load has no floor to stand on.
- **A message missing from the head locale** falls down the chain silently (that's the chain's job); a message missing from *every* locale renders the id and records the miss into an `errors:` list you pass to `formatMessage`.
- **An unknown markup tag** asserts in debug, renders children unstyled in release, and is yours via `onUnknownTag` (see [Markup](#markup--styled-and-tappable-text)).

---

## Platform support

Everything here is widgets, assets, and pure Dart — no platform code of its own:

| Android | iOS | macOS | Windows | Linux | Web |
|:---:|:---:|:---:|:---:|:---:|:---:|
| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Backend engines have their own platform stories — pure Dart everywhere for `fluent_intl`; see [icu_kit's platform table](https://pub.dev/packages/icu_kit#platform-support) for `fluent_icu`.

---

## Not in the box

- **Message formatting itself.** That's [`fluent_bundle`](https://pub.dev/packages/fluent_bundle) (re-exported here, so one import covers both) plus your chosen backend. This package decides *when* and *from where* bundles load — never *how* values format.
- **Code generation.** Typed accessors come from [`fluent_gen`](https://pub.dev/packages/fluent_gen); `TypedFluentDelegate` is the bridge, not the generator.
- **Locale persistence.** `setLocale` doesn't write to disk — where the user's choice lives (shared_preferences, your settings store) is app policy. Restore it at startup: `controller.setLocale(saved)`.
- **Material / Cupertino widget translations.** Flutter's own `GlobalMaterialLocalizations.delegates` handle the framework's built-in strings — run them alongside, exactly as the Quick start shows.

---

## Docs

The README covers the everyday stuff. wanna go deeper?

| Doc | What's inside |
|---|---|
| [Architecture](docs/ARCHITECTURE.md) | How it's built: the loader seam, the controller lifecycle, the delegate contract |
| [Capabilities](docs/CAPABILITY_ROADMAP.md) | What's shipped, what's planned, what won't happen |
| [Updating](docs/UPDATING.md) | Maintenance recipes and the pinned Flutter-behavior watchlist |
| [Example](example/) | Every surface in one app: locale strip, markup, fallback, hot reload — journey-tested |

---

## License

MIT. See [LICENSE](LICENSE).
