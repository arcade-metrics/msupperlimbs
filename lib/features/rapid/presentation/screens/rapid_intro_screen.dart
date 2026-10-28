import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_settings_state.dart';
import 'package:msupperlimbs/features/rapid/data/models/enums/rapid_game_mode_enum.dart';
import 'package:msupperlimbs/presentation/widgets/app_header.dart';
import '../../../user/application/user_state.dart';

class RapidIntroScreen extends ConsumerStatefulWidget {
  const RapidIntroScreen({super.key});

  @override
  ConsumerState<RapidIntroScreen> createState() => _RapidIntroScreenState();
}

class _RapidIntroScreenState extends ConsumerState<RapidIntroScreen> {
  @override
  void initState() {
    super.initState();
    lockToPortrait();
  }

  String _getGameModeText(RapidGameMode mode) {
    switch (mode) {
      case RapidGameMode.leftHand:
        return 'Left Hand Only';
      case RapidGameMode.rightHand:
        return 'Right Hand Only';
      case RapidGameMode.bothHands:
        return 'Both Hands';
    }
  }

  Future<void> _loadSettingsAndNavigate(String userUid, String route) async {
    final settings = await ref.read(rapidSettingsProvider(userUid).future);
    ref.read(rapidSettingsStateProvider.notifier).state = settings;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    final userUid = user.uid;
    final asyncSettings = ref.watch(rapidSettingsProvider(userUid));

    return asyncSettings.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text("Error loading settings: $err")),
      ),
      data: (settings) => Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: AppHeader(title: 'Rapid Challenge'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (settings.showInfoVideo)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 1.0),
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withAlpha((0.3 * 255).round()),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.play_circle_fill,
                                        size: 80, color: Colors.orange),
                                    const SizedBox(height: 8),
                                    const Text('Instruction Video',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500)),
                                    const Text('(Not Implemented)',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: !settings.showInfoVideo,
                                onChanged: (value) async {
                                  if (value == null) return;

                                  final updated =
                                      settings.copyWith(showInfoVideo: !value);
                                  ref
                                      .read(rapidSettingsStateProvider.notifier)
                                      .state = updated;
                                  await ref
                                      .read(rapidSettingsServiceProvider)
                                      .updateRapidSettings(updated);
                                  ref.invalidate(
                                      rapidSettingsProvider(userUid));
                                },
                              ),
                              const Text('Hide on next time'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  IntrinsicWidth(
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _loadSettingsAndNavigate(userUid, '/rapid-mode'),
                          icon: const Icon(Icons.gamepad),
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGameModeText(RapidGameModeX.fromString(
                                    settings.gameMode)),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Text(
                                'Change Game Mode',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 16.0),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _loadSettingsAndNavigate(userUid, '/rapid-game'),
                          icon: const Icon(Icons.play_arrow,
                              size: 32.0, color: Colors.white),
                          label: const Text('START'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            textStyle: const TextStyle(
                                fontSize: 22.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32.0, vertical: 16.0),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _loadSettingsAndNavigate(
                              userUid, '/rapid-settings'),
                          icon: const Icon(Icons.settings),
                          label: const Text('Settings'),
                        ),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.common_back),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


