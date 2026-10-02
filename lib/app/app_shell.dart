import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/playback_insets.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore_rounded),
      label: '发现',
    ),
    NavigationDestination(icon: Icon(Icons.search_rounded), label: '搜索'),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: '我的',
    ),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= KgBreakpoints.navigationRail) {
        return _WideShell(navigationShell: navigationShell);
      }
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: PlaybackInsets.keyboardVisibleOf(context)
            ? null
            : _CompactBottomDock(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _goBranch,
              ),
      );
    },
  );

  void _goBranch(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );
}

class _CompactBottomDock extends StatelessWidget {
  const _CompactBottomDock({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: KgColors.surface,
      border: Border(top: BorderSide(color: KgColors.divider, width: 0.5)),
    ),
    child: SafeArea(
      top: false,
      child: NavigationBar(
        height: KgNavigation.barHeight,
        backgroundColor: Colors.transparent,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: AppShell.destinations,
      ),
    ),
  );
}

class _WideShell extends StatelessWidget {
  const _WideShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Row(
        children: [
          NavigationRail(
            minWidth: KgNavigation.railWidthOf(context),
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            labelType: NavigationRailLabelType.all,
            backgroundColor: KgColors.surface,
            groupAlignment: -0.7,
            leading: const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 24),
              child: Icon(
                Icons.graphic_eq_rounded,
                color: KgColors.accent,
                size: 30,
              ),
            ),
            destinations: AppShell.destinations
                .map(
                  (destination) => NavigationRailDestination(
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                    label: Text(destination.label),
                  ),
                )
                .toList(growable: false),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    ),
  );
}
