import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation shell that wraps the main tab screens.
class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  // Settings is excluded from the nav bar and shown in the AppBar instead.
  static const _navTabs = [
    _Tab(icon: Icons.today, label: 'Today', path: '/home'),
    _Tab(icon: Icons.upcoming, label: 'Upcoming', path: '/upcoming'),
    _Tab(icon: Icons.calendar_month, label: 'Calendar', path: '/calendar'),
    _Tab(icon: Icons.repeat, label: 'Templates', path: '/templates'),
    _Tab(
        icon: Icons.emoji_events_rounded,
        label: 'Achievements',
        path: '/achievements'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    // currentIndex only counts nav tabs (0–4)
    int currentNavIndex =
        _navTabs.indexWhere((t) => location.startsWith(t.path));
    if (currentNavIndex == -1) currentNavIndex = 0;

    // Resolve the label from nav tabs
    final currentTab = _navTabs.firstWhere(
      (t) => location.startsWith(t.path),
      orElse: () => _navTabs.first,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          currentTab.label,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: location.startsWith('/settings')
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentNavIndex,
        onDestinationSelected: (index) {
          context.go(_navTabs[index].path);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: _navTabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon, size: 28),
                  selectedIcon: Icon(t.icon, size: 30),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _Tab {
  final IconData icon;
  final String label;
  final String path;
  const _Tab({required this.icon, required this.label, required this.path});
}
