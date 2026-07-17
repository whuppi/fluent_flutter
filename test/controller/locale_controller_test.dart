import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:fluent_flutter/fluent_flutter.dart';

import '../_support/fakes.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  Future<FluentLocaleController> controller({
    String? initialLocale,
    ValueChanged<String>? onLocaleChanged,
  }) => FluentLocaleController.init(
    loader: standardLoader(),
    fallbackLocale: 'en',
    initialLocale: initialLocale,
    onLocaleChanged: onLocaleChanged,
  );

  testWidgets('init with initialLocale resolves that chain, not following', (
    tester,
  ) async {
    final c = await controller(initialLocale: 'de-CH');
    expect(c.localeChain, ['de-CH', 'de', 'en']);
    expect(c.currentLocale, 'de-CH');
    expect(c.followingDeviceLocale, isFalse);
    c.dispose();
  });

  testWidgets('init without initialLocale follows the device locales', (
    tester,
  ) async {
    binding.platformDispatcher.localesTestValue = [const Locale('de', 'CH')];
    final c = await controller();
    expect(c.currentLocale, 'de-CH');
    expect(c.followingDeviceLocale, isTrue);
    c.dispose();
    binding.platformDispatcher.clearLocalesTestValue();
  });

  testWidgets('setLocale renegotiates, notifies, and reports the change', (
    tester,
  ) async {
    final changes = <String>[];
    final c = await controller(
      initialLocale: 'en',
      onLocaleChanged: changes.add,
    );
    var notified = 0;
    c.addListener(() => notified++);
    final before = c.generation;

    c.setLocale('de');
    expect(c.localeChain, ['de', 'en']);
    expect(notified, 1);
    expect(c.generation, before + 1);
    expect(changes, ['de']);
    c.dispose();
  });

  testWidgets('setLocale to the same chain is a no-op', (tester) async {
    final c = await controller(initialLocale: 'de');
    var notified = 0;
    c.addListener(() => notified++);
    c.setLocale('de');
    expect(notified, 0);
    c.dispose();
  });

  testWidgets('device-locale changes retarget the chain while following', (
    tester,
  ) async {
    binding.platformDispatcher.localesTestValue = [const Locale('en')];
    final c = await controller();
    expect(c.currentLocale, 'en');

    binding.platformDispatcher.localesTestValue = [const Locale('de')];
    // localesTestValue dispatches didChangeLocales to observers.
    expect(c.currentLocale, 'de');
    c.dispose();
    binding.platformDispatcher.clearLocalesTestValue();
  });

  testWidgets('an explicit setLocale stops following the device', (
    tester,
  ) async {
    binding.platformDispatcher.localesTestValue = [const Locale('en')];
    final c = await controller();
    c.setLocale('de-CH');
    expect(c.followingDeviceLocale, isFalse);

    binding.platformDispatcher.localesTestValue = [const Locale('en')];
    expect(c.currentLocale, 'de-CH');
    c.dispose();
    binding.platformDispatcher.clearLocalesTestValue();
  });

  testWidgets('useDeviceLocale resumes following', (tester) async {
    binding.platformDispatcher.localesTestValue = [const Locale('de')];
    final c = await controller(initialLocale: 'en');
    c.useDeviceLocale();
    expect(c.currentLocale, 'de');
    expect(c.followingDeviceLocale, isTrue);
    c.dispose();
    binding.platformDispatcher.clearLocalesTestValue();
  });

  testWidgets('reload evicts the loader and bumps the generation', (
    tester,
  ) async {
    final loader = standardLoader();
    final c = await FluentLocaleController.init(
      loader: loader,
      fallbackLocale: 'en',
      initialLocale: 'en',
    );
    var notified = 0;
    c.addListener(() => notified++);
    final before = c.generation;

    c.reload();
    expect(loader.evictCount, 1);
    expect(c.generation, before + 1);
    expect(notified, 1);
    c.dispose();
  });

  testWidgets('an unknown tag lands on the fallback', (tester) async {
    final c = await controller(initialLocale: 'ja-JP');
    expect(c.localeChain, ['en']);
    c.dispose();
  });

  testWidgets('flutterLocale and supportedLocales convert the tags', (
    tester,
  ) async {
    final c = await controller(initialLocale: 'de-CH');
    expect(c.flutterLocale, const Locale('de', 'CH'));
    expect(c.supportedLocales, const [
      Locale('de', 'CH'),
      Locale('de'),
      Locale('en'),
    ]);
    c.dispose();
  });
}
