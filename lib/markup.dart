/// Inline markup rendered as Flutter spans.
///
/// Translators write HTML5-shaped tags inside messages
/// (`banner = Try <bold>{ $plan }</bold>!`); this barrel maps the
/// resolved span tree to `InlineSpan`s — `FluentText` for the widget
/// form, `fluentSpansToInline` for manual `Text.rich` composition.
/// A separate import because it carries `package:html` (through the
/// core's markup barrel); apps without inline markup pay nothing.
library;

export 'package:fluent_bundle/markup.dart';

export 'src/markup/fluent_text.dart';
export 'src/markup/inline_span_converter.dart';
