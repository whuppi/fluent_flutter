import 'package:flutter/widgets.dart';

import 'package:fluent_bundle/fluent_bundle.dart';

/// What the widget tree reads: the loaded bundle chain for the active
/// locale, behind `Localizations.of`. Immutable — a locale change makes
/// the delegate load a fresh one.
///
/// ```dart
/// Text(FluentLocalization.of(context).formatMessage('greet'))
/// // or, with the extension:
/// Text(context.fluent.formatMessage('greet'))
/// ```
///
/// For inline markup rendered as spans, import
/// `package:fluent_flutter/markup.dart` (the `formatMessageAsSpans`
/// extension and the `FluentText` widget live there so apps without
/// markup never carry the HTML parser).
class FluentLocalization {
  /// Wraps the loaded [bundle] for [locale].
  const FluentLocalization({required this.bundle, required this.locale});

  /// The locale this instance was loaded for.
  final Locale locale;

  /// The loaded fallback chain. Exposed for everything the bundle
  /// surface offers beyond [formatMessage] — `hasMessage`, pattern
  /// caching, the markup extension.
  final FluentBundleChain bundle;

  /// The chain's locale tags, most specific first.
  List<String> get localeChain => bundle.locales;

  /// Format the message identified by [id] through the fallback chain.
  /// Never throws; a miss returns the literal id and records a
  /// [FluentReferenceError] on [errors].
  String formatMessage(
    String id, {
    String? attribute,
    Map<String, Object?> args = const {},
    List<FluentError>? errors,
  }) => bundle.formatMessage(
    id,
    attribute: attribute,
    args: args,
    errors: errors,
  );

  /// The nearest [FluentLocalization], or null when the delegate is not
  /// installed above [context].
  static FluentLocalization? maybeOf(BuildContext context) =>
      Localizations.of<FluentLocalization>(context, FluentLocalization);

  /// The nearest [FluentLocalization].
  ///
  /// Requires a `FluentLocalizationsDelegate` in the enclosing app's
  /// `localizationsDelegates` — asserts with instructions otherwise.
  static FluentLocalization of(BuildContext context) {
    final localization = maybeOf(context);
    assert(
      localization != null,
      'FluentLocalization.of() called without a FluentLocalizationsDelegate '
      'above this context. Add one to MaterialApp.localizationsDelegates '
      '(or WidgetsApp / CupertinoApp).',
    );
    return localization!;
  }
}

/// Sugar over [FluentLocalization.of].
extension FluentContext on BuildContext {
  /// The nearest [FluentLocalization].
  FluentLocalization get fluent => FluentLocalization.of(this);
}
