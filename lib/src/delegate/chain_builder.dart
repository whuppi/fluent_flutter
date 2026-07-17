// The one place a Flutter Locale becomes a loaded FluentBundleChain —
// both delegates (plain and typed) build through here so their
// semantics can't drift.

import 'dart:ui';

import 'package:fluent_bundle/fluent_bundle.dart';
import 'package:fluent_flutter/src/controller/locale_controller.dart';

/// Negotiate [locale] against the controller's available locales and
/// load one bundle per chain member through the controller's loader.
///
/// Negotiated fresh from the locale Flutter resolved (rather than
/// trusting the controller's current chain) so the delegate also works
/// when an app drives `MaterialApp.locale` itself.
Future<FluentBundleChain> buildChainFor(
  Locale locale,
  FluentLocaleController controller, {
  required FluentBackend backend,
}) async {
  final tags = negotiateLocaleChain(
    requested: [locale.toLanguageTag()],
    available: controller.availableLocales,
    fallback: controller.fallbackLocale,
  );
  final bundles = <FluentBundle>[];
  var fallbackHasSources = false;
  for (final tag in tags) {
    final sources = await controller.loader.load(tag);
    if (tag == controller.fallbackLocale && sources.isNotEmpty) {
      fallbackHasSources = true;
    }
    final bundle = FluentBundle(tag, backend: backend);
    for (final source in sources) {
      bundle.addResource(source);
    }
    bundles.add(bundle);
  }
  // The fallback ends every chain, so an empty fallback bundle means
  // EVERY message can miss all the way through — always a setup bug
  // (asset folder not declared in pubspec, or a fallback tag the
  // loader doesn't serve). Loud in dev, harmless in release (misses
  // still render their ids).
  assert(
    fallbackHasSources,
    'The fallback locale "${controller.fallbackLocale}" loaded zero FTL '
    'sources. Check that the assets are declared in pubspec.yaml and '
    'that the fallback tag matches a locale the loader serves '
    '(available: ${controller.availableLocales}).',
  );
  return FluentBundleChain(bundles);
}
