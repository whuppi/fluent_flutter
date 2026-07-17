import 'package:flutter/widgets.dart';

import 'package:fluent_bundle/fluent_bundle.dart';
import 'package:fluent_flutter/src/controller/locale_controller.dart';
import 'package:fluent_flutter/src/delegate/chain_builder.dart';
import 'package:fluent_flutter/src/delegate/localization.dart';

/// Serves [FluentLocalization] through Flutter's own localization
/// machinery — composes with the Material / Cupertino delegates,
/// `Localizations.override`, and `localeResolutionCallback` for free.
///
/// ```dart
/// ListenableBuilder(
///   listenable: controller,
///   builder: (context, _) => MaterialApp(
///     locale: controller.flutterLocale,
///     supportedLocales: controller.supportedLocales,
///     localizationsDelegates: [
///       FluentLocalizationsDelegate(controller),
///       ...GlobalMaterialLocalizations.delegates,
///     ],
///     home: ...,
///   ),
/// )
/// ```
///
/// Rebuilding under a `ListenableBuilder` is what makes
/// [FluentLocaleController.setLocale] and
/// [FluentLocaleController.reload] take effect: the rebuild hands
/// Flutter a fresh delegate whose [shouldReload] compares controller
/// generations.
///
/// Pass a `backend:` from fluent_intl (`IntlBackend()`) or fluent_icu
/// (`IcuBackend()`, after its async init) for CLDR-aware formatting;
/// the default is the spec-fallback [FluentBackend].
class FluentLocalizationsDelegate
    extends LocalizationsDelegate<FluentLocalization> {
  /// Serves bundles negotiated + loaded through [controller],
  /// formatting with [backend].
  FluentLocalizationsDelegate(
    this.controller, {
    this.backend = const FluentBackend(),
  }) : _generation = controller.generation;

  /// The locale state this delegate loads for.
  final FluentLocaleController controller;

  /// Formats numbers, dates, and plurals in every loaded bundle.
  final FluentBackend backend;

  final int _generation;

  /// Always true: the chain negotiates ANY locale down to the fallback,
  /// so there is no locale this delegate refuses to serve.
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<FluentLocalization> load(Locale locale) async => FluentLocalization(
    locale: locale,
    bundle: await buildChainFor(locale, controller, backend: backend),
  );

  /// Reload when the controller moved on since [old] was built —
  /// a locale switch or an explicit [FluentLocaleController.reload].
  @override
  bool shouldReload(covariant FluentLocalizationsDelegate old) =>
      _generation != old._generation;
}
