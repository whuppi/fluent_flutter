import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:fluent_flutter/fluent_flutter.dart';

void main() {
  group('localeFromTag', () {
    test('language only', () {
      expect(localeFromTag('en'), const Locale('en'));
    });

    test('language-region', () {
      expect(localeFromTag('en-US'), const Locale('en', 'US'));
    });

    test('language-script', () {
      expect(
        localeFromTag('zh-Hans'),
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      );
    });

    test('language-script-region', () {
      expect(
        localeFromTag('zh-Hant-TW'),
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      );
    });

    test('normalizes casing and underscores', () {
      expect(localeFromTag('EN_us'), const Locale('en', 'US'));
      expect(
        localeFromTag('zh-hant-tw'),
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      );
    });

    test('round-trips through Locale.toLanguageTag', () {
      for (final tag in ['en', 'en-US', 'zh-Hans', 'zh-Hant-TW']) {
        expect(localeFromTag(tag).toLanguageTag(), tag);
      }
    });
  });
}
