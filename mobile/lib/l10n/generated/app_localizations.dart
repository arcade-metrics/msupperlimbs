import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get common_email;

  /// No description provided for @common_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get common_password;

  /// No description provided for @common_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get common_name;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get common_retry;

  /// No description provided for @common_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String common_error(String error);

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'MS Upper Limbs Assessment'**
  String get app_title;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'MS Upper Limbs'**
  String get app_name;

  /// No description provided for @app_versionLabel.
  ///
  /// In en, this message translates to:
  /// **'MS Upper Limbs v{version}'**
  String app_versionLabel(String version);

  /// No description provided for @auth_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get auth_login;

  /// No description provided for @auth_signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get auth_signup;

  /// No description provided for @auth_createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get auth_createAccount;

  /// No description provided for @auth_noAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get auth_noAccountQuestion;

  /// No description provided for @auth_haveAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get auth_haveAccountQuestion;

  /// No description provided for @auth_consentCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I accept the data use consent'**
  String get auth_consentCheckbox;

  /// No description provided for @auth_consentRequired.
  ///
  /// In en, this message translates to:
  /// **'Consent is required'**
  String get auth_consentRequired;

  /// No description provided for @auth_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get auth_nameRequired;

  /// No description provided for @auth_emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get auth_emailInvalid;

  /// No description provided for @auth_passwordMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get auth_passwordMin;

  /// No description provided for @auth_loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get auth_loginSuccessful;

  /// No description provided for @auth_invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get auth_invalidCredentials;

  /// No description provided for @auth_accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get auth_accountCreatedSuccess;

  /// No description provided for @auth_failedToCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to create account.'**
  String get auth_failedToCreateAccount;

  /// No description provided for @auth_missingToken.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get auth_missingToken;

  /// No description provided for @home_title.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_title;

  /// No description provided for @home_fingerToNoseChallenge.
  ///
  /// In en, this message translates to:
  /// **'Finger-to-Nose Challenge'**
  String get home_fingerToNoseChallenge;

  /// No description provided for @home_rapidChallenge.
  ///
  /// In en, this message translates to:
  /// **'Rapid Challenge'**
  String get home_rapidChallenge;

  /// No description provided for @home_mediapipeDebug.
  ///
  /// In en, this message translates to:
  /// **'MediaPipe Debug'**
  String get home_mediapipeDebug;

  /// No description provided for @home_changeUser.
  ///
  /// In en, this message translates to:
  /// **'Change User'**
  String get home_changeUser;

  /// No description provided for @home_exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get home_exit;

  /// No description provided for @home_noUserLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'No user logged in'**
  String get home_noUserLoggedIn;

  /// No description provided for @camera_permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get camera_permissionDenied;

  /// No description provided for @camera_noneAvailable.
  ///
  /// In en, this message translates to:
  /// **'No camera available'**
  String get camera_noneAvailable;

  /// No description provided for @fnose_intro_title.
  ///
  /// In en, this message translates to:
  /// **'Finger-to-Nose'**
  String get fnose_intro_title;

  /// No description provided for @fnose_intro_errorLoadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error loading settings: {error}'**
  String fnose_intro_errorLoadingSettings(String error);

  /// No description provided for @fnose_intro_instructionVideo.
  ///
  /// In en, this message translates to:
  /// **'Instruction video'**
  String get fnose_intro_instructionVideo;

  /// No description provided for @fnose_intro_notImplemented.
  ///
  /// In en, this message translates to:
  /// **'(not implemented yet)'**
  String get fnose_intro_notImplemented;

  /// No description provided for @fnose_intro_hideOnNextTime.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show next time'**
  String get fnose_intro_hideOnNextTime;

  /// No description provided for @fnose_intro_changeGameMode.
  ///
  /// In en, this message translates to:
  /// **'Change game mode'**
  String get fnose_intro_changeGameMode;

  /// No description provided for @fnose_intro_start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get fnose_intro_start;

  /// No description provided for @fnose_intro_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get fnose_intro_settings;

  /// No description provided for @fnose_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Game mode'**
  String get fnose_mode_title;

  /// No description provided for @fnose_mode_chooseGameMode.
  ///
  /// In en, this message translates to:
  /// **'Choose mode'**
  String get fnose_mode_chooseGameMode;

  /// No description provided for @fnose_mode_leftHandOnly.
  ///
  /// In en, this message translates to:
  /// **'Left Hand Only'**
  String get fnose_mode_leftHandOnly;

  /// No description provided for @fnose_mode_leftHandOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Touch the nose and target with your left hand'**
  String get fnose_mode_leftHandOnlyDesc;

  /// No description provided for @fnose_mode_rightHandOnly.
  ///
  /// In en, this message translates to:
  /// **'Right Hand Only'**
  String get fnose_mode_rightHandOnly;

  /// No description provided for @fnose_mode_rightHandOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Touch the nose and target with your right hand'**
  String get fnose_mode_rightHandOnlyDesc;

  /// No description provided for @fnose_mode_bothHands.
  ///
  /// In en, this message translates to:
  /// **'Both Hands'**
  String get fnose_mode_bothHands;

  /// No description provided for @fnose_mode_bothHandsDesc.
  ///
  /// In en, this message translates to:
  /// **'Alternate between both hands'**
  String get fnose_mode_bothHandsDesc;

  /// No description provided for @fnose_mode_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get fnose_mode_continue;

  /// No description provided for @fnose_settings_title.
  ///
  /// In en, this message translates to:
  /// **'FNose Settings'**
  String get fnose_settings_title;

  /// No description provided for @fnose_settings_advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get fnose_settings_advancedSettings;

  /// No description provided for @fnose_settings_showInstructionVideo.
  ///
  /// In en, this message translates to:
  /// **'Show instruction video'**
  String get fnose_settings_showInstructionVideo;

  /// No description provided for @fnose_settings_totalTime.
  ///
  /// In en, this message translates to:
  /// **'Total time (s)'**
  String get fnose_settings_totalTime;

  /// No description provided for @fnose_settings_targetSize.
  ///
  /// In en, this message translates to:
  /// **'Target size (×)'**
  String get fnose_settings_targetSize;

  /// No description provided for @fnose_settings_settingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get fnose_settings_settingsUpdated;

  /// No description provided for @fnose_settings_defaultsRestored.
  ///
  /// In en, this message translates to:
  /// **'Defaults restored'**
  String get fnose_settings_defaultsRestored;

  /// No description provided for @fnose_settings_saveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String fnose_settings_saveError(String error);

  /// No description provided for @restoreDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get restoreDefaults;

  /// No description provided for @fnose_adv_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get fnose_adv_settings_title;

  /// No description provided for @fnose_adv_settings_updated.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings updated'**
  String get fnose_adv_settings_updated;

  /// No description provided for @fnose_adv_section_arm.
  ///
  /// In en, this message translates to:
  /// **'Arm tracking'**
  String get fnose_adv_section_arm;

  /// No description provided for @fnose_adv_section_target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get fnose_adv_section_target;

  /// No description provided for @fnose_adv_section_position.
  ///
  /// In en, this message translates to:
  /// **'Body positioning'**
  String get fnose_adv_section_position;

  /// No description provided for @fnose_adv_section_nose.
  ///
  /// In en, this message translates to:
  /// **'Nose alignment'**
  String get fnose_adv_section_nose;

  /// No description provided for @fnose_adv_section_stability.
  ///
  /// In en, this message translates to:
  /// **'Device stability'**
  String get fnose_adv_section_stability;

  /// No description provided for @fnose_pregame_keepStill.
  ///
  /// In en, this message translates to:
  /// **'Keep the phone still'**
  String get fnose_pregame_keepStill;

  /// No description provided for @fnose_pregame_tiltAndStill.
  ///
  /// In en, this message translates to:
  /// **'Tilt the phone (~90°) and keep still'**
  String get fnose_pregame_tiltAndStill;

  /// No description provided for @fnose_pregame_deviceStable.
  ///
  /// In en, this message translates to:
  /// **'Device stable — hold…'**
  String get fnose_pregame_deviceStable;

  /// No description provided for @fnose_pregame_motionDetected.
  ///
  /// In en, this message translates to:
  /// **'Motion detected — stabilize again'**
  String get fnose_pregame_motionDetected;

  /// No description provided for @fnose_pregame_positionPose.
  ///
  /// In en, this message translates to:
  /// **'Center your torso and nose in the camera'**
  String get fnose_pregame_positionPose;

  /// No description provided for @fnose_pregame_poseDetected.
  ///
  /// In en, this message translates to:
  /// **'Pose detected — hold position…'**
  String get fnose_pregame_poseDetected;

  /// No description provided for @fnose_pregame_poseLost.
  ///
  /// In en, this message translates to:
  /// **'Pose lost — reposition'**
  String get fnose_pregame_poseLost;

  /// No description provided for @fnose_pregame_calibrating.
  ///
  /// In en, this message translates to:
  /// **'Calibrating target…'**
  String get fnose_pregame_calibrating;

  /// No description provided for @fnose_pregame_surface.
  ///
  /// In en, this message translates to:
  /// **'Keep the device on a stable surface'**
  String get fnose_pregame_surface;

  /// No description provided for @fnose_pregame_raiseRight.
  ///
  /// In en, this message translates to:
  /// **'Raise the right side'**
  String get fnose_pregame_raiseRight;

  /// No description provided for @fnose_pregame_raiseLeft.
  ///
  /// In en, this message translates to:
  /// **'Raise the left side'**
  String get fnose_pregame_raiseLeft;

  /// No description provided for @fnose_pregame_tiltForward.
  ///
  /// In en, this message translates to:
  /// **'Tilt further forward'**
  String get fnose_pregame_tiltForward;

  /// No description provided for @fnose_pregame_tiltBack.
  ///
  /// In en, this message translates to:
  /// **'Tilt further back'**
  String get fnose_pregame_tiltBack;

  /// No description provided for @fnose_pregame_rollOk.
  ///
  /// In en, this message translates to:
  /// **'Side leveling correct — hold…'**
  String get fnose_pregame_rollOk;

  /// No description provided for @fnose_pregame_pitchOk.
  ///
  /// In en, this message translates to:
  /// **'Tilt correct — hold…'**
  String get fnose_pregame_pitchOk;

  /// No description provided for @fnose_pregame_alignNose.
  ///
  /// In en, this message translates to:
  /// **'Align your nose inside the marker'**
  String get fnose_pregame_alignNose;

  /// No description provided for @fnose_pregame_alignFinger.
  ///
  /// In en, this message translates to:
  /// **'Place your index fingertip at the center of the target'**
  String get fnose_pregame_alignFinger;

  /// No description provided for @fnose_game_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving match…'**
  String get fnose_game_saving;

  /// No description provided for @fnose_feedback_title.
  ///
  /// In en, this message translates to:
  /// **'FNose Feedback'**
  String get fnose_feedback_title;

  /// No description provided for @fnose_feedback_noResult.
  ///
  /// In en, this message translates to:
  /// **'No result'**
  String get fnose_feedback_noResult;

  /// No description provided for @fnose_feedback_sparksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sparks'**
  String fnose_feedback_sparksCount(int count);

  /// No description provided for @fnose_feedback_summary.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s · L {left} · R {right}'**
  String fnose_feedback_summary(int seconds, int left, int right);

  /// No description provided for @fnose_feedback_mode.
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}'**
  String fnose_feedback_mode(String mode);

  /// No description provided for @fnose_feedback_avgAngle.
  ///
  /// In en, this message translates to:
  /// **'Avg angle: {angle}°'**
  String fnose_feedback_avgAngle(String angle);

  /// No description provided for @fnose_feedback_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved · match {id}…'**
  String fnose_feedback_saved(String id);

  /// No description provided for @fnose_feedback_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String fnose_feedback_saveFailed(String error);

  /// No description provided for @fnose_feedback_notSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get fnose_feedback_notSaved;

  /// No description provided for @fnose_feedback_logs.
  ///
  /// In en, this message translates to:
  /// **'logs: {touches} touches · {pose} pose'**
  String fnose_feedback_logs(int touches, int pose);

  /// No description provided for @fnose_gameover_title.
  ///
  /// In en, this message translates to:
  /// **'FNose Game Over'**
  String get fnose_gameover_title;

  /// No description provided for @fnose_gameover_finished.
  ///
  /// In en, this message translates to:
  /// **'Match finished'**
  String get fnose_gameover_finished;

  /// No description provided for @fnose_gameover_sparksInTime.
  ///
  /// In en, this message translates to:
  /// **'{count} sparks in {seconds}s'**
  String fnose_gameover_sparksInTime(int count, int seconds);

  /// No description provided for @fnose_gameover_session.
  ///
  /// In en, this message translates to:
  /// **'Session {id}…'**
  String fnose_gameover_session(String id);

  /// No description provided for @fnose_gameover_playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get fnose_gameover_playAgain;

  /// No description provided for @fnose_gameover_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get fnose_gameover_home;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
