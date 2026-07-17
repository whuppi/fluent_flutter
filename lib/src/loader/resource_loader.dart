/// Where FTL comes from — assets, network, disk, tests.
///
/// The delegate asks a loader two questions: which locales exist, and
/// what sources one locale has. Implementations decide the storage.
abstract class FluentResourceLoader {
  /// Const base constructor for implementations.
  const FluentResourceLoader();

  /// Every language tag this loader can serve, discovery-ordered.
  Future<List<String>> availableLocales();

  /// The FTL sources for [languageTag], in add order. Returns an EMPTY
  /// list for a tag this loader has nothing for — never throws for an
  /// unknown tag (composite loaders and fallback chains rely on that).
  Future<List<String>> load(String languageTag);

  /// Drop any cached sources so the next [load] re-reads storage. The
  /// FTL hot-reload hook calls this on every reassemble; the default is
  /// a no-op for loaders that don't cache.
  void evict() {}
}
