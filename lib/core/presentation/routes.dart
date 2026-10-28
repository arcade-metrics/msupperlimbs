import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/core/presentation/auth_guard.dart';
import 'package:msupperlimbs/features/auth/presentation/screens/login_screen.dart';
import 'package:msupperlimbs/features/auth/presentation/screens/signup_screen.dart';
import 'package:msupperlimbs/features/auth/presentation/screens/consent_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_adv_settings_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_feedback_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_game_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_gameover_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_instructions_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_intro_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_mode_selection_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_settings_screen.dart';
import 'package:msupperlimbs/features/rapid/presentation/screens/rapid_intro_screen.dart';
import 'package:msupperlimbs/features/rapid/presentation/screens/rapid_game_screen.dart';
import 'package:msupperlimbs/features/rapid/presentation/screens/rapid_settings_screen.dart';
import 'package:msupperlimbs/features/rapid/presentation/screens/rapid_mode_selection_screen.dart';
import 'package:msupperlimbs/features/rapid/presentation/screens/rapid_feedback_screen.dart';
import 'package:msupperlimbs/features/rapid/presentation/screens/rapid_gameover_screen.dart';
import 'package:msupperlimbs/presentation/screens/home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // --- Authentication routes ---
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(
        path: '/consent', builder: (context, state) => const ConsentScreen()),
    GoRoute(
        path: '/consent-full',
        builder: (context, state) => const ConsentScreen()),

    // --- Home routes ---
    GoRoute(
      path: '/home',
      builder: (context, state) => AuthGuard(child: const HomeScreen()),
    ),

    // --- Finger-to-Nose routes ---
    GoRoute(
      path: '/fnose-intro',
      builder: (context, state) => AuthGuard(child: const FNoseIntroScreen()),
    ),
    GoRoute(
      path: '/fnose-mode',
      builder: (context, state) =>
          AuthGuard(child: const FNoseModeSelectionScreen()),
    ),
    GoRoute(
      path: '/fnose-settings',
      builder: (context, state) =>
          AuthGuard(child: const FNoseSettingsScreen()),
    ),
    GoRoute(
      path: '/fnose-adv-settings',
      builder: (context, state) =>
          AuthGuard(child: const FNoseAdvSettingsScreen()),
    ),
    GoRoute(
      path: '/fnose-instructions',
      builder: (context, state) =>
          AuthGuard(child: const FNoseInstructionsScreen()),
    ),
    GoRoute(
      path: '/fnose-game',
      builder: (context, state) => AuthGuard(child: const FNoseGameScreen()),
    ),
    GoRoute(
      path: '/fnose-feedback',
      builder: (context, state) =>
          AuthGuard(child: const FNoseFeedbackScreen()),
    ),
    GoRoute(
      path: '/fnose-gameover',
      builder: (context, state) => AuthGuard(child: FNoseGameOverScreen()),
    ),

    // --- Rapid routes ---
    GoRoute(
      path: '/rapid-intro',
      builder: (context, state) => AuthGuard(child: const RapidIntroScreen()),
    ),
    GoRoute(
      path: '/rapid-settings',
      builder: (context, state) => AuthGuard(child: const RapidSettingsScreen()),
    ),
    GoRoute(
      path: '/rapid-mode',
      builder: (context, state) => AuthGuard(child: const RapidModeSelectionScreen()),
    ),
    GoRoute(
      path: '/rapid-game',
      builder: (context, state) => AuthGuard(child: const RapidGameScreen()),
    ),
    GoRoute(
      path: '/rapid-feedback',
      builder: (context, state) => AuthGuard(child: const RapidFeedbackScreen()),
    ),
    GoRoute(
      path: '/rapid-gameover',
      builder: (context, state) => AuthGuard(child: const RapidGameOverScreen()),
    ),
  ],
);
