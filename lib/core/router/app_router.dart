import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/dto/dtos.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../ui/auth/login_screen.dart';
import '../../ui/auth/register_screen.dart';
import '../../ui/calendar/calendar_screen.dart';
import '../../ui/home/home_shell.dart';
import '../../ui/onboarding/household_setup_screen.dart';
import '../../ui/settings/settings_screen.dart';
import '../../ui/templates/template_form_screen.dart';
import '../../ui/templates/templates_screen.dart';
import '../../ui/achievements/achievements_screen.dart';
import '../../ui/today/today_screen.dart';
import '../../ui/upcoming/upcoming_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Use a ValueNotifier to trigger redirect re-evaluation without
  // recreating the entire GoRouter (which would rebuild all screens).
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => refreshNotifier.value++);
  ref.listen(householdProvider, (_, __) => refreshNotifier.value++);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final householdState = ref.read(householdProvider);
      final hasHousehold = householdState.hasHousehold;
      final isLoadingHousehold = householdState.isLoading;
      final location = state.uri.toString();

      // Not authenticated → login
      if (!isAuthenticated) {
        if (location == '/login' || location == '/register') {
          return null;
        }
        return '/login';
      }

      // Authenticated but household still loading → stay put
      if (isLoadingHousehold) return null;

      // Authenticated but no household → setup
      if (!hasHousehold && !location.startsWith('/household-setup')) {
        if (location == '/login' || location == '/register') {
          return '/household-setup';
        }
        if (location.startsWith('/household-setup')) return null;
        return '/household-setup';
      }

      // Authenticated with household → don't allow auth screens
      if (isAuthenticated && hasHousehold) {
        if (location == '/login' ||
            location == '/register' ||
            location.startsWith('/household-setup')) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/household-setup',
        builder: (context, state) => const HouseholdSetupScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TodayScreen()),
          ),
          GoRoute(
            path: '/upcoming',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UpcomingScreen()),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CalendarScreen()),
          ),
          GoRoute(
            path: '/templates',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TemplatesScreen()),
          ),
          GoRoute(
            path: '/achievements',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AchievementsScreen()),
          ),
        ],
      ),

      // Settings — pushed on top of shell (no bottom nav)
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Template form (pushed on top of shell)
      GoRoute(
        path: '/templates/create',
        builder: (context, state) => const TemplateFormScreen(),
      ),
      GoRoute(
        path: '/templates/edit',
        builder: (context, state) {
          final template = state.extra as ChoreTemplateDto?;
          return TemplateFormScreen(existing: template);
        },
      ),
    ],
  );
});
