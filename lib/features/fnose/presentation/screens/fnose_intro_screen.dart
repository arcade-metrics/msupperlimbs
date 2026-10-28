import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_adv_settings_state.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_settings_state.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';
import 'package:msupperlimbs/presentation/widgets/app_header.dart';

import '../../../user/application/user_state.dart';

class FNoseIntroScreen extends ConsumerStatefulWidget {
  const FNoseIntroScreen({super.key});

  @override
  ConsumerState<FNoseIntroScreen> createState() => _FNoseIntroScreen();
}

class _FNoseIntroScreen extends ConsumerState<FNoseIntroScreen> {
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

    String _getGameModeText(FNoseGameMode mode) {
      switch (mode) {
        case FNoseGameMode.leftHand:
          return l10n.fnose_intro_leftHandOnly;
        case FNoseGameMode.rightHand:
          return l10n.fnose_intro_rightHandOnly;
        case FNoseGameMode.bothHands:
          return l10n.fnose_intro_bothHands;
      }
    }

    if (user == null) {
      return Scaffold(
        body: Center(child: Text(l10n.fnose_intro_userNotFound)),
      );
    }

    final userUid = user.uid;
    final asyncSettings = ref.watch(fnoseSettingsProvider(userUid));

    return asyncSettings.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text("${l10n.fnose_intro_errorLoadingSettings} $err")),
      ),
      data: (settings) => Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: AppHeader(title: l10n.fnose_intro_title),
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
                                         size: 80, color: Colors.blue),
                                     const SizedBox(height: 8),
                                     Text(l10n.fnose_intro_instructionVideo,
                                         style: const TextStyle(
                                             fontSize: 16,
                                             fontWeight: FontWeight.w500)),
                                     Text(l10n.fnose_intro_notImplemented,
                                         style: const TextStyle(
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
                                      .read(fnoseSettingsStateProvider.notifier)
                                      .state = updated;
                                  await ref
                                      .read(fnoseSettingsServiceProvider)
                                      .updateFNoseSettings(updated);
                                  ref.invalidate(
                                      fnoseSettingsProvider(userUid));
                                },
                              ),
                              Text(l10n.fnose_intro_hideOnNextTime),
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
                              _loadSettingsAndNavigate(userUid, '/fnose-mode'),
                          icon: const Icon(Icons.gamepad),
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGameModeText(FNoseGameModeX.fromString(
                                    settings.gameMode)),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                l10n.fnose_intro_changeGameMode,
                                style: const TextStyle(fontSize: 12),
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
                              _loadSettingsAndNavigate(userUid, '/fnose-game'),
                          icon: const Icon(Icons.play_arrow,
                              size: 32.0, color: Colors.white),
                          label: Text(l10n.fnose_intro_start),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
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
                              userUid, '/fnose-settings'),
                          icon: const Icon(Icons.settings),
                          label: Text(l10n.fnose_intro_settings),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/fnose-instructions'),
                          icon: const Icon(Icons.menu_book),
                          label: Text(l10n.fnose_intro_instructions),
                        ),
                        const SizedBox(height: 24),
                        //Back Button
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
