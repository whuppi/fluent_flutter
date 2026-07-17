import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluent_flutter/fluent_flutter.dart';

/// Serves a synthetic AssetManifest + FTL strings — what `flutter run`
/// would bundle for `assets: [assets/i18n/]`.
class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.assets);

  /// Asset key → FTL content.
  final Map<String, String> assets;

  /// Keys evicted via [evict].
  final List<String> evicted = [];

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final manifest = <String, Object>{
        for (final asset in assets.keys) asset: <Object>[],
      };
      return const StandardMessageCodec().encodeMessage(manifest)!;
    }
    final content = assets[key];
    if (content == null) throw FlutterError('Unable to load asset: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }

  @override
  void evict(String key) {
    evicted.add(key);
    super.evict(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  _FakeAssetBundle bundle() => _FakeAssetBundle({
    'assets/i18n/en.ftl': 'greet = Hello!',
    'assets/i18n/de.ftl': 'greet = Hallo!',
    // Folder layout — loaded sorted, AFTER the single file.
    'assets/i18n/de/zz-extra.ftl': 'extra = mehr',
    'assets/i18n/de/aa-first.ftl': 'first = zuerst',
    // Non-FTL and out-of-path noise the index must skip.
    'assets/i18n/readme.txt': 'not ftl',
    'assets/images/logo.png': 'binary',
  });

  test('availableLocales discovers tags from the manifest', () async {
    final loader = AssetFluentLoader(bundle: bundle());
    expect(await loader.availableLocales(), unorderedEquals(['en', 'de']));
  });

  test('single-file layout loads the one source', () async {
    final loader = AssetFluentLoader(bundle: bundle());
    expect(await loader.load('en'), ['greet = Hello!']);
  });

  test('folder layout appends after the single file, path-sorted', () async {
    final loader = AssetFluentLoader(bundle: bundle());
    expect(await loader.load('de'), [
      'greet = Hallo!',
      'first = zuerst',
      'extra = mehr',
    ]);
  });

  test('unknown tag returns empty, never throws', () async {
    final loader = AssetFluentLoader(bundle: bundle());
    expect(await loader.load('ja'), isEmpty);
  });

  test('a custom basePath scopes the index', () async {
    final custom = _FakeAssetBundle({
      'i18n/fr.ftl': 'greet = Salut!',
      'assets/i18n/en.ftl': 'greet = Hello!',
    });
    final loader = AssetFluentLoader(basePath: 'i18n', bundle: custom);
    expect(await loader.availableLocales(), ['fr']);
  });

  test('evict drops the bundle cache for every indexed key', () async {
    final fake = bundle();
    final loader = AssetFluentLoader(bundle: fake);
    await loader.load('de');
    loader.evict();
    expect(
      fake.evicted,
      containsAll([
        'assets/i18n/de.ftl',
        'assets/i18n/de/aa-first.ftl',
        'assets/i18n/de/zz-extra.ftl',
        'assets/i18n/en.ftl',
      ]),
    );
    // The index rebuilds on next use.
    expect(await loader.availableLocales(), unorderedEquals(['en', 'de']));
  });
}
