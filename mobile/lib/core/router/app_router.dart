import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/auth/presentation/screens/login_screen.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_game_engine.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_adv_settings_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_feedback_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_game_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_gameover_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_intro_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_mode_selection_screen.dart';
import 'package:msupperlimbs/features/fnose/presentation/screens/fnose_settings_screen.dart';
import 'package:msupperlimbs/features/home/presentation/screens/home_screen.dart';
import 'package:msupperlimbs/features/motion/presentation/screens/motion_debug_screen.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_result.dart';
import 'package:msupperlimbs/features/rapid/presentation/screens/rapid_feedback_screen.dart';
import 'package:msupperlimbs/features/rapid/presentation/screens/rapid_game_screen.dart';
import 'package:msupperlimbs/features/rapid/presentation/screens/rapid_gameover_screen.dart';
import 'package:msupperlimbs/features/rapid/presentation/screens/rapid_intro_screen.dart';
import 'package:msupperlimbs/features/rapid/presentation/screens/rapid_mode_selection_screen.dart';
import 'package:msupperlimbs/features/rapid/presentation/screens/rapid_settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      if (auth.status == AuthStatus.unknown) return null;
      if (auth.status == AuthStatus.unauthenticated) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/motion-debug',
        builder: (context, state) => const MotionDebugScreen(),
      ),
      GoRoute(
        path: '/fnose-intro',
        builder: (context, state) => const FnoseIntroScreen(),
      ),
      GoRoute(
        path: '/fnose-settings',
        builder: (context, state) => const FnoseSettingsScreen(),
      ),
      GoRoute(
        path: '/fnose-adv-settings',
        builder: (context, state) => const FnoseAdvSettingsScreen(),
      ),
      GoRoute(
        path: '/fnose-mode',
        builder: (context, state) => const FnoseModeSelectionScreen(),
      ),
      GoRoute(
        path: '/fnose-game',
        builder: (context, state) => const FnoseGameScreen(),
      ),
      GoRoute(
        path: '/fnose-feedback',
        builder: (context, state) =>
            FnoseFeedbackScreen(result: state.extra as FnoseGameResult?),
      ),
      GoRoute(
        path: '/fnose-gameover',
        builder: (context, state) =>
            FnoseGameOverScreen(result: state.extra as FnoseGameResult?),
      ),
      GoRoute(
        path: '/rapid-intro',
        builder: (context, state) => const RapidIntroScreen(),
      ),
      GoRoute(
        path: '/rapid-settings',
        builder: (context, state) => const RapidSettingsScreen(),
      ),
      GoRoute(
        path: '/rapid-mode',
        builder: (context, state) => const RapidModeSelectionScreen(),
      ),
      GoRoute(
        path: '/rapid-game',
        builder: (context, state) => const RapidGameScreen(),
      ),
      GoRoute(
        path: '/rapid-feedback',
        builder: (context, state) =>
            RapidFeedbackScreen(result: state.extra as RapidGameResult?),
      ),
      GoRoute(
        path: '/rapid-gameover',
        builder: (context, state) =>
            RapidGameOverScreen(result: state.extra as RapidGameResult?),
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) => notifyListeners());
  }

  final Ref _ref;
}
