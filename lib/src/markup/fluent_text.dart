import 'package:flutter/widgets.dart';

import 'package:fluent_bundle/fluent_bundle.dart';
import 'package:fluent_bundle/markup.dart';
import 'package:fluent_flutter/src/delegate/localization.dart';
import 'package:fluent_flutter/src/markup/inline_span_converter.dart';

/// A localized [Text.rich] — the `Localized` component of
/// fluent-react, Flutter-shaped. Formats [id] through the nearest
/// [FluentLocalization] and renders inline markup via [tags] /
/// [styles].
///
/// ```dart
/// FluentText(
///   'banner',                     // banner = Try <bold>{ $plan }</bold>!
///   args: {'plan': 'Pro'},
///   styles: {'bold': TextStyle(fontWeight: FontWeight.bold)},
/// )
/// ```
///
/// Tap handling goes through a [tags] builder; the recognizer's
/// lifecycle is the caller's (create it in a `State`, dispose it
/// there — see [FluentTagBuilder]).
class FluentText extends StatelessWidget {
  /// Renders the message [id] (or its [attribute]).
  const FluentText(
    this.id, {
    super.key,
    this.attribute,
    this.args = const {},
    this.tags = const {},
    this.styles = const {},
    this.onUnknownTag,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
  });

  /// The message id to format.
  final String id;

  /// Format this attribute of [id] instead of its value.
  final String? attribute;

  /// The message's `$variable` arguments.
  final Map<String, Object?> args;

  /// Per-tag span builders — see [fluentSpansToInline].
  final Map<String, FluentTagBuilder> tags;

  /// Per-tag text styles — see [fluentSpansToInline].
  final Map<String, TextStyle> styles;

  /// Unknown-tag callback — see [fluentSpansToInline]. Null asserts in
  /// debug on a tag with no builder and no style.
  final void Function(FluentMarkupSpan node)? onUnknownTag;

  /// Base style for the whole message (markup styles merge over it).
  final TextStyle? style;

  /// Passed through to [Text.rich].
  final TextAlign? textAlign;

  /// Passed through to [Text.rich].
  final TextOverflow? overflow;

  /// Passed through to [Text.rich].
  final int? maxLines;

  /// Passed through to [Text.rich].
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final spans = FluentLocalization.of(
      context,
    ).bundle.formatMessageAsSpans(id, attribute: attribute, args: args);
    return Text.rich(
      TextSpan(
        style: style,
        children: fluentSpansToInline(
          spans,
          tags: tags,
          styles: styles,
          onUnknownTag: onUnknownTag,
        ),
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }
}

/// Span rendering on [FluentLocalization] — here (not on the class)
/// so the main entrypoint never carries the HTML parser.
extension FluentLocalizationMarkup on FluentLocalization {
  /// Format [id] and parse its inline markup into a span tree —
  /// [FluentBundle]'s `formatMessageAsSpans`, through the fallback
  /// chain.
  List<FluentSpan> formatMessageAsSpans(
    String id, {
    String? attribute,
    Map<String, Object?> args = const {},
    List<FluentError>? errors,
  }) => bundle.formatMessageAsSpans(
    id,
    attribute: attribute,
    args: args,
    errors: errors,
  );
}
