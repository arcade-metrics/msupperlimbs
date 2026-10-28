import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_settings_state.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';
import 'package:msupperlimbs/features/user/application/user_state.dart';

class FNoseModeSelectionScreen extends ConsumerStatefulWidget {
  const FNoseModeSelectionScreen({super.key});

  @override
  ConsumerState<FNoseModeSelectionScreen> createState() =>
      _FNoseModeSelectionScreenState();
}

class _FNoseModeSelectionScreenState
    extends ConsumerState<FNoseModeSelectionScreen> {
  @override
  @override
  void initState() {
    super.initState();
    lockToPortrait();
    Future.microtask(() async {
      final user = ref.read(userProvider);
      if (user != null) {
        final settings = await ref.read(fnoseSettingsProvider(user.uid).future);
        ref.read(fnoseSettingsStateProvider.notifier).state = settings;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(fnoseSettingsStateProvider);
    final l10n = AppLocalizations.of(context)!;
    
    if (settings == null) {
      return const SizedBox(); // avoid freeze screen with infinite loading
    }

    final currentMode = FNoseGameModeX.fromString(settings.gameMode);
    final userId = settings.userId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fnose_mode_title)),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.fnose_mode_chooseGameMode,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _buildModeCard(
                  context,
                  l10n.fnose_mode_leftHandOnly,
                  l10n.fnose_mode_leftHandOnlyDesc,
                  FNoseGameMode.leftHand,
                  currentMode,
                  userId),
              const SizedBox(height: 16),
              _buildModeCard(
                  context,
                  l10n.fnose_mode_rightHandOnly,
                  l10n.fnose_mode_rightHandOnlyDesc,
                  FNoseGameMode.rightHand,
                  currentMode,
                  userId),

              //TODO verify both hands game rules
              //const SizedBox(height: 16),
              // _buildModeCard(
              //    context,
              //    l10n.fnose_mode_bothHands,
              //    l10n.fnose_mode_bothHandsDesc,
              //    FNoseGameMode.bothHands,
              //    currentMode,
              //    userId),

              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.go('/fnose-intro'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.fnose_mode_continue, style: const TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    String title,
    String description,
    FNoseGameMode mode,
    FNoseGameMode selectedMode,
    String userId,
  ) {
    final isSelected = mode == selectedMode;

    return GestureDetector(
      onTap: () async {
        await ref
            .read(fnoseSettingsServiceProvider)
            .setFNoseGameMode(userId, mode);
        ref.invalidate(fnoseSettingsProvider(userId));
        final updated = await ref.read(fnoseSettingsProvider(userId).future);
        ref.read(fnoseSettingsStateProvider.notifier).state = updated;
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withAlpha((0.1 * 255).round())
              : Colors.grey.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue : Colors.black,
                )),
            const SizedBox(height: 8),
            Text(description,
                style:
                    TextStyle(color: isSelected ? Colors.blue : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
