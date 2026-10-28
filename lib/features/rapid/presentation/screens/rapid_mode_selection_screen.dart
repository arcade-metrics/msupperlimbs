import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_settings_state.dart';
import 'package:msupperlimbs/features/rapid/data/models/enums/rapid_game_mode_enum.dart';
import 'package:msupperlimbs/features/user/application/user_state.dart';

class RapidModeSelectionScreen extends ConsumerStatefulWidget {
  const RapidModeSelectionScreen({super.key});

  @override
  ConsumerState<RapidModeSelectionScreen> createState() =>
      _RapidModeSelectionScreenState();
}

class _RapidModeSelectionScreenState
    extends ConsumerState<RapidModeSelectionScreen> {
  @override
  void initState() {
    super.initState();
    lockToPortrait();
    Future.microtask(() async {
      final user = ref.read(userProvider);
      if (user != null) {
        final settings = await ref.read(rapidSettingsProvider(user.uid).future);
        ref.read(rapidSettingsStateProvider.notifier).state = settings;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(rapidSettingsStateProvider);
    final l10n = AppLocalizations.of(context)!;
    
    if (settings == null) {
      return const SizedBox(); // avoid freeze screen with infinite loading
    }

    final currentMode = RapidGameModeX.fromString(settings.gameMode);
    final userId = settings.userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Game Mode Selection')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Choose Game Mode',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _buildModeCard(
                  context,
                  'Left Hand Only',
                  'Play using only your left hand',
                  RapidGameMode.leftHand,
                  currentMode,
                  userId),
              const SizedBox(height: 16),
              _buildModeCard(
                  context,
                  'Right Hand Only',
                  'Play using only your right hand',
                  RapidGameMode.rightHand,
                  currentMode,
                  userId),
              const SizedBox(height: 16),
              _buildModeCard(
                  context,
                  'Both Hands',
                  'Play using both hands',
                  RapidGameMode.bothHands,
                  currentMode,
                  userId),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.go('/rapid-intro'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 20)),
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
    RapidGameMode mode,
    RapidGameMode selectedMode,
    String userId,
  ) {
    final isSelected = mode == selectedMode;

    return GestureDetector(
      onTap: () async {
        await ref
            .read(rapidSettingsServiceProvider)
            .setRapidGameMode(userId, mode.name);
        ref.invalidate(rapidSettingsProvider(userId));
        final updated = await ref.read(rapidSettingsProvider(userId).future);
        ref.read(rapidSettingsStateProvider.notifier).state = updated;
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
