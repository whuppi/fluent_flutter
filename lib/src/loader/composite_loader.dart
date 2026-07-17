import 'package:fluent_flutter/src/loader/resource_loader.dart';

/// Merges several loaders into one — the app's own FTL plus FTL shipped
/// by packages, or assets plus a network overlay.
///
/// Locales are the union in loader order; a locale's sources
/// concatenate in loader order too, so an earlier loader's messages win
/// inside one bundle (`FluentBundle.addResource` keeps the first
/// definition of a duplicate id).
class CompositeFluentLoader extends FluentResourceLoader {
  /// Merges [loaders], earlier ones winning duplicate message ids.
  CompositeFluentLoader(List<FluentResourceLoader> loaders)
    : loaders = List.unmodifiable(loaders);

  /// The merged loaders, in priority order.
  final List<FluentResourceLoader> loaders;

  @override
  Future<List<String>> availableLocales() async {
    final seen = <String>[];
    for (final loader in loaders) {
      for (final tag in await loader.availableLocales()) {
        if (!seen.contains(tag)) seen.add(tag);
      }
    }
    return List.unmodifiable(seen);
  }

  @override
  Future<List<String>> load(String languageTag) async => [
    for (final loader in loaders) ...await loader.load(languageTag),
  ];

  @override
  void evict() {
    for (final loader in loaders) {
      loader.evict();
    }
  }
}
