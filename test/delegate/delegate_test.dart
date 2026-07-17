import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluent_flutter/fluent_flutter.dart';

import '../_support/fakes.dart';

/// The smallest tree that runs real delegate loads: a [Localizations]
/// widget (what WidgetsApp builds internally) over a probe that reads
/// [FluentLocalization] via the context extension.
Widget host({
  required FluentLocaleController controller,
  required Locale locale,
  required void Function(BuildContext context) probe,
}) => Localizations(
  locale: locale,
  delegates: [
    FluentLocalizationsDelegate(controller),
    DefaultWidgetsLocalizations.delegate,
  ],
  child: Builder(
    builder: (context) {
      probe(context);
      return const SizedBox.shrink();
    },
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<FluentLocaleController> controller() => FluentLocaleController.init(
    loader: standardLoader(),
    fallbackLocale: 'en',
    initialLocale: 'en',
  );

  testWidgets('serves FluentLocalization through Localizations.of', (
    tester,
  ) async {
    final c = await controller();
    late FluentLocalization loc;
    await tester.pumpWidget(
      host(
        controller: c,
        locale: const Locale('en'),
        probe: (context) => loc = context.fluent,
      ),
    );
    await tester.pumpAndSettle();

    expect(loc.formatMessage('greet'), 'Hello!');
    expect(loc.locale, const Locale('en'));
    expect(loc.localeChain, ['en']);
    c.dispose();
  });

  testWidgets('the loaded chain falls back per message', (tester) async {
    final c = await controller();
    late FluentLocalization loc;
    await tester.pumpWidget(
      host(
        controller: c,
        locale: const Locale('de', 'CH'),
        probe: (context) => loc = context.fluent,
      ),
    );
    await tester.pumpAndSettle();

    expect(loc.localeChain, ['de-CH', 'de', 'en']);
    expect(loc.formatMessage('greet'), 'Grüezi!');
    expect(loc.formatMessage('bye'), 'Tschüss!');
    expect(loc.formatMessage('only-base'), 'base wins');

    final errors = <FluentError>[];
    expect(loc.formatMessage('ghost', errors: errors), 'ghost');
    expect(errors.single, isA<FluentReferenceError>());
    c.dispose();
  });

  testWidgets('a locale change loads a fresh localization', (tester) async {
    final c = await controller();
    late FluentLocalization loc;
    Widget at(Locale locale) => host(
      controller: c,
      locale: locale,
      probe: (context) => loc = context.fluent,
    );

    await tester.pumpWidget(at(const Locale('en')));
    await tester.pumpAndSettle();
    expect(loc.formatMessage('greet'), 'Hello!');

    await tester.pumpWidget(at(const Locale('de')));
    await tester.pumpAndSettle();
    expect(loc.formatMessage('greet'), 'Hallo!');
    c.dispose();
  });

  testWidgets('controller.reload() re-loads through a fresh delegate', (
    tester,
  ) async {
    final loader = standardLoader();
    final c = await FluentLocaleController.init(
      loader: loader,
      fallbackLocale: 'en',
      initialLocale: 'en',
    );
    late FluentLocalization loc;
    // The documented wiring: the app rebuilds on controller changes and
    // constructs a new delegate; shouldReload compares generations.
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: c,
        builder:
            (_, __) => host(
              controller: c,
              locale: const Locale('en'),
              probe: (context) => loc = context.fluent,
            ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loc.formatMessage('greet'), 'Hello!');

    loader.sources['en'] = ['greet = Hello, edited!'];
    c.reload();
    await tester.pumpAndSettle();
    expect(loc.formatMessage('greet'), 'Hello, edited!');
    expect(loader.evictCount, 1);
    c.dispose();
  });

  testWidgets('FluentLocalization.of asserts without a delegate', (
    tester,
  ) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          expect(() => FluentLocalization.of(context), throwsAssertionError);
          expect(FluentLocalization.maybeOf(context), isNull);
          return const SizedBox.shrink();
        },
      ),
    );
  });

  testWidgets('an empty fallback bundle asserts loud in debug', (tester) async {
    final c = await FluentLocaleController.init(
      loader: FakeFluentLoader({'de': []}),
      fallbackLocale: 'en',
      initialLocale: 'de',
    );
    final delegate = FluentLocalizationsDelegate(c);
    await expectLater(
      () => delegate.load(const Locale('de')),
      throwsAssertionError,
    );
    c.dispose();
  });
}
