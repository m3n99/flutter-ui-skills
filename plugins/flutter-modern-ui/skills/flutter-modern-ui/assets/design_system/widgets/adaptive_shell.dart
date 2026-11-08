import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';

/// A top-level destination of the app.
class AppDestination {
  const AppDestination({required this.icon, required this.selectedIcon, required this.label});

  /// Outlined icon; [selectedIcon] is the filled variant.
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// App frame that adapts to the window:
///
/// - compact (< 600): bottom NavigationBar
/// - medium and expanded (600–1199): NavigationRail with labels below icons
/// - large (≥ 1200): extended NavigationRail with labels beside icons
///
/// Keep each destination's state alive with an IndexedStack (or the router's
/// stateful shell) in [body].
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.floatingActionButton,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// Bottom-end FAB on phones; at the top of the rail on wider windows.
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final size = context.windowSize;

    if (size == WindowSize.compact) {
      return Scaffold(
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final d in destinations)
              NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
          ],
        ),
      );
    }

    final extended = size.atLeast(WindowSize.large);
    final fab = floatingActionButton;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            leading: fab == null
                ? null
                : Padding(padding: const EdgeInsets.symmetric(vertical: AppSpace.xs), child: fab),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: AppStroke.hairline),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Centers content and caps its width: forms 640, reading 720, dashboards
/// and tables 1440. Use [horizontalPadding] for slivers.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = AppSize.contentMaxWidth});

  final Widget child;
  final double maxWidth;

  /// Side padding that keeps content at most [maxWidth] wide inside
  /// [availableWidth], and never less than the screen padding.
  static double horizontalPadding(double availableWidth, {double maxWidth = AppSize.contentMaxWidth}) =>
      math.max(AppSpace.screen, (availableWidth - maxWidth) / 2);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}
