import 'package:flutter/services.dart';

import 'package:fluent_flutter/src/loader/resource_loader.dart';

/// Loads FTL from the app's asset bundle, locales discovered from the
/// AssetManifest — supported locales are never hand-listed twice.
///
/// Two layouts under [basePath], usable together:
///
///     assets/i18n/en.ftl          — one file per locale
///     assets/i18n/en/app.ftl      — a folder per locale (multi-file,
///     assets/i18n/en/errors.ftl     loaded in sorted-path order after
///                                   the single file)
///
/// Declare the folder in `pubspec.yaml` (`assets: [assets/i18n/]` —
/// Flutter includes one level of children; list locale subfolders too
/// when using the folder layout).
class AssetFluentLoader extends FluentResourceLoader {
  /// Reads from [bundle] (defaults to [rootBundle]) under [basePath].
  AssetFluentLoader({this.basePath = 'assets/i18n', AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  /// The asset directory holding the FTL files, no trailing slash.
  final String basePath;

  final AssetBundle _bundle;

  Map<String, List<String>>? _keysByTag;

  /// Asset keys per language tag: the `{tag}.ftl` file first, then the
  /// `{tag}/**.ftl` files sorted by path.
  Future<Map<String, List<String>>> _index() async {
    final cached = _keysByTag;
    if (cached != null) return cached;
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    final prefix = '$basePath/';
    final singles = <String, String>{};
    final folders = <String, List<String>>{};
    for (final key in manifest.listAssets()) {
      if (!key.startsWith(prefix) || !key.endsWith('.ftl')) continue;
      final rest = key.substring(prefix.length, key.length - '.ftl'.length);
      final slash = rest.indexOf('/');
      if (slash == -1) {
        singles[rest] = key;
      } else {
        folders.putIfAbsent(rest.substring(0, slash), () => []).add(key);
      }
    }
    final index = <String, List<String>>{};
    for (final tag in {...singles.keys, ...folders.keys}) {
      index[tag] = [
        if (singles[tag] != null) singles[tag]!,
        ...[...?folders[tag]]..sort(),
      ];
    }
    return _keysByTag = index;
  }

  @override
  Future<List<String>> availableLocales() async =>
      List.unmodifiable((await _index()).keys);

  @override
  Future<List<String>> load(String languageTag) async {
    final keys = (await _index())[languageTag] ?? const <String>[];
    return [for (final key in keys) await _bundle.loadString(key)];
  }

  @override
  void evict() {
    final index = _keysByTag;
    if (index != null) {
      for (final keys in index.values) {
        keys.forEach(_bundle.evict);
      }
    }
    _keysByTag = null;
  }
}
