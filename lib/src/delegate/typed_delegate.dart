import 'package:flutter/widgets.dart';

import 'package:fluent_bundle/fluent_bundle.dart';
import 'package:fluent_flutter/src/controller/locale_controller.dart';
import 'package:fluent_flutter/src/delegate/chain_builder.dart';

/// The fluent_gen bridge: serves a GENERATED accessor class through the
/// localization machinery, without this package knowing fluent_gen.
///
/// [create] receives the loaded fallback chain — a `FluentBundleChain`
/// IS a `FluentBundle`, so the generated constructor takes it
/// unchanged and every typed accessor gains locale fallback:
///
/// ```dart
/// TypedFluentDelegate<AppMessages>(
///   controller,
///   create: (bundle, tag) => AppMessages(bundle),
///   backend: IntlBackend(),
/// )
/// // then anywhere below the app:
/// final t = Localizations.of<AppMessages>(context, AppMessages)!;
/// Text(t.welcome(name: 'Aria'))
/// ```
///
/// Apps that embed FTL via the generator's `bundle_ftl` option and
/// don't need asset loading can skip this delegate entirely and build
/// from `AppLocale.load()` — this bridge is for asset-shaped FTL and
/// for chain fallback.
class TypedFluentDelegate<T extends Object> extends LocalizationsDelegate<T> {
  /// Serves [create]'s result for chains negotiated + loaded through
  /// [controller], formatting with [backend].
  TypedFluentDelegate(
    this.controller, {
    required this.create,
    this.backend = const FluentBackend(),
  }) : _generation = controller.generation;

  /// The locale state this delegate loads for.
  final FluentLocaleController controller;

  /// Builds the generated class from the loaded chain. [FluentBundle]
  /// here is always a `FluentBundleChain`; the second argument is the
  /// chain's primary tag.
  final T Function(FluentBundle bundle, String primaryTag) create;

  /// Formats numbers, dates, and plurals in every loaded bundle.
  final FluentBackend backend;

  final int _generation;

  /// Always true — the chain negotiates any locale down to the fallback.
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) async {
    final chain = await buildChainFor(locale, controller, backend: backend);
    return create(chain, chain.locales.first);
  }

  /// Reload when the controller moved on since [old] was built.
  @override
  bool shouldReload(covariant TypedFluentDelegate<T> old) =>
      _generation != old._generation;
}
