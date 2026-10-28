import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/features/auth/application/auth_state.dart';
import 'package:msupperlimbs/features/auth/presentation/screens/login_screen.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context)!;

    return user.when(
      data: (user) => user != null ? child : const LoginScreen(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text(l10n.error_generic(err.toString())))),
    );
  }
}
