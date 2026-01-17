import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'RAP Precision'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @estimateDetails.
  ///
  /// In en, this message translates to:
  /// **'Estimate Details'**
  String get estimateDetails;

  /// No description provided for @startNewEstimate.
  ///
  /// In en, this message translates to:
  /// **'Start New Estimate'**
  String get startNewEstimate;

  /// No description provided for @uploadInstruction.
  ///
  /// In en, this message translates to:
  /// **'Upload an image of what you want to build or repair.\nOur AI will handle the rest.'**
  String get uploadInstruction;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @instant.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get instant;

  /// No description provided for @accurate.
  ///
  /// In en, this message translates to:
  /// **'Accurate'**
  String get accurate;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @greenAdvantage.
  ///
  /// In en, this message translates to:
  /// **'Green Advantage'**
  String get greenAdvantage;

  /// No description provided for @roiInsight.
  ///
  /// In en, this message translates to:
  /// **'ROI Insight'**
  String get roiInsight;

  /// No description provided for @emergencySos.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY SOS'**
  String get emergencySos;

  /// No description provided for @broadcastUrgent.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Urgent'**
  String get broadcastUrgent;

  /// No description provided for @findingPros.
  ///
  /// In en, this message translates to:
  /// **'Finding pros near you...'**
  String get findingPros;

  /// No description provided for @proAccepted.
  ///
  /// In en, this message translates to:
  /// **'Pro Accepted!'**
  String get proAccepted;

  /// No description provided for @milesAway.
  ///
  /// In en, this message translates to:
  /// **'miles away'**
  String get milesAway;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @proDashboard.
  ///
  /// In en, this message translates to:
  /// **'Pro Dashboard'**
  String get proDashboard;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @contractors.
  ///
  /// In en, this message translates to:
  /// **'Contractors'**
  String get contractors;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @newEstimate.
  ///
  /// In en, this message translates to:
  /// **'New Estimate'**
  String get newEstimate;

  /// No description provided for @activeJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Jobs'**
  String get activeJobs;

  /// No description provided for @estimateHistory.
  ///
  /// In en, this message translates to:
  /// **'Estimate History'**
  String get estimateHistory;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @activeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Active Currency'**
  String get activeCurrency;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @aboutRap.
  ///
  /// In en, this message translates to:
  /// **'About RAP'**
  String get aboutRap;

  /// No description provided for @manageAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage your business and leads'**
  String get manageAccount;

  /// No description provided for @addTestJob.
  ///
  /// In en, this message translates to:
  /// **'Add Test Job'**
  String get addTestJob;

  /// No description provided for @activeProjects.
  ///
  /// In en, this message translates to:
  /// **'Active Projects'**
  String get activeProjects;

  /// No description provided for @verifiedPro.
  ///
  /// In en, this message translates to:
  /// **'Verified Pro'**
  String get verifiedPro;

  /// No description provided for @unverifiedNote.
  ///
  /// In en, this message translates to:
  /// **'Your account is not verified. Upload documents to gain trust.'**
  String get unverifiedNote;

  /// No description provided for @verifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify Now'**
  String get verifyNow;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get stats;

  /// No description provided for @totalLeads.
  ///
  /// In en, this message translates to:
  /// **'Total Leads'**
  String get totalLeads;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get biometrics;

  /// No description provided for @twoFactor.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactor;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Manage your security settings'**
  String get securitySettings;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'RAP is the new standard for AI-powered repairs and estimations.'**
  String get aboutDescription;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No History Found'**
  String get noHistory;

  /// No description provided for @completeFirstEstimate.
  ///
  /// In en, this message translates to:
  /// **'Complete your first estimate to see it here.'**
  String get completeFirstEstimate;

  /// No description provided for @historySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your past estimations and reports'**
  String get historySubtitle;

  /// No description provided for @verifiedPros.
  ///
  /// In en, this message translates to:
  /// **'Verified professionals in your area'**
  String get verifiedPros;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon to Your Area'**
  String get comingSoon;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to access your account.'**
  String get signInSubtitle;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// No description provided for @newStandard.
  ///
  /// In en, this message translates to:
  /// **'THE NEW STANDARD FOR AI ESTIMATES'**
  String get newStandard;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the elite network of precise estimations.'**
  String get signUpSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No Messages Yet'**
  String get noMessages;

  /// No description provided for @noMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect with contractors to start discussing\nyour next project.'**
  String get noMessagesSubtitle;

  /// No description provided for @startFirstChat.
  ///
  /// In en, this message translates to:
  /// **'Start First Chat'**
  String get startFirstChat;

  /// No description provided for @startChat.
  ///
  /// In en, this message translates to:
  /// **'Start Chat'**
  String get startChat;

  /// No description provided for @onboardingContractors.
  ///
  /// In en, this message translates to:
  /// **'We are currently onboarding top-tier contractors.'**
  String get onboardingContractors;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @noBio.
  ///
  /// In en, this message translates to:
  /// **'No bio available.'**
  String get noBio;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @hire.
  ///
  /// In en, this message translates to:
  /// **'Hire'**
  String get hire;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetails;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompleted;

  /// No description provided for @chatWithCustomer.
  ///
  /// In en, this message translates to:
  /// **'Chat with Customer'**
  String get chatWithCustomer;

  /// No description provided for @noActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'No active jobs yet'**
  String get noActiveJobs;

  /// No description provided for @untitledJob.
  ///
  /// In en, this message translates to:
  /// **'Untitled Job'**
  String get untitledJob;

  /// No description provided for @testJobCreated.
  ///
  /// In en, this message translates to:
  /// **'Test job created successfully!'**
  String get testJobCreated;

  /// No description provided for @docVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Insurance & License Verification'**
  String get docVerificationTitle;

  /// No description provided for @docVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your General Liability Insurance and Active Trade License. Our AI will verify the expiration dates and coverage limits.'**
  String get docVerificationSubtitle;

  /// No description provided for @insurancePolicy.
  ///
  /// In en, this message translates to:
  /// **'Insurance Policy'**
  String get insurancePolicy;

  /// No description provided for @pdfOrImage.
  ///
  /// In en, this message translates to:
  /// **'PDF or Image'**
  String get pdfOrImage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submitForAiReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for AI Review'**
  String get submitForAiReview;

  /// No description provided for @docsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Verification documents submitted! Verification complete.'**
  String get docsSubmitted;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get changePasswordSubtitle;

  /// No description provided for @biometricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use FaceID or Fingerprint'**
  String get biometricsSubtitle;

  /// No description provided for @twoFactorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security'**
  String get twoFactorSubtitle;

  /// No description provided for @securityAssistant.
  ///
  /// In en, this message translates to:
  /// **'Security Assistant'**
  String get securityAssistant;

  /// No description provided for @passwordUpdate.
  ///
  /// In en, this message translates to:
  /// **'Password Update'**
  String get passwordUpdate;

  /// No description provided for @passwordUpdateExplanation.
  ///
  /// In en, this message translates to:
  /// **'Regular password updates protect against unauthorized access. I will send a secure reset link to your email.'**
  String get passwordUpdateExplanation;

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send Link'**
  String get sendLink;

  /// No description provided for @enableBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometrics'**
  String get enableBiometrics;

  /// No description provided for @disableBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Disable Biometrics'**
  String get disableBiometrics;

  /// No description provided for @biometricsEnableExplanation.
  ///
  /// In en, this message translates to:
  /// **'Biometrics allow for faster, secure access using your unique physical traits. This data stays on your device.'**
  String get biometricsEnableExplanation;

  /// No description provided for @biometricsDisableExplanation.
  ///
  /// In en, this message translates to:
  /// **'Disabling biometrics employs standard password entry. Your biometric data remains on your device but won\'t unlock this app.'**
  String get biometricsDisableExplanation;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @enable2FA.
  ///
  /// In en, this message translates to:
  /// **'Enable 2FA'**
  String get enable2FA;

  /// No description provided for @disable2FA.
  ///
  /// In en, this message translates to:
  /// **'Disable 2FA'**
  String get disable2FA;

  /// No description provided for @twoFactorEnableExplanation.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication (2FA) requires a code from your phone in addition to your password. This significantly reduces the risk of account theft.'**
  String get twoFactorEnableExplanation;

  /// No description provided for @twoFactorDisableExplanation.
  ///
  /// In en, this message translates to:
  /// **'Disabling 2FA removes the extra verification step. This makes logging in faster but less secure.'**
  String get twoFactorDisableExplanation;

  /// No description provided for @setup2FA.
  ///
  /// In en, this message translates to:
  /// **'Setup 2FA'**
  String get setup2FA;

  /// No description provided for @turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn Off'**
  String get turnOff;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to'**
  String get resetLinkSent;

  /// No description provided for @estimates.
  ///
  /// In en, this message translates to:
  /// **'Estimates'**
  String get estimates;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @rapBot.
  ///
  /// In en, this message translates to:
  /// **'RAP Assistant'**
  String get rapBot;

  /// No description provided for @jobBoard.
  ///
  /// In en, this message translates to:
  /// **'Job Board'**
  String get jobBoard;

  /// No description provided for @submitBid.
  ///
  /// In en, this message translates to:
  /// **'Submit Bid'**
  String get submitBid;

  /// No description provided for @bidAmount.
  ///
  /// In en, this message translates to:
  /// **'Bid Amount (\$)'**
  String get bidAmount;

  /// No description provided for @bidSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bid submitted successfully!'**
  String get bidSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
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
