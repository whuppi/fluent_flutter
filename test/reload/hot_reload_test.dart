import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluent_flutter/fluent_flutter.dart';

import '../_support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reassemble evicts the loader and re-loads new strings', (
    tester,
  ) async {
    final loader = standardLoader();
    final controller = await FluentLocaleController.init(
      loader: loader,
      fallbackLocale: 'en',
      initialLocale: 'en',
    );
    addTearDown(controller.dispose);

    late FluentLocalization loc;
    await tester.pumpWidget(
      FluentHotReload(
        controller: controller,
        child: ListenableBuilder(
          listenable: controller,
          builder:
              (_, __) => Localizations(
                locale: const Locale('en'),
                delegates: [
                  FluentLocalizationsDelegate(controller),
                  DefaultWidgetsLocalizations.delegate,
                ],
                child: Builder(
                  builder: (context) {
                    loc = context.fluent;
                    return const SizedBox.shrink();
                  },
                ),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loc.formatMessage('greet'), 'Hello!');

    // The dev edits en.ftl and presses `r` — flutter re-syncs the
    // asset; the hook must evict + re-load.
    loader.sources['en'] = ['greet = Hello, reloaded!'];
    // reassembleApplication awaits a frame the test binding only
    // produces on pump — drive both together or the await deadlocks.
    final reassembled = tester.binding.reassembleApplication();
    await tester.pump();
    await reassembled;
    await tester.pumpAndSettle();

    expect(loader.evictCount, 1);
    expect(loc.formatMessage('greet'), 'Hello, reloaded!');
  });

  testWidgets('is a pass-through wrapper', (tester) async {
    final controller = await FluentLocaleController.init(
      loader: standardLoader(),
      fallbackLocale: 'en',
      initialLocale: 'en',
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      FluentHotReload(
        controller: controller,
        child: const Text('child', textDirection: TextDirection.ltr),
      ),
    );
    expect(find.text('child'), findsOneWidget);
  });
}
