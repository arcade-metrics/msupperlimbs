import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/features/gameplay/application/session_state.dart';
import 'package:msupperlimbs/presentation/widgets/app_header.dart';
import 'package:msupperlimbs/features/auth/application/auth_state.dart';

import '../../features/user/application/user_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

const platform = MethodChannel('com.example/native');

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    lockToPortrait();
  }

  Future<void> testNativeCall() async {
    try {
      final result = await platform.invokeMethod('test');
      debugPrint('Native result: $result');
    } on PlatformException catch (e) {
      debugPrint('Failed: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppHeader(title: l10n.home_title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Image.asset(
              isDarkTheme
                  ? 'assets/logo-dark-1024x1024.png'
                  : 'assets/logo-light-1024x1024.png',
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            // Finger-to-Nose
            ElevatedButton(
              onPressed: () {
                if (sessionState != null) {
                  context.go('/fnose-intro');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.home_sessionNotFound)));
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: Text(l10n.home_fingerToNoseChallenge),
            ),
            const SizedBox(height: 16),
            // Rapid Challenge
            ElevatedButton(
              onPressed: () {
                if (sessionState != null) {
                  context.go('/rapid-intro');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.home_sessionNotFound)));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Rapid Challenge'),
            ),
            const SizedBox(height: 60),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Change user
                ElevatedButton(
                  onPressed: () async {
                    final auth = ref.read(authServiceProvider);
                    await auth.signOut();

                    ref.read(userProvider.notifier).state =
                        null; // Reset UserState
                    ref.read(sessionProvider.notifier).state =
                        null; // Reset SessionState

                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: Text(l10n.home_changeUser),
                ),

                // Exit
                ElevatedButton(
                  onPressed: () {
                    if (Platform.isAndroid) {
                      SystemNavigator.pop();
                    } else if (Platform.isIOS) {
                      exit(0);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: Text(l10n.home_exit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
