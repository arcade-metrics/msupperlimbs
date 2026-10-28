import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_adv_settings_state.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_settings_state.dart';
import 'package:msupperlimbs/features/user/application/user_state.dart';
import 'package:msupperlimbs/presentation/widgets/app_header.dart';

class FNoseInstructionsScreen extends ConsumerStatefulWidget {
  const FNoseInstructionsScreen({super.key});

  @override
  ConsumerState<FNoseInstructionsScreen> createState() =>
      _FNoseInstructionsScreen();
}

class _FNoseInstructionsScreen extends ConsumerState<FNoseInstructionsScreen> {
  @override
  void initState() {
    super.initState();
    lockToPortrait();
  }

  Future<void> _loadSettingsAndNavigate(String userUid, String route) async {
    final settings = await ref.read(fnoseSettingsProvider(userUid).future);
    ref.read(fnoseSettingsStateProvider.notifier).state = settings;

    final advSettings =
        await ref.read(fnoseAdvSettingsProvider(userUid).future);
    ref.read(fnoseAdvSettingsStateProvider.notifier).state = advSettings;

    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text(l10n.fnose_instructions_userNotFound)),
      );
    }

    final userUid = user.uid;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppHeader(title: l10n.fnose_instructions_title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_fill,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.fnose_instructions_placeholderText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18.0),
            ),
            const SizedBox(height: 24.0),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Setting Button
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      _loadSettingsAndNavigate(userUid, '/fnose-settings'),
                  icon: const Icon(Icons.settings),
                  label: Text(l10n.fnose_intro_settings),
                ),
                const SizedBox(height: 24),
                //Back Button
                TextButton.icon(
                  onPressed: () => context.go('/fnose-intro'),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l10n.common_back),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
