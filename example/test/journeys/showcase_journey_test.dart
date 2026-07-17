// Drives the exact UI a user sees — real asset loader, real bundled
// FTL, real delegates, real IntlBackend — through the demo's whole
// story: locale switching, CLDR plurals, markup taps, and the
// fallback chain.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluent_flutter/fluent_flutter.dart';
import 'package:fluent_flutter_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The REAL bundled FTL, read once through the real AssetFluentLoader
  // in setUpAll's plain zone — per-test fake-async zones can't drive
  // fresh asset-channel loads after the first test, so each test runs
  // on this snapshot instead.
  late Map<String, List<String>> ftl;
  setUpAll(() async {
    final loader = AssetFluentLoader();
    ftl = {
      for (final tag in await loader.availableLocales())
        tag: await loader.load(tag),
    };
  });

  Future<void> launch(WidgetTester tester) async {
    final controller = await createController(loader: _SnapshotLoader(ftl));
    addTearDown(controller.dispose);
    controller.setLocale('en');
    await tester.pumpWidget(ExampleApp(controller));
    await tester.pumpAndSettle();
  }

  testWidgets('boots in English with every card rendered', (tester) async {
    await launch(tester);
    expect(find.text('fluent_flutter demo'), findsOneWidget);
    expect(find.text('Hello, \u2068Aria\u2069!'), findsOneWidget);
    expect(find.text('one item'), findsOneWidget);
    expect(find.text('Total: \u2068\$1,234.50\u2069'), findsOneWidget);
    expect(find.text('Today is \u2068Jan 15, 2026\u2069'), findsOneWidget);
  });

  testWidgets('the plural stepper drives real CLDR categories', (tester) async {
    await launch(tester);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('\u20682\u2069 items'), findsOneWidget);
  });

  testWidgets('switching to German re-renders every surface', (tester) async {
    await launch(tester);
    await tester.tap(find.text('de'));
    await tester.pumpAndSettle();

    expect(find.text('Hallo, \u2068Aria\u2069!'), findsOneWidget);
    expect(find.text('ein Element'), findsOneWidget);
    // EUR through the German locale — grouping and symbol placement
    // from CLDR via IntlBackend.
    expect(find.text('Summe: \u20681.234,50 €\u2069'), findsOneWidget);
    expect(find.text('Willkommen zurück', findRichText: true), findsOneWidget);
  });

  testWidgets('the tiny de-CH locale exercises the three-rung chain', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.text('de-CH'));
    await tester.pumpAndSettle();

    // greet from de-CH, plural from de, only-english from en — one
    // screen, three rungs.
    expect(find.text('Grüezi, \u2068Aria\u2069!'), findsOneWidget);
    expect(find.text('ein Element'), findsOneWidget);
    expect(find.textContaining('only in English'), findsOneWidget);
    expect(find.textContaining('de-CH → de → en'), findsOneWidget);
  });

  testWidgets('markup renders bold + a link that really taps', (tester) async {
    await launch(tester);
    expect(
      find.textContaining('the guide', findRichText: true),
      findsOneWidget,
    );

    // Fire the link's recognizer through the span tree — proves the
    // tag builder wired a live TapGestureRecognizer.
    final widget = tester.widget(
      find.textContaining('tap here', findRichText: true),
    );
    final root = widget is Text ? widget.textSpan! : (widget as RichText).text;
    var tapped = false;
    root.visitChildren((span) {
      final recognizer = (span is TextSpan) ? span.recognizer : null;
      if (recognizer is TapGestureRecognizer) {
        recognizer.onTap!();
        tapped = true;
        return false;
      }
      return true;
    });
    expect(tapped, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('link tapped'), findsOneWidget);
  });

  testWidgets('the device chip resumes following the platform locale', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = [const Locale('de')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await launch(tester);
    expect(find.text('Hello, \u2068Aria\u2069!'), findsOneWidget);

    await tester.tap(find.text('device'));
    await tester.pumpAndSettle();
    expect(find.text('Hallo, \u2068Aria\u2069!'), findsOneWidget);
  });
}

/// The setUpAll snapshot behind the loader interface.
class _SnapshotLoader extends FluentResourceLoader {
  _SnapshotLoader(this.sources);

  final Map<String, List<String>> sources;

  @override
  Future<List<String>> availableLocales() async =>
      List.unmodifiable(sources.keys);

  @override
  Future<List<String>> load(String languageTag) async =>
      List.unmodifiable(sources[languageTag] ?? const <String>[]);
}
