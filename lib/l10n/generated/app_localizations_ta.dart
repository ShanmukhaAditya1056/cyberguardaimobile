// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'சைபர்கார்டு AI';

  @override
  String get appTagline => 'புத்திசாலித்தனமான பாதுகாப்பு உதவியாளர்';

  @override
  String get dashboard => 'டாஷ்போர்டு';

  @override
  String get alerts => 'எச்சரிக்கைகள்';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get phishingScanner => 'ஃபிஷிங் ஸ்கேனர்';

  @override
  String get appScanner => 'ஆப் ஸ்கேனர்';

  @override
  String get breachMonitor => 'ப்ரீச் கண்காணிப்பு';

  @override
  String get wifiScanner => 'வைஃபை ஸ்கேனர்';

  @override
  String get securityScore => 'பாதுகாப்பு மதிப்பெண்';

  @override
  String get scanNow => 'இப்போது ஸ்கேன் செய்';

  @override
  String get scanning => 'ஸ்கேன் செய்யப்படுகிறது…';

  @override
  String get protected => 'பாதுகாக்கப்பட்டது';

  @override
  String get atRisk => 'ஆபத்தில்';

  @override
  String get critical => 'அவசரம்';

  @override
  String lastScanned(String time) {
    return 'கடைசி ஸ்கேன் $time';
  }

  @override
  String get neverScanned => 'ஒருபோதும் ஸ்கேன் செய்யப்படவில்லை';

  @override
  String get protectionModules => 'பாதுகாப்பு தொகுதிகள்';

  @override
  String get sevenDayScore => '7-நாள் பாதுகாப்பு மதிப்பெண்';

  @override
  String get recentAlerts => 'சமீபத்திய எச்சரிக்கை';

  @override
  String get seeAll => 'அனைத்தும்';

  @override
  String get noAlerts => 'இன்னும் எச்சரிக்கைகள் இல்லை';

  @override
  String get noAlertsDescription =>
      'ஸ்கேன்களின் போது கண்டறியப்பட்ட அச்சுறுத்தல்கள் இங்கு தோன்றும்';

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String get appearance => 'தோற்றம்';

  @override
  String get themeSystem => 'சிஸ்டம் இயல்புநிலை';

  @override
  String get themeLight => 'வெளிச்சம்';

  @override
  String get themeDark => 'இருள்';

  @override
  String get language => 'மொழி';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी (Hindi)';

  @override
  String get languageTamil => 'தமிழ் (Tamil)';

  @override
  String get languageTelugu => 'తెలుగు (Telugu)';

  @override
  String get exportPdf => 'PDF ஆக ஏற்றுமதி';

  @override
  String get exportCsv => 'CSV ஆக ஏற்றுமதி';

  @override
  String get exportPdfSubtitle =>
      'மதிப்பெண், அச்சுறுத்தல்கள் மற்றும் போக்குகளுடன் பிராண்டட் அறிக்கை';

  @override
  String get exportCsvSubtitle => 'ஸ்ப்ரெட்ஷீட்டுக்கான மூல தரவு';

  @override
  String get reports => 'அறிக்கைகள் & ஏற்றுமதி';

  @override
  String get liveSmsGuard => 'நேரடி SMS ஃபிஷிங் காவலர்';

  @override
  String get liveSmsGuardSubtitle =>
      'ஒவ்வொரு உள்வரும் SMS-ஐ ஃபிஷிங் இணைப்புகளுக்கு ஆட்டோ-ஸ்கேன் செய்';

  @override
  String get scanQrCode => 'QR குறியீட்டை ஸ்கேன் செய்';

  @override
  String get checkBreach => 'இப்போது சரிபார்';

  @override
  String get enterEmail => 'உங்கள் மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get enterPassword => 'சோதிக்க கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get noBreachFound => 'ப்ரீச் எதுவும் இல்லை';

  @override
  String breachesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ப்ரீச்கள் கண்டறியப்பட்டன',
      one: '1 ப்ரீச் கண்டறியப்பட்டது',
    );
    return '$_temp0';
  }

  @override
  String get onboardAiSecurityTitle => 'AI-இயக்கப்படும் பாதுகாப்பு 🛡️';

  @override
  String get onboardAiSecurityDesc =>
      'ஆன்-டிவைஸ் இயந்திர கற்றல் நிகழ்நேரத்தில் ஃபிஷிங், மால்வேர் மற்றும் ப்ரீச்களைக் கண்டறியும் — உங்கள் தரவு போனை விட்டு வெளியேறாது.';

  @override
  String get onboardPhishingTitle => 'ஃபிஷிங் கண்டறிதல் 🔗';

  @override
  String get onboardPhishingDesc =>
      'எந்த இணைப்பையும் ஒட்டவும் அல்லது உங்கள் SMS-ஐ ஸ்கேன் செய்யவும் — வங்கி, UPI, OTP ஃபிஷிங் தாக்குதல்களைக் கண்டறியவும்.';

  @override
  String get onboardMalwareTitle => 'மால்வேர் ஸ்கேனர் 🐞';

  @override
  String get onboardMalwareDesc =>
      'அனுமதி வரைபட பகுப்பாய்வைப் பயன்படுத்தி நிறுவப்பட்ட ஆப்களை ஆழமாக ஸ்கேன் செய்து மறைந்த ஸ்பைவேர், ட்ரோஜான், ஸ்டாக்கர்வேரைக் கண்டறியவும்.';

  @override
  String get onboardBreachTitle => 'ப்ரீச் கண்காணிப்பு 🔐';

  @override
  String get onboardBreachDesc =>
      '14B+ கசிந்த பதிவுகளைச் சரிபார். உங்கள் மின்னஞ்சல் மற்றும் கடவுச்சொல் உள்ளூரில் ஹாஷ் செய்யப்படும் — முழுவதும் ஒருபோதும் அனுப்பப்படாது.';

  @override
  String get onboardPermsTitle => 'சில அனுமதிகள் மட்டும் 🙏';

  @override
  String get onboardPermsDesc =>
      'எங்களுக்கு SMS, இடம் மற்றும் அறிவிப்பு அனுமதிகள் தேவை. அனைத்து ஸ்கேன்களும் இந்த சாதனத்திலேயே இருக்கும்.';

  @override
  String get onboardContinue => 'தொடரவும்';

  @override
  String get onboardGrantStart => 'அனுமதிகளை அளித்து தொடங்கு';

  @override
  String get onboardSkip => 'தவிர்க்கவும்';

  @override
  String get scoreGreetingProtected => 'நீங்கள் பாதுகாப்பாக இருக்கிறீர்கள்';

  @override
  String get scoreGreetingAtRisk => 'சில விஷயங்களைச் சரிபார்க்கவும் ⚠️';

  @override
  String get scoreGreetingCritical => 'உடனடியாக நடவடிக்கை எடுக்கவும் 🚨';

  @override
  String get scoreGreetingFirstScan => 'வணக்கம் 👋';

  @override
  String get scoreHeadlineProtected => 'அனைத்தும் ஆரோக்கியமாக உள்ளன';

  @override
  String get scoreHeadlineAtRisk => 'ஒரு விரைவான பார்வை எடுக்கவும்';

  @override
  String get scoreHeadlineCritical => 'முக்கியமான பிரச்சினைகள் கண்டறியப்பட்டன';

  @override
  String get scoreHeadlineFirstScan => 'உங்கள் போனைப் பாதுகாக்கவும்';

  @override
  String get permSmsTitle => 'SMS அணுகல் தேவை';

  @override
  String get permSmsRationale =>
      'ஃபிஷிங் இணைப்புகளைக் கண்டறிய சைபர்கார்டு AI உங்கள் SMS செய்திகளைப் படிக்க வேண்டும். உங்கள் செய்திகள் எந்த சர்வருக்கும் அனுப்பப்படாது.';

  @override
  String get permLocationTitle => 'இட அணுகல் தேவை';

  @override
  String get permLocationRationale =>
      'SSID போன்ற வைஃபை பிணைய விவரங்களை அணுக Android இட அனுமதி தேவைப்படுகிறது. சைபர்கார்டு AI இதை உங்கள் நெட்வொர்க் பாதுகாப்பை பகுப்பாய்வு செய்ய மட்டுமே பயன்படுத்துகிறது.';

  @override
  String get permNotifTitle => 'அறிவிப்புகள்';

  @override
  String get permNotifRationale =>
      'அச்சுறுத்தல்களைக் கண்டறிந்தவுடன் நீங்கள் உடனடி நடவடிக்கை எடுக்க சைபர்கார்டு AI அறிவிப்புகளை அனுப்புகிறது.';

  @override
  String get permAllowButton => 'அனுமதி அளி';

  @override
  String get permNotNow => 'இப்போது வேண்டாம்';

  @override
  String get dialogCancel => 'ரத்துசெய்';

  @override
  String get dialogConfirm => 'உறுதிசெய்';

  @override
  String get dialogClearAll => 'அனைத்தையும் அழி';

  @override
  String get dialogReset => 'மீட்டமை';

  @override
  String get dialogDelete => 'நீக்கு';

  @override
  String get dialogClose => 'மூடு';

  @override
  String get breachInputTitle => 'உங்கள் தரவு கசிந்துள்ளதா எனப் பாருங்கள்';

  @override
  String get breachInputSubtitle =>
      '12+ பில்லியன் கசிந்த பதிவுகளில் தேடுகிறோம்';

  @override
  String get breachTabEmail => 'மின்னஞ்சல்';

  @override
  String get breachTabPhone => 'கைபேசி எண்';

  @override
  String get breachInputHintEmail => 'உங்கள் மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get breachInputHintPhone => '10-இலக்க எண்ணை உள்ளிடவும்';

  @override
  String get breachPrivacyFooter =>
      'k-மறைவு பாதுகாப்பு · உங்கள் தரவு இந்த சாதனத்தை விட்டு வெளியேறாது';

  @override
  String get breachNoBreaches => 'உள்ளீடு கசிவுகள் இல்லை';

  @override
  String get breachNoBreachesEmailDesc =>
      'நல்ல செய்தி! உங்கள் மின்னஞ்சல் எந்த அறியப்பட்ட தரவு கசிவிலும் இல்லை.';

  @override
  String get breachNoBreachesPhoneDesc =>
      'நல்ல செய்தி! இந்தத் தொலைபேசி எண் எந்த அறியப்பட்ட தரவு கசிவிலும் இல்லை.';

  @override
  String get breachCheckedCount => '12,454,308,593 பதிவுகள் சரிபார்க்கப்பட்டது';

  @override
  String get breachStayProtected => 'பாதுகாப்பாக இருங்கள்';

  @override
  String get breachTipUnique =>
      'ஒவ்வொரு கணக்கிற்கும் தனித்த கடவுச்சொற்களைப் பயன்படுத்தவும்';

  @override
  String get breach2FA => 'இரு-காரணி அங்கீகாரத்தை இயக்கவும்';

  @override
  String get breachPwManager => 'கடவுச்சொல் நிர்வாகியைப் பயன்படுத்தவும்';

  @override
  String get breachOfflineBannerTitle =>
      'ஆஃப்லைன் தரவுத்தளத்திலிருந்து முடிவுகள்';

  @override
  String get breachOfflineBannerBody =>
      'இவை உண்மையான வரலாற்று கசிவுகள், ஆனால் பொருத்தம் உங்கள் மின்னஞ்சலின் உள்ளூர் ஹாஷிலிருந்து வருகிறது — HIBP நேரடி தேடலில் இருந்து அல்ல. நேரடிச் சரிபார்ப்புக்கு அமைப்புகளில் இலவச HIBP API சாவியை அமைக்கவும்.';

  @override
  String get breachFoundEmail =>
      'உங்கள் மின்னஞ்சல் இந்தக் கசிவுகளில் வெளிப்பட்டது:';

  @override
  String get breachFoundPhone => 'இந்த எண் இந்தக் கசிவுகளில் வெளிப்பட்டது:';

  @override
  String breachAccountsAffected(String count) {
    return '$count கணக்குகள் பாதிக்கப்பட்டுள்ளன';
  }

  @override
  String get breachCompromisedData => 'வெளிப்பட்ட தரவு';

  @override
  String get breachWhatToDo => 'நான் என்ன செய்ய வேண்டும்?';

  @override
  String get breachStep1 =>
      'இதையே மீண்டும் பயன்படுத்திய ஒவ்வொரு தளத்திலும் கடவுச்சொற்களை மாற்றவும்.';

  @override
  String get breachStep2 =>
      'இரு-காரணி அங்கீகாரத்தை இயக்கவும் — சாத்தியமானால் authenticator செயலியுடன்.';

  @override
  String get breachStep3 =>
      'கசிந்த சேவை போல் பாசாங்கு செய்யும் ஃபிஷிங் மின்னஞ்சல்களைப் பற்றி கவனமாக இருங்கள்.';

  @override
  String get breachStep4 =>
      'ஒவ்வொரு கணக்கிற்கும் தனித்த கடவுச்சொற்களைக் கொள்ள கடவுச்சொல் நிர்வாகியைக் கருதவும்.';

  @override
  String get breachPastChecks => 'முந்தைய சரிபார்ப்புகள்';

  @override
  String get breachStatusSafe => 'பாதுகாப்பானது';

  @override
  String get breachStatusBreached => 'கசிந்தது';

  @override
  String get breachPrivacyTitle =>
      'உங்கள் தனியுரிமையை எப்படிக் காப்பாற்றுகிறோம்';

  @override
  String get breachPrivacyStep1 =>
      'உங்கள் உள்ளீடு உங்கள் சாதனத்திலேயே ஹாஷ் செய்யப்படுகிறது.';

  @override
  String get breachPrivacyStep2 =>
      'ஹாஷின் முதல் 5 எழுத்துகள் மட்டுமே HIBP-க்கு அனுப்பப்படுகின்றன.';

  @override
  String get breachPrivacyStep3 =>
      'ஆயிரக்கணக்கான பொருந்தும் ஹாஷ்கள் திரும்ப வருகின்றன.';

  @override
  String get breachPrivacyStep4 =>
      '100% பொருத்த சோதனை உங்கள் சாதனத்திலேயே நடக்கிறது.';

  @override
  String get qrScanTitle => 'QR ஸ்கேன்';

  @override
  String get qrUploadFromGallery => 'கேலரியில் இருந்து பதிவேற்று';

  @override
  String get qrPointAtCode =>
      'எந்த QR-ஐயும் காண்பிக்கவும் · ஸ்கேன் URL-கள் சாதனத்திலேயே சரிபார்க்கப்படும்';

  @override
  String get qrNotAUrl => 'இது URL அல்ல';

  @override
  String get qrNotAUrlBody => 'QR கோட் உரையை கொண்டிருந்தது, இணைப்பை அல்ல:';

  @override
  String get qrPhishingDetected => 'ஃபிஷிங் QR கண்டறியப்பட்டது';

  @override
  String get qrSafeLink => 'பாதுகாப்பான இணைப்பு';

  @override
  String get qrScanAnother => 'மீண்டும் ஸ்கேன்';

  @override
  String get qrViewDetails => 'விவரங்களைக் காண்க';

  @override
  String qrConfidence(int count) {
    return '$count% நம்பிக்கை';
  }

  @override
  String get qrCameraUnavailable =>
      'கேமரா கிடைக்கவில்லை. கேமரா அனுமதி வழங்கி மீண்டும் முயற்சிக்கவும்.';

  @override
  String get qrOpenSettings => 'அமைப்புகளைத் திற';

  @override
  String get qrNoCodeInImage => 'இந்தப் படத்தில் QR கோட் இல்லை.';

  @override
  String get scoreSuffix => '/100';

  @override
  String get scoreLabel => 'மதிப்பெண்';

  @override
  String scannedAgo(String time) {
    return '$time ஸ்கேன் செய்யப்பட்டது';
  }

  @override
  String get dashboardRefreshed => 'டாஷ்போர்டு புதுப்பிக்கப்பட்டது';

  @override
  String dashboardRefreshedWithWifi(int score) {
    return 'டாஷ்போர்டு புதுப்பிக்கப்பட்டது · வைஃபை நம்பிக்கை $score/100';
  }

  @override
  String get moduleTitlePhishing => 'ஃபிஷிங்';

  @override
  String get moduleSubtitlePhishing => 'URL & SMS ஸ்கேனர்';

  @override
  String get moduleTitleMalware => 'மால்வேர்';

  @override
  String get moduleSubtitleMalware => 'ஆப் பாதுகாப்பு';

  @override
  String get moduleTitleBreach => 'மீறல்';

  @override
  String get moduleSubtitleBreach => 'தரவு கசிவு கண்காணிப்பு';

  @override
  String get moduleTitleWifi => 'வைஃபை';

  @override
  String get moduleSubtitleWifi => 'வலையமைப்பு பகுப்பாய்வு';

  @override
  String get moduleNotScanned => 'ஸ்கேன் இல்லை';

  @override
  String get statTotalScans => 'மொத்த ஸ்கேன்கள்';

  @override
  String get statThreats => 'அச்சுறுத்தல்கள்';

  @override
  String get statLastScan => 'கடைசி ஸ்கேன்';

  @override
  String get statNever => 'ஒருபோதும் இல்லை';

  @override
  String get settingRealTimeAlerts => 'நிகழ்நேர எச்சரிக்கைகள்';

  @override
  String get settingRealTimeAlertsSub =>
      'அச்சுறுத்தல்கள் கண்டறியப்படும்போது அறிவிப்பு பெறுங்கள்';

  @override
  String get settingClipboardScan => 'கிளிப்போர்டு ஸ்கேன்';

  @override
  String get settingClipboardScanSub =>
      'கிளிப்போர்டில் நகலெடுக்கப்பட்ட URL-களை ஸ்கேன் செய்க';

  @override
  String get settingWifiAutoScan => 'தானியங்கி வைஃபை ஸ்கேன்';

  @override
  String get settingWifiAutoScanSub => 'வலையமைப்பு மாறும்போது ஸ்கேன் செய்க';

  @override
  String get smsPermissionDenied =>
      'SMS அனுமதி மறுக்கப்பட்டது — நேரடி ஸ்கேன் தொடங்க முடியாது';

  @override
  String get settingsAutoScanFrequency => 'ஸ்கேன் அதிர்வெண்';

  @override
  String settingsBackgroundScanEvery(int hours) {
    return 'ஒவ்வொரு $hours மணிநேரத்திற்கும் பின்னணி ஸ்கேன்';
  }

  @override
  String get settingsHibpTitle => 'Have I Been Pwned API விசை';

  @override
  String get settingsHibpDesc =>
      'மின்னஞ்சல் மீறல் சோதனைக்கு தேவை. haveibeenpwned.com/API/Key இல் இலவசமாக பெறுங்கள்';

  @override
  String get settingsHibpPasteHint => 'உங்கள் API விசையை இங்கே ஒட்டவும்…';

  @override
  String get settingsHibpSave => 'விசையை சேமி';

  @override
  String get settingsHibpSaved => 'API விசை சேமிக்கப்பட்டது';

  @override
  String get settingsHibpConfigured => 'API விசை அமைக்கப்பட்டது';

  @override
  String get settingsPrivacy => 'தனியுரிமை & தரவு';

  @override
  String get settingsKAnon => 'k-அநாமதேய நெறிமுறை';

  @override
  String get settingsKAnonDesc =>
      'கடவுச்சொற்கள் எந்த சேவையகத்திற்கும் அனுப்பப்படாது. SHA-1 ஹாஷின் முதல் 5 எழுத்துகள் மட்டுமே அனுப்பப்படுகின்றன. உங்கள் சான்றுகள் சாதனத்தை விட்டு வெளியேறாது.';

  @override
  String get settingsLocalStorage => 'உள்ளக சேமிப்பு மட்டும்';

  @override
  String get settingsLocalStorageDesc =>
      'அனைத்து ஸ்கேன் முடிவுகளும் வரலாறும் என்க்ரிப்ட் செய்யப்பட்ட Hive சேமிப்பில் சாதனத்தில் சேமிக்கப்படுகின்றன. எந்த தரவும் சேவையகங்களுக்கு அனுப்பப்படவில்லை.';

  @override
  String get settingsAbout => 'பற்றி';

  @override
  String get settingsAboutVersion => 'பதிப்பு';

  @override
  String get settingsAboutEngine => 'கண்டறிதல் இயந்திரம்';

  @override
  String get settingsAboutSources => 'தரவு ஆதாரங்கள்';

  @override
  String get settingsAboutModel => 'AI மாதிரி';

  @override
  String get settingsDangerZone => 'ஆபத்து மண்டலம்';

  @override
  String get settingsResetDesc =>
      'அனைத்து அமைப்புகளையும் இயல்புநிலைக்கு மீட்டமை. இது ஸ்கேன் வரலாற்றை நீக்காது.';

  @override
  String get settingsResetBtn => 'அமைப்புகளை மீட்டமை';

  @override
  String get settingsResetTitle => 'அமைப்புகளை மீட்டமை';

  @override
  String get settingsResetBody =>
      'அனைத்து அமைப்புகளும் இயல்புநிலைக்கு மீட்டமைக்கப்படும். தொடரவா?';

  @override
  String get exportGenerating => 'PDF அறிக்கை உருவாக்கப்படுகிறது…';

  @override
  String exportFailed(String error) {
    return 'ஏற்றுமதி தோல்வி: $error';
  }

  @override
  String get alertsMarkAllRead => 'அனைத்தும் படித்ததாக குறி';

  @override
  String alertsNoFilter(String filter) {
    return '$filter எச்சரிக்கைகள் இல்லை';
  }

  @override
  String get alertsTryDifferent => 'வேறு வடிகட்டியை முயற்சிக்கவும்';

  @override
  String get alertsClearTitle => 'அனைத்து எச்சரிக்கைகளையும் அழி';

  @override
  String get alertsClearBody =>
      'இது அனைத்து எச்சரிக்கைகளையும் நிரந்தரமாக நீக்கும்.';

  @override
  String get alertsFilterAll => 'அனைத்தும்';

  @override
  String get alertsFilterPhishing => 'ஃபிஷிங்';

  @override
  String get alertsFilterMalware => 'மால்வேர்';

  @override
  String get alertsFilterBreach => 'மீறல்';

  @override
  String get alertsFilterWifi => 'வைஃபை';

  @override
  String get malwareIssuesFound => 'சிக்கல்கள் கண்டறியப்பட்டன ⚠️';

  @override
  String get malwareAppSecurity => 'ஆப் பாதுகாப்பு 🛡️';

  @override
  String get malwareTapToScan =>
      'உங்கள் ஆப்களை பகுப்பாய்வு செய்ய ஸ்கேனை அழுத்தவும்';

  @override
  String malwareAppsThreats(int apps, int threats) {
    String _temp0 = intl.Intl.pluralLogic(
      threats,
      locale: localeName,
      other: 'அச்சுறுத்தல்கள்',
      one: 'அச்சுறுத்தல்',
    );
    return '$apps ஆப்கள் · $threats $_temp0';
  }

  @override
  String malwareLastScan(String time) {
    return 'கடைசி ஸ்கேன் $time';
  }

  @override
  String get malwareScanNow => 'ஆப்களை ஸ்கேன் செய்';

  @override
  String malwareAnalysing(String name) {
    return '$name பகுப்பாய்வு…';
  }

  @override
  String malwareEtaSec(String sec) {
    return '~$secவி';
  }

  @override
  String malwareProgress(int progress, int total) {
    return '$progress / $total ஆப்கள்';
  }

  @override
  String get malwareRiskCritical => 'முக்கியமான';

  @override
  String get malwareRiskHigh => 'உயர்';

  @override
  String get malwareRiskMedium => 'நடுத்தர';

  @override
  String get malwareRiskLow => 'குறைந்த';

  @override
  String get malwareSearch => 'ஆப்களை தேடு…';

  @override
  String get malwareNoAppsTitle => 'ஆப்கள் கிடைக்கவில்லை';

  @override
  String get malwareNoAppsSub =>
      'உங்கள் நிறுவப்பட்ட ஆப்களை பகுப்பாய்வு செய்ய ஸ்கேனை அழுத்தவும்';

  @override
  String get malwareNoMatchTitle => 'வடிகட்டிக்கு பொருந்தும் ஆப்கள் இல்லை';

  @override
  String get malwareNoMatchSub =>
      'வேறு வடிகட்டி அல்லது தேடல் சொல்லை முயற்சிக்கவும்';

  @override
  String malwarePermsVerified(int count) {
    return '$count அனுமதிகள் • சரிபார்க்கப்பட்டது';
  }

  @override
  String malwarePermsSideloaded(int count) {
    return '$count அனுமதிகள் • பக்கமாக நிறுவப்பட்டது';
  }

  @override
  String get phishingUrlTab => '🔗  URL ஸ்கேனர்';

  @override
  String get phishingSmsTab => '💬  SMS ஸ்கேனர்';

  @override
  String get phishingCheckLink => 'இணைப்பை சரிபார் 🔍';

  @override
  String get phishingPasteHint =>
      'எந்த URL-ஐயும் ஒட்டவும் — நாங்கள் சாதனத்தில் ஸ்கேன் செய்வோம்';

  @override
  String get phishingPaste => 'ஒட்டு';

  @override
  String get phishingScanNow => 'ஸ்கேன் செய்';

  @override
  String get phishingScanHistory => 'ஸ்கேன் வரலாறு';

  @override
  String phishingScans(int count) {
    return '$count ஸ்கேன்கள்';
  }

  @override
  String get phishingNoScansTitle => 'இன்னும் ஸ்கேன்கள் இல்லை';

  @override
  String get phishingNoScansSub =>
      'நீங்கள் ஸ்கேன் செய்யும் URL-கள் இங்கே தோன்றும்';

  @override
  String get phishingAnalysingTitle => 'AI URL-ஐ பகுப்பாய்வு செய்கிறது';

  @override
  String get phishingAnalysingSub =>
      'TLD, முக்கிய சொற்கள், அமைப்பு பரிசோதிக்கப்படுகிறது';

  @override
  String get phishingVerdictPhishing => 'ஃபிஷிங்';

  @override
  String get phishingVerdictSafe => 'பாதுகாப்பானது';

  @override
  String get phishingConfidence => 'நம்பிக்கை';

  @override
  String get phishingWhyFlagged => 'AI ஏன் இதை குறித்தது';

  @override
  String get phishingHowItWorks => 'ஃபிஷிங் கண்டறிதல் எவ்வாறு செயல்படுகிறது';

  @override
  String get phishingHowItWorksBody =>
      'சைபர்கார்ட் AI சாதனத்திலேயே SHAP-விளக்கக்கூடிய விதி அடிப்படையிலான கண்டறிதலைப் பயன்படுத்துகிறது. பகுப்பாய்வில் TLD நற்பெயர், முக்கிய சொல் பொருத்தம், URL அமைப்பு, மற்றும் பிராண்ட் போலி சோதனைகள் அடங்கும். எல்லா பகுப்பாய்வும் சாதனத்திலேயே செய்யப்படுகிறது — உங்கள் URL-கள் ஒருபோதும் வெளியேறவில்லை.';

  @override
  String get phishingGotIt => 'புரிந்தது';

  @override
  String get phishingSmsTitle => 'SMS ஃபிஷிங் 📨';

  @override
  String get phishingSmsSub => 'உங்கள் செய்திகளை சாதனத்தில் ஸ்கேன் செய்கிறோம்';

  @override
  String get phishingSmsLoad => 'SMS ஏற்று';

  @override
  String get phishingSmsScanAll => 'அனைத்தையும் ஸ்கேன்';

  @override
  String get phishingSmsNoneTitle => 'SMS ஏற்றப்படவில்லை';

  @override
  String get phishingSmsNoneSub =>
      'சமீபத்திய செய்திகளை பெற \"SMS ஏற்று\" அழுத்தவும்';

  @override
  String get phishingSmsUnknown => 'தெரியாதது';

  @override
  String get phishingSmsSuspicious => 'சந்தேகத்திற்குரியது';

  @override
  String get phishingSmsLinksScannedSafe => 'இணைப்புகள் பாதுகாப்பானவை';

  @override
  String get phishingSmsLinksSuspicious =>
      'சந்தேகத்திற்குரிய இணைப்புகள் கண்டறியப்பட்டன!';

  @override
  String phishingSmsScanLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'இணைப்புகளை',
      one: 'இணைப்பை',
    );
    return '$count $_temp0 ஸ்கேன் செய்';
  }

  @override
  String get phishingSmsNoUrls => 'இந்த செய்தியில் URL-கள் இல்லை';

  @override
  String get wifiClearHistoryTooltip => 'வரலாற்றை அழி';

  @override
  String get wifiClearTitle => 'வரலாற்றை அழி';

  @override
  String get wifiClearBody => 'அனைத்து வைஃபை ஸ்கேன் வரலாற்றையும் அகற்றவா?';

  @override
  String get wifiClear => 'அழி';

  @override
  String get wifiScanThis => 'இந்த வலையை ஸ்கேன்';

  @override
  String get wifiScanning => 'வலையமைப்பு ஸ்கேன் செய்யப்படுகிறது…';

  @override
  String get wifiScanningSub => 'நிகழ்நேரத்தில் பாதுகாப்பு பகுப்பாய்வு';

  @override
  String get wifiNoScan => 'இன்னும் ஸ்கேன் இல்லை';

  @override
  String get wifiNoScanSub =>
      'உங்கள் வைஃபையை பகுப்பாய்வு செய்ய ஸ்கேன் வலையமைப்பு அழுத்தவும்';

  @override
  String get wifiUnknownSsid => 'அறியப்படாத SSID';

  @override
  String wifiTrust(int score) {
    return 'நம்பிக்கை: $score%';
  }

  @override
  String get wifiTrustScore => 'நம்பிக்கை மதிப்பெண்';

  @override
  String get wifiSignal => 'சிக்னல்';

  @override
  String get wifiBand => 'பேண்ட்';

  @override
  String get wifiSpeed => 'வேகம்';

  @override
  String get wifiEncrypted => 'என்க்ரிப்ட்';

  @override
  String get wifiYes => 'ஆம்';

  @override
  String get wifiNo => 'இல்லை';

  @override
  String get wifiSecurityChecks => 'பாதுகாப்பு சோதனைகள்';

  @override
  String wifiChecksPassed(int passed, int total) {
    return '$passed/$total தேர்ச்சி';
  }

  @override
  String get wifiCheckEncryption => 'என்க்ரிப்ஷன்';

  @override
  String get wifiCheckSignalStrength => 'சிக்னல் வலிமை';

  @override
  String get wifiCheckDnsHealth => 'DNS ஆரோக்கியம்';

  @override
  String get wifiCheckEvilTwin => 'தீய இரட்டை கண்டறிதல்';

  @override
  String get wifiCheckLatency => 'வலையமைப்பு தாமதம்';

  @override
  String get wifiCheckModernBand => 'நவீன பேண்ட் (5GHz)';

  @override
  String get wifiEncDescYes =>
      'வலையமைப்பு WPA2/WPA3 என்க்ரிப்ஷனைப் பயன்படுத்துகிறது';

  @override
  String get wifiEncDescNo =>
      'திறந்த வலையமைப்பு — போக்குவரத்து என்க்ரிப்ட் ஆகவில்லை';

  @override
  String wifiDnsDescYes(int ms) {
    return 'DNS ${ms}ms இல் தீர்க்கப்பட்டது';
  }

  @override
  String get wifiDnsDescNo => 'DNS தீர்க்கப்படவில்லை — இடையீட்டு சாத்தியம்';

  @override
  String wifiBssidDesc(String bssid) {
    return 'BSSID $bssid சேமிக்கப்பட்ட பதிவுடன் பொருந்துகிறது';
  }

  @override
  String wifiLatencyDesc(int ms) {
    return 'தாமதம்: ${ms}ms';
  }

  @override
  String get wifiLatencyDescNone => 'தாமதம் அளவிடப்படவில்லை';

  @override
  String get wifiBandDesc5 => '5GHz பேண்ட் பயன்பாட்டில் — குறைந்த இடையூறு';

  @override
  String get wifiBandDesc24 => '2.4GHz பேண்ட் பயன்பாட்டில் — அதிக இடையூறு';

  @override
  String wifiSignalDesc(int rssi, String label) {
    return 'சிக்னல்: $rssi dBm ($label)';
  }

  @override
  String get wifiNetworkDetails => 'வலையமைப்பு விவரங்கள்';

  @override
  String get wifiDetailSsid => 'SSID';

  @override
  String get wifiDetailBssid => 'BSSID';

  @override
  String get wifiDetailIp => 'IP முகவரி';

  @override
  String get wifiDetailFrequency => 'அதிர்வெண்';

  @override
  String get wifiDetailBand => 'பேண்ட்';

  @override
  String get wifiDetailLinkSpeed => 'லிங்க் வேகம்';

  @override
  String get wifiDetailSignal => 'சிக்னல்';

  @override
  String get wifiDetailDnsLatency => 'DNS தாமதம்';

  @override
  String get wifiDetailScanned => 'ஸ்கேன் செய்யப்பட்டது';

  @override
  String get wifiUnknown => 'தெரியாதது';

  @override
  String get wifiNA => 'பொருந்தாது';

  @override
  String get cyberDefense => 'சைபர் பாதுகாப்பு';

  @override
  String get defenseThreatFusion => 'அச்சுறுத்தல் இணைப்பு';

  @override
  String get defenseScreenshotScan => 'ஸ்கிரீன்ஷாட் ஸ்கேன்';

  @override
  String get defensePredictiveRisk => 'முன்னறிவிப்பு ஆபத்து';

  @override
  String get defenseArbitrationLog => 'தீர்ப்பு பதிவு';

  @override
  String get linkProtection => 'இணைப்பு பாதுகாப்பு';

  @override
  String get linkInterceptorTitle => 'ஸ்மார்ட் இணைப்பு இடைமறிப்பான்';

  @override
  String get linkInterceptorSub =>
      'மற்ற செயலிகளில் திறக்கும் இணைப்புகளை ஏற்றுவதற்கு முன் ஸ்கேன் செய்யவும்';

  @override
  String get cloudIntelTitle => 'கிளவுட் அச்சுறுத்தல் நுண்ணறிவு';

  @override
  String get cloudIntelSub =>
      'இணைப்புகளை Google Safe Browsing உடன் சரிபார்க்கவும் (தட்டிய இணைப்பு Google-க்கு அனுப்பப்படும்). இயல்பாக அணைக்கப்பட்டுள்ளது.';

  @override
  String get saveLinkHistoryTitle => 'இணைப்பு வரலாற்றைச் சேமி';

  @override
  String get saveLinkHistorySub =>
      'ஸ்கேன் செய்த இணைப்புகளை இந்த சாதனத்தில் சேமிக்கவும். அணைப்பு = எதுவும் வைக்கப்படாது.';

  @override
  String get defaultBrowserTitle =>
      'CyberGuard ஐ இயல்புநிலை உலாவியாக அமைக்கவும்';

  @override
  String get defaultBrowserSub =>
      'இணைப்புகள் திறப்பதற்கு முன் சரிபார்க்க தேவை. CyberGuard ஒவ்வொரு இணைப்பையும் ஸ்கேன் செய்து, பாதுகாப்பானவற்றை உங்கள் உலாவிக்கு அனுப்புகிறது.';

  @override
  String get defaultBrowserActive =>
      'CyberGuard உங்கள் இயல்புநிலை உலாவி — தட்டிய இணைப்புகள் பாதுகாக்கப்படுகின்றன.';

  @override
  String get defaultBrowserSetCta => 'இயல்புநிலை உலாவியாக அமைக்கவும்';

  @override
  String get cloudIntelDialogTitle => 'கிளவுட் அச்சுறுத்தல் நுண்ணறிவை இயக்கவா?';

  @override
  String get cloudIntelDialogBody =>
      'இயக்கப்பட்டால், இடைமறித்த இணைப்புகள் Google Safe Browsing உடன் சரிபார்க்கப்படும். நீங்கள் தட்டிய இணைப்பு இந்தச் சரிபார்ப்புக்காக Google-க்கு அனுப்பப்படும். வேறு எதுவும் உங்கள் சாதனத்தை விட்டு வெளியேறாது. இதை எப்போது வேண்டுமானாலும் அணைக்கலாம்.';

  @override
  String get commonEnable => 'இயக்கு';

  @override
  String get commonCancel => 'ரத்து';

  @override
  String get threatBandSafe => 'பாதுகாப்பானது (0-30)';

  @override
  String get threatBandSuspicious => 'சந்தேகத்திற்குரியது (31-60)';

  @override
  String get threatBandDangerous => 'ஆபத்தானது (61-80)';

  @override
  String get threatBandCritical => 'முக்கியமானது (81-100)';

  @override
  String get threatLevelSafe => 'பாதுகாப்பானது';

  @override
  String get threatLevelSuspicious => 'சந்தேகத்திற்குரியது';

  @override
  String get threatLevelDangerous => 'ஆபத்தானது';

  @override
  String get threatLevelCritical => 'முக்கியமானது';

  @override
  String confidencePct(int pct) {
    return 'நம்பகத்தன்மை $pct%';
  }

  @override
  String get warnDangerousTitle => 'ஆபத்தான இணையதளம் கண்டறியப்பட்டது';

  @override
  String get warnSuspiciousTitle => 'சந்தேகத்திற்குரிய இணையதளம்';

  @override
  String get warnRiskScore => 'ஆபத்து மதிப்பெண்';

  @override
  String get warnOverrideDefault =>
      'நம்பகமான அச்சுறுத்தல் நுண்ணறிவு மேலெழுதலால் தடுக்கப்பட்டது.';

  @override
  String get warnConflict =>
      'கண்டறிதல் ஆதாரங்கள் வேறுபட்டன — தீர்ப்பால் முடிவு சரிசெய்யப்பட்டது.';

  @override
  String get warnDestination => 'இலக்கு';

  @override
  String warnVia(String app) {
    return '$app வழியாக';
  }

  @override
  String get warnWhyFlagged => 'ஏன் குறிக்கப்பட்டது';

  @override
  String get warnSources => 'நுண்ணறிவு ஆதாரங்கள்';

  @override
  String get warnGoBack => 'பின் செல் (பரிந்துரைக்கப்படுகிறது)';

  @override
  String get warnContinue => 'எப்படியும் தொடரவும்';

  @override
  String get warnReport => 'இந்த இணைப்பைப் புகாரளி';

  @override
  String get warnReported => 'புகாரளிக்கப்பட்டது. நன்றி.';

  @override
  String get warnOpenDangerousTitle => 'ஆபத்தான தளத்தைத் திறக்கவா?';

  @override
  String get warnOpenDangerousBody =>
      'CyberGuard இந்த இணைப்பை அதிக ஆபத்துடையதாக மதிப்பிட்டுள்ளது. இதைத் திறப்பது உங்கள் சான்றுகள் அல்லது சாதனத்தை வெளிப்படுத்தலாம். உங்கள் சொந்த ஆபத்தில் தொடரவா?';

  @override
  String get warnOpenAnyway => 'எப்படியும் திற';

  @override
  String get warnPrivacyNote =>
      'அமைப்புகளில் இணைப்பு வரலாற்றை இயக்காத வரை எந்த URL-உம் சேமிக்கப்படாது.';

  @override
  String get fusionTitle => 'அச்சுறுத்தல் இணைப்பு ஸ்கேன்';

  @override
  String get fusionPrompt =>
      'அனைத்து நுண்ணறிவு ஆதாரங்களிலும் ஒரு இணைப்பைச் சரிபார்க்கவும்';

  @override
  String get fusionRunScan => 'இணைப்பு ஸ்கேனை இயக்கு';

  @override
  String get fusionUnified => 'ஒருங்கிணைந்த';

  @override
  String get fusionSourceAttribution => 'ஆதார வரவு';

  @override
  String get fusionExplanation => 'விளக்கம்';

  @override
  String get fusionConflict =>
      'ஆதாரங்கள் வேறுபட்டன — தீர்ப்பால் சரிசெய்யப்பட்டது.';

  @override
  String fusionTrust(int weight) {
    return 'நம்பிக்கை $weight';
  }

  @override
  String get arbitrationTitle => 'தீர்ப்பு பதிவு';

  @override
  String get arbitrationClear => 'பதிவை அழி';

  @override
  String get arbitrationEmptyTitle => 'இதுவரை முரண்பாடுகள் இல்லை';

  @override
  String get arbitrationEmptyBody =>
      'கண்டறிதல் ஆதாரங்கள் வேறுபடும்போது அல்லது நம்பகமான ஆதாரம் CyberGuard-ஐ மேலெழுதும்போது, முடிவு இங்கே பதிவாகும்.';

  @override
  String arbitrationOverride(String level) {
    return 'நம்பகமான மேலெழுதல் → $level';
  }

  @override
  String arbitrationConflictTitle(String level) {
    return 'ஆதார முரண்பாடு → $level';
  }

  @override
  String get riskTitle => 'முன்னறிவிப்பு ஆபத்து';

  @override
  String get riskNoData => 'தரவு இல்லை';

  @override
  String get riskBandLow => 'குறைவு';

  @override
  String get riskBandMedium => 'நடுத்தரம்';

  @override
  String get riskBandHigh => 'அதிகம்';

  @override
  String riskSuffix(String band) {
    return '$band ஆபத்து';
  }

  @override
  String get riskForecastTitle => 'அச்சுறுத்தல் முன்னறிவிப்பு';

  @override
  String get riskTimelineTitle => '7-நாள் ஆபத்து காலவரிசை';

  @override
  String riskWhyTitle(String band) {
    return 'உங்கள் ஆபத்து ஏன் $band';
  }

  @override
  String get riskRecommendations => 'பரிந்துரைகள்';

  @override
  String get forecastPhishing => 'ஃபிஷிங் தாக்குதல்';

  @override
  String get forecastCredentialTheft => 'சான்று திருட்டு';

  @override
  String get forecastMalware => 'தீம்பொருள் தொற்று';

  @override
  String get rfPhishingTitle => 'ஃபிஷிங் இணைப்புகள் கண்டறியப்பட்டன';

  @override
  String rfPhishingDetail(int count) {
    return 'கடந்த 7 நாட்களில் $count குறிக்கப்பட்டது';
  }

  @override
  String get rfSmsTitle => 'சந்தேகத்திற்குரிய SMS பெறப்பட்டது';

  @override
  String rfSmsDetail(int count) {
    return '$count ஃபிஷிங் SMS கண்டறியப்பட்டது';
  }

  @override
  String get rfWifiTitle => 'தெரியாத Wi-Fi நெட்வொர்க்குகள் பயன்படுத்தப்பட்டன';

  @override
  String rfWifiDetail(int count) {
    return '$count குறைந்த நம்பிக்கை நெட்வொர்க்குகள் இணைக்கப்பட்டன';
  }

  @override
  String get rfMalwareTitle => 'ஆபத்தான செயலிகள் நிறுவப்பட்டன';

  @override
  String rfMalwareDetail(int count) {
    return '$count அதிக ஆபத்துள்ள செயலிகள் கண்டறியப்பட்டன';
  }

  @override
  String get rfInterceptTitle => 'சமீபத்தில் தடுக்கப்பட்ட இணைப்புகள்';

  @override
  String rfInterceptDetail(int count) {
    return '$count ஆபத்தான இணைப்புகள் இடைமறிக்கப்பட்டன';
  }

  @override
  String get rfBreachTitle => 'அறியப்பட்ட மீறலில் சான்றுகள்';

  @override
  String get rfBreachDetail => 'உங்கள் கணக்கு மீறப்பட்ட தரவில் தோன்றுகிறது';

  @override
  String get rfTrendTitle => 'பாதுகாப்பு மதிப்பெண் குறைகிறது';

  @override
  String rfTrendDetail(int pts) {
    return 'பாதுகாப்பு சமீபத்தில் $pts புள்ளிகள் குறைந்தது';
  }

  @override
  String get recBreach =>
      'மீறப்பட்ட கணக்குகளின் கடவுச்சொற்களை மாற்றி 2FA-ஐ இயக்கவும்.';

  @override
  String get recPhishing =>
      'எதிர்பாராத செய்திகளில் இணைப்புகளைத் தட்டுவதைத் தவிர்க்கவும்; அனுப்புநரைச் சரிபார்க்கவும்.';

  @override
  String get recWifi =>
      'பொது Wi-Fi-யில் முக்கியமான உள்நுழைவைத் தவிர்க்கவும்; நம்பகமான நெட்வொர்க்கைப் பயன்படுத்தவும்.';

  @override
  String get recMalware =>
      'அதிக ஆபத்துள்ள செயலிகளை மதிப்பாய்வு செய்து அகற்றவும்; Play Store-இல் இருந்து மட்டுமே நிறுவவும்.';

  @override
  String get recInterceptor =>
      'தொடர்ந்த பாதுகாப்புக்காக ஸ்மார்ட் இணைப்பு இடைமறிப்பானை இயக்கி வைக்கவும்.';

  @override
  String get recHealthy =>
      'நீங்கள் நல்ல நிலையில் உள்ளீர்கள் — CyberGuard பாதுகாப்புகளை இயக்கி வைக்கவும்.';

  @override
  String get screenshotTitle => 'ஸ்கிரீன்ஷாட் ஸ்கேனர்';

  @override
  String get screenshotPrompt =>
      'சந்தேகத்திற்குரிய பக்கத்தின் ஸ்கிரீன்ஷாட்டை ஸ்கேன் செய்யவும்';

  @override
  String get screenshotDesc =>
      'போலி வங்கி, UPI, OTP, உள்நுழைவு, KYC, லாட்டரி மற்றும் ஆதரவு மோசடிகளைக் கண்டறிகிறது. படங்கள் சாதனத்திலேயே பகுப்பாய்வு செய்யப்படுகின்றன.';

  @override
  String get screenshotGallery => 'கேலரி';

  @override
  String get screenshotCamera => 'கேமரா';

  @override
  String get screenshotScam => 'மோசடி';

  @override
  String get screenshotLooksClean => 'சுத்தமாகத் தெரிகிறது';

  @override
  String screenshotBrand(String brand) {
    return 'குறிப்பிடப்பட்ட பிராண்ட்: $brand';
  }

  @override
  String get screenshotIndicators => 'குறிகாட்டிகள்';

  @override
  String get screenshotExtractedText => 'பிரித்தெடுக்கப்பட்ட உரை';

  @override
  String get scamFakeBank => 'போலி வங்கி பக்கம்';

  @override
  String get scamFakeUpi => 'போலி UPI / கட்டண பக்கம்';

  @override
  String get scamFakeOtp => 'போலி OTP கோரிக்கை';

  @override
  String get scamFakeLogin => 'போலி உள்நுழைவு பக்கம்';

  @override
  String get scamFakeKyc => 'போலி KYC படிவம்';

  @override
  String get scamFakeLottery => 'லாட்டரி / பரிசு மோசடி';

  @override
  String get scamFakeInvestment => 'முதலீட்டு மோசடி';

  @override
  String get scamFakeSupport => 'போலி வாடிக்கையாளர் ஆதரவு';

  @override
  String get scamNone => 'மோசடி குறிகாட்டிகள் இல்லை';

  @override
  String scamReasonCategory(String category, String matched) {
    return '$category: \"$matched\"';
  }

  @override
  String scamReasonBrand(String brand) {
    return 'குறிப்பிடப்பட்ட பிராண்ட்: $brand';
  }

  @override
  String scamReasonUrgency(String word) {
    return 'அவசர / அழுத்த வார்த்தைகள்: \"$word\"';
  }

  @override
  String get scamReasonNoIndicators =>
      'உரையில் மோசடி குறிகாட்டிகள் எதுவும் கண்டறியப்படவில்லை';

  @override
  String get scamReasonNoText =>
      'படத்தில் படிக்கக்கூடிய உரை எதுவும் கிடைக்கவில்லை';

  @override
  String get authTitle => 'CyberGuard AI இல் உள்நுழையவும்';

  @override
  String get authSubtitle =>
      'உங்கள் பாதுகாப்பு அமைப்புகளை எல்லா சாதனங்களிலும் ஒத்திசைக்கவும்';

  @override
  String get authSignIn => 'உள்நுழை';

  @override
  String get authSignUp => 'கணக்கை உருவாக்கு';

  @override
  String get authPassword => 'கடவுச்சொல்';

  @override
  String get authContinueGoogle => 'Google மூலம் தொடரவும்';

  @override
  String get authForgotPassword => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get authNoAccount => 'புதியவரா? கணக்கை உருவாக்குங்கள்';

  @override
  String get authHaveAccount => 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழையவும்';

  @override
  String get authOr => 'அல்லது';

  @override
  String get authContinueOffline => 'கணக்கு இல்லாமல் தொடரவும்';

  @override
  String get authResetSent =>
      'அந்த முகவரி பதிவு செய்யப்பட்டிருந்தால், மீட்டமைப்பு இணைப்பு அனுப்பப்படும்.';

  @override
  String get authUnavailableTitle =>
      'இந்த பதிப்பில் உள்நுழைவு அமைக்கப்படவில்லை';

  @override
  String get authUnavailableBody =>
      'இந்த ஆப் Firebase சான்றுகள் இல்லாமல் உருவாக்கப்பட்டது, எனவே கணக்குகள் கிடைக்கவில்லை. மற்ற அனைத்தும் வழக்கம் போல் ஆஃப்லைனில் இயங்கும்.';

  @override
  String get authErrInvalidEmail =>
      'அந்த மின்னஞ்சல் முகவரி சரியாகத் தெரியவில்லை';

  @override
  String get authErrWrongPassword => 'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறு';

  @override
  String get authErrUserNotFound => 'அந்த மின்னஞ்சலுக்கு கணக்கு எதுவும் இல்லை';

  @override
  String get authErrEmailInUse => 'அந்த மின்னஞ்சலுக்கு ஏற்கனவே கணக்கு உள்ளது';

  @override
  String get authErrWeakPassword => 'குறைந்தது 6 எழுத்துகளைப் பயன்படுத்தவும்';

  @override
  String get authErrNetwork =>
      'இணைப்பு இல்லை. உங்கள் நெட்வொர்க்கைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get authErrUnknown => 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get authSignOut => 'வெளியேறு';

  @override
  String authSignedInAs(String email) {
    return '$email ஆக உள்நுழைந்துள்ளீர்கள்';
  }

  @override
  String get authWelcomeBack => 'மீண்டும் வரவேற்கிறோம்';

  @override
  String get authCreateAccountTitle => 'உங்கள் கணக்கை உருவாக்குங்கள்';

  @override
  String get authHeroTagline => 'உங்கள் தொலைபேசியின் பாதுகாப்பு, ஒரே இடத்தில்';

  @override
  String get authTabSignIn => 'உள்நுழை';

  @override
  String get authTabRegister => 'பதிவு';

  @override
  String get authSecuredNote =>
      'கேர்ப்பு முதல் கேர்ப்பு வரை என்கிரிப்ட் செய்யப்பட்டது';

  @override
  String get authSigningIn => 'உள்நுழைகிறது…';

  @override
  String get verifyEmailTitle => 'உங்கள் மின்னஞ்சல் முகவரியை உறுதிப்படுத்தவும்';

  @override
  String verifyEmailBody(String email) {
    return '$email க்கு ஒரு இணைப்பை அனுப்பியுள்ளோம். இந்த முகவரி உங்களுடையது என்பதை உறுதிப்படுத்த அதைக் கிளிக் செய்யவும்.';
  }

  @override
  String get verifyEmailResend => 'இணைப்பை மீண்டும் அனுப்பு';

  @override
  String get verifyEmailSent =>
      'சரிபார்ப்பு இணைப்பு அனுப்பப்பட்டது. உங்கள் இன்பாக்ஸ் மற்றும் ஸ்பேமைப் பாருங்கள்.';

  @override
  String get verifyEmailFailed =>
      'இணைப்பை அனுப்ப முடியவில்லை. சில நிமிடங்களில் மீண்டும் முயற்சிக்கவும்.';

  @override
  String get verifyEmailDone => 'மின்னஞ்சல் உறுதிப்படுத்தப்பட்டது. நன்றி!';
}
