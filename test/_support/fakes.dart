// Shared test doubles. In-memory, mutable, instrumented — every suite
// that needs "FTL from somewhere" goes through these instead of assets.

import 'package:fluent_flutter/fluent_flutter.dart';

/// An in-memory loader: `sources[tag]` is the FTL list served for that
/// tag. Mutate the map + call the controller's `reload()` to model an
/// FTL edit; [evictCount] counts cache drops.
class FakeFluentLoader extends FluentResourceLoader {
  /// Serves [sources] verbatim.
  FakeFluentLoader(this.sources);

  /// Tag → FTL sources. Mutable on purpose.
  final Map<String, List<String>> sources;

  /// How many times [evict] ran.
  int evictCount = 0;

  @override
  Future<List<String>> availableLocales() async =>
      List.unmodifiable(sources.keys);

  @override
  Future<List<String>> load(String languageTag) async =>
      List.unmodifiable(sources[languageTag] ?? const <String>[]);

  @override
  void evict() => evictCount++;
}

/// The standard three-locale fixture: partial `de-CH`, partial `de`,
/// complete `en` base.
FakeFluentLoader standardLoader() => FakeFluentLoader({
  'de-CH': ['greet = Grüezi!'],
  'de': ['greet = Hallo!\nbye = Tschüss!'],
  'en': [
    'greet = Hello!\nbye = Bye!\nonly-base = base wins',
    r'tagged = read <bold>{ $thing }</bold> now',
  ],
});
