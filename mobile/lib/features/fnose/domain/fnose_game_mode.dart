import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

/// The API accepts only one hand per match (`leftHand` / `rightHand`).
enum FnoseGameMode { leftHand, rightHand }

extension FnoseGameModeX on FnoseGameMode {
  static const selectableModes = FnoseGameMode.values;

  String get apiValue => name;

  String label(AppLocalizations l10n) => switch (this) {
    FnoseGameMode.leftHand => l10n.fnose_mode_leftHandOnly,
    FnoseGameMode.rightHand => l10n.fnose_mode_rightHandOnly,
  };

  String description(AppLocalizations l10n) => switch (this) {
    FnoseGameMode.leftHand => l10n.fnose_mode_leftHandOnlyDesc,
    FnoseGameMode.rightHand => l10n.fnose_mode_rightHandOnlyDesc,
  };

  static FnoseGameMode fromString(String value) {
    return switch (value) {
      'rightHand' => FnoseGameMode.rightHand,
      _ => FnoseGameMode.leftHand,
    };
  }
}
