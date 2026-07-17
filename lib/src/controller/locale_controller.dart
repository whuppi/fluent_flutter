import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:fluent_bundle/fluent_bundle.dart';
import 'package:fluent_flutter/src/common/locale_tags.dart';
import 'package:fluent_flutter/src/loader/resource_loader.dart';

/// The app's locale state: which locales exist, which chain is active,
/// and the verbs that change it. A [ChangeNotifier] — rebuild the
/// `MaterialApp` (or any subtree) with a `ListenableBuilder` on it.
///
/// Construct with [FluentLocaleController.init] — locale discovery is
/// async (the AssetManifest); everything after init is synchronous.
///
/// ```dart
/// final controller = await FluentLocaleController.init(
///   loader: AssetFluentLoader(),
///   fallbackLocale: 'en',
/// );
/// runApp(MyApp(controller: controller));
/// ```
///
/// Following the DEVICE locale ([useDeviceLocale]) keeps listening for
/// system-settings changes until an explicit [setLocale] takes over —
/// mirroring how users expect language pickers to behave.
class FluentLocaleController extends ChangeNotifier
    with WidgetsBindingObserver {
  FluentLocaleController._({
    required this.loader,
    required List<String> availableLocales,
    required this.fallbackLocale,
    this.onLocaleChanged,
  }) : availableLocales = List.unmodifiable(availableLocales);

  /// Discovers the available locales and resolves the starting chain:
  /// [initialLocale] when given (a persisted user choice — see
  /// [onLocaleChanged]), the device locales otherwise.
  ///
  /// [fallbackLocale] ends every chain — make it the locale your FTL
  /// covers completely (the fluent_gen `base_locale` when generating).
  static Future<FluentLocaleController> init({
    required FluentResourceLoader loader,
    required String fallbackLocale,
    String? initialLocale,
    ValueChanged<String>? onLocaleChanged,
  }) async {
    final controller = FluentLocaleController._(
      loader: loader,
      availableLocales: await loader.availableLocales(),
      fallbackLocale: fallbackLocale,
      onLocaleChanged: onLocaleChanged,
    );
    if (initialLocale != null) {
      controller._resolve([initialLocale], followDevice: false);
    } else {
      controller._resolve(controller._deviceTags(), followDevice: true);
    }
    return controller;
  }

  /// Serves the FTL. Also the eviction seam for FTL hot reload.
  final FluentResourceLoader loader;

  /// Every locale the loader can serve, discovery-ordered.
  final List<String> availableLocales;

  /// The chain's last resort — the fully covered base locale.
  final String fallbackLocale;

  /// Fired after every chain change with the new primary tag — the
  /// persistence seam (write it to storage, feed it back as
  /// `initialLocale` on next launch). No storage dependency here.
  final ValueChanged<String>? onLocaleChanged;

  List<String> _chain = const [];
  bool _followingDevice = false;
  int _generation = 0;

  /// The active locale fallback chain, most specific first. Never
  /// empty after [init] (the fallback ends it).
  List<String> get localeChain => _chain;

  /// The chain's primary tag.
  String get currentLocale => _chain.first;

  /// [currentLocale] as a Flutter [Locale] — feed `MaterialApp.locale`.
  Locale get flutterLocale => localeFromTag(currentLocale);

  /// [availableLocales] as Flutter [Locale]s — feed
  /// `MaterialApp.supportedLocales`.
  List<Locale> get supportedLocales => [
    for (final tag in availableLocales) localeFromTag(tag),
  ];

  /// Bumped on every change the delegates must re-load for — chain
  /// changes and [reload]. Delegates compare it in `shouldReload`.
  int get generation => _generation;

  /// Whether the controller is following the device locale (and will
  /// react to system-settings changes).
  bool get followingDeviceLocale => _followingDevice;

  /// Switch to [tag] (negotiated against [availableLocales]) and stop
  /// following the device locale.
  void setLocale(String tag) => _resolve([tag], followDevice: false);

  /// Switch to the device's locale preference and keep following it
  /// until the next explicit [setLocale].
  void useDeviceLocale() => _resolve(_deviceTags(), followDevice: true);

  /// Force the delegates to re-load (evicting the loader's cache) —
  /// the FTL hot-reload path. No-op cost in release builds where
  /// nothing changed; the reassemble hook calls this.
  void reload() {
    loader.evict();
    _generation++;
    notifyListeners();
  }

  // Through the binding, not PlatformDispatcher.instance — the binding's
  // dispatcher is what tests (and embedders) override.
  List<String> _deviceTags() => [
    for (final locale in WidgetsBinding.instance.platformDispatcher.locales)
      locale.toLanguageTag(),
  ];

  void _resolve(List<String> requested, {required bool followDevice}) {
    final chain = negotiateLocaleChain(
      requested: requested,
      available: availableLocales,
      fallback: fallbackLocale,
    );
    _setFollowing(followDevice);
    if (listEquals(chain, _chain)) return;
    // The first resolution (during init) is not a "change" — a
    // persistence callback must not re-save the locale it just fed in.
    final isChange = _chain.isNotEmpty;
    _chain = chain;
    _generation++;
    notifyListeners();
    if (isChange) onLocaleChanged?.call(currentLocale);
  }

  void _setFollowing(bool follow) {
    if (follow == _followingDevice) return;
    _followingDevice = follow;
    if (follow) {
      WidgetsBinding.instance.addObserver(this);
    } else {
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_followingDevice) _resolve(_deviceTags(), followDevice: true);
  }

  @override
  void dispose() {
    _setFollowing(false);
    super.dispose();
  }
}
