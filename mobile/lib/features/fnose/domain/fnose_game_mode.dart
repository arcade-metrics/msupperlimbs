import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

enum FnoseGameMode { leftHand, rightHand, bothHands }

extension FnoseGameModeX on FnoseGameMode {
  static const selectableModes = [
    FnoseGameMode.leftHand,
    FnoseGameMode.rightHand,
  ];

  String get apiValue => name;

  String label(AppLocalizations l10n) => switch (this) {
    FnoseGameMode.leftHand => l10n.fnose_mode_leftHandOnly,
    FnoseGameMode.rightHand => l10n.fnose_mode_rightHandOnly,
    FnoseGameMode.bothHands => l10n.fnose_mode_bothHands,
  };

  String description(AppLocalizations l10n) => switch (this) {
    FnoseGameMode.leftHand => l10n.fnose_mode_leftHandOnlyDesc,
    FnoseGameMode.rightHand => l10n.fnose_mode_rightHandOnlyDesc,
    FnoseGameMode.bothHands => l10n.fnose_mode_bothHandsDesc,
  };

  static FnoseGameMode fromString(String value) {
    return switch (value) {
      'rightHand' => FnoseGameMode.rightHand,
      'bothHands' => FnoseGameMode.leftHand,
      _ => FnoseGameMode.leftHand,
    };
  }
}
