import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:fluent_bundle/markup.dart';

/// Builds the [InlineSpan] for one markup tag. [node] carries the tag
/// name and its attributes (`node.attrs['href']` for
/// `<a href="/help">`); [children] are the tag's contents, already
/// converted.
///
/// Builders own any `GestureRecognizer` they create — recognizers must
/// be disposed, so create them in a `State` and close over them here
/// rather than allocating inside the builder (the standard
/// [TextSpan.recognizer] lifecycle rule).
typedef FluentTagBuilder =
    InlineSpan Function(FluentMarkupSpan node, List<InlineSpan> children);

/// Convert a resolved fluent span tree to Flutter [InlineSpan]s —
/// Mozilla's overlay model meeting `Text.rich`.
///
/// Per markup tag, in precedence order:
///
/// 1. a [tags] builder — full power: `WidgetSpan`s, tap recognizers
///    from `node.attrs`, nested styling;
/// 2. a [styles] entry — the tag's children wrapped in a styled
///    [TextSpan], the 90% case;
/// 3. neither — the OVERLAY RULE: the tag's children render unstyled
///    (translator content is never dropped), and [onUnknownTag] fires.
///    Leaving [onUnknownTag] null asserts in debug builds so a
///    translator's typo'd tag is loud in dev and harmless in release;
///    pass a callback (even an empty one) to opt out.
List<InlineSpan> fluentSpansToInline(
  List<FluentSpan> spans, {
  Map<String, FluentTagBuilder> tags = const {},
  Map<String, TextStyle> styles = const {},
  void Function(FluentMarkupSpan node)? onUnknownTag,
}) => [
  for (final span in spans)
    switch (span) {
      FluentTextSpan(:final text) => TextSpan(text: text),
      FluentMarkupSpan() => _markup(span, tags, styles, onUnknownTag),
    },
];

InlineSpan _markup(
  FluentMarkupSpan node,
  Map<String, FluentTagBuilder> tags,
  Map<String, TextStyle> styles,
  void Function(FluentMarkupSpan node)? onUnknownTag,
) {
  final children = fluentSpansToInline(
    node.children,
    tags: tags,
    styles: styles,
    onUnknownTag: onUnknownTag,
  );
  final builder = tags[node.tag];
  if (builder != null) return builder(node, children);
  final style = styles[node.tag];
  if (style != null) return TextSpan(style: style, children: children);
  if (onUnknownTag != null) {
    onUnknownTag(node);
  } else {
    assert(
      false,
      'No builder or style for markup tag <${node.tag}>. Add it to '
      '`tags:` or `styles:`, or pass `onUnknownTag:` to accept unknown '
      'tags (their children render unstyled).',
    );
  }
  return TextSpan(children: children);
}

/// Re-attach [recognizer] to every text-bearing span in [children].
///
/// Flutter fires a [TextSpan.recognizer] only on the span that OWNS
/// the text under the pointer — a recognizer on a wrapper span whose
/// text lives in children never receives a tap. Tag builders therefore
/// can't just wrap: run the children through this and every leaf
/// becomes tappable.
///
/// ```dart
/// 'link': (node, children) => TextSpan(
///   style: underline,
///   children: applyRecognizer(_linkTap, children),
/// ),
/// ```
///
/// `WidgetSpan`s pass through untouched — their widgets own their own
/// gestures. The recognizer's lifecycle stays the caller's (create in
/// a `State`, dispose there).
List<InlineSpan> applyRecognizer(
  GestureRecognizer recognizer,
  List<InlineSpan> children,
) => [
  for (final child in children)
    switch (child) {
      TextSpan() => TextSpan(
        text: child.text,
        style: child.style,
        recognizer: child.recognizer ?? recognizer,
        children:
            child.children == null
                ? null
                : applyRecognizer(recognizer, child.children!),
      ),
      _ => child,
    },
];
