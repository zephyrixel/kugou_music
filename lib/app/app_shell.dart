import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/kg_glass_surface.dart';
import 'package:kgmusic/features/player/mini_player.dart';

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
      icon: Icon(Icons.library_music_outlined),
      selectedIcon: Icon(Icons.library_music_rounded),
      label: '音乐库',
    ),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= KgBreakpoints.navigationRail) {
        return _WideShell(navigationShell: navigationShell);
      }
      return Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: _CompactBottomDock(
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
  Widget build(BuildContext context) => KgGlassSurface(
    borderRadius: BorderRadius.zero,
    color: KgColors.surface.withValues(alpha: 0.72),
    borderColor: Colors.transparent,
    blurSigma: 20,
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: KgMotion.resolve(context, KgMotion.medium),
            curve: KgMotion.standard,
            alignment: Alignment.bottomCenter,
            child: const MiniPlayer(),
          ),
          NavigationBar(
            height: 68,
            backgroundColor: Colors.transparent,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: AppShell.destinations,
          ),
        ],
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
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: Text('发现'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search_rounded),
                label: Text('搜索'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music_rounded),
                label: Text('音乐库'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(child: navigationShell),
                KgGlassSurface(
                  borderRadius: BorderRadius.zero,
                  color: KgColors.surface.withValues(alpha: 0.72),
                  borderColor: Colors.transparent,
                  child: AnimatedSize(
                    duration: KgMotion.resolve(context, KgMotion.medium),
                    curve: KgMotion.standard,
                    alignment: Alignment.bottomCenter,
                    child: Align(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: const MiniPlayer(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
