// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'साइबरगार्ड AI';

  @override
  String get appTagline => 'बुद्धिमान सुरक्षा सहायक';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get alerts => 'अलर्ट';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get phishingScanner => 'फ़िशिंग स्कैनर';

  @override
  String get appScanner => 'ऐप स्कैनर';

  @override
  String get breachMonitor => 'ब्रीच मॉनिटर';

  @override
  String get wifiScanner => 'वाई-फ़ाई स्कैनर';

  @override
  String get securityScore => 'सुरक्षा स्कोर';

  @override
  String get scanNow => 'अभी स्कैन करें';

  @override
  String get scanning => 'स्कैन हो रहा है…';

  @override
  String get protected => 'सुरक्षित';

  @override
  String get atRisk => 'जोखिम में';

  @override
  String get critical => 'गंभीर';

  @override
  String lastScanned(String time) {
    return 'अंतिम स्कैन $time';
  }

  @override
  String get neverScanned => 'कभी स्कैन नहीं किया';

  @override
  String get protectionModules => 'सुरक्षा मॉड्यूल';

  @override
  String get sevenDayScore => '7-दिन का सुरक्षा स्कोर';

  @override
  String get recentAlerts => 'हाल के अलर्ट';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get noAlerts => 'अभी तक कोई अलर्ट नहीं';

  @override
  String get noAlertsDescription =>
      'स्कैन के दौरान पाई गई धमकियाँ यहाँ दिखेंगी';

  @override
  String get notifications => 'सूचनाएँ';

  @override
  String get appearance => 'रूप';

  @override
  String get themeSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get themeLight => 'हल्का';

  @override
  String get themeDark => 'गहरा';

  @override
  String get language => 'भाषा';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी (Hindi)';

  @override
  String get languageTamil => 'தமிழ் (Tamil)';

  @override
  String get languageTelugu => 'తెలుగు (Telugu)';

  @override
  String get exportPdf => 'PDF के रूप में निर्यात';

  @override
  String get exportCsv => 'CSV के रूप में निर्यात';

  @override
  String get exportPdfSubtitle =>
      'स्कोर, ख़तरों और रुझानों के साथ ब्रांडेड रिपोर्ट';

  @override
  String get exportCsvSubtitle => 'स्प्रेडशीट के लिए कच्चा डेटा';

  @override
  String get reports => 'रिपोर्ट और निर्यात';

  @override
  String get liveSmsGuard => 'लाइव SMS फ़िशिंग गार्ड';

  @override
  String get liveSmsGuardSubtitle =>
      'हर आने वाले SMS की फ़िशिंग लिंक के लिए ऑटो-जाँच';

  @override
  String get scanQrCode => 'QR कोड स्कैन करें';

  @override
  String get checkBreach => 'अभी जाँचें';

  @override
  String get enterEmail => 'अपना ईमेल पता दर्ज करें';

  @override
  String get enterPassword => 'जाँचने के लिए पासवर्ड दर्ज करें';

  @override
  String get noBreachFound => 'कोई ब्रीच नहीं मिला';

  @override
  String breachesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ब्रीच मिले',
      one: '1 ब्रीच मिला',
    );
    return '$_temp0';
  }

  @override
  String get onboardAiSecurityTitle => 'AI-संचालित सुरक्षा 🛡️';

  @override
  String get onboardAiSecurityDesc =>
      'ऑन-डिवाइस मशीन लर्निंग वास्तविक समय में फ़िशिंग, मैलवेयर और ब्रीच का पता लगाती है — आपका डेटा कभी फ़ोन से बाहर नहीं जाता।';

  @override
  String get onboardPhishingTitle => 'फ़िशिंग का पता 🔗';

  @override
  String get onboardPhishingDesc =>
      'किसी भी लिंक को पेस्ट करें या अपने SMS स्कैन करें — बैंकिंग, UPI और OTP को निशाना बनाने वाली फ़िशिंग पहचानें।';

  @override
  String get onboardMalwareTitle => 'मैलवेयर स्कैनर 🐞';

  @override
  String get onboardMalwareDesc =>
      'पर्मिशन ग्राफ़ विश्लेषण से इंस्टॉल किए गए ऐप्स को गहराई से स्कैन करें — स्पाइवेयर, ट्रोजन और स्टॉकरवेयर खोजें।';

  @override
  String get onboardBreachTitle => 'ब्रीच मॉनिटर 🔐';

  @override
  String get onboardBreachDesc =>
      '14B+ लीक रिकॉर्ड जाँचें। आपका ईमेल और पासवर्ड स्थानीय रूप से हैश किए जाते हैं — पूरा कभी नहीं भेजा जाता।';

  @override
  String get onboardPermsTitle => 'बस कुछ अनुमतियाँ 🙏';

  @override
  String get onboardPermsDesc =>
      'हमें SMS, स्थान और सूचना अनुमतियाँ चाहिए। सभी स्कैन इसी डिवाइस पर रहते हैं — कुछ भी सर्वर पर नहीं जाता।';

  @override
  String get onboardContinue => 'जारी रखें';

  @override
  String get onboardGrantStart => 'अनुमतियाँ दें और शुरू करें';

  @override
  String get onboardSkip => 'छोड़ें';

  @override
  String get scoreGreetingProtected => 'आप सुरक्षित हैं';

  @override
  String get scoreGreetingAtRisk => 'कुछ चीज़ें जाँचनी हैं ⚠️';

  @override
  String get scoreGreetingCritical => 'तुरंत कार्रवाई करें 🚨';

  @override
  String get scoreGreetingFirstScan => 'नमस्ते 👋';

  @override
  String get scoreHeadlineProtected => 'सब कुछ ठीक है';

  @override
  String get scoreHeadlineAtRisk => 'एक नज़र डालें';

  @override
  String get scoreHeadlineCritical => 'गंभीर समस्याएँ मिलीं';

  @override
  String get scoreHeadlineFirstScan => 'अपना फ़ोन सुरक्षित करें';

  @override
  String get permSmsTitle => 'SMS एक्सेस चाहिए';

  @override
  String get permSmsRationale =>
      'साइबरगार्ड AI को फ़िशिंग लिंक का पता लगाने के लिए आपके SMS पढ़ने की ज़रूरत है। आपके मैसेज कभी किसी सर्वर पर नहीं भेजे जाते — सारा विश्लेषण आपके डिवाइस पर ही होता है।';

  @override
  String get permLocationTitle => 'स्थान एक्सेस चाहिए';

  @override
  String get permLocationRationale =>
      'Android को SSID जैसे वाई-फ़ाई विवरण देखने के लिए स्थान अनुमति चाहिए। साइबरगार्ड AI इसका उपयोग केवल आपके वर्तमान नेटवर्क की सुरक्षा जाँचने के लिए करता है।';

  @override
  String get permNotifTitle => 'सूचनाएँ';

  @override
  String get permNotifRationale =>
      'जब साइबरगार्ड AI ख़तरों का पता लगाता है तो वह सूचनाएँ भेजता है ताकि आप तुरंत कार्रवाई कर सकें।';

  @override
  String get permAllowButton => 'अनुमति दें';

  @override
  String get permNotNow => 'अभी नहीं';

  @override
  String get dialogCancel => 'रद्द करें';

  @override
  String get dialogConfirm => 'पुष्टि करें';

  @override
  String get dialogClearAll => 'सब हटाएँ';

  @override
  String get dialogReset => 'रीसेट';

  @override
  String get dialogDelete => 'मिटाएँ';

  @override
  String get dialogClose => 'बंद करें';

  @override
  String get breachInputTitle => 'जांचें कि आपका डेटा लीक हुआ है या नहीं';

  @override
  String get breachInputSubtitle => 'हम 12+ अरब लीक रिकॉर्ड में जाँच करते हैं';

  @override
  String get breachTabEmail => 'ईमेल';

  @override
  String get breachTabPhone => 'फ़ोन नंबर';

  @override
  String get breachInputHintEmail => 'अपना ईमेल पता दर्ज करें';

  @override
  String get breachInputHintPhone => 'अपना 10-अंकीय नंबर दर्ज करें';

  @override
  String get breachPrivacyFooter =>
      'k-गुमनामी सुरक्षित · आपका डेटा इस डिवाइस से बाहर नहीं जाता';

  @override
  String get breachNoBreaches => 'कोई उल्लंघन नहीं मिला';

  @override
  String get breachNoBreachesEmailDesc =>
      'अच्छी खबर! आपका ईमेल किसी ज्ञात डेटा उल्लंघन में नहीं मिला।';

  @override
  String get breachNoBreachesPhoneDesc =>
      'अच्छी खबर! यह फ़ोन नंबर किसी ज्ञात डेटा उल्लंघन में नहीं मिला।';

  @override
  String get breachCheckedCount => '12,454,308,593 रिकॉर्ड चेक किए गए';

  @override
  String get breachStayProtected => 'सुरक्षित रहें';

  @override
  String get breachTipUnique => 'हर खाते के लिए अनूठा पासवर्ड इस्तेमाल करें';

  @override
  String get breach2FA => 'टू-फैक्टर ऑथेंटिकेशन सक्षम करें';

  @override
  String get breachPwManager => 'पासवर्ड मैनेजर का उपयोग करें';

  @override
  String get breachOfflineBannerTitle =>
      'ऑफ़लाइन डेटाबेस से परिणाम दिखाए जा रहे हैं';

  @override
  String get breachOfflineBannerBody =>
      'ये असली ऐतिहासिक उल्लंघन हैं, लेकिन मिलान आपके ईमेल के स्थानीय हैश से लिया गया है — लाइव HIBP लुकअप से नहीं। लाइव सत्यापन के लिए सेटिंग्स में मुफ्त HIBP API कुंजी कॉन्फ़िगर करें।';

  @override
  String get breachFoundEmail => 'आपका ईमेल इन उल्लंघनों में उजागर हुआ था:';

  @override
  String get breachFoundPhone => 'यह नंबर इन उल्लंघनों में उजागर हुआ था:';

  @override
  String breachAccountsAffected(String count) {
    return '$count खाते प्रभावित';
  }

  @override
  String get breachCompromisedData => 'उजागर डेटा';

  @override
  String get breachWhatToDo => 'मुझे क्या करना चाहिए?';

  @override
  String get breachStep1 =>
      'हर उस साइट पर पासवर्ड बदलें जहाँ आपने यही जानकारी दोबारा इस्तेमाल की।';

  @override
  String get breachStep2 =>
      'टू-फैक्टर ऑथेंटिकेशन सक्षम करें — बेहतर हो प्रमाणक ऐप के साथ।';

  @override
  String get breachStep3 =>
      'उल्लंघित सेवा का नाम लेकर आने वाले फ़िशिंग ईमेल से सावधान रहें।';

  @override
  String get breachStep4 =>
      'हर खाते के लिए अनूठा पासवर्ड रखने हेतु पासवर्ड मैनेजर पर विचार करें।';

  @override
  String get breachPastChecks => 'पिछली जाँचें';

  @override
  String get breachStatusSafe => 'सुरक्षित';

  @override
  String get breachStatusBreached => 'उल्लंघित';

  @override
  String get breachPrivacyTitle => 'हम आपकी निजता की रक्षा कैसे करते हैं';

  @override
  String get breachPrivacyStep1 =>
      'आपका इनपुट आपके डिवाइस पर ही हैश किया जाता है।';

  @override
  String get breachPrivacyStep2 =>
      'हैश के केवल पहले 5 अक्षर HIBP को भेजे जाते हैं।';

  @override
  String get breachPrivacyStep3 => 'हज़ारों मिलते-जुलते हैश वापस आते हैं।';

  @override
  String get breachPrivacyStep4 => '100% मिलान-जाँच आपके डिवाइस पर ही होती है।';

  @override
  String get qrScanTitle => 'QR स्कैन करें';

  @override
  String get qrUploadFromGallery => 'गैलरी से अपलोड करें';

  @override
  String get qrPointAtCode =>
      'किसी भी QR पर तानें · स्कैन URL डिवाइस पर ही जाँचे जाते हैं';

  @override
  String get qrNotAUrl => 'यह URL नहीं है';

  @override
  String get qrNotAUrlBody => 'QR कोड में टेक्स्ट था, लिंक नहीं:';

  @override
  String get qrPhishingDetected => 'फ़िशिंग QR मिला';

  @override
  String get qrSafeLink => 'सुरक्षित लिंक';

  @override
  String get qrScanAnother => 'फिर स्कैन करें';

  @override
  String get qrViewDetails => 'विवरण देखें';

  @override
  String qrConfidence(int count) {
    return '$count% आत्मविश्वास';
  }

  @override
  String get qrCameraUnavailable =>
      'कैमरा उपलब्ध नहीं। कैमरा अनुमति दें और फिर कोशिश करें।';

  @override
  String get qrOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get qrNoCodeInImage => 'इस छवि में कोई QR कोड नहीं मिला।';

  @override
  String get scoreSuffix => '/100';

  @override
  String get scoreLabel => 'स्कोर';

  @override
  String scannedAgo(String time) {
    return '$time स्कैन हुआ';
  }

  @override
  String get dashboardRefreshed => 'डैशबोर्ड ताज़ा हुआ';

  @override
  String dashboardRefreshedWithWifi(int score) {
    return 'डैशबोर्ड ताज़ा हुआ · वाई-फ़ाई ट्रस्ट $score/100';
  }

  @override
  String get moduleTitlePhishing => 'फ़िशिंग';

  @override
  String get moduleSubtitlePhishing => 'URL और SMS स्कैनर';

  @override
  String get moduleTitleMalware => 'मैलवेयर';

  @override
  String get moduleSubtitleMalware => 'ऐप सुरक्षा';

  @override
  String get moduleTitleBreach => 'ब्रीच';

  @override
  String get moduleSubtitleBreach => 'डेटा लीक मॉनिटर';

  @override
  String get moduleTitleWifi => 'वाई-फ़ाई';

  @override
  String get moduleSubtitleWifi => 'नेटवर्क विश्लेषक';

  @override
  String get moduleNotScanned => 'स्कैन नहीं';

  @override
  String get statTotalScans => 'कुल स्कैन';

  @override
  String get statThreats => 'ख़तरे';

  @override
  String get statLastScan => 'अंतिम स्कैन';

  @override
  String get statNever => 'कभी नहीं';

  @override
  String get settingRealTimeAlerts => 'रीयल-टाइम अलर्ट';

  @override
  String get settingRealTimeAlertsSub => 'ख़तरे पाए जाने पर सूचना पाएँ';

  @override
  String get settingClipboardScan => 'क्लिपबोर्ड स्कैन';

  @override
  String get settingClipboardScanSub =>
      'क्लिपबोर्ड में कॉपी किए गए URL स्कैन करें';

  @override
  String get settingWifiAutoScan => 'ऑटो वाई-फ़ाई स्कैन';

  @override
  String get settingWifiAutoScanSub => 'नेटवर्क बदलने पर स्कैन करें';

  @override
  String get smsPermissionDenied =>
      'SMS अनुमति अस्वीकृत — लाइव स्कैन शुरू नहीं हो सकता';

  @override
  String get settingsAutoScanFrequency => 'ऑटो स्कैन आवृत्ति';

  @override
  String settingsBackgroundScanEvery(int hours) {
    return 'हर $hours घंटे में बैकग्राउंड स्कैन';
  }

  @override
  String get settingsHibpTitle => 'Have I Been Pwned API कुंजी';

  @override
  String get settingsHibpDesc =>
      'ईमेल ब्रीच जाँच के लिए आवश्यक। मुफ़्त कुंजी haveibeenpwned.com/API/Key पर लें';

  @override
  String get settingsHibpPasteHint => 'अपनी API कुंजी यहाँ पेस्ट करें…';

  @override
  String get settingsHibpSave => 'कुंजी सहेजें';

  @override
  String get settingsHibpSaved => 'API कुंजी सहेजी गई';

  @override
  String get settingsHibpConfigured => 'API कुंजी कॉन्फ़िगर है';

  @override
  String get settingsPrivacy => 'गोपनीयता और डेटा';

  @override
  String get settingsKAnon => 'k-गुमनामी प्रोटोकॉल';

  @override
  String get settingsKAnonDesc =>
      'पासवर्ड कभी किसी सर्वर पर नहीं भेजे जाते। केवल SHA-1 हैश के पहले 5 अक्षर भेजे जाते हैं। आपकी जानकारी डिवाइस से बाहर नहीं जाती।';

  @override
  String get settingsLocalStorage => 'केवल स्थानीय स्टोरेज';

  @override
  String get settingsLocalStorageDesc =>
      'सभी स्कैन परिणाम और इतिहास एन्क्रिप्टेड Hive स्टोरेज में आपके डिवाइस पर रहते हैं। कोई डेटा हमारे सर्वर पर नहीं जाता।';

  @override
  String get settingsAbout => 'के बारे में';

  @override
  String get settingsAboutVersion => 'संस्करण';

  @override
  String get settingsAboutEngine => 'डिटेक्शन इंजन';

  @override
  String get settingsAboutSources => 'डेटा स्रोत';

  @override
  String get settingsAboutModel => 'AI मॉडल';

  @override
  String get settingsDangerZone => 'खतरा क्षेत्र';

  @override
  String get settingsResetDesc =>
      'सभी सेटिंग्स को डिफ़ॉल्ट पर रीसेट करें। यह स्कैन इतिहास नहीं मिटाएगा।';

  @override
  String get settingsResetBtn => 'सेटिंग्स रीसेट करें';

  @override
  String get settingsResetTitle => 'सेटिंग्स रीसेट करें';

  @override
  String get settingsResetBody =>
      'सभी सेटिंग्स डिफ़ॉल्ट पर वापस आ जाएँगी। जारी रखें?';

  @override
  String get exportGenerating => 'PDF रिपोर्ट बना रहे हैं…';

  @override
  String exportFailed(String error) {
    return 'निर्यात विफल: $error';
  }

  @override
  String get alertsMarkAllRead => 'सभी पढ़े हुए के रूप में चिह्नित करें';

  @override
  String alertsNoFilter(String filter) {
    return 'कोई $filter अलर्ट नहीं';
  }

  @override
  String get alertsTryDifferent => 'अलग फ़िल्टर आज़माएँ';

  @override
  String get alertsClearTitle => 'सभी अलर्ट हटाएँ';

  @override
  String get alertsClearBody => 'इससे सभी अलर्ट स्थायी रूप से मिट जाएँगे।';

  @override
  String get alertsFilterAll => 'सभी';

  @override
  String get alertsFilterPhishing => 'फ़िशिंग';

  @override
  String get alertsFilterMalware => 'मैलवेयर';

  @override
  String get alertsFilterBreach => 'ब्रीच';

  @override
  String get alertsFilterWifi => 'वाई-फ़ाई';

  @override
  String get malwareIssuesFound => 'समस्याएँ मिलीं ⚠️';

  @override
  String get malwareAppSecurity => 'ऐप सुरक्षा 🛡️';

  @override
  String get malwareTapToScan =>
      'अपने ऐप्स का विश्लेषण करने के लिए स्कैन दबाएँ';

  @override
  String malwareAppsThreats(int apps, int threats) {
    String _temp0 = intl.Intl.pluralLogic(
      threats,
      locale: localeName,
      other: 'ख़तरे',
      one: 'ख़तरा',
    );
    return '$apps ऐप्स · $threats $_temp0';
  }

  @override
  String malwareLastScan(String time) {
    return 'अंतिम स्कैन $time';
  }

  @override
  String get malwareScanNow => 'ऐप्स अभी स्कैन करें';

  @override
  String malwareAnalysing(String name) {
    return '$name का विश्लेषण…';
  }

  @override
  String malwareEtaSec(String sec) {
    return '~$sec सेकंड';
  }

  @override
  String malwareProgress(int progress, int total) {
    return '$progress / $total ऐप्स';
  }

  @override
  String get malwareRiskCritical => 'गंभीर';

  @override
  String get malwareRiskHigh => 'उच्च';

  @override
  String get malwareRiskMedium => 'मध्यम';

  @override
  String get malwareRiskLow => 'कम';

  @override
  String get malwareSearch => 'ऐप्स खोजें…';

  @override
  String get malwareNoAppsTitle => 'कोई ऐप नहीं मिला';

  @override
  String get malwareNoAppsSub =>
      'अपने इंस्टॉल किए गए ऐप्स का विश्लेषण करने के लिए स्कैन दबाएँ';

  @override
  String get malwareNoMatchTitle => 'किसी फ़िल्टर से मेल नहीं खाते';

  @override
  String get malwareNoMatchSub => 'अलग फ़िल्टर या खोज शब्द आज़माएँ';

  @override
  String malwarePermsVerified(int count) {
    return '$count अनुमतियाँ • सत्यापित';
  }

  @override
  String malwarePermsSideloaded(int count) {
    return '$count अनुमतियाँ • साइडलोडेड';
  }

  @override
  String get phishingUrlTab => '🔗  URL स्कैनर';

  @override
  String get phishingSmsTab => '💬  SMS स्कैनर';

  @override
  String get phishingCheckLink => 'लिंक जाँचें 🔍';

  @override
  String get phishingPasteHint =>
      'कोई भी URL पेस्ट करें — हम इसे डिवाइस पर ही जाँचेंगे';

  @override
  String get phishingPaste => 'पेस्ट';

  @override
  String get phishingScanNow => 'अभी स्कैन करें';

  @override
  String get phishingScanHistory => 'स्कैन इतिहास';

  @override
  String phishingScans(int count) {
    return '$count स्कैन';
  }

  @override
  String get phishingNoScansTitle => 'अभी तक कोई स्कैन नहीं';

  @override
  String get phishingNoScansSub => 'स्कैन किए गए URL यहाँ दिखेंगे';

  @override
  String get phishingAnalysingTitle => 'AI URL का विश्लेषण कर रहा है';

  @override
  String get phishingAnalysingSub =>
      'TLD, कीवर्ड, पैटर्न और संरचना की जाँच की जा रही है';

  @override
  String get phishingVerdictPhishing => 'फ़िशिंग';

  @override
  String get phishingVerdictSafe => 'सुरक्षित';

  @override
  String get phishingConfidence => 'विश्वास';

  @override
  String get phishingWhyFlagged => 'AI ने इसे क्यों चिह्नित किया';

  @override
  String get phishingHowItWorks => 'फ़िशिंग पहचान कैसे काम करती है';

  @override
  String get phishingHowItWorksBody =>
      'साइबरगार्ड AI डिवाइस पर ही SHAP-व्याख्या योग्य नियम-आधारित पहचान का उपयोग करता है। विश्लेषण में TLD प्रतिष्ठा, कीवर्ड मिलान, URL संरचना और ब्रांड पहचान जाँच शामिल है। सारा विश्लेषण डिवाइस पर ही होता है — आपके URL कभी डिवाइस से बाहर नहीं जाते।';

  @override
  String get phishingGotIt => 'समझ गया';

  @override
  String get phishingSmsTitle => 'SMS फ़िशिंग 📨';

  @override
  String get phishingSmsSub => 'हम आपके मैसेज डिवाइस पर ही स्कैन करते हैं';

  @override
  String get phishingSmsLoad => 'SMS लोड करें';

  @override
  String get phishingSmsScanAll => 'सभी स्कैन करें';

  @override
  String get phishingSmsNoneTitle => 'कोई SMS लोड नहीं';

  @override
  String get phishingSmsNoneSub =>
      'हाल के मैसेज लाने के लिए \"SMS लोड करें\" दबाएँ';

  @override
  String get phishingSmsUnknown => 'अज्ञात';

  @override
  String get phishingSmsSuspicious => 'संदिग्ध';

  @override
  String get phishingSmsLinksScannedSafe => 'लिंक स्कैन — सुरक्षित';

  @override
  String get phishingSmsLinksSuspicious => 'संदिग्ध लिंक मिले!';

  @override
  String phishingSmsScanLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'लिंक',
      one: 'लिंक',
    );
    return '$count $_temp0 स्कैन करें';
  }

  @override
  String get phishingSmsNoUrls => 'इस मैसेज में कोई URL नहीं मिला';

  @override
  String get wifiClearHistoryTooltip => 'इतिहास साफ़ करें';

  @override
  String get wifiClearTitle => 'इतिहास साफ़ करें';

  @override
  String get wifiClearBody => 'सभी वाई-फ़ाई स्कैन इतिहास हटाएँ?';

  @override
  String get wifiClear => 'साफ़ करें';

  @override
  String get wifiScanThis => 'इस नेटवर्क को स्कैन करें';

  @override
  String get wifiScanning => 'नेटवर्क स्कैन हो रहा है…';

  @override
  String get wifiScanningSub => 'रीयल-टाइम में सुरक्षा का विश्लेषण';

  @override
  String get wifiNoScan => 'अभी तक कोई स्कैन नहीं';

  @override
  String get wifiNoScanSub =>
      'अपने वाई-फ़ाई का विश्लेषण करने के लिए स्कैन नेटवर्क दबाएँ';

  @override
  String get wifiUnknownSsid => 'अज्ञात SSID';

  @override
  String wifiTrust(int score) {
    return 'ट्रस्ट: $score%';
  }

  @override
  String get wifiTrustScore => 'ट्रस्ट स्कोर';

  @override
  String get wifiSignal => 'सिग्नल';

  @override
  String get wifiBand => 'बैंड';

  @override
  String get wifiSpeed => 'स्पीड';

  @override
  String get wifiEncrypted => 'एन्क्रिप्टेड';

  @override
  String get wifiYes => 'हाँ';

  @override
  String get wifiNo => 'नहीं';

  @override
  String get wifiSecurityChecks => 'सुरक्षा जाँच';

  @override
  String wifiChecksPassed(int passed, int total) {
    return '$passed/$total पास';
  }

  @override
  String get wifiCheckEncryption => 'एन्क्रिप्शन';

  @override
  String get wifiCheckSignalStrength => 'सिग्नल की मज़बूती';

  @override
  String get wifiCheckDnsHealth => 'DNS स्वास्थ्य';

  @override
  String get wifiCheckEvilTwin => 'इविल ट्विन पहचान';

  @override
  String get wifiCheckLatency => 'नेटवर्क लेटेंसी';

  @override
  String get wifiCheckModernBand => 'आधुनिक बैंड (5GHz)';

  @override
  String get wifiEncDescYes => 'नेटवर्क WPA2/WPA3 एन्क्रिप्शन उपयोग करता है';

  @override
  String get wifiEncDescNo => 'ओपन नेटवर्क — ट्रैफ़िक एन्क्रिप्टेड नहीं है';

  @override
  String wifiDnsDescYes(int ms) {
    return 'DNS ${ms}ms में हल हुआ';
  }

  @override
  String get wifiDnsDescNo => 'DNS हल नहीं हुआ — संभावित रोक';

  @override
  String wifiBssidDesc(String bssid) {
    return 'BSSID $bssid संग्रहीत रिकॉर्ड से मेल खाता है';
  }

  @override
  String wifiLatencyDesc(int ms) {
    return 'लेटेंसी: ${ms}ms';
  }

  @override
  String get wifiLatencyDescNone => 'लेटेंसी मापी नहीं गई';

  @override
  String get wifiBandDesc5 => '5GHz बैंड का उपयोग — कम हस्तक्षेप';

  @override
  String get wifiBandDesc24 => '2.4GHz बैंड का उपयोग — अधिक हस्तक्षेप';

  @override
  String wifiSignalDesc(int rssi, String label) {
    return 'सिग्नल: $rssi dBm ($label)';
  }

  @override
  String get wifiNetworkDetails => 'नेटवर्क विवरण';

  @override
  String get wifiDetailSsid => 'SSID';

  @override
  String get wifiDetailBssid => 'BSSID';

  @override
  String get wifiDetailIp => 'IP पता';

  @override
  String get wifiDetailFrequency => 'फ़्रीक्वेंसी';

  @override
  String get wifiDetailBand => 'बैंड';

  @override
  String get wifiDetailLinkSpeed => 'लिंक स्पीड';

  @override
  String get wifiDetailSignal => 'सिग्नल';

  @override
  String get wifiDetailDnsLatency => 'DNS लेटेंसी';

  @override
  String get wifiDetailScanned => 'स्कैन किया गया';

  @override
  String get wifiUnknown => 'अज्ञात';

  @override
  String get wifiNA => 'लागू नहीं';

  @override
  String get cyberDefense => 'साइबर रक्षा';

  @override
  String get defenseThreatFusion => 'थ्रेट फ्यूज़न';

  @override
  String get defenseScreenshotScan => 'स्क्रीनशॉट स्कैन';

  @override
  String get defensePredictiveRisk => 'पूर्वानुमानित जोखिम';

  @override
  String get defenseArbitrationLog => 'मध्यस्थता लॉग';

  @override
  String get linkProtection => 'लिंक सुरक्षा';

  @override
  String get linkInterceptorTitle => 'स्मार्ट लिंक इंटरसेप्टर';

  @override
  String get linkInterceptorSub =>
      'अन्य ऐप्स से खोले गए लिंक को लोड होने से पहले स्कैन करें';

  @override
  String get cloudIntelTitle => 'क्लाउड थ्रेट इंटेलिजेंस';

  @override
  String get cloudIntelSub =>
      'लिंक को Google Safe Browsing से जाँचें (टैप किया गया लिंक Google को भेजा जाता है)। डिफ़ॉल्ट रूप से बंद।';

  @override
  String get saveLinkHistoryTitle => 'लिंक इतिहास सहेजें';

  @override
  String get saveLinkHistorySub =>
      'स्कैन किए गए लिंक इस डिवाइस पर संग्रहीत करें। बंद = कुछ भी नहीं रखा जाता।';

  @override
  String get defaultBrowserTitle => 'CyberGuard को डिफ़ॉल्ट ब्राउज़र बनाएं';

  @override
  String get defaultBrowserSub =>
      'लिंक खुलने से पहले जाँचने के लिए आवश्यक। CyberGuard हर लिंक स्कैन करता है, फिर सुरक्षित लिंक आपके ब्राउज़र को सौंपता है।';

  @override
  String get defaultBrowserActive =>
      'CyberGuard आपका डिफ़ॉल्ट ब्राउज़र है — टैप किए गए लिंक सुरक्षित हैं।';

  @override
  String get defaultBrowserSetCta => 'डिफ़ॉल्ट ब्राउज़र बनाएं';

  @override
  String get cloudIntelDialogTitle => 'क्लाउड थ्रेट इंटेलिजेंस सक्षम करें?';

  @override
  String get cloudIntelDialogBody =>
      'चालू होने पर, इंटरसेप्ट किए गए लिंक Google Safe Browsing से जाँचे जाते हैं। आपके द्वारा टैप किया गया लिंक इस जाँच के लिए Google को भेजा जाता है। आपके डिवाइस से और कुछ नहीं जाता। आप इसे कभी भी बंद कर सकते हैं।';

  @override
  String get commonEnable => 'सक्षम करें';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get threatBandSafe => 'सुरक्षित (0-30)';

  @override
  String get threatBandSuspicious => 'संदिग्ध (31-60)';

  @override
  String get threatBandDangerous => 'खतरनाक (61-80)';

  @override
  String get threatBandCritical => 'गंभीर (81-100)';

  @override
  String get threatLevelSafe => 'सुरक्षित';

  @override
  String get threatLevelSuspicious => 'संदिग्ध';

  @override
  String get threatLevelDangerous => 'खतरनाक';

  @override
  String get threatLevelCritical => 'गंभीर';

  @override
  String confidencePct(int pct) {
    return 'विश्वास $pct%';
  }

  @override
  String get warnDangerousTitle => 'खतरनाक वेबसाइट पहचानी गई';

  @override
  String get warnSuspiciousTitle => 'संदिग्ध वेबसाइट';

  @override
  String get warnRiskScore => 'जोखिम स्कोर';

  @override
  String get warnOverrideDefault =>
      'विश्वसनीय थ्रेट इंटेलिजेंस ओवरराइड द्वारा अवरुद्ध।';

  @override
  String get warnConflict =>
      'पहचान स्रोत असहमत — मध्यस्थता द्वारा निर्णय का मिलान किया गया।';

  @override
  String get warnDestination => 'गंतव्य';

  @override
  String warnVia(String app) {
    return '$app के माध्यम से';
  }

  @override
  String get warnWhyFlagged => 'इसे क्यों चिह्नित किया गया';

  @override
  String get warnSources => 'इंटेलिजेंस स्रोत';

  @override
  String get warnGoBack => 'वापस जाएँ (अनुशंसित)';

  @override
  String get warnContinue => 'फिर भी जारी रखें';

  @override
  String get warnReport => 'इस लिंक की रिपोर्ट करें';

  @override
  String get warnReported => 'रिपोर्ट किया गया। धन्यवाद।';

  @override
  String get warnOpenDangerousTitle => 'खतरनाक साइट खोलें?';

  @override
  String get warnOpenDangerousBody =>
      'CyberGuard ने इस लिंक को उच्च जोखिम वाला बताया है। इसे खोलने से आपके क्रेडेंशियल या डिवाइस उजागर हो सकते हैं। अपने जोखिम पर जारी रखें?';

  @override
  String get warnOpenAnyway => 'फिर भी खोलें';

  @override
  String get warnPrivacyNote =>
      'जब तक आप सेटिंग्स में लिंक इतिहास सक्षम नहीं करते, कोई URL संग्रहीत नहीं होता।';

  @override
  String get fusionTitle => 'थ्रेट फ्यूज़न स्कैन';

  @override
  String get fusionPrompt => 'सभी इंटेलिजेंस स्रोतों में एक लिंक जाँचें';

  @override
  String get fusionRunScan => 'फ्यूज़न स्कैन चलाएँ';

  @override
  String get fusionUnified => 'एकीकृत';

  @override
  String get fusionSourceAttribution => 'स्रोत श्रेय';

  @override
  String get fusionExplanation => 'व्याख्या';

  @override
  String get fusionConflict => 'स्रोत असहमत — मध्यस्थता द्वारा मिलान।';

  @override
  String fusionTrust(int weight) {
    return 'विश्वास $weight';
  }

  @override
  String get arbitrationTitle => 'मध्यस्थता लॉग';

  @override
  String get arbitrationClear => 'लॉग साफ़ करें';

  @override
  String get arbitrationEmptyTitle => 'अभी तक कोई विरोध नहीं';

  @override
  String get arbitrationEmptyBody =>
      'जब पहचान स्रोत असहमत होते हैं या कोई विश्वसनीय स्रोत CyberGuard को ओवरराइड करता है, तो निर्णय यहाँ दर्ज होता है।';

  @override
  String arbitrationOverride(String level) {
    return 'विश्वसनीय ओवरराइड → $level';
  }

  @override
  String arbitrationConflictTitle(String level) {
    return 'स्रोत विरोध → $level';
  }

  @override
  String get riskTitle => 'पूर्वानुमानित जोखिम';

  @override
  String get riskNoData => 'कोई डेटा नहीं';

  @override
  String get riskBandLow => 'कम';

  @override
  String get riskBandMedium => 'मध्यम';

  @override
  String get riskBandHigh => 'उच्च';

  @override
  String riskSuffix(String band) {
    return '$band जोखिम';
  }

  @override
  String get riskForecastTitle => 'खतरे का पूर्वानुमान';

  @override
  String get riskTimelineTitle => '7-दिन जोखिम समयरेखा';

  @override
  String riskWhyTitle(String band) {
    return 'आपका जोखिम $band क्यों है';
  }

  @override
  String get riskRecommendations => 'अनुशंसाएँ';

  @override
  String get forecastPhishing => 'फ़िशिंग हमला';

  @override
  String get forecastCredentialTheft => 'क्रेडेंशियल चोरी';

  @override
  String get forecastMalware => 'मैलवेयर संक्रमण';

  @override
  String get rfPhishingTitle => 'फ़िशिंग लिंक मिले';

  @override
  String rfPhishingDetail(int count) {
    return 'पिछले 7 दिनों में $count चिह्नित';
  }

  @override
  String get rfSmsTitle => 'संदिग्ध SMS प्राप्त';

  @override
  String rfSmsDetail(int count) {
    return '$count फ़िशिंग SMS पहचाने गए';
  }

  @override
  String get rfWifiTitle => 'अज्ञात Wi-Fi नेटवर्क उपयोग किए गए';

  @override
  String rfWifiDetail(int count) {
    return '$count कम-विश्वास नेटवर्क से जुड़े';
  }

  @override
  String get rfMalwareTitle => 'जोखिम भरे ऐप्स इंस्टॉल';

  @override
  String rfMalwareDetail(int count) {
    return '$count उच्च-जोखिम ऐप्स पहचाने गए';
  }

  @override
  String get rfInterceptTitle => 'हाल ही में अवरुद्ध लिंक';

  @override
  String rfInterceptDetail(int count) {
    return '$count खतरनाक लिंक इंटरसेप्ट किए गए';
  }

  @override
  String get rfBreachTitle => 'ज्ञात उल्लंघन में क्रेडेंशियल';

  @override
  String get rfBreachDetail =>
      'आपका खाता उल्लंघन किए गए डेटा में दिखाई देता है';

  @override
  String get rfTrendTitle => 'सुरक्षा स्कोर घट रहा है';

  @override
  String rfTrendDetail(int pts) {
    return 'सुरक्षा हाल ही में $pts अंक गिरी';
  }

  @override
  String get recBreach =>
      'उल्लंघन किए गए खातों के पासवर्ड बदलें और 2FA सक्षम करें।';

  @override
  String get recPhishing =>
      'अप्रत्याशित संदेशों में लिंक टैप करने से बचें; प्रेषक सत्यापित करें।';

  @override
  String get recWifi =>
      'सार्वजनिक Wi-Fi पर संवेदनशील लॉगिन से बचें; विश्वसनीय नेटवर्क उपयोग करें।';

  @override
  String get recMalware =>
      'उच्च-जोखिम ऐप्स की समीक्षा कर हटाएँ; केवल Play Store से इंस्टॉल करें।';

  @override
  String get recInterceptor =>
      'निरंतर सुरक्षा के लिए स्मार्ट लिंक इंटरसेप्टर सक्षम रखें।';

  @override
  String get recHealthy =>
      'आप अच्छी स्थिति में हैं — CyberGuard सुरक्षा सक्षम रखें।';

  @override
  String get screenshotTitle => 'स्क्रीनशॉट स्कैनर';

  @override
  String get screenshotPrompt => 'संदिग्ध पृष्ठ का स्क्रीनशॉट स्कैन करें';

  @override
  String get screenshotDesc =>
      'नकली बैंक, UPI, OTP, लॉगिन, KYC, लॉटरी और सहायता घोटालों का पता लगाता है। छवियाँ डिवाइस पर ही विश्लेषित होती हैं।';

  @override
  String get screenshotGallery => 'गैलरी';

  @override
  String get screenshotCamera => 'कैमरा';

  @override
  String get screenshotScam => 'घोटाला';

  @override
  String get screenshotLooksClean => 'साफ़ दिखता है';

  @override
  String screenshotBrand(String brand) {
    return 'ब्रांड उल्लेख: $brand';
  }

  @override
  String get screenshotIndicators => 'संकेतक';

  @override
  String get screenshotExtractedText => 'निकाला गया पाठ';

  @override
  String get scamFakeBank => 'नकली बैंक पृष्ठ';

  @override
  String get scamFakeUpi => 'नकली UPI / भुगतान पृष्ठ';

  @override
  String get scamFakeOtp => 'नकली OTP अनुरोध';

  @override
  String get scamFakeLogin => 'नकली लॉगिन पृष्ठ';

  @override
  String get scamFakeKyc => 'नकली KYC फ़ॉर्म';

  @override
  String get scamFakeLottery => 'लॉटरी / पुरस्कार घोटाला';

  @override
  String get scamFakeInvestment => 'निवेश घोटाला';

  @override
  String get scamFakeSupport => 'नकली ग्राहक सहायता';

  @override
  String get scamNone => 'कोई घोटाला संकेतक नहीं';

  @override
  String scamReasonCategory(String category, String matched) {
    return '$category: \"$matched\"';
  }

  @override
  String scamReasonBrand(String brand) {
    return 'ब्रांड उल्लेख: $brand';
  }

  @override
  String scamReasonUrgency(String word) {
    return 'तात्कालिकता / दबाव शब्द: \"$word\"';
  }

  @override
  String get scamReasonNoIndicators => 'पाठ में कोई घोटाला संकेतक नहीं मिला';

  @override
  String get scamReasonNoText => 'छवि में कोई पठनीय पाठ नहीं मिला';

  @override
  String get authTitle => 'CyberGuard AI में साइन इन करें';

  @override
  String get authSubtitle => 'अपनी सुरक्षा सेटिंग्स सभी डिवाइस पर सिंक करें';

  @override
  String get authSignIn => 'साइन इन';

  @override
  String get authSignUp => 'खाता बनाएँ';

  @override
  String get authPassword => 'पासवर्ड';

  @override
  String get authContinueGoogle => 'Google से जारी रखें';

  @override
  String get authForgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get authNoAccount => 'नए हैं? खाता बनाएँ';

  @override
  String get authHaveAccount => 'पहले से खाता है? साइन इन करें';

  @override
  String get authOr => 'या';

  @override
  String get authContinueOffline => 'बिना खाते के जारी रखें';

  @override
  String get authResetSent =>
      'यदि वह पता पंजीकृत है, तो रीसेट लिंक भेजा जा रहा है।';

  @override
  String get authUnavailableTitle => 'इस बिल्ड में साइन-इन सेट नहीं है';

  @override
  String get authUnavailableBody =>
      'यह ऐप Firebase क्रेडेंशियल के बिना बनाया गया था, इसलिए खाते उपलब्ध नहीं हैं। बाकी सब कुछ हमेशा की तरह ऑफ़लाइन काम करता है।';

  @override
  String get authErrInvalidEmail => 'यह ईमेल पता सही नहीं लगता';

  @override
  String get authErrWrongPassword => 'ईमेल या पासवर्ड ग़लत है';

  @override
  String get authErrUserNotFound => 'इस ईमेल के लिए कोई खाता नहीं मिला';

  @override
  String get authErrEmailInUse => 'इस ईमेल के लिए खाता पहले से मौजूद है';

  @override
  String get authErrWeakPassword => 'कम से कम 6 अक्षर इस्तेमाल करें';

  @override
  String get authErrNetwork =>
      'कोई कनेक्शन नहीं। अपना नेटवर्क जाँचें और फिर कोशिश करें।';

  @override
  String get authErrUnknown => 'कुछ ग़लत हो गया। कृपया फिर कोशिश करें।';

  @override
  String get authSignOut => 'साइन आउट';

  @override
  String authSignedInAs(String email) {
    return '$email के रूप में साइन इन';
  }

  @override
  String get authWelcomeBack => 'वापस स्वागत है';

  @override
  String get authCreateAccountTitle => 'अपना खाता बनाएँ';

  @override
  String get authHeroTagline => 'आपके फ़ोन की सुरक्षा, एक ही जगह';

  @override
  String get authTabSignIn => 'साइन इन';

  @override
  String get authTabRegister => 'पंजीकरण';

  @override
  String get authSecuredNote => 'एंड-टू-एंड एन्क्रिप्टेड साइन-इन से सुरक्षित';

  @override
  String get authSigningIn => 'साइन इन किया जा रहा है…';

  @override
  String get verifyEmailTitle => 'अपना ईमेल पता सत्यापित करें';

  @override
  String verifyEmailBody(String email) {
    return 'हमने $email पर एक लिंक भेजा है। यह पता आपका है, इसकी पुष्टि के लिए उस पर क्लिक करें।';
  }

  @override
  String get verifyEmailResend => 'लिंक फिर भेजें';

  @override
  String get verifyEmailSent =>
      'सत्यापन लिंक भेजा गया। अपना इनबॉक्स और स्पैम देखें।';

  @override
  String get verifyEmailFailed =>
      'लिंक नहीं भेजा जा सका। कुछ मिनट बाद फिर कोशिश करें।';

  @override
  String get verifyEmailDone => 'ईमेल की पुष्टि हो गई। धन्यवाद!';
}
