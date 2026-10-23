import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/hive_service.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/garden/garden_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/habit_detail/habit_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/new_habit_screen.dart';
import '../../features/onboarding/character_screen.dart';
import '../../features/onboarding/username_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import '../widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class ProfileStateNotifier extends ChangeNotifier {
  ProfileStateNotifier() {
    try {
      HiveService.instance.settingsBox.watch(key: 'has_profile').listen((_) {
        notifyListeners();
      });
      HiveService.instance.profileBox.watch(key: 'current').listen((_) {
        notifyListeners();
      });
    } catch (_) {}
  }

  bool get hasProfile => HiveService.instance.hasProfile;
}

final ProfileStateNotifier profileNotifier = ProfileStateNotifier();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  refreshListenable: profileNotifier,
  redirect: (BuildContext context, GoRouterState state) {
    final hasProfile = profileNotifier.hasProfile;
    final loc = state.matchedLocation;
    final isOnboardingRoute = loc == '/welcome' ||
        loc == '/onboarding/character' ||
        loc == '/onboarding/username';

    // 1. Profil yoksa: onboarding rotalarında değilse /welcome'a yönlendir
    if (!hasProfile) {
      return isOnboardingRoute ? null : '/welcome';
    }

    // 2. Profil varsa ve karşılama ekranındaysa /home'a yönlendir
    if (loc == '/welcome') {
      return '/home';
    }

    return null;
  },
  routes: [
    // Welcome & Onboarding routes (outside bottom bar)
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/onboarding/character',
      builder: (context, state) => const CharacterScreen(),
    ),
    GoRoute(
      path: '/onboarding/username',
      builder: (context, state) => const UsernameScreen(),
    ),

    // Full-page New Habit (as specified: full page, NOT bottom sheet)
    GoRoute(
      path: '/new-habit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NewHabitScreen(),
    ),

    // Habit Detail Screen (single scroll page)
    GoRoute(
      path: '/habit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final habitId = state.pathParameters['id'] ?? '';
        return HabitDetailScreen(habitId: habitId);
      },
    ),

    // Garden Screen (full page flower gallery)
    GoRoute(
      path: '/garden',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GardenScreen(),
    ),

    // Main App Shell with 4 tab destinations + center FAB push
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Bahçem
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Branch 1: Alışkanlıklar
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/habits',
              builder: (context, state) => const HabitsScreen(),
            ),
          ],
        ),

        // Branch 2: Analiz
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),

        // Branch 3: Profil
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
