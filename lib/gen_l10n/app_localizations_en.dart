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
  String get common_save => 'Save';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_or => 'Or';

  @override
  String get common_email => 'Email';

  @override
  String get common_password => 'Password';

  @override
  String get auth_login => 'Login';

  @override
  String get auth_signup => 'Sign Up';

  @override
  String get auth_noAccountQuestion => 'Don\'t have an account?';

  @override
  String get auth_signInWithGoogle => 'Sign in with Google';

  @override
  String get auth_accountCreatedSuccess => 'Account created successfully!';

  @override
  String get auth_failedToCreateAccount => 'Failed to create account.';

  @override
  String get auth_loginSuccessful => 'Login successful!';

  @override
  String get auth_invalidCredentials => 'Invalid email or password.';

  @override
  String get auth_googleLoginSuccessful => 'Login with Google successful!';

  @override
  String get auth_googleLoginFailed => 'Login with Google failed.';

  @override
  String get consent_title => 'Consent';

  @override
  String get consent_requireConsent =>
      'You have been informed about the study by the research team and understand the purpose and procedures. No images or videos are recorded, only movement data is processed in real time.';

  @override
  String get consent_tickBelow =>
      'Please tick below if you have been adequately informed about this study, have no further questions, and would like to proceed.';

  @override
  String get consent_readFull =>
      'Read the full Participant Information Sheet and Consent Form';

  @override
  String get consent_checkboxText =>
      'I confirm that I have been informed by the research team and consent to participate in the study.';

  @override
  String get consent_exit => 'Exit';

  @override
  String get consent_proceed => 'Proceed';

  @override
  String get consent_participantInfo => 'Participant Information';

  @override
  String get consent_fullText =>
      'Space reserved for the complete Participant Information Sheet and Consent Form terms.';

  @override
  String get home_title => 'Home';

  @override
  String get home_fingerToNoseChallenge => 'Finger-to-Nose Challenge';

  @override
  String get home_sessionNotFound => 'Session not found!';

  @override
  String get home_changeUser => 'Change User';

  @override
  String get home_exit => 'Exit';

  @override
  String get home_noUserLoggedIn => 'No user logged in';

  @override
  String get fnose_intro_title => 'Finger-to-Nose Intro';

  @override
  String get fnose_intro_userNotFound => 'User not found';

  @override
  String get fnose_intro_errorLoadingSettings => 'Error loading settings:';

  @override
  String get fnose_intro_instructionVideo => 'Instruction Video';

  @override
  String get fnose_intro_notImplemented => 'Not Implemented';

  @override
  String get fnose_intro_hideOnNextTime => 'Hide on next time';

  @override
  String get fnose_intro_leftHandOnly => 'Left Hand Only';

  @override
  String get fnose_intro_rightHandOnly => 'Right Hand Only';

  @override
  String get fnose_intro_bothHands => 'Both Hands';

  @override
  String get fnose_intro_changeGameMode => 'Change Game Mode';

  @override
  String get fnose_intro_start => 'START';

  @override
  String get fnose_intro_settings => 'Settings';

  @override
  String get fnose_intro_instructions => 'Instructions';

  @override
  String get fnose_instructions_title => 'Instructions';

  @override
  String get fnose_instructions_userNotFound => 'User not found';

  @override
  String get fnose_instructions_placeholderText =>
      'This page is reserved for detailed instructions about the activity.\nIt is under development and will be implemented soon.';

  @override
  String get fnose_settings_title => 'Settings';

  @override
  String get fnose_settings_advancedSettings => 'Advanced Settings';

  @override
  String get fnose_settings_showInstructionVideo => 'Show Instruction Video';

  @override
  String get fnose_settings_settingsUpdated => 'Settings updated!';

  @override
  String get fnose_settings_consentRevoked => 'Consent revoked.';

  @override
  String get fnose_settings_removeFromPlatform => 'Remove from Platform';

  @override
  String get fnose_settings_exportMyData => 'Export My Data';

  @override
  String get fnose_adv_settings_title => 'Advanced Settings';

  @override
  String get fnose_adv_settings_advancedSettingsUpdated =>
      'Advanced Settings updated!';

  @override
  String get changeUser => 'Change User';

  @override
  String get exit => 'Exit';

  @override
  String get back => 'Back';

  @override
  String get start => 'Start';

  @override
  String get settings => 'Settings';

  @override
  String get instructions => 'Instructions';

  @override
  String get fingerToNoseChallenge => 'Finger-to-Nose Challenge';

  @override
  String get fingerToNoseIntro => 'Finger-to-Nose Intro';

  @override
  String get hideOnNextTime => 'Hide on next time';

  @override
  String get leftHandOnly => 'Left Hand Only';

  @override
  String get rightHandOnly => 'Right Hand Only';

  @override
  String get changeGameMode => 'Change Game Mode';

  @override
  String get notImplemented => 'Not Implemented';

  @override
  String get instructionVideo => 'Instruction Video';

  @override
  String get showInstructionVideo => 'Show Instruction Video';

  @override
  String get totalTimeSec => 'Total Time (sec)';

  @override
  String get update => 'Update';

  @override
  String get restoreDefaults => 'Restore defaults';

  @override
  String get dataPrivacy => 'Data & Privacy';

  @override
  String get revokeMyConsent => 'Revoke My Consent';

  @override
  String get revokeFromPlatform => 'Revoke from Platform';

  @override
  String get exportMyData => 'Export My Data';

  @override
  String get armTrackingSettings => 'Arm Tracking Settings';

  @override
  String get armFlexionThreshold => 'Arm Flexion Threshold';

  @override
  String get armFlexionThresholdDesc =>
      'Minimum elbow angle to be considered a flexed arm';

  @override
  String get armExtensionThreshold => 'Arm Extension Threshold';

  @override
  String get armExtensionThresholdDesc =>
      'Maximum elbow angle to detect full extension';

  @override
  String get horizontalElbowShoulderDistanceThreshold =>
      'Horizontal Elbow/Shoulder Distance Threshold';

  @override
  String get horizontalElbowShoulderDistanceThresholdDesc =>
      '(Disabled) Max allowed horizontal distance between elbow and shoulder (how far the arm is opened sideways)';

  @override
  String get verticalElbowShoulderDistanceThreshold =>
      'Vertical Elbow/Shoulder Distance Threshold';

  @override
  String get verticalElbowShoulderDistanceThresholdDesc =>
      '(Disabled) Max allowed vertical distance between elbow and shoulder (how high or low the elbow is positioned)';

  @override
  String get distanceToNoseThreshold => 'Distance to nose threshold';

  @override
  String get distanceToNoseThresholdDesc =>
      'Maximum distance between index and nose to register a nose touch (in normalized units)';

  @override
  String get minElbowAngleChange =>
      'Minimum Elbow angle change for movement detection';

  @override
  String get minElbowAngleChangeDesc =>
      'Minimum Elbow angular change required to trigger movement detection';

  @override
  String get minShoulderAngleChange =>
      'Minimum shoulder angle change for movement detection';

  @override
  String get minShoulderAngleChangeDesc =>
      'Minimum shoulder angular change required to trigger movement detection';

  @override
  String get angleBufferSize => 'Angle Buffer Size';

  @override
  String get angleBufferSizeDesc =>
      'Number of recent angles stored to detect direction changes. Higher numbers are more stable and less sensitive.';

  @override
  String get minDistanceToTarget => 'Minimum distance to target';

  @override
  String get minDistanceToTargetDesc =>
      'Minimum distance to the target required to register a hit (in normalized units)';

  @override
  String get selectTargetModel => 'Select Target Model';

  @override
  String get selectTargetSize => 'Select Target Size';

  @override
  String get small => 'Small';

  @override
  String get targetSize => 'Target Size';

  @override
  String get big => 'Big';

  @override
  String get targetSettings => 'Target Settings';

  @override
  String get targetHorizontalPosition => 'Target Horizontal Position';

  @override
  String get targetHorizontalPositionDesc =>
      'Distance from screen edge to target edge (0.0 = at edge, 0.5 = at centre). Left hand: left edge; Right hand: right edge.';

  @override
  String get targetVerticalPosition => 'Target Vertical Position';

  @override
  String get targetVerticalPositionDesc =>
      'Vertical screen position of the target (0.0 = top; 1.0 = bottom)';

  @override
  String get userPositioningSettings => 'User Positioning Settings';

  @override
  String get minScreenDistance => 'Min Screen Distance';

  @override
  String get minScreenDistanceDesc =>
      'Minimum distance from device for a correct positioning';

  @override
  String get maxScreenDistance => 'Maximum Screen Distance';

  @override
  String get maxScreenDistanceDesc =>
      'Maximum distance from device for a correct positioning';

  @override
  String get shoulderVerticalAlignmentThreshold =>
      'Shoulder Vertical Alignment Threshold';

  @override
  String get shoulderVerticalAlignmentThresholdDesc =>
      'Maximum vertical difference allowed between shoulders';

  @override
  String get trunkAxialAlignmentThreshold => 'Trunk axial alignment threshold';

  @override
  String get trunkAxialAlignmentThresholdDesc =>
      'Maximum allowed trunk rotation for correct alignment';

  @override
  String get userScreenAlignmentThreshold => 'User Screen alignment threshold';

  @override
  String get userScreenAlignmentThresholdDesc =>
      'Maximum deviation allowed from best screen position';

  @override
  String get noseAlignmentPositionX => 'Nose Alignment Position X';

  @override
  String get noseAlignmentPositionY => 'Nose Alignment Position Y';

  @override
  String get noseAlignmentPositionXDesc =>
      'Horizontal position as % of screen width (0.75 = 75% from left edge)';

  @override
  String get noseAlignmentPositionYDesc =>
      'Target vertical position for nose alignment (0 = top, 1 = bottom)';

  @override
  String get noseAlignmentThreshold => 'Nose alignment threshold';

  @override
  String get noseAlignmentThresholdDesc =>
      'Tolerance for nose alignment validation';

  @override
  String get noseAlignmentTargetRadius => 'Alignment Target Visual Radius';

  @override
  String get noseAlignmentTargetRadiusDesc =>
      'Visual size of the indicator circle on screen (% of width). Can be larger than validation threshold.';

  @override
  String get movementSensitivity =>
      'Movement Sensitivity (moving Average Frames)';

  @override
  String get movementSensitivityDesc =>
      'Higher values smooth movements; lower values make the alignment react faster. Recommended range: 10-30 frames.';

  @override
  String get devicePositioningSettings => 'Device positioning settings';

  @override
  String get stabilitySettings => 'Stability Settings';

  @override
  String get stabilityThreshold => 'Stability threshold';

  @override
  String get stabilityThresholdDesc =>
      'Maximum allowed movement for device to be considered stable';

  @override
  String get requiredStableTime => 'Required Stable Time (ms)';

  @override
  String get requiredStableTimeDesc =>
      'Minimum time the device must stay stable before accepting alignment';

  @override
  String get eventThrottle => 'Event Throttle (ms)';

  @override
  String get eventThrottleDesc =>
      'Minimum time between two consecutive updates. Higher values reduce update frequency.';

  @override
  String get updateBounce => 'Update bounce (ms)';

  @override
  String get updateBounceDesc =>
      'Delay after last movement before updating stability checks';

  @override
  String get angleWindow => 'Angle window (seconds)';

  @override
  String get angleWindowDesc =>
      'Time window used to average the tilt angle measurements';

  @override
  String get minAngle => 'Min angle';

  @override
  String get minAngleDesc =>
      'Minimum device angle allowed for proper alignment';

  @override
  String get maxAngle => 'Max angle';

  @override
  String get maxAngleDesc =>
      'Maximum device tilt angle allowed for proper alignment';

  @override
  String get alpha => 'Alpha';

  @override
  String get alphaDesc =>
      'Weighting factor for smoothing sensor data (decimal 0 to 1) higher values are smoother.';

  @override
  String get fnose_mode_title => 'Select Game Mode';

  @override
  String get fnose_mode_chooseGameMode => 'Choose your game mode:';

  @override
  String get fnose_mode_leftHandOnly => 'Left Hand Only';

  @override
  String get fnose_mode_leftHandOnlyDesc =>
      'Use only your left hand to hit the targets';

  @override
  String get fnose_mode_rightHandOnly => 'Right Hand Only';

  @override
  String get fnose_mode_rightHandOnlyDesc =>
      'Use only your right hand to hit the targets';

  @override
  String get fnose_mode_bothHands => 'Both Hands';

  @override
  String get fnose_mode_bothHandsDesc => 'Use any hand to hit the targets';

  @override
  String get fnose_mode_continue => 'Continue';

  @override
  String get fnose_feedback_wellDone => '🎉 Well Done! 🎉';

  @override
  String get fnose_feedback_missionComplete => 'Mission Complete!';

  @override
  String get fnose_gameover_title => 'Game Over';

  @override
  String get fnose_gameover_noMatchData => 'No match data available.';

  @override
  String get fnose_gameover_totalTime => '⏱️ Total time';

  @override
  String get fnose_gameover_leftTouches => '👈 Left touches';

  @override
  String get fnose_gameover_rightTouches => '👉 Right touches';

  @override
  String get fnose_gameover_totalTouches => '🎯 Total touches';

  @override
  String get fnose_gameover_matchStatistics => '📊 Match Statistics';

  @override
  String get fnose_gameover_avgTouchTime => '⚡ Avg Touch Time';

  @override
  String get fnose_gameover_avgDistance => '📏 Avg Distance';

  @override
  String get fnose_gameover_avgAngle => '📐 Avg Angle';

  @override
  String get fnose_gameover_timeCV => '⏱️ Time CV';

  @override
  String get fnose_gameover_distanceCV => '📏 Distance CV';

  @override
  String get fnose_gameover_angleCV => '📐 Angle CV';

  @override
  String get fnose_gameover_precisionIndex => '🎯 Precision Index';

  @override
  String get fnose_gameover_consistencyIndex => '🔄 Consistency Index';

  @override
  String get fnose_gameover_touchHeatmap => 'Touch Heatmap';

  @override
  String get fnose_gameover_performanceTrend =>
      '📈 Performance Trend (Last 5 Matches)';

  @override
  String get fnose_gameover_noPreviousMatches =>
      'No previous matches available';

  @override
  String get fnose_gameover_performanceComparison =>
      '📊 Performance Comparison';

  @override
  String get fnose_gameover_noGlobalStats => 'No global stats available';

  @override
  String get fnose_gameover_noCurrentMatchData => 'No current match data';

  @override
  String get fnose_gameover_precisionGauge => '🎯 Precision Gauge';

  @override
  String get fnose_gameover_precisionDataNotAvailable =>
      'Precision data not available';

  @override
  String get fnose_gameover_errorLoadingTouchData =>
      'Error loading touch data:';

  @override
  String get fnose_gameover_touchTime => '⚡ Touch Time (s)';

  @override
  String get fnose_gameover_accuracy => '🎯 Accuracy (%)';

  @override
  String get fnose_gameover_distance => '📏 Distance (%)';

  @override
  String get fnose_gameover_you => 'You:';

  @override
  String get fnose_gameover_avg => 'Avg:';

  @override
  String get fnose_gameover_global => 'Global:';

  @override
  String get fnose_gameover_home => 'Home';

  @override
  String get fnose_gameover_playAgain => 'Play Again';

  @override
  String get fnose_gameover_exit => 'Exit';

  @override
  String get validation_positionFound => 'POSITION FOUND!';

  @override
  String get validation_adjustYourPosition => 'Adjust your position';

  @override
  String get validation_screenDistance => 'Screen Distance';

  @override
  String get validation_shoulderYAlign => 'Shoulder Y-Align';

  @override
  String get validation_depthZAlign => 'Depth Z-Align';

  @override
  String get validation_positionCentered => 'Position Centered';

  @override
  String get stability_stablePositionFound => 'STABLE POSITION FOUND';

  @override
  String get stability_tiltPhoneUp => 'TILT YOUR PHONE UP A BIT';

  @override
  String get stability_tiltPhoneDown => 'TILT YOUR PHONE DOWN A BIT';

  @override
  String get stability_keepDeviceStable =>
      'KEEP YOUR DEVICE IN A STABLE POSITION';

  @override
  String get stability_go => 'GO!';

  @override
  String get stability_errorCheckingAngle => 'Error checking angle:';

  @override
  String get stability_errorCheckingStability => 'Error checking stability:';

  @override
  String get app_title => 'MS Upper Limbs Assessment';

  @override
  String get app_subtitle => '☂️ for Umbrella app v';

  @override
  String get app_name => 'MS Upper Limbs';

  @override
  String get position_moveCloser => 'MOVE A LITTLE CLOSER';

  @override
  String get position_moveFarther => 'MOVE A LITTLE FAR';

  @override
  String get position_faceDevice => 'FACE THE DEVICE DIRECTLY';

  @override
  String get position_alignShoulders => 'ALIGN SHOULDERS';

  @override
  String get position_moveLeft => 'MOVE FURTHER TO THE LEFT';

  @override
  String get position_moveRight => 'MOVE FURTHER TO THE RIGHT';

  @override
  String get position_moveDown => 'MOVE FURTHER DOWN';

  @override
  String get position_moveUp => 'MOVE FURTHER UP';

  @override
  String get position_positionFound => 'POSITION FOUND!';

  @override
  String get position_faceAndShouldersNotVisible =>
      'Please, make sure your face and shoulders are visible';

  @override
  String get position_noseClose => 'MOVE YOUR FACE A LITTLE CLOSER';

  @override
  String get position_noseFar => 'ALIGN YOUR FACE WITH THE CIRCLE';

  @override
  String get adjust_position_title => 'Adjust Your Position';

  @override
  String get calibration_calibratingTarget => 'CALIBRATING TARGET';

  @override
  String get calibration_holdPosition => '✅ HOLD THIS POSITION';

  @override
  String get calibration_startingIn => 'STARTING IN...';

  @override
  String get gameover_histogram_title =>
      '⏱️ Interval between touches (dynamic bins)';

  @override
  String get gameover_histogram_notEnoughTouches =>
      'Not enough touches to show histogram.';

  @override
  String get gameover_distribution_title => '📈 Touch Interval Distribution';

  @override
  String get gameover_distribution_notEnoughTouches =>
      'Not enough touches to show distribution.';

  @override
  String gameover_distribution_range(Object end, Object start) {
    return '$start–$end';
  }

  @override
  String gameover_distribution_range_ms(Object end, Object start) {
    return '$start–$end ms';
  }

  @override
  String error_generic(Object error) {
    return 'Error: $error';
  }

  @override
  String get error_loading => 'Loading...';

  @override
  String get camera_calibration_calibrating => 'CALIBRATING CAMERA...';

  @override
  String camera_calibration_testingConfig(int current, int total) {
    return 'TESTING CONFIGURATION $current/$total...';
  }

  @override
  String get camera_calibration_complete => 'CALIBRATION COMPLETE!';

  @override
  String get camera_calibration_failed => 'LANDMARKS NOT DETECTED';

  @override
  String get camera_calibration_failedMessage =>
      'Position yourself facing the camera and try again.';

  @override
  String camera_calibration_seconds(int seconds) {
    return '$seconds / 10 SECONDS';
  }
}
