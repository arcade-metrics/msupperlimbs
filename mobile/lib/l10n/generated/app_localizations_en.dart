// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get common_back => 'Back';

  @override
  String get common_email => 'Email';

  @override
  String get common_password => 'Password';

  @override
  String get common_name => 'Name';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_save => 'Save';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_retry => 'Try again';

  @override
  String get common_continue => 'Continue';

  @override
  String common_error(String error) {
    return 'Error: $error';
  }

  @override
  String get app_title => 'MS Upper Limbs Assessment';

  @override
  String get app_name => 'MS Upper Limbs';

  @override
  String app_versionLabel(String version) {
    return 'MS Upper Limbs v$version';
  }

  @override
  String get auth_login => 'Login';

  @override
  String get auth_signup => 'Sign Up';

  @override
  String get auth_createAccount => 'Create account';

  @override
  String get auth_noAccountQuestion => 'Don\'t have an account? Sign up';

  @override
  String get auth_haveAccountQuestion => 'Already have an account? Login';

  @override
  String get auth_consentCheckbox => 'I accept the data use consent';

  @override
  String get auth_consentRequired => 'Consent is required';

  @override
  String get auth_nameRequired => 'Enter your name';

  @override
  String get auth_emailInvalid => 'Invalid email';

  @override
  String get auth_passwordMin => 'Minimum 6 characters';

  @override
  String get auth_loginSuccessful => 'Login successful!';

  @override
  String get auth_invalidCredentials => 'Invalid email or password.';

  @override
  String get auth_accountCreatedSuccess => 'Account created successfully!';

  @override
  String get auth_failedToCreateAccount => 'Failed to create account.';

  @override
  String get auth_missingToken => 'Not authenticated';

  @override
  String get home_title => 'Home';

  @override
  String get home_fingerToNoseChallenge => 'Finger-to-Nose Challenge';

  @override
  String get home_rapidChallenge => 'Rapid Challenge';

  @override
  String get home_mediapipeDebug => 'MediaPipe Debug';

  @override
  String get home_changeUser => 'Change User';

  @override
  String get home_exit => 'Exit';

  @override
  String get home_noUserLoggedIn => 'No user logged in';

  @override
  String get camera_permissionDenied => 'Camera permission denied';

  @override
  String get camera_noneAvailable => 'No camera available';

  @override
  String get fnose_intro_title => 'Finger-to-Nose';

  @override
  String fnose_intro_errorLoadingSettings(String error) {
    return 'Error loading settings: $error';
  }

  @override
  String get fnose_intro_instructionVideo => 'Instruction video';

  @override
  String get fnose_intro_notImplemented => '(not implemented yet)';

  @override
  String get fnose_intro_hideOnNextTime => 'Don\'t show next time';

  @override
  String get fnose_intro_changeGameMode => 'Change game mode';

  @override
  String get fnose_intro_start => 'START';

  @override
  String get fnose_intro_settings => 'Settings';

  @override
  String get fnose_mode_title => 'Game mode';

  @override
  String get fnose_mode_chooseGameMode => 'Choose mode';

  @override
  String get fnose_mode_leftHandOnly => 'Left Hand Only';

  @override
  String get fnose_mode_leftHandOnlyDesc =>
      'Touch the nose and target with your left hand';

  @override
  String get fnose_mode_rightHandOnly => 'Right Hand Only';

  @override
  String get fnose_mode_rightHandOnlyDesc =>
      'Touch the nose and target with your right hand';

  @override
  String get fnose_mode_bothHands => 'Both Hands';

  @override
  String get fnose_mode_bothHandsDesc => 'Alternate between both hands';

  @override
  String get fnose_mode_continue => 'Continue';

  @override
  String get fnose_settings_title => 'FNose Settings';

  @override
  String get fnose_settings_advancedSettings => 'Advanced settings';

  @override
  String get fnose_settings_showInstructionVideo => 'Show instruction video';

  @override
  String get fnose_settings_totalTime => 'Total time (s)';

  @override
  String get fnose_settings_targetSize => 'Target size (×)';

  @override
  String get fnose_settings_settingsUpdated => 'Settings saved';

  @override
  String get fnose_settings_defaultsRestored => 'Defaults restored';

  @override
  String fnose_settings_saveError(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get restoreDefaults => 'Restore defaults';

  @override
  String get fnose_adv_settings_title => 'Advanced Settings';

  @override
  String get fnose_adv_settings_updated => 'Advanced settings updated';

  @override
  String get fnose_adv_section_arm => 'Arm tracking';

  @override
  String get fnose_adv_section_target => 'Target';

  @override
  String get fnose_adv_section_position => 'Body positioning';

  @override
  String get fnose_adv_section_nose => 'Nose alignment';

  @override
  String get fnose_adv_section_stability => 'Device stability';

  @override
  String get fnose_pregame_keepStill => 'Keep the phone still';

  @override
  String get fnose_pregame_tiltAndStill =>
      'Tilt the phone (~90°) and keep still';

  @override
  String get fnose_pregame_deviceStable => 'Device stable — hold…';

  @override
  String get fnose_pregame_motionDetected =>
      'Motion detected — stabilize again';

  @override
  String get fnose_pregame_positionPose =>
      'Center your torso and nose in the camera';

  @override
  String get fnose_pregame_poseDetected => 'Pose detected — hold position…';

  @override
  String get fnose_pregame_poseLost => 'Pose lost — reposition';

  @override
  String get fnose_pregame_calibrating => 'Calibrating target…';

  @override
  String get fnose_pregame_surface => 'Keep the device on a stable surface';

  @override
  String get fnose_pregame_raiseRight => 'Raise the right side';

  @override
  String get fnose_pregame_raiseLeft => 'Raise the left side';

  @override
  String get fnose_pregame_tiltForward => 'Tilt further forward';

  @override
  String get fnose_pregame_tiltBack => 'Tilt further back';

  @override
  String get fnose_pregame_rollOk => 'Side leveling correct — hold…';

  @override
  String get fnose_pregame_pitchOk => 'Tilt correct — hold…';

  @override
  String get fnose_pregame_alignNose => 'Align your nose inside the marker';

  @override
  String get fnose_pregame_alignFinger =>
      'Place your index fingertip at the center of the target';

  @override
  String get fnose_game_saving => 'Saving match…';

  @override
  String get fnose_feedback_title => 'FNose Feedback';

  @override
  String get fnose_feedback_noResult => 'No result';

  @override
  String fnose_feedback_sparksCount(int count) {
    return '$count sparks';
  }

  @override
  String fnose_feedback_summary(int seconds, int left, int right) {
    return '${seconds}s · L $left · R $right';
  }

  @override
  String fnose_feedback_mode(String mode) {
    return 'Mode: $mode';
  }

  @override
  String fnose_feedback_avgAngle(String angle) {
    return 'Avg angle: $angle°';
  }

  @override
  String fnose_feedback_saved(String id) {
    return 'Saved · match $id…';
  }

  @override
  String fnose_feedback_saveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get fnose_feedback_notSaved => 'Not saved';

  @override
  String fnose_feedback_logs(int touches, int pose) {
    return 'logs: $touches touches · $pose pose';
  }

  @override
  String get fnose_gameover_title => 'FNose Game Over';

  @override
  String get fnose_gameover_finished => 'Match finished';

  @override
  String fnose_gameover_sparksInTime(int count, int seconds) {
    return '$count sparks in ${seconds}s';
  }

  @override
  String fnose_gameover_session(String id) {
    return 'Session $id…';
  }

  @override
  String get fnose_gameover_playAgain => 'Play again';

  @override
  String get fnose_gameover_home => 'Home';
}
