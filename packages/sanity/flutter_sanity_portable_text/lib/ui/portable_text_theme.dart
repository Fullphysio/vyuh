import 'package:flutter/material.dart';

import '../flutter_sanity_portable_text.dart';

/// An [InheritedWidget] that supplies a [PortableTextConfig] to its subtree.
///
/// Mirrors Flutter's `Theme` / `Theme.of`: descendant Portable Text widgets resolve their
/// config via [PortableTextConfig.of], which returns the nearest [PortableTextTheme]'s
/// [config] or falls back to [PortableTextConfig.shared]. Wrap a subtree to render it with a
/// different configuration without mutating the global [PortableTextConfig.shared].
class PortableTextTheme extends InheritedWidget {
  /// The configuration applied to descendant Portable Text widgets.
  final PortableTextConfig config;

  const PortableTextTheme({
    super.key,
    required this.config,
    required super.child,
  });

  /// The [PortableTextConfig] of the nearest [PortableTextTheme] ancestor, or `null` if none.
  static PortableTextConfig? maybeOf(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PortableTextTheme>()?.config;

  @override
  bool updateShouldNotify(final PortableTextTheme oldWidget) =>
      config != oldWidget.config;
}

/// Restyles descendant Portable Text by transforming the *inherited* text style for each
/// named style (e.g. `'normal'`, `'h2'`).
///
/// Each entry receives the resolved style produced by the ambient config's builder and
/// returns the adjusted style, so callers express only the delta:
///
/// ```dart
/// PortableTextStyleOverride(
///   styles: {'normal': (s) => s.copyWith(fontSize: (s.fontSize ?? 16) - 2)},
///   child: ...,
/// )
/// ```
///
/// The inherited builder is captured internally, so referencing the same style name does
/// not recurse. Everything else (blocks, marks, spacing, parsing) is inherited unchanged.
class PortableTextStyleOverride extends StatelessWidget {
  /// Per-style transforms applied on top of the inherited resolved style. Keys are style
  /// names (`'normal'`, `'h2'`, …); a key that the ambient config does not define is ignored.
  final Map<String, TextStyle Function(TextStyle)> styles;

  /// The subtree whose Portable Text should be restyled.
  final Widget child;

  const PortableTextStyleOverride({
    super.key,
    required this.styles,
    required this.child,
  });

  @override
  Widget build(final BuildContext context) {
    final base = PortableTextConfig.of(context);
    final wrapped = <String, TextStyleBuilder>{
      for (final entry in styles.entries)
        if (base.styles[entry.key] case final builder?)
          entry.key: (final ctx, final inherited) =>
              entry.value(builder(ctx, inherited)),
    };
    return PortableTextTheme(
      config: base.copyWith(styles: wrapped),
      child: child,
    );
  }
}
