import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/app_locale.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/statistics/statistics_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/add_asset/add_asset_screen.dart';
import '../features/asset_details/asset_details_screen.dart';
import '../features/settings/webdav_settings_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/trends',
          name: 'trends',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatisticsScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/settings/webdav',
      name: 'settings-webdav',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const WebDavSettingsScreen(),
    ),
    GoRoute(
      path: '/add-asset',
      name: 'add-asset',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AddAssetScreen(),
    ),
    GoRoute(
      path: '/asset/:id',
      name: 'asset-detail',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => AssetDetailsScreen(
        assetId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/asset/:id/edit',
      name: 'edit-asset',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => AddAssetScreen(
        editAssetId: state.pathParameters['id'],
      ),
    ),
  ],
);

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex;
    if (location.startsWith('/trends')) {
      currentIndex = 1;
    } else if (location.startsWith('/settings')) {
      currentIndex = 2;
    } else {
      currentIndex = 0;
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/');
          case 1:
            context.go('/trends');
          case 2:
            context.go('/settings');
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2),
          label: l10n.assets,
        ),
        NavigationDestination(
          icon: const Icon(Icons.trending_up_outlined),
          selectedIcon: const Icon(Icons.trending_up),
          label: l10n.trends,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.settings,
        ),
      ],
    );
  }
}
