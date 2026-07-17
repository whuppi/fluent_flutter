// fluent_flutter example app — every surface in one file.
//
// A locale strip switches between English, German, and Swiss German
// (a deliberately tiny locale) live; every card below re-renders in
// the picked locale. The Fallback card shows the loaded chain and a
// message that only exists in English — the bundle-chain fallback,
// visible. The Markup card renders translator-authored inline tags as
// styled text and a tappable link. Editing any `.ftl` under
// `assets/i18n/` and pressing `r` updates the strings live
// (`FluentHotReload`).
//
// The whole app lives in this one file because pub.dev renders it on
// the package's Example tab — splitting it would hide everything else
// from that page. The journey tests drive this exact UI through the
// real delegates and the real assets (`test/journeys/`).

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:fluent_flutter/fluent_flutter.dart';
import 'package:fluent_flutter/markup.dart';
import 'package:fluent_intl/fluent_intl.dart';

/// One bootstrap for the app AND the journey suites. The app runs the
/// real asset loader; the journeys pass a snapshot [loader] read from
/// the same bundled FTL once (flutter_test serves fresh asset loads
/// reliably only outside per-test fake-async zones).
Future<FluentLocaleController> createController({
  FluentResourceLoader? loader,
}) => FluentLocaleController.init(
  loader: loader ?? AssetFluentLoader(),
  fallbackLocale: 'en',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await createController();
  runApp(
    FluentHotReload(controller: controller, child: ExampleApp(controller)),
  );
}

/// The app shell: rebuilds on controller changes, wires the fluent
/// delegate (backed by `IntlBackend` for CLDR-aware output) into
/// MaterialApp's own localization machinery.
class ExampleApp extends StatelessWidget {
  /// Runs the demo on [controller].
  const ExampleApp(this.controller, {super.key});

  /// The app's locale state.
  final FluentLocaleController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder:
        (context, _) => MaterialApp(
          locale: controller.flutterLocale,
          supportedLocales: controller.supportedLocales,
          localizationsDelegates: [
            FluentLocalizationsDelegate(controller, backend: IntlBackend()),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: HomePage(controller: controller),
        ),
  );
}

/// The showcase: locale strip + one card per surface.
class HomePage extends StatefulWidget {
  /// Drives the locale strip through [controller].
  const HomePage({required this.controller, super.key});

  /// The app's locale state.
  final FluentLocaleController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _count = 1;

  // Recognizers live in the State (not in build) so they can be
  // disposed — the standard TextSpan.recognizer lifecycle.
  late final TapGestureRecognizer _linkTap =
      TapGestureRecognizer()
        ..onTap =
            () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('link tapped')));

  @override
  void dispose() {
    _linkTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fluent = context.fluent;
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(title: Text(fluent.formatMessage('app-title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Locale strip — setLocale + useDeviceLocale live ────────
          Wrap(
            spacing: 8,
            children: [
              for (final tag in controller.availableLocales)
                ChoiceChip(
                  label: Text(tag),
                  selected:
                      !controller.followingDeviceLocale &&
                      controller.currentLocale == tag,
                  onSelected: (_) => controller.setLocale(tag),
                ),
              ChoiceChip(
                label: const Text('device'),
                selected: controller.followingDeviceLocale,
                onSelected: (_) => controller.useDeviceLocale(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Messages — args, CLDR plurals, currency, dates ─────────
          _DemoCard(
            title: 'Messages',
            children: [
              Text(fluent.formatMessage('greet', args: {'name': 'Aria'})),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fluent.formatMessage('items', args: {'count': _count}),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _count += 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              Text(fluent.formatMessage('price', args: {'amount': 1234.5})),
              Text(
                fluent.formatMessage(
                  'today',
                  args: {'date': DateTime(2026, 1, 15)},
                ),
              ),
            ],
          ),

          // ── Markup — translator-authored tags, styled + tappable ───
          _DemoCard(
            title: 'Markup',
            children: [
              FluentText(
                'banner',
                styles: const {'bold': TextStyle(fontWeight: FontWeight.bold)},
                tags: {
                  // applyRecognizer puts the tap on the LEAF text
                  // spans — a recognizer on the wrapper never fires.
                  'a':
                      (node, children) => TextSpan(
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        children: applyRecognizer(_linkTap, children),
                      ),
                },
              ),
              // Attributes render like any pattern — per-attribute.
              FluentText('login', attribute: 'title'),
            ],
          ),

          // ── Fallback — the loaded chain, visible ───────────────────
          _DemoCard(
            title: 'Fallback',
            children: [
              Text(
                '${fluent.formatMessage('chain-label')}: '
                '${fluent.localeChain.join(' → ')}',
              ),
              Text(fluent.formatMessage('only-english')),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final child in children)
            Padding(padding: const EdgeInsets.only(bottom: 4), child: child),
        ],
      ),
    ),
  );
}
