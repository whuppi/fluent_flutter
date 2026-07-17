import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluent_flutter/markup.dart';

void main() {
  const bold = TextStyle(fontWeight: FontWeight.bold);

  test('text spans become plain TextSpans', () {
    final spans = fluentSpansToInline(const [FluentTextSpan('hello')]);
    expect(spans, hasLength(1));
    expect((spans.single as TextSpan).text, 'hello');
  });

  test('a styles entry wraps the tag children in a styled TextSpan', () {
    final spans = fluentSpansToInline(
      const [
        FluentTextSpan('a '),
        FluentMarkupSpan(tag: 'bold', children: [FluentTextSpan('b')]),
      ],
      styles: const {'bold': bold},
    );
    final tag = spans[1] as TextSpan;
    expect(tag.style, bold);
    expect((tag.children!.single as TextSpan).text, 'b');
  });

  test('a tags builder wins over a styles entry and sees the attrs', () {
    late FluentMarkupSpan seen;
    final spans = fluentSpansToInline(
      const [
        FluentMarkupSpan(
          tag: 'a',
          attrs: {'href': '/help'},
          children: [FluentTextSpan('help')],
        ),
      ],
      styles: const {'a': bold},
      tags: {
        'a': (node, children) {
          seen = node;
          return TextSpan(children: children);
        },
      },
    );
    expect(seen.attrs['href'], '/help');
    expect((spans.single as TextSpan).style, isNull);
  });

  test('applyRecognizer makes the LEAF text spans tappable', () {
    final recognizer = TapGestureRecognizer();
    addTearDown(recognizer.dispose);
    final spans = fluentSpansToInline(
      const [
        FluentMarkupSpan(tag: 'link', children: [FluentTextSpan('tap')]),
        FluentMarkupSpan(tag: 'icon', children: []),
      ],
      tags: {
        // Flutter fires recognizers only on the span owning the text —
        // the helper re-attaches to every leaf.
        'link':
            (node, children) =>
                TextSpan(children: applyRecognizer(recognizer, children)),
        'icon': (node, children) => const WidgetSpan(child: SizedBox(width: 4)),
      },
    );
    final leaf = (spans[0] as TextSpan).children!.single as TextSpan;
    expect(leaf.text, 'tap');
    expect(leaf.recognizer, same(recognizer));
    expect(spans[1], isA<WidgetSpan>());
  });

  test('nested tags convert recursively', () {
    final spans = fluentSpansToInline(
      const [
        FluentMarkupSpan(
          tag: 'outer',
          children: [
            FluentTextSpan('x '),
            FluentMarkupSpan(tag: 'inner', children: [FluentTextSpan('y')]),
          ],
        ),
      ],
      styles: const {'outer': bold, 'inner': TextStyle(inherit: true)},
    );
    final outer = spans.single as TextSpan;
    final inner = outer.children![1] as TextSpan;
    expect((inner.children!.single as TextSpan).text, 'y');
  });

  test('an unknown tag asserts in debug when no callback opts out', () {
    expect(
      () => fluentSpansToInline(const [
        FluentMarkupSpan(tag: 'typo', children: [FluentTextSpan('x')]),
      ]),
      throwsAssertionError,
    );
  });

  test('the overlay rule: unknown tag children render unstyled', () {
    final unknown = <FluentMarkupSpan>[];
    final spans = fluentSpansToInline(const [
      FluentMarkupSpan(tag: 'typo', children: [FluentTextSpan('kept')]),
    ], onUnknownTag: unknown.add);
    expect(unknown.single.tag, 'typo');
    final span = spans.single as TextSpan;
    expect(span.style, isNull);
    expect((span.children!.single as TextSpan).text, 'kept');
  });
}
