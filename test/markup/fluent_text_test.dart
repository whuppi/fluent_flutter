import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluent_flutter/fluent_flutter.dart';
import 'package:fluent_flutter/markup.dart';

import '../_support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const bold = TextStyle(fontWeight: FontWeight.bold);

  Future<Widget> app(Widget child) async {
    final controller = await FluentLocaleController.init(
      loader: standardLoader(),
      fallbackLocale: 'en',
      initialLocale: 'en',
    );
    addTearDown(controller.dispose);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Localizations(
        locale: const Locale('en'),
        delegates: [
          FluentLocalizationsDelegate(controller),
          DefaultWidgetsLocalizations.delegate,
        ],
        child: child,
      ),
    );
  }

  testWidgets('renders the formatted message with tag styles', (tester) async {
    await tester.pumpWidget(
      await app(
        const FluentText(
          'tagged',
          args: {'thing': 'FTL'},
          styles: {'bold': bold},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rich = tester.widget<Text>(find.byType(Text));
    final root = rich.textSpan! as TextSpan;
    // read <bold>{ $thing }</bold> now → text, styled tag, text.
    expect(root.toPlainText(), 'read \u2068FTL\u2069 now');
    final tag = root.children![1] as TextSpan;
    expect(tag.style, bold);
    expect(find.byType(RichText), findsOneWidget);
  });

  testWidgets('formatMessageAsSpans extension resolves through the chain', (
    tester,
  ) async {
    late List<FluentSpan> spans;
    await tester.pumpWidget(
      await app(
        Builder(
          builder: (context) {
            spans = context.fluent.formatMessageAsSpans(
              'tagged',
              args: {'thing': 'x'},
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(spans.whereType<FluentMarkupSpan>().single.tag, 'bold');
  });

  testWidgets('renders an attribute when asked', (tester) async {
    final controller = await FluentLocaleController.init(
      loader: FakeFluentLoader({
        'en': ['login = Sign in\n    .title = Welcome back'],
      }),
      fallbackLocale: 'en',
      initialLocale: 'en',
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Localizations(
          locale: const Locale('en'),
          delegates: [
            FluentLocalizationsDelegate(controller),
            DefaultWidgetsLocalizations.delegate,
          ],
          child: const FluentText('login', attribute: 'title'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome back', findRichText: true), findsOneWidget);
  });
}
