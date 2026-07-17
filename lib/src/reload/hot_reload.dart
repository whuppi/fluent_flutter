import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:fluent_flutter/src/controller/locale_controller.dart';

/// FTL hot reload with zero external tooling: edit a `.ftl` under your
/// assets, press `r`, see the new strings.
///
/// `flutter run` re-syncs changed assets on hot reload; what it can't
/// do is invalidate the asset-bundle string cache or make the
/// localization delegates re-load. This widget closes that gap — its
/// [State.reassemble] evicts the loader's cache and bumps the
/// controller generation, which re-runs every fluent delegate.
///
/// Wrap it anywhere above (or around) the app:
///
/// ```dart
/// runApp(FluentHotReload(
///   controller: controller,
///   child: MyApp(controller: controller),
/// ));
/// ```
///
/// Debug-only by construction: release builds never reassemble, and
/// the widget is otherwise a pass-through.
class FluentHotReload extends StatefulWidget {
  /// Reloads [controller] on every hot reassemble.
  const FluentHotReload({
    required this.controller,
    required this.child,
    super.key,
  });

  /// The controller whose loader + delegates get refreshed.
  final FluentLocaleController controller;

  /// The subtree to pass through unchanged.
  final Widget child;

  @override
  State<FluentHotReload> createState() => _FluentHotReloadState();
}

class _FluentHotReloadState extends State<FluentHotReload> {
  @override
  void reassemble() {
    super.reassemble();
    if (kDebugMode) widget.controller.reload();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
