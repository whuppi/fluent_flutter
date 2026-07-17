import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluent_flutter/fluent_flutter.dart';

import '../_support/fakes.dart';

/// Stands in for a fluent_gen-generated accessor class — same shape:
/// wraps a [FluentBundle], one method per message.
class Messages {
  Messages(this.bundle, this.primaryTag);

  final FluentBundle bundle;
  final String primaryTag;

  String greet() => bundle.formatMessage('greet');
  String bye() => bundle.formatMessage('bye');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('serves the generated-shaped class with chain fallback', (
    tester,
  ) async {
    final c = await FluentLocaleController.init(
      loader: standardLoader(),
      fallbackLocale: 'en',
      initialLocale: 'de-CH',
    );
    late Messages t;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('de', 'CH'),
        delegates: [
          TypedFluentDelegate<Messages>(c, create: Messages.new),
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Builder(
          builder: (context) {
            t = Localizations.of<Messages>(context, Messages)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(t.primaryTag, 'de-CH');
    // greet from de-CH; bye falls through the chain to de.
    expect(t.greet(), 'Grüezi!');
    expect(t.bye(), 'Tschüss!');
    c.dispose();
  });
}
