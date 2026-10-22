import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/garden/garden_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/habit_detail/habit_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/new_habit_screen.dart';
import '../../features/onboarding/character_screen.dart';
import '../../features/onboarding/username_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    // Auth & Onboarding routes (outside bottom bar)
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
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

    // Main App Shell with 5 branches (4 tab destinations + center FAB push)
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
