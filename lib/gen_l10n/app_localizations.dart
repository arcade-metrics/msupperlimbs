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
/// import 'gen_l10n/app_localizations.dart';
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
    Locale('pt')
  ];

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

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

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_or.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get common_or;

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

  /// No description provided for @auth_noAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get auth_noAccountQuestion;

  /// No description provided for @auth_signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get auth_signInWithGoogle;

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

  /// No description provided for @auth_googleLoginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login with Google successful!'**
  String get auth_googleLoginSuccessful;

  /// No description provided for @auth_googleLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login with Google failed.'**
  String get auth_googleLoginFailed;

  /// No description provided for @consent_title.
  ///
  /// In en, this message translates to:
  /// **'Consent'**
  String get consent_title;

  /// No description provided for @consent_requireConsent.
  ///
  /// In en, this message translates to:
  /// **'You have been informed about the study by the research team and understand the purpose and procedures. No images or videos are recorded, only movement data is processed in real time.'**
  String get consent_requireConsent;

  /// No description provided for @consent_tickBelow.
  ///
  /// In en, this message translates to:
  /// **'Please tick below if you have been adequately informed about this study, have no further questions, and would like to proceed.'**
  String get consent_tickBelow;

  /// No description provided for @consent_readFull.
  ///
  /// In en, this message translates to:
  /// **'Read the full Participant Information Sheet and Consent Form'**
  String get consent_readFull;

  /// No description provided for @consent_checkboxText.
  ///
  /// In en, this message translates to:
  /// **'I confirm that I have been informed by the research team and consent to participate in the study.'**
  String get consent_checkboxText;

  /// No description provided for @consent_exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get consent_exit;

  /// No description provided for @consent_proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get consent_proceed;

  /// No description provided for @consent_participantInfo.
  ///
  /// In en, this message translates to:
  /// **'Participant Information'**
  String get consent_participantInfo;

  /// No description provided for @consent_fullText.
  ///
  /// In en, this message translates to:
  /// **'Space reserved for the complete Participant Information Sheet and Consent Form terms.'**
  String get consent_fullText;

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

  /// No description provided for @home_sessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Session not found!'**
  String get home_sessionNotFound;

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

  /// No description provided for @fnose_intro_title.
  ///
  /// In en, this message translates to:
  /// **'Finger-to-Nose Intro'**
  String get fnose_intro_title;

  /// No description provided for @fnose_intro_userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get fnose_intro_userNotFound;

  /// No description provided for @fnose_intro_errorLoadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error loading settings:'**
  String get fnose_intro_errorLoadingSettings;

  /// No description provided for @fnose_intro_instructionVideo.
  ///
  /// In en, this message translates to:
  /// **'Instruction Video'**
  String get fnose_intro_instructionVideo;

  /// No description provided for @fnose_intro_notImplemented.
  ///
  /// In en, this message translates to:
  /// **'Not Implemented'**
  String get fnose_intro_notImplemented;

  /// No description provided for @fnose_intro_hideOnNextTime.
  ///
  /// In en, this message translates to:
  /// **'Hide on next time'**
  String get fnose_intro_hideOnNextTime;

  /// No description provided for @fnose_intro_leftHandOnly.
  ///
  /// In en, this message translates to:
  /// **'Left Hand Only'**
  String get fnose_intro_leftHandOnly;

  /// No description provided for @fnose_intro_rightHandOnly.
  ///
  /// In en, this message translates to:
  /// **'Right Hand Only'**
  String get fnose_intro_rightHandOnly;

  /// No description provided for @fnose_intro_bothHands.
  ///
  /// In en, this message translates to:
  /// **'Both Hands'**
  String get fnose_intro_bothHands;

  /// No description provided for @fnose_intro_changeGameMode.
  ///
  /// In en, this message translates to:
  /// **'Change Game Mode'**
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

  /// No description provided for @fnose_intro_instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get fnose_intro_instructions;

  /// No description provided for @fnose_instructions_title.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get fnose_instructions_title;

  /// No description provided for @fnose_instructions_userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get fnose_instructions_userNotFound;

  /// No description provided for @fnose_instructions_placeholderText.
  ///
  /// In en, this message translates to:
  /// **'This page is reserved for detailed instructions about the activity.\nIt is under development and will be implemented soon.'**
  String get fnose_instructions_placeholderText;

  /// No description provided for @fnose_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get fnose_settings_title;

  /// No description provided for @fnose_settings_advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get fnose_settings_advancedSettings;

  /// No description provided for @fnose_settings_showInstructionVideo.
  ///
  /// In en, this message translates to:
  /// **'Show Instruction Video'**
  String get fnose_settings_showInstructionVideo;

  /// No description provided for @fnose_settings_settingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings updated!'**
  String get fnose_settings_settingsUpdated;

  /// No description provided for @fnose_settings_consentRevoked.
  ///
  /// In en, this message translates to:
  /// **'Consent revoked.'**
  String get fnose_settings_consentRevoked;

  /// No description provided for @fnose_settings_removeFromPlatform.
  ///
  /// In en, this message translates to:
  /// **'Remove from Platform'**
  String get fnose_settings_removeFromPlatform;

  /// No description provided for @fnose_settings_exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export My Data'**
  String get fnose_settings_exportMyData;

  /// No description provided for @fnose_adv_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get fnose_adv_settings_title;

  /// No description provided for @fnose_adv_settings_advancedSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings updated!'**
  String get fnose_adv_settings_advancedSettingsUpdated;

  /// No description provided for @changeUser.
  ///
  /// In en, this message translates to:
  /// **'Change User'**
  String get changeUser;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @fingerToNoseChallenge.
  ///
  /// In en, this message translates to:
  /// **'Finger-to-Nose Challenge'**
  String get fingerToNoseChallenge;

  /// No description provided for @fingerToNoseIntro.
  ///
  /// In en, this message translates to:
  /// **'Finger-to-Nose Intro'**
  String get fingerToNoseIntro;

  /// No description provided for @hideOnNextTime.
  ///
  /// In en, this message translates to:
  /// **'Hide on next time'**
  String get hideOnNextTime;

  /// No description provided for @leftHandOnly.
  ///
  /// In en, this message translates to:
  /// **'Left Hand Only'**
  String get leftHandOnly;

  /// No description provided for @rightHandOnly.
  ///
  /// In en, this message translates to:
  /// **'Right Hand Only'**
  String get rightHandOnly;

  /// No description provided for @changeGameMode.
  ///
  /// In en, this message translates to:
  /// **'Change Game Mode'**
  String get changeGameMode;

  /// No description provided for @notImplemented.
  ///
  /// In en, this message translates to:
  /// **'Not Implemented'**
  String get notImplemented;

  /// No description provided for @instructionVideo.
  ///
  /// In en, this message translates to:
  /// **'Instruction Video'**
  String get instructionVideo;

  /// No description provided for @showInstructionVideo.
  ///
  /// In en, this message translates to:
  /// **'Show Instruction Video'**
  String get showInstructionVideo;

  /// No description provided for @totalTimeSec.
  ///
  /// In en, this message translates to:
  /// **'Total Time (sec)'**
  String get totalTimeSec;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @restoreDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get restoreDefaults;

  /// No description provided for @dataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get dataPrivacy;

  /// No description provided for @revokeMyConsent.
  ///
  /// In en, this message translates to:
  /// **'Revoke My Consent'**
  String get revokeMyConsent;

  /// No description provided for @revokeFromPlatform.
  ///
  /// In en, this message translates to:
  /// **'Revoke from Platform'**
  String get revokeFromPlatform;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export My Data'**
  String get exportMyData;

  /// No description provided for @armTrackingSettings.
  ///
  /// In en, this message translates to:
  /// **'Arm Tracking Settings'**
  String get armTrackingSettings;

  /// No description provided for @armFlexionThreshold.
  ///
  /// In en, this message translates to:
  /// **'Arm Flexion Threshold'**
  String get armFlexionThreshold;

  /// No description provided for @armFlexionThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimum elbow angle to be considered a flexed arm'**
  String get armFlexionThresholdDesc;

  /// No description provided for @armExtensionThreshold.
  ///
  /// In en, this message translates to:
  /// **'Arm Extension Threshold'**
  String get armExtensionThreshold;

  /// No description provided for @armExtensionThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum elbow angle to detect full extension'**
  String get armExtensionThresholdDesc;

  /// No description provided for @horizontalElbowShoulderDistanceThreshold.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Elbow/Shoulder Distance Threshold'**
  String get horizontalElbowShoulderDistanceThreshold;

  /// No description provided for @horizontalElbowShoulderDistanceThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'(Disabled) Max allowed horizontal distance between elbow and shoulder (how far the arm is opened sideways)'**
  String get horizontalElbowShoulderDistanceThresholdDesc;

  /// No description provided for @verticalElbowShoulderDistanceThreshold.
  ///
  /// In en, this message translates to:
  /// **'Vertical Elbow/Shoulder Distance Threshold'**
  String get verticalElbowShoulderDistanceThreshold;

  /// No description provided for @verticalElbowShoulderDistanceThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'(Disabled) Max allowed vertical distance between elbow and shoulder (how high or low the elbow is positioned)'**
  String get verticalElbowShoulderDistanceThresholdDesc;

  /// No description provided for @distanceToNoseThreshold.
  ///
  /// In en, this message translates to:
  /// **'Distance to nose threshold'**
  String get distanceToNoseThreshold;

  /// No description provided for @distanceToNoseThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum distance between index and nose to register a nose touch (in normalized units)'**
  String get distanceToNoseThresholdDesc;

  /// No description provided for @minElbowAngleChange.
  ///
  /// In en, this message translates to:
  /// **'Minimum Elbow angle change for movement detection'**
  String get minElbowAngleChange;

  /// No description provided for @minElbowAngleChangeDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimum Elbow angular change required to trigger movement detection'**
  String get minElbowAngleChangeDesc;

  /// No description provided for @minShoulderAngleChange.
  ///
  /// In en, this message translates to:
  /// **'Minimum shoulder angle change for movement detection'**
  String get minShoulderAngleChange;

  /// No description provided for @minShoulderAngleChangeDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimum shoulder angular change required to trigger movement detection'**
  String get minShoulderAngleChangeDesc;

  /// No description provided for @angleBufferSize.
  ///
  /// In en, this message translates to:
  /// **'Angle Buffer Size'**
  String get angleBufferSize;

  /// No description provided for @angleBufferSizeDesc.
  ///
  /// In en, this message translates to:
  /// **'Number of recent angles stored to detect direction changes. Higher numbers are more stable and less sensitive.'**
  String get angleBufferSizeDesc;

  /// No description provided for @minDistanceToTarget.
  ///
  /// In en, this message translates to:
  /// **'Minimum distance to target'**
  String get minDistanceToTarget;

  /// No description provided for @minDistanceToTargetDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimum distance to the target required to register a hit (in normalized units)'**
  String get minDistanceToTargetDesc;

  /// No description provided for @selectTargetModel.
  ///
  /// In en, this message translates to:
  /// **'Select Target Model'**
  String get selectTargetModel;

  /// No description provided for @selectTargetSize.
  ///
  /// In en, this message translates to:
  /// **'Select Target Size'**
  String get selectTargetSize;

  /// No description provided for @small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// No description provided for @targetSize.
  ///
  /// In en, this message translates to:
  /// **'Target Size'**
  String get targetSize;

  /// No description provided for @big.
  ///
  /// In en, this message translates to:
  /// **'Big'**
  String get big;

  /// No description provided for @targetSettings.
  ///
  /// In en, this message translates to:
  /// **'Target Settings'**
  String get targetSettings;

  /// No description provided for @targetHorizontalPosition.
  ///
  /// In en, this message translates to:
  /// **'Target Horizontal Position'**
  String get targetHorizontalPosition;

  /// No description provided for @targetHorizontalPositionDesc.
  ///
  /// In en, this message translates to:
  /// **'Distance from screen edge to target edge (0.0 = at edge, 0.5 = at centre). Left hand: left edge; Right hand: right edge.'**
  String get targetHorizontalPositionDesc;

  /// No description provided for @targetVerticalPosition.
  ///
  /// In en, this message translates to:
  /// **'Target Vertical Position'**
  String get targetVerticalPosition;

  /// No description provided for @targetVerticalPositionDesc.
  ///
  /// In en, this message translates to:
  /// **'Vertical screen position of the target (0.0 = top; 1.0 = bottom)'**
  String get targetVerticalPositionDesc;

  /// No description provided for @userPositioningSettings.
  ///
  /// In en, this message translates to:
  /// **'User Positioning Settings'**
  String get userPositioningSettings;

  /// No description provided for @minScreenDistance.
  ///
  /// In en, this message translates to:
  /// **'Min Screen Distance'**
  String get minScreenDistance;

  /// No description provided for @minScreenDistanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimum distance from device for a correct positioning'**
  String get minScreenDistanceDesc;

  /// No description provided for @maxScreenDistance.
  ///
  /// In en, this message translates to:
  /// **'Maximum Screen Distance'**
  String get maxScreenDistance;

  /// No description provided for @maxScreenDistanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum distance from device for a correct positioning'**
  String get maxScreenDistanceDesc;

  /// No description provided for @shoulderVerticalAlignmentThreshold.
  ///
  /// In en, this message translates to:
  /// **'Shoulder Vertical Alignment Threshold'**
  String get shoulderVerticalAlignmentThreshold;

  /// No description provided for @shoulderVerticalAlignmentThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum vertical difference allowed between shoulders'**
  String get shoulderVerticalAlignmentThresholdDesc;

  /// No description provided for @trunkAxialAlignmentThreshold.
  ///
  /// In en, this message translates to:
  /// **'Trunk axial alignment threshold'**
  String get trunkAxialAlignmentThreshold;

  /// No description provided for @trunkAxialAlignmentThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum allowed trunk rotation for correct alignment'**
  String get trunkAxialAlignmentThresholdDesc;

  /// No description provided for @userScreenAlignmentThreshold.
  ///
  /// In en, this message translates to:
  /// **'User Screen alignment threshold'**
  String get userScreenAlignmentThreshold;

  /// No description provided for @userScreenAlignmentThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum deviation allowed from best screen position'**
  String get userScreenAlignmentThresholdDesc;

  /// No description provided for @noseAlignmentPositionX.
  ///
  /// In en, this message translates to:
  /// **'Nose Alignment Position X'**
  String get noseAlignmentPositionX;

  /// No description provided for @noseAlignmentPositionY.
  ///
  /// In en, this message translates to:
  /// **'Nose Alignment Position Y'**
  String get noseAlignmentPositionY;

  /// No description provided for @noseAlignmentPositionXDesc.
  ///
  /// In en, this message translates to:
  /// **'Horizontal position as % of screen width (0.75 = 75% from left edge)'**
  String get noseAlignmentPositionXDesc;

  /// No description provided for @noseAlignmentPositionYDesc.
  ///
  /// In en, this message translates to:
  /// **'Target vertical position for nose alignment (0 = top, 1 = bottom)'**
  String get noseAlignmentPositionYDesc;

  /// No description provided for @noseAlignmentThreshold.
  ///
  /// In en, this message translates to:
  /// **'Nose alignment threshold'**
  String get noseAlignmentThreshold;

  /// No description provided for @noseAlignmentThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Tolerance for nose alignment validation'**
  String get noseAlignmentThresholdDesc;

  /// No description provided for @noseAlignmentTargetRadius.
  ///
  /// In en, this message translates to:
  /// **'Alignment Target Visual Radius'**
  String get noseAlignmentTargetRadius;

  /// No description provided for @noseAlignmentTargetRadiusDesc.
  ///
  /// In en, this message translates to:
  /// **'Visual size of the indicator circle on screen (% of width). Can be larger than validation threshold.'**
  String get noseAlignmentTargetRadiusDesc;

  /// No description provided for @movementSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Movement Sensitivity (moving Average Frames)'**
  String get movementSensitivity;

  /// No description provided for @movementSensitivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Higher values smooth movements; lower values make the alignment react faster. Recommended range: 10-30 frames.'**
  String get movementSensitivityDesc;

  /// No description provided for @devicePositioningSettings.
  ///
  /// In en, this message translates to:
  /// **'Device positioning settings'**
  String get devicePositioningSettings;

  /// No description provided for @stabilitySettings.
  ///
  /// In en, this message translates to:
  /// **'Stability Settings'**
  String get stabilitySettings;

  /// No description provided for @stabilityThreshold.
  ///
  /// In en, this message translates to:
  /// **'Stability threshold'**
  String get stabilityThreshold;

  /// No description provided for @stabilityThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum allowed movement for device to be considered stable'**
  String get stabilityThresholdDesc;

  /// No description provided for @requiredStableTime.
  ///
  /// In en, this message translates to:
  /// **'Required Stable Time (ms)'**
  String get requiredStableTime;

  /// No description provided for @requiredStableTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimum time the device must stay stable before accepting alignment'**
  String get requiredStableTimeDesc;

  /// No description provided for @eventThrottle.
  ///
  /// In en, this message translates to:
  /// **'Event Throttle (ms)'**
  String get eventThrottle;

  /// No description provided for @eventThrottleDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimum time between two consecutive updates. Higher values reduce update frequency.'**
  String get eventThrottleDesc;

  /// No description provided for @updateBounce.
  ///
  /// In en, this message translates to:
  /// **'Update bounce (ms)'**
  String get updateBounce;

  /// No description provided for @updateBounceDesc.
  ///
  /// In en, this message translates to:
  /// **'Delay after last movement before updating stability checks'**
  String get updateBounceDesc;

  /// No description provided for @angleWindow.
  ///
  /// In en, this message translates to:
  /// **'Angle window (seconds)'**
  String get angleWindow;

  /// No description provided for @angleWindowDesc.
  ///
  /// In en, this message translates to:
  /// **'Time window used to average the tilt angle measurements'**
  String get angleWindowDesc;

  /// No description provided for @minAngle.
  ///
  /// In en, this message translates to:
  /// **'Min angle'**
  String get minAngle;

  /// No description provided for @minAngleDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimum device angle allowed for proper alignment'**
  String get minAngleDesc;

  /// No description provided for @maxAngle.
  ///
  /// In en, this message translates to:
  /// **'Max angle'**
  String get maxAngle;

  /// No description provided for @maxAngleDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum device tilt angle allowed for proper alignment'**
  String get maxAngleDesc;

  /// No description provided for @alpha.
  ///
  /// In en, this message translates to:
  /// **'Alpha'**
  String get alpha;

  /// No description provided for @alphaDesc.
  ///
  /// In en, this message translates to:
  /// **'Weighting factor for smoothing sensor data (decimal 0 to 1) higher values are smoother.'**
  String get alphaDesc;

  /// No description provided for @fnose_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Select Game Mode'**
  String get fnose_mode_title;

  /// No description provided for @fnose_mode_chooseGameMode.
  ///
  /// In en, this message translates to:
  /// **'Choose your game mode:'**
  String get fnose_mode_chooseGameMode;

  /// No description provided for @fnose_mode_leftHandOnly.
  ///
  /// In en, this message translates to:
  /// **'Left Hand Only'**
  String get fnose_mode_leftHandOnly;

  /// No description provided for @fnose_mode_leftHandOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Use only your left hand to hit the targets'**
  String get fnose_mode_leftHandOnlyDesc;

  /// No description provided for @fnose_mode_rightHandOnly.
  ///
  /// In en, this message translates to:
  /// **'Right Hand Only'**
  String get fnose_mode_rightHandOnly;

  /// No description provided for @fnose_mode_rightHandOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Use only your right hand to hit the targets'**
  String get fnose_mode_rightHandOnlyDesc;

  /// No description provided for @fnose_mode_bothHands.
  ///
  /// In en, this message translates to:
  /// **'Both Hands'**
  String get fnose_mode_bothHands;

  /// No description provided for @fnose_mode_bothHandsDesc.
  ///
  /// In en, this message translates to:
  /// **'Use any hand to hit the targets'**
  String get fnose_mode_bothHandsDesc;

  /// No description provided for @fnose_mode_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get fnose_mode_continue;

  /// No description provided for @fnose_feedback_wellDone.
  ///
  /// In en, this message translates to:
  /// **'🎉 Well Done! 🎉'**
  String get fnose_feedback_wellDone;

  /// No description provided for @fnose_feedback_missionComplete.
  ///
  /// In en, this message translates to:
  /// **'Mission Complete!'**
  String get fnose_feedback_missionComplete;

  /// No description provided for @fnose_gameover_title.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get fnose_gameover_title;

  /// No description provided for @fnose_gameover_noMatchData.
  ///
  /// In en, this message translates to:
  /// **'No match data available.'**
  String get fnose_gameover_noMatchData;

  /// No description provided for @fnose_gameover_totalTime.
  ///
  /// In en, this message translates to:
  /// **'⏱️ Total time'**
  String get fnose_gameover_totalTime;

  /// No description provided for @fnose_gameover_leftTouches.
  ///
  /// In en, this message translates to:
  /// **'👈 Left touches'**
  String get fnose_gameover_leftTouches;

  /// No description provided for @fnose_gameover_rightTouches.
  ///
  /// In en, this message translates to:
  /// **'👉 Right touches'**
  String get fnose_gameover_rightTouches;

  /// No description provided for @fnose_gameover_totalTouches.
  ///
  /// In en, this message translates to:
  /// **'🎯 Total touches'**
  String get fnose_gameover_totalTouches;

  /// No description provided for @fnose_gameover_matchStatistics.
  ///
  /// In en, this message translates to:
  /// **'📊 Match Statistics'**
  String get fnose_gameover_matchStatistics;

  /// No description provided for @fnose_gameover_avgTouchTime.
  ///
  /// In en, this message translates to:
  /// **'⚡ Avg Touch Time'**
  String get fnose_gameover_avgTouchTime;

  /// No description provided for @fnose_gameover_avgDistance.
  ///
  /// In en, this message translates to:
  /// **'📏 Avg Distance'**
  String get fnose_gameover_avgDistance;

  /// No description provided for @fnose_gameover_avgAngle.
  ///
  /// In en, this message translates to:
  /// **'📐 Avg Angle'**
  String get fnose_gameover_avgAngle;

  /// No description provided for @fnose_gameover_timeCV.
  ///
  /// In en, this message translates to:
  /// **'⏱️ Time CV'**
  String get fnose_gameover_timeCV;

  /// No description provided for @fnose_gameover_distanceCV.
  ///
  /// In en, this message translates to:
  /// **'📏 Distance CV'**
  String get fnose_gameover_distanceCV;

  /// No description provided for @fnose_gameover_angleCV.
  ///
  /// In en, this message translates to:
  /// **'📐 Angle CV'**
  String get fnose_gameover_angleCV;

  /// No description provided for @fnose_gameover_precisionIndex.
  ///
  /// In en, this message translates to:
  /// **'🎯 Precision Index'**
  String get fnose_gameover_precisionIndex;

  /// No description provided for @fnose_gameover_consistencyIndex.
  ///
  /// In en, this message translates to:
  /// **'🔄 Consistency Index'**
  String get fnose_gameover_consistencyIndex;

  /// No description provided for @fnose_gameover_touchHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Touch Heatmap'**
  String get fnose_gameover_touchHeatmap;

  /// No description provided for @fnose_gameover_performanceTrend.
  ///
  /// In en, this message translates to:
  /// **'📈 Performance Trend (Last 5 Matches)'**
  String get fnose_gameover_performanceTrend;

  /// No description provided for @fnose_gameover_noPreviousMatches.
  ///
  /// In en, this message translates to:
  /// **'No previous matches available'**
  String get fnose_gameover_noPreviousMatches;

  /// No description provided for @fnose_gameover_performanceComparison.
  ///
  /// In en, this message translates to:
  /// **'📊 Performance Comparison'**
  String get fnose_gameover_performanceComparison;

  /// No description provided for @fnose_gameover_noGlobalStats.
  ///
  /// In en, this message translates to:
  /// **'No global stats available'**
  String get fnose_gameover_noGlobalStats;

  /// No description provided for @fnose_gameover_noCurrentMatchData.
  ///
  /// In en, this message translates to:
  /// **'No current match data'**
  String get fnose_gameover_noCurrentMatchData;

  /// No description provided for @fnose_gameover_precisionGauge.
  ///
  /// In en, this message translates to:
  /// **'🎯 Precision Gauge'**
  String get fnose_gameover_precisionGauge;

  /// No description provided for @fnose_gameover_precisionDataNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Precision data not available'**
  String get fnose_gameover_precisionDataNotAvailable;

  /// No description provided for @fnose_gameover_errorLoadingTouchData.
  ///
  /// In en, this message translates to:
  /// **'Error loading touch data:'**
  String get fnose_gameover_errorLoadingTouchData;

  /// No description provided for @fnose_gameover_touchTime.
  ///
  /// In en, this message translates to:
  /// **'⚡ Touch Time (s)'**
  String get fnose_gameover_touchTime;

  /// No description provided for @fnose_gameover_accuracy.
  ///
  /// In en, this message translates to:
  /// **'🎯 Accuracy (%)'**
  String get fnose_gameover_accuracy;

  /// No description provided for @fnose_gameover_distance.
  ///
  /// In en, this message translates to:
  /// **'📏 Distance (%)'**
  String get fnose_gameover_distance;

  /// No description provided for @fnose_gameover_you.
  ///
  /// In en, this message translates to:
  /// **'You:'**
  String get fnose_gameover_you;

  /// No description provided for @fnose_gameover_avg.
  ///
  /// In en, this message translates to:
  /// **'Avg:'**
  String get fnose_gameover_avg;

  /// No description provided for @fnose_gameover_global.
  ///
  /// In en, this message translates to:
  /// **'Global:'**
  String get fnose_gameover_global;

  /// No description provided for @fnose_gameover_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get fnose_gameover_home;

  /// No description provided for @fnose_gameover_playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get fnose_gameover_playAgain;

  /// No description provided for @fnose_gameover_exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get fnose_gameover_exit;

  /// No description provided for @validation_positionFound.
  ///
  /// In en, this message translates to:
  /// **'POSITION FOUND!'**
  String get validation_positionFound;

  /// No description provided for @validation_adjustYourPosition.
  ///
  /// In en, this message translates to:
  /// **'Adjust your position'**
  String get validation_adjustYourPosition;

  /// No description provided for @validation_screenDistance.
  ///
  /// In en, this message translates to:
  /// **'Screen Distance'**
  String get validation_screenDistance;

  /// No description provided for @validation_shoulderYAlign.
  ///
  /// In en, this message translates to:
  /// **'Shoulder Y-Align'**
  String get validation_shoulderYAlign;

  /// No description provided for @validation_depthZAlign.
  ///
  /// In en, this message translates to:
  /// **'Depth Z-Align'**
  String get validation_depthZAlign;

  /// No description provided for @validation_positionCentered.
  ///
  /// In en, this message translates to:
  /// **'Position Centered'**
  String get validation_positionCentered;

  /// No description provided for @stability_stablePositionFound.
  ///
  /// In en, this message translates to:
  /// **'STABLE POSITION FOUND'**
  String get stability_stablePositionFound;

  /// No description provided for @stability_tiltPhoneUp.
  ///
  /// In en, this message translates to:
  /// **'TILT YOUR PHONE UP A BIT'**
  String get stability_tiltPhoneUp;

  /// No description provided for @stability_tiltPhoneDown.
  ///
  /// In en, this message translates to:
  /// **'TILT YOUR PHONE DOWN A BIT'**
  String get stability_tiltPhoneDown;

  /// No description provided for @stability_keepDeviceStable.
  ///
  /// In en, this message translates to:
  /// **'KEEP YOUR DEVICE IN A STABLE POSITION'**
  String get stability_keepDeviceStable;

  /// No description provided for @stability_go.
  ///
  /// In en, this message translates to:
  /// **'GO!'**
  String get stability_go;

  /// No description provided for @stability_errorCheckingAngle.
  ///
  /// In en, this message translates to:
  /// **'Error checking angle:'**
  String get stability_errorCheckingAngle;

  /// No description provided for @stability_errorCheckingStability.
  ///
  /// In en, this message translates to:
  /// **'Error checking stability:'**
  String get stability_errorCheckingStability;

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'MS Upper Limbs Assessment'**
  String get app_title;

  /// No description provided for @app_subtitle.
  ///
  /// In en, this message translates to:
  /// **'☂️ for Umbrella app v'**
  String get app_subtitle;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'MS Upper Limbs'**
  String get app_name;

  /// No description provided for @position_moveCloser.
  ///
  /// In en, this message translates to:
  /// **'MOVE A LITTLE CLOSER'**
  String get position_moveCloser;

  /// No description provided for @position_moveFarther.
  ///
  /// In en, this message translates to:
  /// **'MOVE A LITTLE FAR'**
  String get position_moveFarther;

  /// No description provided for @position_faceDevice.
  ///
  /// In en, this message translates to:
  /// **'FACE THE DEVICE DIRECTLY'**
  String get position_faceDevice;

  /// No description provided for @position_alignShoulders.
  ///
  /// In en, this message translates to:
  /// **'ALIGN SHOULDERS'**
  String get position_alignShoulders;

  /// No description provided for @position_moveLeft.
  ///
  /// In en, this message translates to:
  /// **'MOVE FURTHER TO THE LEFT'**
  String get position_moveLeft;

  /// No description provided for @position_moveRight.
  ///
  /// In en, this message translates to:
  /// **'MOVE FURTHER TO THE RIGHT'**
  String get position_moveRight;

  /// No description provided for @position_moveDown.
  ///
  /// In en, this message translates to:
  /// **'MOVE FURTHER DOWN'**
  String get position_moveDown;

  /// No description provided for @position_moveUp.
  ///
  /// In en, this message translates to:
  /// **'MOVE FURTHER UP'**
  String get position_moveUp;

  /// No description provided for @position_positionFound.
  ///
  /// In en, this message translates to:
  /// **'POSITION FOUND!'**
  String get position_positionFound;

  /// No description provided for @position_faceAndShouldersNotVisible.
  ///
  /// In en, this message translates to:
  /// **'Please, make sure your face and shoulders are visible'**
  String get position_faceAndShouldersNotVisible;

  /// No description provided for @position_noseClose.
  ///
  /// In en, this message translates to:
  /// **'MOVE YOUR FACE A LITTLE CLOSER'**
  String get position_noseClose;

  /// No description provided for @position_noseFar.
  ///
  /// In en, this message translates to:
  /// **'ALIGN YOUR FACE WITH THE CIRCLE'**
  String get position_noseFar;

  /// No description provided for @adjust_position_title.
  ///
  /// In en, this message translates to:
  /// **'Adjust Your Position'**
  String get adjust_position_title;

  /// No description provided for @calibration_calibratingTarget.
  ///
  /// In en, this message translates to:
  /// **'CALIBRATING TARGET'**
  String get calibration_calibratingTarget;

  /// No description provided for @calibration_holdPosition.
  ///
  /// In en, this message translates to:
  /// **'✅ HOLD THIS POSITION'**
  String get calibration_holdPosition;

  /// No description provided for @calibration_startingIn.
  ///
  /// In en, this message translates to:
  /// **'STARTING IN...'**
  String get calibration_startingIn;

  /// No description provided for @gameover_histogram_title.
  ///
  /// In en, this message translates to:
  /// **'⏱️ Interval between touches (dynamic bins)'**
  String get gameover_histogram_title;

  /// No description provided for @gameover_histogram_notEnoughTouches.
  ///
  /// In en, this message translates to:
  /// **'Not enough touches to show histogram.'**
  String get gameover_histogram_notEnoughTouches;

  /// No description provided for @gameover_distribution_title.
  ///
  /// In en, this message translates to:
  /// **'📈 Touch Interval Distribution'**
  String get gameover_distribution_title;

  /// No description provided for @gameover_distribution_notEnoughTouches.
  ///
  /// In en, this message translates to:
  /// **'Not enough touches to show distribution.'**
  String get gameover_distribution_notEnoughTouches;

  /// No description provided for @gameover_distribution_range.
  ///
  /// In en, this message translates to:
  /// **'{start}–{end}'**
  String gameover_distribution_range(Object end, Object start);

  /// No description provided for @gameover_distribution_range_ms.
  ///
  /// In en, this message translates to:
  /// **'{start}–{end} ms'**
  String gameover_distribution_range_ms(Object end, Object start);

  /// No description provided for @error_generic.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error_generic(Object error);

  /// No description provided for @error_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get error_loading;

  /// No description provided for @camera_calibration_calibrating.
  ///
  /// In en, this message translates to:
  /// **'CALIBRATING CAMERA...'**
  String get camera_calibration_calibrating;

  /// No description provided for @camera_calibration_testingConfig.
  ///
  /// In en, this message translates to:
  /// **'TESTING CONFIGURATION {current}/{total}...'**
  String camera_calibration_testingConfig(int current, int total);

  /// No description provided for @camera_calibration_complete.
  ///
  /// In en, this message translates to:
  /// **'CALIBRATION COMPLETE!'**
  String get camera_calibration_complete;

  /// No description provided for @camera_calibration_failed.
  ///
  /// In en, this message translates to:
  /// **'LANDMARKS NOT DETECTED'**
  String get camera_calibration_failed;

  /// No description provided for @camera_calibration_failedMessage.
  ///
  /// In en, this message translates to:
  /// **'Position yourself facing the camera and try again.'**
  String get camera_calibration_failedMessage;

  /// No description provided for @camera_calibration_seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} / 10 SECONDS'**
  String camera_calibration_seconds(int seconds);
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
      'that was used.');
}
