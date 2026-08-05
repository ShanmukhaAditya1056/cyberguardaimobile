import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

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
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
    Locale('te')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CyberGuard AI'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Intelligent Security Assistant'**
  String get appTagline;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @phishingScanner.
  ///
  /// In en, this message translates to:
  /// **'Phishing Scanner'**
  String get phishingScanner;

  /// No description provided for @appScanner.
  ///
  /// In en, this message translates to:
  /// **'App Scanner'**
  String get appScanner;

  /// No description provided for @breachMonitor.
  ///
  /// In en, this message translates to:
  /// **'Breach Monitor'**
  String get breachMonitor;

  /// No description provided for @wifiScanner.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Scanner'**
  String get wifiScanner;

  /// No description provided for @securityScore.
  ///
  /// In en, this message translates to:
  /// **'Security Score'**
  String get securityScore;

  /// No description provided for @scanNow.
  ///
  /// In en, this message translates to:
  /// **'Scan now'**
  String get scanNow;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// No description provided for @protected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get protected;

  /// No description provided for @atRisk.
  ///
  /// In en, this message translates to:
  /// **'At Risk'**
  String get atRisk;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @lastScanned.
  ///
  /// In en, this message translates to:
  /// **'Last scanned {time}'**
  String lastScanned(String time);

  /// No description provided for @neverScanned.
  ///
  /// In en, this message translates to:
  /// **'Never scanned'**
  String get neverScanned;

  /// No description provided for @protectionModules.
  ///
  /// In en, this message translates to:
  /// **'Protection Modules'**
  String get protectionModules;

  /// No description provided for @sevenDayScore.
  ///
  /// In en, this message translates to:
  /// **'7-Day Security Score'**
  String get sevenDayScore;

  /// No description provided for @recentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Recent Alerts'**
  String get recentAlerts;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet'**
  String get noAlerts;

  /// No description provided for @noAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Threats detected during scans will appear here'**
  String get noAlertsDescription;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी (Hindi)'**
  String get languageHindi;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ் (Tamil)'**
  String get languageTamil;

  /// No description provided for @languageTelugu.
  ///
  /// In en, this message translates to:
  /// **'తెలుగు (Telugu)'**
  String get languageTelugu;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportPdf;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get exportCsv;

  /// No description provided for @exportPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Branded report with score, threats and trends'**
  String get exportPdfSubtitle;

  /// No description provided for @exportCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Raw scan + alert data for spreadsheets'**
  String get exportCsvSubtitle;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports & Export'**
  String get reports;

  /// No description provided for @liveSmsGuard.
  ///
  /// In en, this message translates to:
  /// **'Live SMS Phishing Guard'**
  String get liveSmsGuard;

  /// No description provided for @liveSmsGuardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-scan every incoming SMS for phishing links'**
  String get liveSmsGuardSubtitle;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQrCode;

  /// No description provided for @checkBreach.
  ///
  /// In en, this message translates to:
  /// **'Check Now'**
  String get checkBreach;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password to test'**
  String get enterPassword;

  /// No description provided for @noBreachFound.
  ///
  /// In en, this message translates to:
  /// **'No breaches found'**
  String get noBreachFound;

  /// No description provided for @breachesFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 breach found} other{{count} breaches found}}'**
  String breachesFound(int count);

  /// No description provided for @onboardAiSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'AI-powered security 🛡️'**
  String get onboardAiSecurityTitle;

  /// No description provided for @onboardAiSecurityDesc.
  ///
  /// In en, this message translates to:
  /// **'On-device machine learning detects phishing, malware, and breaches — all in real time, none of your data leaves your phone.'**
  String get onboardAiSecurityDesc;

  /// No description provided for @onboardPhishingTitle.
  ///
  /// In en, this message translates to:
  /// **'Phishing detection 🔗'**
  String get onboardPhishingTitle;

  /// No description provided for @onboardPhishingDesc.
  ///
  /// In en, this message translates to:
  /// **'Paste any link or scan your SMS to spot phishing attempts targeting banking, UPI, and OTPs — explained simply.'**
  String get onboardPhishingDesc;

  /// No description provided for @onboardMalwareTitle.
  ///
  /// In en, this message translates to:
  /// **'Malware scanner 🐞'**
  String get onboardMalwareTitle;

  /// No description provided for @onboardMalwareDesc.
  ///
  /// In en, this message translates to:
  /// **'Deep-scan installed apps using permission graph analysis to find hidden spyware, trojans, and stalkerware.'**
  String get onboardMalwareDesc;

  /// No description provided for @onboardBreachTitle.
  ///
  /// In en, this message translates to:
  /// **'Breach monitor 🔐'**
  String get onboardBreachTitle;

  /// No description provided for @onboardBreachDesc.
  ///
  /// In en, this message translates to:
  /// **'Check 14B+ leaked records. Your email and password are hashed locally and never sent in full.'**
  String get onboardBreachDesc;

  /// No description provided for @onboardPermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Just a few permissions 🙏'**
  String get onboardPermsTitle;

  /// No description provided for @onboardPermsDesc.
  ///
  /// In en, this message translates to:
  /// **'We need SMS, location, and notification access. All scans stay on this device — nothing is sent to any server.'**
  String get onboardPermsDesc;

  /// No description provided for @onboardContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardContinue;

  /// No description provided for @onboardGrantStart.
  ///
  /// In en, this message translates to:
  /// **'Grant permissions & start'**
  String get onboardGrantStart;

  /// No description provided for @onboardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardSkip;

  /// No description provided for @scoreGreetingProtected.
  ///
  /// In en, this message translates to:
  /// **'You\'re protected'**
  String get scoreGreetingProtected;

  /// No description provided for @scoreGreetingAtRisk.
  ///
  /// In en, this message translates to:
  /// **'A few things to check ⚠️'**
  String get scoreGreetingAtRisk;

  /// No description provided for @scoreGreetingCritical.
  ///
  /// In en, this message translates to:
  /// **'Action needed 🚨'**
  String get scoreGreetingCritical;

  /// No description provided for @scoreGreetingFirstScan.
  ///
  /// In en, this message translates to:
  /// **'Hi there 👋'**
  String get scoreGreetingFirstScan;

  /// No description provided for @scoreHeadlineProtected.
  ///
  /// In en, this message translates to:
  /// **'Everything looks healthy'**
  String get scoreHeadlineProtected;

  /// No description provided for @scoreHeadlineAtRisk.
  ///
  /// In en, this message translates to:
  /// **'Take a quick look'**
  String get scoreHeadlineAtRisk;

  /// No description provided for @scoreHeadlineCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical issues found'**
  String get scoreHeadlineCritical;

  /// No description provided for @scoreHeadlineFirstScan.
  ///
  /// In en, this message translates to:
  /// **'Let\'s secure your phone'**
  String get scoreHeadlineFirstScan;

  /// No description provided for @permSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'SMS Access Needed'**
  String get permSmsTitle;

  /// No description provided for @permSmsRationale.
  ///
  /// In en, this message translates to:
  /// **'CyberGuard AI needs to read your SMS messages to detect phishing links. Your messages are never sent to any server — all analysis happens locally on your device.'**
  String get permSmsRationale;

  /// No description provided for @permLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Access Needed'**
  String get permLocationTitle;

  /// No description provided for @permLocationRationale.
  ///
  /// In en, this message translates to:
  /// **'Android requires location permission to access Wi-Fi network details like SSID. CyberGuard AI uses this only to analyse your current network security — your location data is never stored or shared.'**
  String get permLocationRationale;

  /// No description provided for @permNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permNotifTitle;

  /// No description provided for @permNotifRationale.
  ///
  /// In en, this message translates to:
  /// **'CyberGuard AI sends notifications when it detects threats so you can act immediately. You can customise notification types in Settings.'**
  String get permNotifRationale;

  /// No description provided for @permAllowButton.
  ///
  /// In en, this message translates to:
  /// **'Allow Permission'**
  String get permAllowButton;

  /// No description provided for @permNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get permNotNow;

  /// No description provided for @dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// No description provided for @dialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get dialogConfirm;

  /// No description provided for @dialogClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get dialogClearAll;

  /// No description provided for @dialogReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get dialogReset;

  /// No description provided for @dialogDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dialogDelete;

  /// No description provided for @dialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// No description provided for @breachInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Check if your data was leaked'**
  String get breachInputTitle;

  /// No description provided for @breachInputSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We check across 12+ billion leaked records'**
  String get breachInputSubtitle;

  /// No description provided for @breachTabEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get breachTabEmail;

  /// No description provided for @breachTabPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get breachTabPhone;

  /// No description provided for @breachInputHintEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get breachInputHintEmail;

  /// No description provided for @breachInputHintPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your 10-digit number'**
  String get breachInputHintPhone;

  /// No description provided for @breachPrivacyFooter.
  ///
  /// In en, this message translates to:
  /// **'k-Anonymity protected · Your data never leaves this device'**
  String get breachPrivacyFooter;

  /// No description provided for @breachNoBreaches.
  ///
  /// In en, this message translates to:
  /// **'No breaches found'**
  String get breachNoBreaches;

  /// No description provided for @breachNoBreachesEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'Good news! Your email wasn\'t found in any known data breach.'**
  String get breachNoBreachesEmailDesc;

  /// No description provided for @breachNoBreachesPhoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Good news! This phone number wasn\'t found in any known data breach.'**
  String get breachNoBreachesPhoneDesc;

  /// No description provided for @breachCheckedCount.
  ///
  /// In en, this message translates to:
  /// **'Checked 12,454,308,593 records'**
  String get breachCheckedCount;

  /// No description provided for @breachStayProtected.
  ///
  /// In en, this message translates to:
  /// **'Stay protected'**
  String get breachStayProtected;

  /// No description provided for @breachTipUnique.
  ///
  /// In en, this message translates to:
  /// **'Use unique passwords for each account'**
  String get breachTipUnique;

  /// No description provided for @breach2FA.
  ///
  /// In en, this message translates to:
  /// **'Enable two-factor authentication'**
  String get breach2FA;

  /// No description provided for @breachPwManager.
  ///
  /// In en, this message translates to:
  /// **'Use a password manager'**
  String get breachPwManager;

  /// No description provided for @breachOfflineBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Showing results from offline database'**
  String get breachOfflineBannerTitle;

  /// No description provided for @breachOfflineBannerBody.
  ///
  /// In en, this message translates to:
  /// **'These are real historical breaches but the match is derived from a local hash of your email, not a live HIBP lookup. Configure a free HIBP API key in Settings for live verification.'**
  String get breachOfflineBannerBody;

  /// No description provided for @breachFoundEmail.
  ///
  /// In en, this message translates to:
  /// **'Your email was exposed in the following breaches:'**
  String get breachFoundEmail;

  /// No description provided for @breachFoundPhone.
  ///
  /// In en, this message translates to:
  /// **'This number was exposed in the following breaches:'**
  String get breachFoundPhone;

  /// No description provided for @breachAccountsAffected.
  ///
  /// In en, this message translates to:
  /// **'{count} accounts affected'**
  String breachAccountsAffected(String count);

  /// No description provided for @breachCompromisedData.
  ///
  /// In en, this message translates to:
  /// **'COMPROMISED DATA'**
  String get breachCompromisedData;

  /// No description provided for @breachWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What should I do?'**
  String get breachWhatToDo;

  /// No description provided for @breachStep1.
  ///
  /// In en, this message translates to:
  /// **'Change passwords on every site where you reused this credential.'**
  String get breachStep1;

  /// No description provided for @breachStep2.
  ///
  /// In en, this message translates to:
  /// **'Enable two-factor authentication, ideally with an authenticator app.'**
  String get breachStep2;

  /// No description provided for @breachStep3.
  ///
  /// In en, this message translates to:
  /// **'Watch for phishing emails impersonating the breached service.'**
  String get breachStep3;

  /// No description provided for @breachStep4.
  ///
  /// In en, this message translates to:
  /// **'Consider a password manager to keep unique passwords per account.'**
  String get breachStep4;

  /// No description provided for @breachPastChecks.
  ///
  /// In en, this message translates to:
  /// **'Past checks'**
  String get breachPastChecks;

  /// No description provided for @breachStatusSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get breachStatusSafe;

  /// No description provided for @breachStatusBreached.
  ///
  /// In en, this message translates to:
  /// **'Breached'**
  String get breachStatusBreached;

  /// No description provided for @breachPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'How we protect your privacy'**
  String get breachPrivacyTitle;

  /// No description provided for @breachPrivacyStep1.
  ///
  /// In en, this message translates to:
  /// **'Your input is hashed on your device.'**
  String get breachPrivacyStep1;

  /// No description provided for @breachPrivacyStep2.
  ///
  /// In en, this message translates to:
  /// **'Only the first 5 characters of the hash are sent to HIBP.'**
  String get breachPrivacyStep2;

  /// No description provided for @breachPrivacyStep3.
  ///
  /// In en, this message translates to:
  /// **'Thousands of matching hashes come back.'**
  String get breachPrivacyStep3;

  /// No description provided for @breachPrivacyStep4.
  ///
  /// In en, this message translates to:
  /// **'100% of the match check happens locally on your device.'**
  String get breachPrivacyStep4;

  /// No description provided for @qrScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get qrScanTitle;

  /// No description provided for @qrUploadFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Upload from gallery'**
  String get qrUploadFromGallery;

  /// No description provided for @qrPointAtCode.
  ///
  /// In en, this message translates to:
  /// **'Point at any QR · scanned URLs are checked locally'**
  String get qrPointAtCode;

  /// No description provided for @qrNotAUrl.
  ///
  /// In en, this message translates to:
  /// **'Not a URL'**
  String get qrNotAUrl;

  /// No description provided for @qrNotAUrlBody.
  ///
  /// In en, this message translates to:
  /// **'The QR code contained text, not a link:'**
  String get qrNotAUrlBody;

  /// No description provided for @qrPhishingDetected.
  ///
  /// In en, this message translates to:
  /// **'Phishing QR detected'**
  String get qrPhishingDetected;

  /// No description provided for @qrSafeLink.
  ///
  /// In en, this message translates to:
  /// **'Safe link'**
  String get qrSafeLink;

  /// No description provided for @qrScanAnother.
  ///
  /// In en, this message translates to:
  /// **'Scan another'**
  String get qrScanAnother;

  /// No description provided for @qrViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get qrViewDetails;

  /// No description provided for @qrConfidence.
  ///
  /// In en, this message translates to:
  /// **'{count}% confidence'**
  String qrConfidence(int count);

  /// No description provided for @qrCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable. Grant camera permission and try again.'**
  String get qrCameraUnavailable;

  /// No description provided for @qrOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get qrOpenSettings;

  /// No description provided for @qrNoCodeInImage.
  ///
  /// In en, this message translates to:
  /// **'No QR code found in this image.'**
  String get qrNoCodeInImage;

  /// No description provided for @scoreSuffix.
  ///
  /// In en, this message translates to:
  /// **'/100'**
  String get scoreSuffix;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'score'**
  String get scoreLabel;

  /// No description provided for @scannedAgo.
  ///
  /// In en, this message translates to:
  /// **'Scanned {time}'**
  String scannedAgo(String time);

  /// No description provided for @dashboardRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Dashboard refreshed'**
  String get dashboardRefreshed;

  /// No description provided for @dashboardRefreshedWithWifi.
  ///
  /// In en, this message translates to:
  /// **'Dashboard refreshed · Wi-Fi trust {score}/100'**
  String dashboardRefreshedWithWifi(int score);

  /// No description provided for @moduleTitlePhishing.
  ///
  /// In en, this message translates to:
  /// **'Phishing'**
  String get moduleTitlePhishing;

  /// No description provided for @moduleSubtitlePhishing.
  ///
  /// In en, this message translates to:
  /// **'URL & SMS scanner'**
  String get moduleSubtitlePhishing;

  /// No description provided for @moduleTitleMalware.
  ///
  /// In en, this message translates to:
  /// **'Malware'**
  String get moduleTitleMalware;

  /// No description provided for @moduleSubtitleMalware.
  ///
  /// In en, this message translates to:
  /// **'App security'**
  String get moduleSubtitleMalware;

  /// No description provided for @moduleTitleBreach.
  ///
  /// In en, this message translates to:
  /// **'Breach'**
  String get moduleTitleBreach;

  /// No description provided for @moduleSubtitleBreach.
  ///
  /// In en, this message translates to:
  /// **'Data leak monitor'**
  String get moduleSubtitleBreach;

  /// No description provided for @moduleTitleWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get moduleTitleWifi;

  /// No description provided for @moduleSubtitleWifi.
  ///
  /// In en, this message translates to:
  /// **'Network analyser'**
  String get moduleSubtitleWifi;

  /// No description provided for @statTotalScans.
  ///
  /// In en, this message translates to:
  /// **'Total Scans'**
  String get statTotalScans;

  /// No description provided for @statThreats.
  ///
  /// In en, this message translates to:
  /// **'Threats'**
  String get statThreats;

  /// No description provided for @statLastScan.
  ///
  /// In en, this message translates to:
  /// **'Last Scan'**
  String get statLastScan;

  /// No description provided for @statNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get statNever;

  /// No description provided for @settingRealTimeAlerts.
  ///
  /// In en, this message translates to:
  /// **'Real-time Alerts'**
  String get settingRealTimeAlerts;

  /// No description provided for @settingRealTimeAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'Get notified when threats are detected'**
  String get settingRealTimeAlertsSub;

  /// No description provided for @settingClipboardScan.
  ///
  /// In en, this message translates to:
  /// **'Clipboard Scan'**
  String get settingClipboardScan;

  /// No description provided for @settingClipboardScanSub.
  ///
  /// In en, this message translates to:
  /// **'Scan URLs copied to clipboard'**
  String get settingClipboardScanSub;

  /// No description provided for @settingWifiAutoScan.
  ///
  /// In en, this message translates to:
  /// **'Auto Wi-Fi Scan'**
  String get settingWifiAutoScan;

  /// No description provided for @settingWifiAutoScanSub.
  ///
  /// In en, this message translates to:
  /// **'Scan on network change'**
  String get settingWifiAutoScanSub;

  /// No description provided for @smsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'SMS permission denied — cannot start live scan'**
  String get smsPermissionDenied;

  /// No description provided for @settingsAutoScanFrequency.
  ///
  /// In en, this message translates to:
  /// **'Auto Scan Frequency'**
  String get settingsAutoScanFrequency;

  /// No description provided for @settingsBackgroundScanEvery.
  ///
  /// In en, this message translates to:
  /// **'Background scan every {hours}h'**
  String settingsBackgroundScanEvery(int hours);

  /// No description provided for @settingsHibpTitle.
  ///
  /// In en, this message translates to:
  /// **'Have I Been Pwned API Key'**
  String get settingsHibpTitle;

  /// No description provided for @settingsHibpDesc.
  ///
  /// In en, this message translates to:
  /// **'Required for email breach checks. Get your free key at haveibeenpwned.com/API/Key'**
  String get settingsHibpDesc;

  /// No description provided for @settingsHibpPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your API key here…'**
  String get settingsHibpPasteHint;

  /// No description provided for @settingsHibpSave.
  ///
  /// In en, this message translates to:
  /// **'Save Key'**
  String get settingsHibpSave;

  /// No description provided for @settingsHibpSaved.
  ///
  /// In en, this message translates to:
  /// **'API key saved'**
  String get settingsHibpSaved;

  /// No description provided for @settingsHibpConfigured.
  ///
  /// In en, this message translates to:
  /// **'API key configured'**
  String get settingsHibpConfigured;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get settingsPrivacy;

  /// No description provided for @settingsKAnon.
  ///
  /// In en, this message translates to:
  /// **'k-Anonymity Protocol'**
  String get settingsKAnon;

  /// No description provided for @settingsKAnonDesc.
  ///
  /// In en, this message translates to:
  /// **'Passwords are never sent to any server. Only the first 5 characters of the SHA-1 hash are transmitted. Your credentials never leave your device.'**
  String get settingsKAnonDesc;

  /// No description provided for @settingsLocalStorage.
  ///
  /// In en, this message translates to:
  /// **'Local Storage Only'**
  String get settingsLocalStorage;

  /// No description provided for @settingsLocalStorageDesc.
  ///
  /// In en, this message translates to:
  /// **'All scan results and history are stored locally on your device using encrypted Hive storage. No data is sent to our servers.'**
  String get settingsLocalStorageDesc;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsAboutVersion;

  /// No description provided for @settingsAboutEngine.
  ///
  /// In en, this message translates to:
  /// **'Detection Engine'**
  String get settingsAboutEngine;

  /// No description provided for @settingsAboutSources.
  ///
  /// In en, this message translates to:
  /// **'Data Sources'**
  String get settingsAboutSources;

  /// No description provided for @settingsAboutModel.
  ///
  /// In en, this message translates to:
  /// **'AI Model'**
  String get settingsAboutModel;

  /// No description provided for @settingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get settingsDangerZone;

  /// No description provided for @settingsResetDesc.
  ///
  /// In en, this message translates to:
  /// **'Reset all settings to defaults. This will not delete scan history.'**
  String get settingsResetDesc;

  /// No description provided for @settingsResetBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get settingsResetBtn;

  /// No description provided for @settingsResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetBody.
  ///
  /// In en, this message translates to:
  /// **'All settings will be restored to defaults. Continue?'**
  String get settingsResetBody;

  /// No description provided for @exportGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF report…'**
  String get exportGenerating;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @alertsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get alertsMarkAllRead;

  /// No description provided for @alertsNoFilter.
  ///
  /// In en, this message translates to:
  /// **'No {filter} alerts'**
  String alertsNoFilter(String filter);

  /// No description provided for @alertsTryDifferent.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter'**
  String get alertsTryDifferent;

  /// No description provided for @alertsClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Alerts'**
  String get alertsClearTitle;

  /// No description provided for @alertsClearBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all alerts.'**
  String get alertsClearBody;

  /// No description provided for @alertsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get alertsFilterAll;

  /// No description provided for @alertsFilterPhishing.
  ///
  /// In en, this message translates to:
  /// **'Phishing'**
  String get alertsFilterPhishing;

  /// No description provided for @alertsFilterMalware.
  ///
  /// In en, this message translates to:
  /// **'Malware'**
  String get alertsFilterMalware;

  /// No description provided for @alertsFilterBreach.
  ///
  /// In en, this message translates to:
  /// **'Breach'**
  String get alertsFilterBreach;

  /// No description provided for @alertsFilterWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get alertsFilterWifi;

  /// No description provided for @malwareIssuesFound.
  ///
  /// In en, this message translates to:
  /// **'Issues found ⚠️'**
  String get malwareIssuesFound;

  /// No description provided for @malwareAppSecurity.
  ///
  /// In en, this message translates to:
  /// **'App security 🛡️'**
  String get malwareAppSecurity;

  /// No description provided for @malwareTapToScan.
  ///
  /// In en, this message translates to:
  /// **'Tap scan to analyse your apps'**
  String get malwareTapToScan;

  /// No description provided for @malwareAppsThreats.
  ///
  /// In en, this message translates to:
  /// **'{apps} apps · {threats} {threats, plural, =1{threat} other{threats}}'**
  String malwareAppsThreats(int apps, int threats);

  /// No description provided for @malwareLastScan.
  ///
  /// In en, this message translates to:
  /// **'Last scan {time}'**
  String malwareLastScan(String time);

  /// No description provided for @malwareScanNow.
  ///
  /// In en, this message translates to:
  /// **'Scan apps now'**
  String get malwareScanNow;

  /// No description provided for @malwareAnalysing.
  ///
  /// In en, this message translates to:
  /// **'Analysing {name}…'**
  String malwareAnalysing(String name);

  /// No description provided for @malwareEtaSec.
  ///
  /// In en, this message translates to:
  /// **'~{sec}s'**
  String malwareEtaSec(String sec);

  /// No description provided for @malwareProgress.
  ///
  /// In en, this message translates to:
  /// **'{progress} / {total} apps'**
  String malwareProgress(int progress, int total);

  /// No description provided for @malwareRiskCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get malwareRiskCritical;

  /// No description provided for @malwareRiskHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get malwareRiskHigh;

  /// No description provided for @malwareRiskMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get malwareRiskMedium;

  /// No description provided for @malwareRiskLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get malwareRiskLow;

  /// No description provided for @malwareSearch.
  ///
  /// In en, this message translates to:
  /// **'Search apps…'**
  String get malwareSearch;

  /// No description provided for @malwareNoAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'No apps found'**
  String get malwareNoAppsTitle;

  /// No description provided for @malwareNoAppsSub.
  ///
  /// In en, this message translates to:
  /// **'Tap Scan to analyse your installed apps'**
  String get malwareNoAppsSub;

  /// No description provided for @malwareNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No apps match filter'**
  String get malwareNoMatchTitle;

  /// No description provided for @malwareNoMatchSub.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or search term'**
  String get malwareNoMatchSub;

  /// No description provided for @malwarePermsVerified.
  ///
  /// In en, this message translates to:
  /// **'{count} permissions • Verified'**
  String malwarePermsVerified(int count);

  /// No description provided for @malwarePermsSideloaded.
  ///
  /// In en, this message translates to:
  /// **'{count} permissions • Sideloaded'**
  String malwarePermsSideloaded(int count);

  /// No description provided for @phishingUrlTab.
  ///
  /// In en, this message translates to:
  /// **'🔗  URL Scanner'**
  String get phishingUrlTab;

  /// No description provided for @phishingSmsTab.
  ///
  /// In en, this message translates to:
  /// **'💬  SMS Scanner'**
  String get phishingSmsTab;

  /// No description provided for @phishingCheckLink.
  ///
  /// In en, this message translates to:
  /// **'Check a link 🔍'**
  String get phishingCheckLink;

  /// No description provided for @phishingPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste any URL — we\'ll scan it locally'**
  String get phishingPasteHint;

  /// No description provided for @phishingPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get phishingPaste;

  /// No description provided for @phishingScanNow.
  ///
  /// In en, this message translates to:
  /// **'Scan now'**
  String get phishingScanNow;

  /// No description provided for @phishingScanHistory.
  ///
  /// In en, this message translates to:
  /// **'Scan History'**
  String get phishingScanHistory;

  /// No description provided for @phishingScans.
  ///
  /// In en, this message translates to:
  /// **'{count} scans'**
  String phishingScans(int count);

  /// No description provided for @phishingNoScansTitle.
  ///
  /// In en, this message translates to:
  /// **'No scans yet'**
  String get phishingNoScansTitle;

  /// No description provided for @phishingNoScansSub.
  ///
  /// In en, this message translates to:
  /// **'URLs you scan will appear here'**
  String get phishingNoScansSub;

  /// No description provided for @phishingAnalysingTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Analysing URL'**
  String get phishingAnalysingTitle;

  /// No description provided for @phishingAnalysingSub.
  ///
  /// In en, this message translates to:
  /// **'Checking TLD, keywords, patterns, and structure'**
  String get phishingAnalysingSub;

  /// No description provided for @phishingVerdictPhishing.
  ///
  /// In en, this message translates to:
  /// **'PHISHING'**
  String get phishingVerdictPhishing;

  /// No description provided for @phishingVerdictSafe.
  ///
  /// In en, this message translates to:
  /// **'SAFE'**
  String get phishingVerdictSafe;

  /// No description provided for @phishingConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get phishingConfidence;

  /// No description provided for @phishingWhyFlagged.
  ///
  /// In en, this message translates to:
  /// **'Why AI flagged this'**
  String get phishingWhyFlagged;

  /// No description provided for @phishingHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How Phishing Detection Works'**
  String get phishingHowItWorks;

  /// No description provided for @phishingHowItWorksBody.
  ///
  /// In en, this message translates to:
  /// **'CyberGuard AI uses on-device rule-based detection with SHAP explainability to identify phishing URLs. Analysis includes TLD reputation, keyword matching, URL structure, and brand impersonation checks. All analysis is done locally — your URLs never leave your device.'**
  String get phishingHowItWorksBody;

  /// No description provided for @phishingGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get phishingGotIt;

  /// No description provided for @phishingSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'SMS Phishing 📨'**
  String get phishingSmsTitle;

  /// No description provided for @phishingSmsSub.
  ///
  /// In en, this message translates to:
  /// **'We scan your messages locally'**
  String get phishingSmsSub;

  /// No description provided for @phishingSmsLoad.
  ///
  /// In en, this message translates to:
  /// **'Load SMS'**
  String get phishingSmsLoad;

  /// No description provided for @phishingSmsScanAll.
  ///
  /// In en, this message translates to:
  /// **'Scan All'**
  String get phishingSmsScanAll;

  /// No description provided for @phishingSmsNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No SMS loaded'**
  String get phishingSmsNoneTitle;

  /// No description provided for @phishingSmsNoneSub.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Load SMS\" to fetch your recent messages'**
  String get phishingSmsNoneSub;

  /// No description provided for @phishingSmsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get phishingSmsUnknown;

  /// No description provided for @phishingSmsSuspicious.
  ///
  /// In en, this message translates to:
  /// **'SUSPICIOUS'**
  String get phishingSmsSuspicious;

  /// No description provided for @phishingSmsLinksScannedSafe.
  ///
  /// In en, this message translates to:
  /// **'Links Scanned — Safe'**
  String get phishingSmsLinksScannedSafe;

  /// No description provided for @phishingSmsLinksSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Suspicious Links Found!'**
  String get phishingSmsLinksSuspicious;

  /// No description provided for @phishingSmsScanLinks.
  ///
  /// In en, this message translates to:
  /// **'Scan {count} {count, plural, =1{link} other{links}}'**
  String phishingSmsScanLinks(int count);

  /// No description provided for @phishingSmsNoUrls.
  ///
  /// In en, this message translates to:
  /// **'No URLs found in this message'**
  String get phishingSmsNoUrls;

  /// No description provided for @wifiClearHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get wifiClearHistoryTooltip;

  /// No description provided for @wifiClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get wifiClearTitle;

  /// No description provided for @wifiClearBody.
  ///
  /// In en, this message translates to:
  /// **'Remove all Wi-Fi scan history?'**
  String get wifiClearBody;

  /// No description provided for @wifiClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get wifiClear;

  /// No description provided for @wifiScanThis.
  ///
  /// In en, this message translates to:
  /// **'Scan this network'**
  String get wifiScanThis;

  /// No description provided for @wifiScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning network…'**
  String get wifiScanning;

  /// No description provided for @wifiScanningSub.
  ///
  /// In en, this message translates to:
  /// **'Analysing security in real-time'**
  String get wifiScanningSub;

  /// No description provided for @wifiNoScan.
  ///
  /// In en, this message translates to:
  /// **'No scan yet'**
  String get wifiNoScan;

  /// No description provided for @wifiNoScanSub.
  ///
  /// In en, this message translates to:
  /// **'Tap Scan Network to analyse your Wi-Fi'**
  String get wifiNoScanSub;

  /// No description provided for @wifiUnknownSsid.
  ///
  /// In en, this message translates to:
  /// **'Unknown SSID'**
  String get wifiUnknownSsid;

  /// No description provided for @wifiTrust.
  ///
  /// In en, this message translates to:
  /// **'Trust: {score}%'**
  String wifiTrust(int score);

  /// No description provided for @wifiTrustScore.
  ///
  /// In en, this message translates to:
  /// **'Trust Score'**
  String get wifiTrustScore;

  /// No description provided for @wifiSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get wifiSignal;

  /// No description provided for @wifiBand.
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get wifiBand;

  /// No description provided for @wifiSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get wifiSpeed;

  /// No description provided for @wifiEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get wifiEncrypted;

  /// No description provided for @wifiYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get wifiYes;

  /// No description provided for @wifiNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get wifiNo;

  /// No description provided for @wifiSecurityChecks.
  ///
  /// In en, this message translates to:
  /// **'Security Checks'**
  String get wifiSecurityChecks;

  /// No description provided for @wifiChecksPassed.
  ///
  /// In en, this message translates to:
  /// **'{passed}/{total} passed'**
  String wifiChecksPassed(int passed, int total);

  /// No description provided for @wifiCheckEncryption.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get wifiCheckEncryption;

  /// No description provided for @wifiCheckSignalStrength.
  ///
  /// In en, this message translates to:
  /// **'Signal Strength'**
  String get wifiCheckSignalStrength;

  /// No description provided for @wifiCheckDnsHealth.
  ///
  /// In en, this message translates to:
  /// **'DNS Health'**
  String get wifiCheckDnsHealth;

  /// No description provided for @wifiCheckEvilTwin.
  ///
  /// In en, this message translates to:
  /// **'Evil Twin Detection'**
  String get wifiCheckEvilTwin;

  /// No description provided for @wifiCheckLatency.
  ///
  /// In en, this message translates to:
  /// **'Network Latency'**
  String get wifiCheckLatency;

  /// No description provided for @wifiCheckModernBand.
  ///
  /// In en, this message translates to:
  /// **'Modern Band (5GHz)'**
  String get wifiCheckModernBand;

  /// No description provided for @wifiEncDescYes.
  ///
  /// In en, this message translates to:
  /// **'Network uses WPA2/WPA3 encryption'**
  String get wifiEncDescYes;

  /// No description provided for @wifiEncDescNo.
  ///
  /// In en, this message translates to:
  /// **'Open network — traffic is unencrypted'**
  String get wifiEncDescNo;

  /// No description provided for @wifiDnsDescYes.
  ///
  /// In en, this message translates to:
  /// **'DNS resolved in {ms}ms'**
  String wifiDnsDescYes(int ms);

  /// No description provided for @wifiDnsDescNo.
  ///
  /// In en, this message translates to:
  /// **'DNS resolution failed — possible interception'**
  String get wifiDnsDescNo;

  /// No description provided for @wifiBssidDesc.
  ///
  /// In en, this message translates to:
  /// **'BSSID {bssid} matches stored record'**
  String wifiBssidDesc(String bssid);

  /// No description provided for @wifiLatencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Latency: {ms}ms'**
  String wifiLatencyDesc(int ms);

  /// No description provided for @wifiLatencyDescNone.
  ///
  /// In en, this message translates to:
  /// **'Latency not measured'**
  String get wifiLatencyDescNone;

  /// No description provided for @wifiBandDesc5.
  ///
  /// In en, this message translates to:
  /// **'Using 5GHz band — less interference'**
  String get wifiBandDesc5;

  /// No description provided for @wifiBandDesc24.
  ///
  /// In en, this message translates to:
  /// **'Using 2.4GHz band — more interference'**
  String get wifiBandDesc24;

  /// No description provided for @wifiSignalDesc.
  ///
  /// In en, this message translates to:
  /// **'Signal: {rssi} dBm ({label})'**
  String wifiSignalDesc(int rssi, String label);

  /// No description provided for @wifiNetworkDetails.
  ///
  /// In en, this message translates to:
  /// **'Network Details'**
  String get wifiNetworkDetails;

  /// No description provided for @wifiDetailSsid.
  ///
  /// In en, this message translates to:
  /// **'SSID'**
  String get wifiDetailSsid;

  /// No description provided for @wifiDetailBssid.
  ///
  /// In en, this message translates to:
  /// **'BSSID'**
  String get wifiDetailBssid;

  /// No description provided for @wifiDetailIp.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get wifiDetailIp;

  /// No description provided for @wifiDetailFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get wifiDetailFrequency;

  /// No description provided for @wifiDetailBand.
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get wifiDetailBand;

  /// No description provided for @wifiDetailLinkSpeed.
  ///
  /// In en, this message translates to:
  /// **'Link Speed'**
  String get wifiDetailLinkSpeed;

  /// No description provided for @wifiDetailSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get wifiDetailSignal;

  /// No description provided for @wifiDetailDnsLatency.
  ///
  /// In en, this message translates to:
  /// **'DNS Latency'**
  String get wifiDetailDnsLatency;

  /// No description provided for @wifiDetailScanned.
  ///
  /// In en, this message translates to:
  /// **'Scanned'**
  String get wifiDetailScanned;

  /// No description provided for @wifiUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get wifiUnknown;

  /// No description provided for @wifiNA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get wifiNA;

  /// No description provided for @cyberDefense.
  ///
  /// In en, this message translates to:
  /// **'Cyber Defense'**
  String get cyberDefense;

  /// No description provided for @defenseThreatFusion.
  ///
  /// In en, this message translates to:
  /// **'Threat Fusion'**
  String get defenseThreatFusion;

  /// No description provided for @defenseScreenshotScan.
  ///
  /// In en, this message translates to:
  /// **'Screenshot Scan'**
  String get defenseScreenshotScan;

  /// No description provided for @defensePredictiveRisk.
  ///
  /// In en, this message translates to:
  /// **'Predictive Risk'**
  String get defensePredictiveRisk;

  /// No description provided for @defenseArbitrationLog.
  ///
  /// In en, this message translates to:
  /// **'Arbitration Log'**
  String get defenseArbitrationLog;

  /// No description provided for @linkProtection.
  ///
  /// In en, this message translates to:
  /// **'Link Protection'**
  String get linkProtection;

  /// No description provided for @linkInterceptorTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Link Interceptor'**
  String get linkInterceptorTitle;

  /// No description provided for @linkInterceptorSub.
  ///
  /// In en, this message translates to:
  /// **'Scan links you open from other apps before they load'**
  String get linkInterceptorSub;

  /// No description provided for @cloudIntelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud threat intelligence'**
  String get cloudIntelTitle;

  /// No description provided for @cloudIntelSub.
  ///
  /// In en, this message translates to:
  /// **'Check links against Google Safe Browsing (sends the tapped link to Google). Off by default.'**
  String get cloudIntelSub;

  /// No description provided for @saveLinkHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Save link history'**
  String get saveLinkHistoryTitle;

  /// No description provided for @saveLinkHistorySub.
  ///
  /// In en, this message translates to:
  /// **'Store scanned links on this device. Off = nothing is kept.'**
  String get saveLinkHistorySub;

  /// No description provided for @defaultBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'Set CyberGuard as default browser'**
  String get defaultBrowserTitle;

  /// No description provided for @defaultBrowserSub.
  ///
  /// In en, this message translates to:
  /// **'Required to check links before they open. CyberGuard scans each link, then hands safe ones to your browser.'**
  String get defaultBrowserSub;

  /// No description provided for @defaultBrowserActive.
  ///
  /// In en, this message translates to:
  /// **'CyberGuard is your default browser — tapped links are protected.'**
  String get defaultBrowserActive;

  /// No description provided for @defaultBrowserSetCta.
  ///
  /// In en, this message translates to:
  /// **'Set as Default Browser'**
  String get defaultBrowserSetCta;

  /// No description provided for @cloudIntelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable cloud threat intelligence?'**
  String get cloudIntelDialogTitle;

  /// No description provided for @cloudIntelDialogBody.
  ///
  /// In en, this message translates to:
  /// **'When on, intercepted links are checked against Google Safe Browsing. The link you tapped is sent to Google for this check. Nothing else leaves your device. You can turn this off anytime.'**
  String get cloudIntelDialogBody;

  /// No description provided for @commonEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get commonEnable;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @threatBandSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe (0-30)'**
  String get threatBandSafe;

  /// No description provided for @threatBandSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Suspicious (31-60)'**
  String get threatBandSuspicious;

  /// No description provided for @threatBandDangerous.
  ///
  /// In en, this message translates to:
  /// **'Dangerous (61-80)'**
  String get threatBandDangerous;

  /// No description provided for @threatBandCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical (81-100)'**
  String get threatBandCritical;

  /// No description provided for @threatLevelSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get threatLevelSafe;

  /// No description provided for @threatLevelSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Suspicious'**
  String get threatLevelSuspicious;

  /// No description provided for @threatLevelDangerous.
  ///
  /// In en, this message translates to:
  /// **'Dangerous'**
  String get threatLevelDangerous;

  /// No description provided for @threatLevelCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get threatLevelCritical;

  /// No description provided for @confidencePct.
  ///
  /// In en, this message translates to:
  /// **'confidence {pct}%'**
  String confidencePct(int pct);

  /// No description provided for @warnDangerousTitle.
  ///
  /// In en, this message translates to:
  /// **'Dangerous Website Detected'**
  String get warnDangerousTitle;

  /// No description provided for @warnSuspiciousTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspicious Website'**
  String get warnSuspiciousTitle;

  /// No description provided for @warnRiskScore.
  ///
  /// In en, this message translates to:
  /// **'RISK SCORE'**
  String get warnRiskScore;

  /// No description provided for @warnOverrideDefault.
  ///
  /// In en, this message translates to:
  /// **'Blocked by trusted threat intelligence override.'**
  String get warnOverrideDefault;

  /// No description provided for @warnConflict.
  ///
  /// In en, this message translates to:
  /// **'Detection sources disagreed — verdict reconciled by arbitration.'**
  String get warnConflict;

  /// No description provided for @warnDestination.
  ///
  /// In en, this message translates to:
  /// **'DESTINATION'**
  String get warnDestination;

  /// No description provided for @warnVia.
  ///
  /// In en, this message translates to:
  /// **'via {app}'**
  String warnVia(String app);

  /// No description provided for @warnWhyFlagged.
  ///
  /// In en, this message translates to:
  /// **'WHY THIS IS FLAGGED'**
  String get warnWhyFlagged;

  /// No description provided for @warnSources.
  ///
  /// In en, this message translates to:
  /// **'INTELLIGENCE SOURCES'**
  String get warnSources;

  /// No description provided for @warnGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back (Recommended)'**
  String get warnGoBack;

  /// No description provided for @warnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue Anyway'**
  String get warnContinue;

  /// No description provided for @warnReport.
  ///
  /// In en, this message translates to:
  /// **'Report this link'**
  String get warnReport;

  /// No description provided for @warnReported.
  ///
  /// In en, this message translates to:
  /// **'Reported. Thank you.'**
  String get warnReported;

  /// No description provided for @warnOpenDangerousTitle.
  ///
  /// In en, this message translates to:
  /// **'Open a dangerous site?'**
  String get warnOpenDangerousTitle;

  /// No description provided for @warnOpenDangerousBody.
  ///
  /// In en, this message translates to:
  /// **'CyberGuard rated this link as high-risk. Opening it could expose your credentials or device. Continue at your own risk?'**
  String get warnOpenDangerousBody;

  /// No description provided for @warnOpenAnyway.
  ///
  /// In en, this message translates to:
  /// **'Open anyway'**
  String get warnOpenAnyway;

  /// No description provided for @warnPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'No URLs are stored unless you enable link history in Settings.'**
  String get warnPrivacyNote;

  /// No description provided for @fusionTitle.
  ///
  /// In en, this message translates to:
  /// **'Threat Fusion Scan'**
  String get fusionTitle;

  /// No description provided for @fusionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Check a link across all intelligence sources'**
  String get fusionPrompt;

  /// No description provided for @fusionRunScan.
  ///
  /// In en, this message translates to:
  /// **'Run Fusion Scan'**
  String get fusionRunScan;

  /// No description provided for @fusionUnified.
  ///
  /// In en, this message translates to:
  /// **'UNIFIED'**
  String get fusionUnified;

  /// No description provided for @fusionSourceAttribution.
  ///
  /// In en, this message translates to:
  /// **'SOURCE ATTRIBUTION'**
  String get fusionSourceAttribution;

  /// No description provided for @fusionExplanation.
  ///
  /// In en, this message translates to:
  /// **'EXPLANATION'**
  String get fusionExplanation;

  /// No description provided for @fusionConflict.
  ///
  /// In en, this message translates to:
  /// **'Sources disagreed — reconciled by arbitration.'**
  String get fusionConflict;

  /// No description provided for @fusionTrust.
  ///
  /// In en, this message translates to:
  /// **'trust {weight}'**
  String fusionTrust(int weight);

  /// No description provided for @arbitrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Arbitration Log'**
  String get arbitrationTitle;

  /// No description provided for @arbitrationClear.
  ///
  /// In en, this message translates to:
  /// **'Clear log'**
  String get arbitrationClear;

  /// No description provided for @arbitrationEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conflicts yet'**
  String get arbitrationEmptyTitle;

  /// No description provided for @arbitrationEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When detection sources disagree or a trusted source overrides CyberGuard, the decision is recorded here.'**
  String get arbitrationEmptyBody;

  /// No description provided for @arbitrationOverride.
  ///
  /// In en, this message translates to:
  /// **'Trusted override → {level}'**
  String arbitrationOverride(String level);

  /// No description provided for @arbitrationConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Source conflict → {level}'**
  String arbitrationConflictTitle(String level);

  /// No description provided for @riskTitle.
  ///
  /// In en, this message translates to:
  /// **'Predictive Risk'**
  String get riskTitle;

  /// No description provided for @riskNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get riskNoData;

  /// No description provided for @riskBandLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get riskBandLow;

  /// No description provided for @riskBandMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get riskBandMedium;

  /// No description provided for @riskBandHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get riskBandHigh;

  /// No description provided for @riskSuffix.
  ///
  /// In en, this message translates to:
  /// **'{band} RISK'**
  String riskSuffix(String band);

  /// No description provided for @riskForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Threat Forecast'**
  String get riskForecastTitle;

  /// No description provided for @riskTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'7-Day Risk Timeline'**
  String get riskTimelineTitle;

  /// No description provided for @riskWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why your risk is {band}'**
  String riskWhyTitle(String band);

  /// No description provided for @riskRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get riskRecommendations;

  /// No description provided for @forecastPhishing.
  ///
  /// In en, this message translates to:
  /// **'Phishing Attack'**
  String get forecastPhishing;

  /// No description provided for @forecastCredentialTheft.
  ///
  /// In en, this message translates to:
  /// **'Credential Theft'**
  String get forecastCredentialTheft;

  /// No description provided for @forecastMalware.
  ///
  /// In en, this message translates to:
  /// **'Malware Infection'**
  String get forecastMalware;

  /// No description provided for @rfPhishingTitle.
  ///
  /// In en, this message translates to:
  /// **'Phishing links encountered'**
  String get rfPhishingTitle;

  /// No description provided for @rfPhishingDetail.
  ///
  /// In en, this message translates to:
  /// **'{count} flagged in the last 7 days'**
  String rfPhishingDetail(int count);

  /// No description provided for @rfSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspicious SMS received'**
  String get rfSmsTitle;

  /// No description provided for @rfSmsDetail.
  ///
  /// In en, this message translates to:
  /// **'{count} phishing SMS detected'**
  String rfSmsDetail(int count);

  /// No description provided for @rfWifiTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown Wi-Fi networks used'**
  String get rfWifiTitle;

  /// No description provided for @rfWifiDetail.
  ///
  /// In en, this message translates to:
  /// **'{count} low-trust networks connected'**
  String rfWifiDetail(int count);

  /// No description provided for @rfMalwareTitle.
  ///
  /// In en, this message translates to:
  /// **'Risky apps installed'**
  String get rfMalwareTitle;

  /// No description provided for @rfMalwareDetail.
  ///
  /// In en, this message translates to:
  /// **'{count} high-risk apps detected'**
  String rfMalwareDetail(int count);

  /// No description provided for @rfInterceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Links blocked recently'**
  String get rfInterceptTitle;

  /// No description provided for @rfInterceptDetail.
  ///
  /// In en, this message translates to:
  /// **'{count} dangerous links intercepted'**
  String rfInterceptDetail(int count);

  /// No description provided for @rfBreachTitle.
  ///
  /// In en, this message translates to:
  /// **'Credentials in a known breach'**
  String get rfBreachTitle;

  /// No description provided for @rfBreachDetail.
  ///
  /// In en, this message translates to:
  /// **'Your account appears in breached data'**
  String get rfBreachDetail;

  /// No description provided for @rfTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Security score declining'**
  String get rfTrendTitle;

  /// No description provided for @rfTrendDetail.
  ///
  /// In en, this message translates to:
  /// **'Protection dropped {pts} pts recently'**
  String rfTrendDetail(int pts);

  /// No description provided for @recBreach.
  ///
  /// In en, this message translates to:
  /// **'Change passwords for breached accounts and enable 2FA.'**
  String get recBreach;

  /// No description provided for @recPhishing.
  ///
  /// In en, this message translates to:
  /// **'Avoid tapping links in unexpected messages; verify the sender.'**
  String get recPhishing;

  /// No description provided for @recWifi.
  ///
  /// In en, this message translates to:
  /// **'Avoid sensitive logins on public Wi-Fi; use a trusted network.'**
  String get recWifi;

  /// No description provided for @recMalware.
  ///
  /// In en, this message translates to:
  /// **'Review and uninstall high-risk apps; install only from Play Store.'**
  String get recMalware;

  /// No description provided for @recInterceptor.
  ///
  /// In en, this message translates to:
  /// **'Keep the Smart Link Interceptor enabled for ongoing protection.'**
  String get recInterceptor;

  /// No description provided for @recHealthy.
  ///
  /// In en, this message translates to:
  /// **'You\'re in good shape — keep CyberGuard protections enabled.'**
  String get recHealthy;

  /// No description provided for @screenshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Screenshot Scanner'**
  String get screenshotTitle;

  /// No description provided for @screenshotPrompt.
  ///
  /// In en, this message translates to:
  /// **'Scan a suspicious page screenshot'**
  String get screenshotPrompt;

  /// No description provided for @screenshotDesc.
  ///
  /// In en, this message translates to:
  /// **'Detects fake bank, UPI, OTP, login, KYC, lottery and support scams. Images are analysed on-device.'**
  String get screenshotDesc;

  /// No description provided for @screenshotGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get screenshotGallery;

  /// No description provided for @screenshotCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get screenshotCamera;

  /// No description provided for @screenshotScam.
  ///
  /// In en, this message translates to:
  /// **'SCAM'**
  String get screenshotScam;

  /// No description provided for @screenshotLooksClean.
  ///
  /// In en, this message translates to:
  /// **'Looks clean'**
  String get screenshotLooksClean;

  /// No description provided for @screenshotBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand referenced: {brand}'**
  String screenshotBrand(String brand);

  /// No description provided for @screenshotIndicators.
  ///
  /// In en, this message translates to:
  /// **'INDICATORS'**
  String get screenshotIndicators;

  /// No description provided for @screenshotExtractedText.
  ///
  /// In en, this message translates to:
  /// **'EXTRACTED TEXT'**
  String get screenshotExtractedText;

  /// No description provided for @scamFakeBank.
  ///
  /// In en, this message translates to:
  /// **'Fake bank page'**
  String get scamFakeBank;

  /// No description provided for @scamFakeUpi.
  ///
  /// In en, this message translates to:
  /// **'Fake UPI / payment page'**
  String get scamFakeUpi;

  /// No description provided for @scamFakeOtp.
  ///
  /// In en, this message translates to:
  /// **'Fake OTP request'**
  String get scamFakeOtp;

  /// No description provided for @scamFakeLogin.
  ///
  /// In en, this message translates to:
  /// **'Fake login page'**
  String get scamFakeLogin;

  /// No description provided for @scamFakeKyc.
  ///
  /// In en, this message translates to:
  /// **'Fake KYC form'**
  String get scamFakeKyc;

  /// No description provided for @scamFakeLottery.
  ///
  /// In en, this message translates to:
  /// **'Lottery / prize scam'**
  String get scamFakeLottery;

  /// No description provided for @scamFakeInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment scam'**
  String get scamFakeInvestment;

  /// No description provided for @scamFakeSupport.
  ///
  /// In en, this message translates to:
  /// **'Fake customer support'**
  String get scamFakeSupport;

  /// No description provided for @scamNone.
  ///
  /// In en, this message translates to:
  /// **'No scam indicators'**
  String get scamNone;

  /// No description provided for @scamReasonCategory.
  ///
  /// In en, this message translates to:
  /// **'{category}: \"{matched}\"'**
  String scamReasonCategory(String category, String matched);

  /// No description provided for @scamReasonBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand referenced: {brand}'**
  String scamReasonBrand(String brand);

  /// No description provided for @scamReasonUrgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency / pressure wording: \"{word}\"'**
  String scamReasonUrgency(String word);

  /// No description provided for @scamReasonNoIndicators.
  ///
  /// In en, this message translates to:
  /// **'No scam indicators detected in the text'**
  String get scamReasonNoIndicators;

  /// No description provided for @scamReasonNoText.
  ///
  /// In en, this message translates to:
  /// **'No readable text found in the image'**
  String get scamReasonNoText;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to CyberGuard AI'**
  String get authTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync your security settings across devices'**
  String get authSubtitle;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authSignUp;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authContinueOffline.
  ///
  /// In en, this message translates to:
  /// **'Continue without an account'**
  String get authContinueOffline;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'If that address is registered, a reset link is on its way.'**
  String get authResetSent;

  /// No description provided for @authUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-in isn\'t set up in this build'**
  String get authUnavailableTitle;

  /// No description provided for @authUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This copy of the app was built without Firebase credentials, so accounts are unavailable. Everything else works offline as usual.'**
  String get authUnavailableBody;

  /// No description provided for @authErrInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address doesn\'t look right'**
  String get authErrInvalidEmail;

  /// No description provided for @authErrWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get authErrWrongPassword;

  /// No description provided for @authErrUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for that email'**
  String get authErrUserNotFound;

  /// No description provided for @authErrEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for that email'**
  String get authErrEmailInUse;

  /// No description provided for @authErrWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get authErrWeakPassword;

  /// No description provided for @authErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get authErrNetwork;

  /// No description provided for @authErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrUnknown;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String authSignedInAs(String email);
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
      <String>['en', 'hi', 'ta', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
