/// Flutter integration for the fluent family.
///
/// Everything an app needs to serve Project Fluent messages through
/// Flutter's localization machinery:
///
///   * `AssetFluentLoader` — FTL from assets, locales discovered from
///     the AssetManifest.
///   * `FluentLocaleController` — the locale state + verbs
///     (`setLocale`, `useDeviceLocale`, `reload`).
///   * `FluentLocalizationsDelegate` — serves `FluentLocalization`
///     (`context.fluent.formatMessage(...)`) with bundle-chain locale
///     fallback.
///   * `TypedFluentDelegate` — the same, serving a fluent_gen-generated
///     accessor class.
///   * `FluentHotReload` — edit `.ftl`, press `r`, see new strings.
///
/// The whole `fluent_bundle` runtime is re-exported. Pass a `backend:`
/// from `package:fluent_intl` or `package:fluent_icu` to the delegates
/// for CLDR-aware formatting.
///
/// Inline markup rendered as spans (`FluentText`, `fluentSpansToInline`)
/// lives in `package:fluent_flutter/markup.dart` — a separate import so
/// apps without markup never carry the HTML parser.
library;

export 'package:fluent_bundle/fluent_bundle.dart';

export 'src/common/locale_tags.dart';
export 'src/controller/locale_controller.dart';
export 'src/delegate/delegate.dart';
export 'src/delegate/localization.dart';
export 'src/delegate/typed_delegate.dart';
export 'src/loader/asset_loader.dart';
export 'src/loader/composite_loader.dart';
export 'src/loader/resource_loader.dart';
export 'src/reload/hot_reload.dart';
