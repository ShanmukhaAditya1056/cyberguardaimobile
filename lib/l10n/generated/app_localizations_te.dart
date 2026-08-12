// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appName => 'సైబర్‌గార్డ్ AI';

  @override
  String get appTagline => 'తెలివైన భద్రతా సహాయకుడు';

  @override
  String get dashboard => 'డాష్‌బోర్డ్';

  @override
  String get alerts => 'హెచ్చరికలు';

  @override
  String get settings => 'సెట్టింగ్‌లు';

  @override
  String get phishingScanner => 'ఫిషింగ్ స్కానర్';

  @override
  String get appScanner => 'యాప్ స్కానర్';

  @override
  String get breachMonitor => 'బ్రీచ్ మానిటర్';

  @override
  String get wifiScanner => 'వైఫై స్కానర్';

  @override
  String get securityScore => 'భద్రతా స్కోర్';

  @override
  String get scanNow => 'ఇప్పుడే స్కాన్ చేయి';

  @override
  String get scanning => 'స్కాన్ అవుతోంది…';

  @override
  String get protected => 'రక్షితం';

  @override
  String get atRisk => 'ప్రమాదంలో';

  @override
  String get critical => 'క్లిష్టమైనది';

  @override
  String lastScanned(String time) {
    return 'చివరి స్కాన్ $time';
  }

  @override
  String get neverScanned => 'ఎప్పుడూ స్కాన్ చేయలేదు';

  @override
  String get protectionModules => 'రక్షణ మాడ్యూల్స్';

  @override
  String get sevenDayScore => '7-రోజుల భద్రతా స్కోర్';

  @override
  String get recentAlerts => 'ఇటీవలి హెచ్చరికలు';

  @override
  String get seeAll => 'అన్నీ చూడండి';

  @override
  String get noAlerts => 'ఇంకా హెచ్చరికలు లేవు';

  @override
  String get noAlertsDescription =>
      'స్కాన్ల సమయంలో గుర్తించబడిన ముప్పులు ఇక్కడ కనిపిస్తాయి';

  @override
  String get notifications => 'నోటిఫికేషన్లు';

  @override
  String get appearance => 'ప్రదర్శన';

  @override
  String get themeSystem => 'సిస్టమ్ డిఫాల్ట్';

  @override
  String get themeLight => 'లైట్';

  @override
  String get themeDark => 'డార్క్';

  @override
  String get language => 'భాష';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी (Hindi)';

  @override
  String get languageTamil => 'தமிழ் (Tamil)';

  @override
  String get languageTelugu => 'తెలుగు (Telugu)';

  @override
  String get exportPdf => 'PDF గా ఎగుమతి చేయి';

  @override
  String get exportCsv => 'CSV గా ఎగుమతి చేయి';

  @override
  String get exportPdfSubtitle =>
      'స్కోర్, ముప్పులు మరియు ట్రెండ్‌లతో బ్రాండెడ్ నివేదిక';

  @override
  String get exportCsvSubtitle => 'స్ప్రెడ్‌షీట్‌ల కోసం ముడి డేటా';

  @override
  String get reports => 'నివేదికలు & ఎగుమతి';

  @override
  String get liveSmsGuard => 'లైవ్ SMS ఫిషింగ్ గార్డ్';

  @override
  String get liveSmsGuardSubtitle => 'ప్రతి ఇన్‌కమింగ్ SMS ఆటో-స్కాన్';

  @override
  String get scanQrCode => 'QR కోడ్ స్కాన్ చేయి';

  @override
  String get checkBreach => 'ఇప్పుడే తనిఖీ';

  @override
  String get enterEmail => 'మీ ఇమెయిల్ చిరునామా ఎంటర్ చేయి';

  @override
  String get enterPassword => 'పరీక్షించడానికి పాస్‌వర్డ్ ఎంటర్ చేయి';

  @override
  String get noBreachFound => 'బ్రీచ్‌లు లేవు';

  @override
  String breachesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count బ్రీచ్‌లు కనుగొనబడ్డాయి',
      one: '1 బ్రీచ్ కనుగొనబడింది',
    );
    return '$_temp0';
  }

  @override
  String get onboardAiSecurityTitle => 'AI-శక్తితో భద్రత 🛡️';

  @override
  String get onboardAiSecurityDesc =>
      'ఆన్-డివైస్ మెషీన్ లెర్నింగ్ నిజ సమయంలో ఫిషింగ్, మాల్‌వేర్, బ్రీచ్‌లను గుర్తిస్తుంది — మీ డేటా ఫోన్‌ను విడిచిపెట్టదు.';

  @override
  String get onboardPhishingTitle => 'ఫిషింగ్ గుర్తింపు 🔗';

  @override
  String get onboardPhishingDesc =>
      'ఏదైనా లింక్ పేస్ట్ చేయండి లేదా మీ SMS స్కాన్ చేయండి — బ్యాంకింగ్, UPI, OTP లక్ష్యంగా చేసుకున్న ఫిషింగ్‌ను గుర్తించండి.';

  @override
  String get onboardMalwareTitle => 'మాల్‌వేర్ స్కానర్ 🐞';

  @override
  String get onboardMalwareDesc =>
      'పర్మిషన్ గ్రాఫ్ విశ్లేషణతో ఇన్‌స్టాల్ చేయబడిన యాప్‌లను లోతుగా స్కాన్ చేసి స్పైవేర్, ట్రోజన్‌లు, స్టాకర్‌వేర్‌ను కనుగొనండి.';

  @override
  String get onboardBreachTitle => 'బ్రీచ్ మానిటర్ 🔐';

  @override
  String get onboardBreachDesc =>
      '14B+ లీక్ రికార్డులను తనిఖీ చేయండి. మీ ఇమెయిల్ మరియు పాస్‌వర్డ్ స్థానికంగా హాష్ చేయబడతాయి — పూర్తిగా ఎప్పుడూ పంపబడవు.';

  @override
  String get onboardPermsTitle => 'కొన్ని అనుమతులు మాత్రమే 🙏';

  @override
  String get onboardPermsDesc =>
      'మాకు SMS, లొకేషన్ మరియు నోటిఫికేషన్ అనుమతులు అవసరం. అన్ని స్కాన్లు ఈ పరికరంలోనే ఉంటాయి.';

  @override
  String get onboardContinue => 'కొనసాగించు';

  @override
  String get onboardGrantStart => 'అనుమతులు ఇచ్చి ప్రారంభించు';

  @override
  String get onboardSkip => 'దాటవేయి';

  @override
  String get scoreGreetingProtected => 'మీరు రక్షితంగా ఉన్నారు';

  @override
  String get scoreGreetingAtRisk => 'కొన్ని విషయాలు తనిఖీ చేయాలి ⚠️';

  @override
  String get scoreGreetingCritical => 'తక్షణ చర్య అవసరం 🚨';

  @override
  String get scoreGreetingFirstScan => 'నమస్తే 👋';

  @override
  String get scoreHeadlineProtected => 'అంతా బాగానే ఉంది';

  @override
  String get scoreHeadlineAtRisk => 'ఒక్కసారి చూడండి';

  @override
  String get scoreHeadlineCritical => 'క్లిష్టమైన సమస్యలు కనుగొనబడ్డాయి';

  @override
  String get scoreHeadlineFirstScan => 'మీ ఫోన్‌ను భద్రపరచండి';

  @override
  String get permSmsTitle => 'SMS యాక్సెస్ అవసరం';

  @override
  String get permSmsRationale =>
      'ఫిషింగ్ లింక్‌లను గుర్తించడానికి సైబర్‌గార్డ్ AI మీ SMS సందేశాలను చదవాలి. మీ సందేశాలు ఎప్పుడూ సర్వర్‌కు పంపబడవు.';

  @override
  String get permLocationTitle => 'లొకేషన్ యాక్సెస్ అవసరం';

  @override
  String get permLocationRationale =>
      'SSID వంటి వైఫై వివరాలను యాక్సెస్ చేయడానికి Android-కు లొకేషన్ అనుమతి అవసరం. సైబర్‌గార్డ్ AI దీన్ని మీ నెట్‌వర్క్ భద్రతను విశ్లేషించడానికి మాత్రమే ఉపయోగిస్తుంది.';

  @override
  String get permNotifTitle => 'నోటిఫికేషన్లు';

  @override
  String get permNotifRationale =>
      'ముప్పులను గుర్తించినప్పుడు మీరు తక్షణం చర్య తీసుకోవడానికి సైబర్‌గార్డ్ AI నోటిఫికేషన్లను పంపుతుంది.';

  @override
  String get permAllowButton => 'అనుమతి ఇవ్వు';

  @override
  String get permNotNow => 'ఇప్పుడు కాదు';

  @override
  String get dialogCancel => 'రద్దు';

  @override
  String get dialogConfirm => 'నిర్ధారించు';

  @override
  String get dialogClearAll => 'అన్నీ తొలగించు';

  @override
  String get dialogReset => 'రీసెట్';

  @override
  String get dialogDelete => 'తొలగించు';

  @override
  String get dialogClose => 'మూసివేయి';

  @override
  String get breachInputTitle => 'మీ డేటా లీక్ అయిందో లేదో తనిఖీ చేయండి';

  @override
  String get breachInputSubtitle =>
      '12+ బిలియన్ లీక్ రికార్డులలో మేము తనిఖీ చేస్తాము';

  @override
  String get breachTabEmail => 'ఇమెయిల్';

  @override
  String get breachTabPhone => 'ఫోన్ నంబర్';

  @override
  String get breachInputHintEmail => 'మీ ఇమెయిల్ చిరునామా నమోదు చేయండి';

  @override
  String get breachInputHintPhone => 'మీ 10-అంకెల నంబర్ నమోదు చేయండి';

  @override
  String get breachPrivacyFooter => 'k-అజ్ఞాత రక్షణ · మీ డేటా ఈ పరికరం వదలదు';

  @override
  String get breachNoBreaches => 'ఏ ఉల్లంఘనలు కనుగొనబడలేదు';

  @override
  String get breachNoBreachesEmailDesc =>
      'శుభవార్త! తెలిసిన ఏ డేటా ఉల్లంఘనలోనూ మీ ఇమెయిల్ లేదు.';

  @override
  String get breachNoBreachesPhoneDesc =>
      'శుభవార్త! తెలిసిన ఏ డేటా ఉల్లంఘనలోనూ ఈ నంబర్ లేదు.';

  @override
  String get breachCheckedCount => '12,454,308,593 రికార్డులు తనిఖీ చేయబడ్డాయి';

  @override
  String get breachStayProtected => 'రక్షితంగా ఉండండి';

  @override
  String get breachTipUnique =>
      'ప్రతి ఖాతాకు ప్రత్యేక పాస్‌వర్డ్‌లు ఉపయోగించండి';

  @override
  String get breach2FA => 'ద్వి-అంశ ధృవీకరణను ప్రారంభించండి';

  @override
  String get breachPwManager => 'పాస్‌వర్డ్ నిర్వాహకిని ఉపయోగించండి';

  @override
  String get breachOfflineBannerTitle =>
      'ఆఫ్‌లైన్ డేటాబేస్ నుండి ఫలితాలు చూపబడుతున్నాయి';

  @override
  String get breachOfflineBannerBody =>
      'ఇవి నిజమైన చారిత్రాత్మక ఉల్లంఘనలు, కానీ సరిపోలిక మీ ఇమెయిల్ యొక్క స్థానిక హ్యాష్ నుండి తీసుకోబడింది — లైవ్ HIBP లుక్‌అప్ నుండి కాదు. లైవ్ ధృవీకరణ కోసం సెట్టింగ్స్‌లో ఉచిత HIBP API కీని కాన్ఫిగర్ చేయండి.';

  @override
  String get breachFoundEmail => 'ఈ ఉల్లంఘనలలో మీ ఇమెయిల్ బయటపెట్టబడింది:';

  @override
  String get breachFoundPhone => 'ఈ ఉల్లంఘనలలో ఈ నంబర్ బయటపెట్టబడింది:';

  @override
  String breachAccountsAffected(String count) {
    return '$count ఖాతాలు ప్రభావితమయ్యాయి';
  }

  @override
  String get breachCompromisedData => 'బయటపడిన డేటా';

  @override
  String get breachWhatToDo => 'నేను ఏం చేయాలి?';

  @override
  String get breachStep1 =>
      'ఇదే సమాచారాన్ని మరల ఉపయోగించిన ప్రతి సైట్‌లో పాస్‌వర్డ్‌లను మార్చండి.';

  @override
  String get breachStep2 =>
      'ద్వి-అంశ ధృవీకరణను ప్రారంభించండి — సాధ్యమైతే authenticator యాప్‌తో.';

  @override
  String get breachStep3 =>
      'ఉల్లంఘించబడిన సేవలాగే నటించే ఫిషింగ్ ఇమెయిల్‌ల పట్ల జాగ్రత్తగా ఉండండి.';

  @override
  String get breachStep4 =>
      'ప్రతి ఖాతాకు ప్రత్యేక పాస్‌వర్డ్‌లు ఉండేందుకు పాస్‌వర్డ్ నిర్వాహకిని పరిగణించండి.';

  @override
  String get breachPastChecks => 'గత తనిఖీలు';

  @override
  String get breachStatusSafe => 'సురక్షితం';

  @override
  String get breachStatusBreached => 'ఉల్లంఘించబడింది';

  @override
  String get breachPrivacyTitle => 'మేము మీ గోప్యతను ఎలా రక్షిస్తాము';

  @override
  String get breachPrivacyStep1 =>
      'మీ ఇన్‌పుట్ మీ పరికరంలోనే హ్యాష్ చేయబడుతుంది.';

  @override
  String get breachPrivacyStep2 =>
      'హ్యాష్ యొక్క మొదటి 5 అక్షరాలు మాత్రమే HIBP-కు పంపబడతాయి.';

  @override
  String get breachPrivacyStep3 => 'వేలాది సరిపోలిక హ్యాష్‌లు తిరిగి వస్తాయి.';

  @override
  String get breachPrivacyStep4 =>
      '100% సరిపోలిక తనిఖీ మీ పరికరంలోనే జరుగుతుంది.';

  @override
  String get qrScanTitle => 'QR స్కాన్';

  @override
  String get qrUploadFromGallery => 'గ్యాలరీ నుండి అప్‌లోడ్ చేయండి';

  @override
  String get qrPointAtCode =>
      'ఏదైనా QR వద్దకు సూచించండి · స్కాన్ చేసిన URL-లు పరికరంలోనే తనిఖీ చేయబడతాయి';

  @override
  String get qrNotAUrl => 'ఇది URL కాదు';

  @override
  String get qrNotAUrlBody => 'QR కోడ్ లింక్ కాదు, టెక్స్ట్ ఉంది:';

  @override
  String get qrPhishingDetected => 'ఫిషింగ్ QR కనుగొనబడింది';

  @override
  String get qrSafeLink => 'సురక్షిత లింక్';

  @override
  String get qrScanAnother => 'మరో దాన్ని స్కాన్ చేయండి';

  @override
  String get qrViewDetails => 'వివరాలు చూడండి';

  @override
  String qrConfidence(int count) {
    return '$count% నమ్మకం';
  }

  @override
  String get qrCameraUnavailable =>
      'కెమెరా అందుబాటులో లేదు. కెమెరా అనుమతి ఇచ్చి మళ్లీ ప్రయత్నించండి.';

  @override
  String get qrOpenSettings => 'సెట్టింగ్స్ తెరవండి';

  @override
  String get qrNoCodeInImage => 'ఈ చిత్రంలో QR కోడ్ కనుగొనబడలేదు.';

  @override
  String get scoreSuffix => '/100';

  @override
  String get scoreLabel => 'స్కోర్';

  @override
  String scannedAgo(String time) {
    return '$time స్కాన్ చేయబడింది';
  }

  @override
  String get dashboardRefreshed => 'డాష్‌బోర్డ్ రిఫ్రెష్ అయింది';

  @override
  String dashboardRefreshedWithWifi(int score) {
    return 'డాష్‌బోర్డ్ రిఫ్రెష్ అయింది · వైఫై ట్రస్ట్ $score/100';
  }

  @override
  String get moduleTitlePhishing => 'ఫిషింగ్';

  @override
  String get moduleSubtitlePhishing => 'URL & SMS స్కానర్';

  @override
  String get moduleTitleMalware => 'మాల్వేర్';

  @override
  String get moduleSubtitleMalware => 'యాప్ భద్రత';

  @override
  String get moduleTitleBreach => 'ఉల్లంఘన';

  @override
  String get moduleSubtitleBreach => 'డేటా లీక్ మానిటర్';

  @override
  String get moduleTitleWifi => 'వైఫై';

  @override
  String get moduleSubtitleWifi => 'నెట్‌వర్క్ విశ్లేషకుడు';

  @override
  String get moduleNotScanned => 'స్కాన్ కాలేదు';

  @override
  String get statTotalScans => 'మొత్తం స్కాన్లు';

  @override
  String get statThreats => 'బెదిరింపులు';

  @override
  String get statLastScan => 'చివరి స్కాన్';

  @override
  String get statNever => 'ఎప్పుడూ లేదు';

  @override
  String get settingRealTimeAlerts => 'రియల్-టైమ్ హెచ్చరికలు';

  @override
  String get settingRealTimeAlertsSub =>
      'బెదిరింపులు గుర్తించబడినప్పుడు నోటిఫై చేయండి';

  @override
  String get settingClipboardScan => 'క్లిప్‌బోర్డ్ స్కాన్';

  @override
  String get settingClipboardScanSub =>
      'క్లిప్‌బోర్డ్‌కు కాపీ చేసిన URL-లను స్కాన్ చేయండి';

  @override
  String get settingWifiAutoScan => 'ఆటో వైఫై స్కాన్';

  @override
  String get settingWifiAutoScanSub => 'నెట్‌వర్క్ మారినప్పుడు స్కాన్ చేయండి';

  @override
  String get smsPermissionDenied =>
      'SMS అనుమతి తిరస్కరించబడింది — లైవ్ స్కాన్ ప్రారంభించలేదు';

  @override
  String get settingsAutoScanFrequency => 'ఆటో స్కాన్ ఫ్రీక్వెన్సీ';

  @override
  String settingsBackgroundScanEvery(int hours) {
    return 'ప్రతి $hours గంటలకు బ్యాక్‌గ్రౌండ్ స్కాన్';
  }

  @override
  String get settingsHibpTitle => 'Have I Been Pwned API కీ';

  @override
  String get settingsHibpDesc =>
      'ఇమెయిల్ ఉల్లంఘన తనిఖీలకు అవసరం. haveibeenpwned.com/API/Key వద్ద ఉచితంగా పొందండి';

  @override
  String get settingsHibpPasteHint => 'మీ API కీని ఇక్కడ పేస్ట్ చేయండి…';

  @override
  String get settingsHibpSave => 'కీని సేవ్ చేయండి';

  @override
  String get settingsHibpSaved => 'API కీ సేవ్ చేయబడింది';

  @override
  String get settingsHibpConfigured => 'API కీ కాన్ఫిగర్ చేయబడింది';

  @override
  String get settingsPrivacy => 'గోప్యత & డేటా';

  @override
  String get settingsKAnon => 'k-అనామకత ప్రోటోకాల్';

  @override
  String get settingsKAnonDesc =>
      'పాస్‌వర్డ్‌లు ఏ సర్వర్‌కు పంపబడవు. SHA-1 హాష్‌లోని మొదటి 5 అక్షరాలు మాత్రమే ప్రసారం అవుతాయి. మీ సాక్ష్యాధారాలు మీ పరికరాన్ని వదిలి వెళ్లవు.';

  @override
  String get settingsLocalStorage => 'స్థానిక నిల్వ మాత్రమే';

  @override
  String get settingsLocalStorageDesc =>
      'అన్ని స్కాన్ ఫలితాలు మరియు చరిత్ర మీ పరికరంలో ఎన్‌క్రిప్టెడ్ Hive నిల్వలో నిల్వ చేయబడతాయి. మా సర్వర్‌లకు ఏ డేటా పంపబడదు.';

  @override
  String get settingsAbout => 'గురించి';

  @override
  String get settingsAboutVersion => 'వెర్షన్';

  @override
  String get settingsAboutEngine => 'డిటెక్షన్ ఇంజిన్';

  @override
  String get settingsAboutSources => 'డేటా మూలాలు';

  @override
  String get settingsAboutModel => 'AI మోడల్';

  @override
  String get settingsDangerZone => 'ప్రమాద జోన్';

  @override
  String get settingsResetDesc =>
      'అన్ని సెట్టింగ్‌లను డిఫాల్ట్‌లకు రీసెట్ చేయండి. ఇది స్కాన్ చరిత్రను తొలగించదు.';

  @override
  String get settingsResetBtn => 'సెట్టింగ్‌లను రీసెట్ చేయండి';

  @override
  String get settingsResetTitle => 'సెట్టింగ్‌లను రీసెట్ చేయండి';

  @override
  String get settingsResetBody =>
      'అన్ని సెట్టింగ్‌లు డిఫాల్ట్‌లకు పునరుద్ధరించబడతాయి. కొనసాగించాలా?';

  @override
  String get exportGenerating => 'PDF నివేదిక సృష్టించబడుతోంది…';

  @override
  String exportFailed(String error) {
    return 'ఎగుమతి విఫలమైంది: $error';
  }

  @override
  String get alertsMarkAllRead => 'అన్నీ చదివినట్లు గుర్తు పెట్టండి';

  @override
  String alertsNoFilter(String filter) {
    return '$filter హెచ్చరికలు లేవు';
  }

  @override
  String get alertsTryDifferent => 'వేరే ఫిల్టర్‌ను ప్రయత్నించండి';

  @override
  String get alertsClearTitle => 'అన్ని హెచ్చరికలను తొలగించండి';

  @override
  String get alertsClearBody => 'ఇది అన్ని హెచ్చరికలను శాశ్వతంగా తొలగిస్తుంది.';

  @override
  String get alertsFilterAll => 'అన్నీ';

  @override
  String get alertsFilterPhishing => 'ఫిషింగ్';

  @override
  String get alertsFilterMalware => 'మాల్వేర్';

  @override
  String get alertsFilterBreach => 'ఉల్లంఘన';

  @override
  String get alertsFilterWifi => 'వైఫై';

  @override
  String get malwareIssuesFound => 'సమస్యలు కనుగొనబడ్డాయి ⚠️';

  @override
  String get malwareAppSecurity => 'యాప్ భద్రత 🛡️';

  @override
  String get malwareTapToScan => 'మీ యాప్‌లను విశ్లేషించడానికి స్కాన్ నొక్కండి';

  @override
  String malwareAppsThreats(int apps, int threats) {
    String _temp0 = intl.Intl.pluralLogic(
      threats,
      locale: localeName,
      other: 'బెదిరింపులు',
      one: 'బెదిరింపు',
    );
    return '$apps యాప్‌లు · $threats $_temp0';
  }

  @override
  String malwareLastScan(String time) {
    return 'చివరి స్కాన్ $time';
  }

  @override
  String get malwareScanNow => 'ఇప్పుడు యాప్‌లను స్కాన్ చేయండి';

  @override
  String malwareAnalysing(String name) {
    return '$name విశ్లేషిస్తోంది…';
  }

  @override
  String malwareEtaSec(String sec) {
    return '~$secసె';
  }

  @override
  String malwareProgress(int progress, int total) {
    return '$progress / $total యాప్‌లు';
  }

  @override
  String get malwareRiskCritical => 'క్రిటికల్';

  @override
  String get malwareRiskHigh => 'అధికం';

  @override
  String get malwareRiskMedium => 'మధ్యస్థం';

  @override
  String get malwareRiskLow => 'తక్కువ';

  @override
  String get malwareSearch => 'యాప్‌లను శోధించండి…';

  @override
  String get malwareNoAppsTitle => 'యాప్‌లు కనుగొనబడలేదు';

  @override
  String get malwareNoAppsSub =>
      'మీ ఇన్‌స్టాల్ చేసిన యాప్‌లను విశ్లేషించడానికి స్కాన్ నొక్కండి';

  @override
  String get malwareNoMatchTitle => 'ఫిల్టర్‌కు సరిపోయే యాప్‌లు లేవు';

  @override
  String get malwareNoMatchSub =>
      'వేరే ఫిల్టర్ లేదా శోధన పదాన్ని ప్రయత్నించండి';

  @override
  String malwarePermsVerified(int count) {
    return '$count అనుమతులు • ధృవీకరించబడింది';
  }

  @override
  String malwarePermsSideloaded(int count) {
    return '$count అనుమతులు • సైడ్‌లోడెడ్';
  }

  @override
  String get phishingUrlTab => '🔗  URL స్కానర్';

  @override
  String get phishingSmsTab => '💬  SMS స్కానర్';

  @override
  String get phishingCheckLink => 'లింక్‌ను తనిఖీ చేయండి 🔍';

  @override
  String get phishingPasteHint =>
      'ఏదైనా URLని పేస్ట్ చేయండి — మేము పరికరంలోనే స్కాన్ చేస్తాము';

  @override
  String get phishingPaste => 'పేస్ట్';

  @override
  String get phishingScanNow => 'ఇప్పుడు స్కాన్ చేయండి';

  @override
  String get phishingScanHistory => 'స్కాన్ చరిత్ర';

  @override
  String phishingScans(int count) {
    return '$count స్కాన్‌లు';
  }

  @override
  String get phishingNoScansTitle => 'ఇంకా స్కాన్‌లు లేవు';

  @override
  String get phishingNoScansSub => 'మీరు స్కాన్ చేసే URL-లు ఇక్కడ కనిపిస్తాయి';

  @override
  String get phishingAnalysingTitle => 'AI URLని విశ్లేషిస్తోంది';

  @override
  String get phishingAnalysingSub =>
      'TLD, కీవర్డ్‌లు, నమూనాలు మరియు నిర్మాణాన్ని తనిఖీ చేస్తోంది';

  @override
  String get phishingVerdictPhishing => 'ఫిషింగ్';

  @override
  String get phishingVerdictSafe => 'సురక్షితం';

  @override
  String get phishingConfidence => 'నమ్మకం';

  @override
  String get phishingWhyFlagged => 'AI ఎందుకు దీన్ని గుర్తించింది';

  @override
  String get phishingHowItWorks => 'ఫిషింగ్ గుర్తింపు ఎలా పనిచేస్తుంది';

  @override
  String get phishingHowItWorksBody =>
      'సైబర్‌గార్డ్ AI పరికరంలోనే SHAP-వివరణాత్మక నియమ-ఆధారిత గుర్తింపును ఉపయోగిస్తుంది. విశ్లేషణలో TLD ప్రతిష్ట, కీవర్డ్ సరిపోలిక, URL నిర్మాణం మరియు బ్రాండ్ అనుకరణ తనిఖీలు ఉన్నాయి. మొత్తం విశ్లేషణ స్థానికంగా జరుగుతుంది — మీ URL-లు మీ పరికరాన్ని వదిలి వెళ్లవు.';

  @override
  String get phishingGotIt => 'అర్థమైంది';

  @override
  String get phishingSmsTitle => 'SMS ఫిషింగ్ 📨';

  @override
  String get phishingSmsSub => 'మేము మీ సందేశాలను స్థానికంగా స్కాన్ చేస్తాము';

  @override
  String get phishingSmsLoad => 'SMS లోడ్ చేయండి';

  @override
  String get phishingSmsScanAll => 'అన్నీ స్కాన్ చేయండి';

  @override
  String get phishingSmsNoneTitle => 'SMS లోడ్ కాలేదు';

  @override
  String get phishingSmsNoneSub =>
      'మీ ఇటీవలి సందేశాలను పొందడానికి \"SMS లోడ్ చేయండి\" నొక్కండి';

  @override
  String get phishingSmsUnknown => 'తెలియనిది';

  @override
  String get phishingSmsSuspicious => 'అనుమానాస్పదం';

  @override
  String get phishingSmsLinksScannedSafe =>
      'లింక్‌లు స్కాన్ చేయబడ్డాయి — సురక్షితం';

  @override
  String get phishingSmsLinksSuspicious =>
      'అనుమానాస్పద లింక్‌లు కనుగొనబడ్డాయి!';

  @override
  String phishingSmsScanLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'లింక్‌లు',
      one: 'లింక్',
    );
    return '$count $_temp0 స్కాన్ చేయండి';
  }

  @override
  String get phishingSmsNoUrls => 'ఈ సందేశంలో URL-లు లేవు';

  @override
  String get wifiClearHistoryTooltip => 'చరిత్రను తొలగించండి';

  @override
  String get wifiClearTitle => 'చరిత్రను తొలగించండి';

  @override
  String get wifiClearBody => 'అన్ని వైఫై స్కాన్ చరిత్రను తీసివేయాలా?';

  @override
  String get wifiClear => 'తొలగించండి';

  @override
  String get wifiScanThis => 'ఈ నెట్‌వర్క్‌ను స్కాన్ చేయండి';

  @override
  String get wifiScanning => 'నెట్‌వర్క్ స్కాన్ చేయబడుతోంది…';

  @override
  String get wifiScanningSub => 'రియల్-టైమ్‌లో భద్రతను విశ్లేషిస్తోంది';

  @override
  String get wifiNoScan => 'ఇంకా స్కాన్ లేదు';

  @override
  String get wifiNoScanSub =>
      'మీ వైఫైని విశ్లేషించడానికి స్కాన్ నెట్‌వర్క్ నొక్కండి';

  @override
  String get wifiUnknownSsid => 'తెలియని SSID';

  @override
  String wifiTrust(int score) {
    return 'ట్రస్ట్: $score%';
  }

  @override
  String get wifiTrustScore => 'ట్రస్ట్ స్కోర్';

  @override
  String get wifiSignal => 'సిగ్నల్';

  @override
  String get wifiBand => 'బ్యాండ్';

  @override
  String get wifiSpeed => 'వేగం';

  @override
  String get wifiEncrypted => 'ఎన్‌క్రిప్టెడ్';

  @override
  String get wifiYes => 'అవును';

  @override
  String get wifiNo => 'కాదు';

  @override
  String get wifiSecurityChecks => 'భద్రతా తనిఖీలు';

  @override
  String wifiChecksPassed(int passed, int total) {
    return '$passed/$total ఉత్తీర్ణం';
  }

  @override
  String get wifiCheckEncryption => 'ఎన్‌క్రిప్షన్';

  @override
  String get wifiCheckSignalStrength => 'సిగ్నల్ బలం';

  @override
  String get wifiCheckDnsHealth => 'DNS ఆరోగ్యం';

  @override
  String get wifiCheckEvilTwin => 'చెడు జంట గుర్తింపు';

  @override
  String get wifiCheckLatency => 'నెట్‌వర్క్ లేటెన్సీ';

  @override
  String get wifiCheckModernBand => 'ఆధునిక బ్యాండ్ (5GHz)';

  @override
  String get wifiEncDescYes =>
      'నెట్‌వర్క్ WPA2/WPA3 ఎన్‌క్రిప్షన్ ఉపయోగిస్తుంది';

  @override
  String get wifiEncDescNo => 'ఓపెన్ నెట్‌వర్క్ — ట్రాఫిక్ ఎన్‌క్రిప్ట్ కాలేదు';

  @override
  String wifiDnsDescYes(int ms) {
    return 'DNS ${ms}ms లో పరిష్కరించబడింది';
  }

  @override
  String get wifiDnsDescNo => 'DNS పరిష్కారం విఫలమైంది — అడ్డగింపు అవకాశం';

  @override
  String wifiBssidDesc(String bssid) {
    return 'BSSID $bssid నిల్వ చేసిన రికార్డుతో సరిపోతుంది';
  }

  @override
  String wifiLatencyDesc(int ms) {
    return 'లేటెన్సీ: ${ms}ms';
  }

  @override
  String get wifiLatencyDescNone => 'లేటెన్సీ కొలవబడలేదు';

  @override
  String get wifiBandDesc5 => '5GHz బ్యాండ్ ఉపయోగంలో — తక్కువ అంతరాయం';

  @override
  String get wifiBandDesc24 => '2.4GHz బ్యాండ్ ఉపయోగంలో — ఎక్కువ అంతరాయం';

  @override
  String wifiSignalDesc(int rssi, String label) {
    return 'సిగ్నల్: $rssi dBm ($label)';
  }

  @override
  String get wifiNetworkDetails => 'నెట్‌వర్క్ వివరాలు';

  @override
  String get wifiDetailSsid => 'SSID';

  @override
  String get wifiDetailBssid => 'BSSID';

  @override
  String get wifiDetailIp => 'IP చిరునామా';

  @override
  String get wifiDetailFrequency => 'ఫ్రీక్వెన్సీ';

  @override
  String get wifiDetailBand => 'బ్యాండ్';

  @override
  String get wifiDetailLinkSpeed => 'లింక్ వేగం';

  @override
  String get wifiDetailSignal => 'సిగ్నల్';

  @override
  String get wifiDetailDnsLatency => 'DNS లేటెన్సీ';

  @override
  String get wifiDetailScanned => 'స్కాన్ చేయబడింది';

  @override
  String get wifiUnknown => 'తెలియనిది';

  @override
  String get wifiNA => 'వర్తించదు';

  @override
  String get cyberDefense => 'సైబర్ రక్షణ';

  @override
  String get defenseThreatFusion => 'థ్రెట్ ఫ్యూజన్';

  @override
  String get defenseScreenshotScan => 'స్క్రీన్‌షాట్ స్కాన్';

  @override
  String get defensePredictiveRisk => 'ముందస్తు అంచనా ప్రమాదం';

  @override
  String get defenseArbitrationLog => 'మధ్యవర్తిత్వ లాగ్';

  @override
  String get linkProtection => 'లింక్ రక్షణ';

  @override
  String get linkInterceptorTitle => 'స్మార్ట్ లింక్ ఇంటర్‌సెప్టర్';

  @override
  String get linkInterceptorSub =>
      'ఇతర యాప్‌ల నుండి తెరిచే లింక్‌లను లోడ్ కాకముందే స్కాన్ చేయండి';

  @override
  String get cloudIntelTitle => 'క్లౌడ్ థ్రెట్ ఇంటెలిజెన్స్';

  @override
  String get cloudIntelSub =>
      'లింక్‌లను Google Safe Browsing తో తనిఖీ చేయండి (నొక్కిన లింక్ Googleకు పంపబడుతుంది). డిఫాల్ట్‌గా ఆఫ్.';

  @override
  String get saveLinkHistoryTitle => 'లింక్ చరిత్రను సేవ్ చేయండి';

  @override
  String get saveLinkHistorySub =>
      'స్కాన్ చేసిన లింక్‌లను ఈ పరికరంలో నిల్వ చేయండి. ఆఫ్ = ఏదీ ఉంచబడదు.';

  @override
  String get defaultBrowserTitle =>
      'CyberGuard‌ను డిఫాల్ట్ బ్రౌజర్‌గా సెట్ చేయండి';

  @override
  String get defaultBrowserSub =>
      'లింక్‌లు తెరవక ముందు తనిఖీ చేయడానికి అవసరం. CyberGuard ప్రతి లింక్‌ను స్కాన్ చేసి, సురక్షితమైనవాటిని మీ బ్రౌజర్‌కు అందిస్తుంది.';

  @override
  String get defaultBrowserActive =>
      'CyberGuard మీ డిఫాల్ట్ బ్రౌజర్ — ట్యాప్ చేసిన లింక్‌లు రక్షించబడ్డాయి.';

  @override
  String get defaultBrowserSetCta => 'డిఫాల్ట్ బ్రౌజర్‌గా సెట్ చేయండి';

  @override
  String get cloudIntelDialogTitle =>
      'క్లౌడ్ థ్రెట్ ఇంటెలిజెన్స్‌ను ప్రారంభించాలా?';

  @override
  String get cloudIntelDialogBody =>
      'ఆన్‌లో ఉన్నప్పుడు, ఇంటర్‌సెప్ట్ చేసిన లింక్‌లు Google Safe Browsing తో తనిఖీ చేయబడతాయి. మీరు నొక్కిన లింక్ ఈ తనిఖీ కోసం Googleకు పంపబడుతుంది. మరేదీ మీ పరికరం నుండి బయటకు వెళ్లదు. మీరు దీన్ని ఎప్పుడైనా ఆఫ్ చేయవచ్చు.';

  @override
  String get commonEnable => 'ప్రారంభించు';

  @override
  String get commonCancel => 'రద్దు';

  @override
  String get threatBandSafe => 'సురక్షితం (0-30)';

  @override
  String get threatBandSuspicious => 'అనుమానాస్పదం (31-60)';

  @override
  String get threatBandDangerous => 'ప్రమాదకరం (61-80)';

  @override
  String get threatBandCritical => 'క్లిష్టం (81-100)';

  @override
  String get threatLevelSafe => 'సురక్షితం';

  @override
  String get threatLevelSuspicious => 'అనుమానాస్పదం';

  @override
  String get threatLevelDangerous => 'ప్రమాదకరం';

  @override
  String get threatLevelCritical => 'క్లిష్టం';

  @override
  String confidencePct(int pct) {
    return 'విశ్వాసం $pct%';
  }

  @override
  String get warnDangerousTitle => 'ప్రమాదకర వెబ్‌సైట్ గుర్తించబడింది';

  @override
  String get warnSuspiciousTitle => 'అనుమానాస్పద వెబ్‌సైట్';

  @override
  String get warnRiskScore => 'ప్రమాద స్కోర్';

  @override
  String get warnOverrideDefault =>
      'విశ్వసనీయ థ్రెట్ ఇంటెలిజెన్స్ ఓవర్‌రైడ్ ద్వారా నిరోధించబడింది.';

  @override
  String get warnConflict =>
      'గుర్తింపు మూలాలు విభేదించాయి — మధ్యవర్తిత్వం ద్వారా తీర్పు సరిచేయబడింది.';

  @override
  String get warnDestination => 'గమ్యం';

  @override
  String warnVia(String app) {
    return '$app ద్వారా';
  }

  @override
  String get warnWhyFlagged => 'ఇది ఎందుకు ఫ్లాగ్ చేయబడింది';

  @override
  String get warnSources => 'ఇంటెలిజెన్స్ మూలాలు';

  @override
  String get warnGoBack => 'వెనక్కి వెళ్లు (సిఫార్సు)';

  @override
  String get warnContinue => 'అయినా కొనసాగించు';

  @override
  String get warnReport => 'ఈ లింక్‌ను నివేదించు';

  @override
  String get warnReported => 'నివేదించబడింది. ధన్యవాదాలు.';

  @override
  String get warnOpenDangerousTitle => 'ప్రమాదకర సైట్‌ను తెరవాలా?';

  @override
  String get warnOpenDangerousBody =>
      'CyberGuard ఈ లింక్‌ను అధిక ప్రమాదకరంగా రేట్ చేసింది. దీన్ని తెరవడం మీ ఆధారాలు లేదా పరికరాన్ని బహిర్గతం చేయవచ్చు. మీ స్వంత ప్రమాదంలో కొనసాగించాలా?';

  @override
  String get warnOpenAnyway => 'అయినా తెరువు';

  @override
  String get warnPrivacyNote =>
      'మీరు సెట్టింగ్‌లలో లింక్ చరిత్రను ప్రారంభించనంత వరకు ఏ URL నిల్వ చేయబడదు.';

  @override
  String get fusionTitle => 'థ్రెట్ ఫ్యూజన్ స్కాన్';

  @override
  String get fusionPrompt =>
      'అన్ని ఇంటెలిజెన్స్ మూలాలలో ఒక లింక్‌ను తనిఖీ చేయండి';

  @override
  String get fusionRunScan => 'ఫ్యూజన్ స్కాన్ నడుపు';

  @override
  String get fusionUnified => 'ఏకీకృతం';

  @override
  String get fusionSourceAttribution => 'మూల ఆపాదన';

  @override
  String get fusionExplanation => 'వివరణ';

  @override
  String get fusionConflict =>
      'మూలాలు విభేదించాయి — మధ్యవర్తిత్వం ద్వారా సరిచేయబడింది.';

  @override
  String fusionTrust(int weight) {
    return 'విశ్వాసం $weight';
  }

  @override
  String get arbitrationTitle => 'మధ్యవర్తిత్వ లాగ్';

  @override
  String get arbitrationClear => 'లాగ్ క్లియర్ చేయి';

  @override
  String get arbitrationEmptyTitle => 'ఇంకా విభేదాలు లేవు';

  @override
  String get arbitrationEmptyBody =>
      'గుర్తింపు మూలాలు విభేదించినప్పుడు లేదా విశ్వసనీయ మూలం CyberGuardను ఓవర్‌రైడ్ చేసినప్పుడు, నిర్ణయం ఇక్కడ నమోదు అవుతుంది.';

  @override
  String arbitrationOverride(String level) {
    return 'విశ్వసనీయ ఓవర్‌రైడ్ → $level';
  }

  @override
  String arbitrationConflictTitle(String level) {
    return 'మూల విభేదం → $level';
  }

  @override
  String get riskTitle => 'ముందస్తు అంచనా ప్రమాదం';

  @override
  String get riskNoData => 'డేటా లేదు';

  @override
  String get riskBandLow => 'తక్కువ';

  @override
  String get riskBandMedium => 'మధ్యస్థం';

  @override
  String get riskBandHigh => 'అధికం';

  @override
  String riskSuffix(String band) {
    return '$band ప్రమాదం';
  }

  @override
  String get riskForecastTitle => 'ముప్పు సూచన';

  @override
  String get riskTimelineTitle => '7-రోజుల ప్రమాద కాలక్రమం';

  @override
  String riskWhyTitle(String band) {
    return 'మీ ప్రమాదం ఎందుకు $band';
  }

  @override
  String get riskRecommendations => 'సిఫార్సులు';

  @override
  String get forecastPhishing => 'ఫిషింగ్ దాడి';

  @override
  String get forecastCredentialTheft => 'ఆధార దొంగతనం';

  @override
  String get forecastMalware => 'మాల్‌వేర్ సంక్రమణ';

  @override
  String get rfPhishingTitle => 'ఫిషింగ్ లింక్‌లు ఎదురయ్యాయి';

  @override
  String rfPhishingDetail(int count) {
    return 'గత 7 రోజుల్లో $count ఫ్లాగ్ చేయబడ్డాయి';
  }

  @override
  String get rfSmsTitle => 'అనుమానాస్పద SMS అందింది';

  @override
  String rfSmsDetail(int count) {
    return '$count ఫిషింగ్ SMS గుర్తించబడ్డాయి';
  }

  @override
  String get rfWifiTitle => 'తెలియని Wi-Fi నెట్‌వర్క్‌లు ఉపయోగించబడ్డాయి';

  @override
  String rfWifiDetail(int count) {
    return '$count తక్కువ-విశ్వాస నెట్‌వర్క్‌లకు కనెక్ట్ అయ్యారు';
  }

  @override
  String get rfMalwareTitle => 'ప్రమాదకర యాప్‌లు ఇన్‌స్టాల్ చేయబడ్డాయి';

  @override
  String rfMalwareDetail(int count) {
    return '$count అధిక-ప్రమాద యాప్‌లు గుర్తించబడ్డాయి';
  }

  @override
  String get rfInterceptTitle => 'ఇటీవల నిరోధించిన లింక్‌లు';

  @override
  String rfInterceptDetail(int count) {
    return '$count ప్రమాదకర లింక్‌లు ఇంటర్‌సెప్ట్ చేయబడ్డాయి';
  }

  @override
  String get rfBreachTitle => 'తెలిసిన ఉల్లంఘనలో ఆధారాలు';

  @override
  String get rfBreachDetail => 'మీ ఖాతా ఉల్లంఘించబడిన డేటాలో కనిపిస్తుంది';

  @override
  String get rfTrendTitle => 'భద్రతా స్కోర్ తగ్గుతోంది';

  @override
  String rfTrendDetail(int pts) {
    return 'భద్రత ఇటీవల $pts పాయింట్లు తగ్గింది';
  }

  @override
  String get recBreach =>
      'ఉల్లంఘించబడిన ఖాతాల పాస్‌వర్డ్‌లను మార్చి 2FA ప్రారంభించండి.';

  @override
  String get recPhishing =>
      'ఊహించని సందేశాలలో లింక్‌లను నొక్కడం మానుకోండి; పంపినవారిని ధృవీకరించండి.';

  @override
  String get recWifi =>
      'పబ్లిక్ Wi-Fiలో సున్నితమైన లాగిన్‌లను మానుకోండి; విశ్వసనీయ నెట్‌వర్క్‌ను ఉపయోగించండి.';

  @override
  String get recMalware =>
      'అధిక-ప్రమాద యాప్‌లను సమీక్షించి తొలగించండి; Play Store నుండి మాత్రమే ఇన్‌స్టాల్ చేయండి.';

  @override
  String get recInterceptor =>
      'నిరంతర రక్షణ కోసం స్మార్ట్ లింక్ ఇంటర్‌సెప్టర్‌ను ప్రారంభించి ఉంచండి.';

  @override
  String get recHealthy =>
      'మీరు మంచి స్థితిలో ఉన్నారు — CyberGuard రక్షణలను ప్రారంభించి ఉంచండి.';

  @override
  String get screenshotTitle => 'స్క్రీన్‌షాట్ స్కానర్';

  @override
  String get screenshotPrompt =>
      'అనుమానాస్పద పేజీ స్క్రీన్‌షాట్‌ను స్కాన్ చేయండి';

  @override
  String get screenshotDesc =>
      'నకిలీ బ్యాంక్, UPI, OTP, లాగిన్, KYC, లాటరీ మరియు సపోర్ట్ మోసాలను గుర్తిస్తుంది. చిత్రాలు పరికరంలోనే విశ్లేషించబడతాయి.';

  @override
  String get screenshotGallery => 'గ్యాలరీ';

  @override
  String get screenshotCamera => 'కెమెరా';

  @override
  String get screenshotScam => 'మోసం';

  @override
  String get screenshotLooksClean => 'శుభ్రంగా కనిపిస్తోంది';

  @override
  String screenshotBrand(String brand) {
    return 'ప్రస్తావించబడిన బ్రాండ్: $brand';
  }

  @override
  String get screenshotIndicators => 'సూచికలు';

  @override
  String get screenshotExtractedText => 'సంగ్రహించిన వచనం';

  @override
  String get scamFakeBank => 'నకిలీ బ్యాంక్ పేజీ';

  @override
  String get scamFakeUpi => 'నకిలీ UPI / చెల్లింపు పేజీ';

  @override
  String get scamFakeOtp => 'నకిలీ OTP అభ్యర్థన';

  @override
  String get scamFakeLogin => 'నకిలీ లాగిన్ పేజీ';

  @override
  String get scamFakeKyc => 'నకిలీ KYC ఫారం';

  @override
  String get scamFakeLottery => 'లాటరీ / బహుమతి మోసం';

  @override
  String get scamFakeInvestment => 'పెట్టుబడి మోసం';

  @override
  String get scamFakeSupport => 'నకిలీ కస్టమర్ సపోర్ట్';

  @override
  String get scamNone => 'మోసం సూచికలు లేవు';

  @override
  String scamReasonCategory(String category, String matched) {
    return '$category: \"$matched\"';
  }

  @override
  String scamReasonBrand(String brand) {
    return 'ప్రస్తావించబడిన బ్రాండ్: $brand';
  }

  @override
  String scamReasonUrgency(String word) {
    return 'అత్యవసర / ఒత్తిడి పదాలు: \"$word\"';
  }

  @override
  String get scamReasonNoIndicators => 'వచనంలో మోసం సూచికలు ఏవీ కనుగొనబడలేదు';

  @override
  String get scamReasonNoText => 'చిత్రంలో చదవగలిగే వచనం ఏదీ కనుగొనబడలేదు';

  @override
  String get authTitle => 'CyberGuard AI లో సైన్ ఇన్ చేయండి';

  @override
  String get authSubtitle =>
      'మీ భద్రతా సెట్టింగ్‌లను అన్ని పరికరాల్లో సమకాలీకరించండి';

  @override
  String get authSignIn => 'సైన్ ఇన్';

  @override
  String get authSignUp => 'ఖాతా సృష్టించండి';

  @override
  String get authPassword => 'పాస్‌వర్డ్';

  @override
  String get authContinueGoogle => 'Google తో కొనసాగండి';

  @override
  String get authForgotPassword => 'పాస్‌వర్డ్ మర్చిపోయారా?';

  @override
  String get authNoAccount => 'కొత్తవారా? ఖాతా సృష్టించండి';

  @override
  String get authHaveAccount => 'ఇప్పటికే ఖాతా ఉందా? సైన్ ఇన్ చేయండి';

  @override
  String get authOr => 'లేదా';

  @override
  String get authContinueOffline => 'ఖాతా లేకుండా కొనసాగండి';

  @override
  String get authResetSent =>
      'ఆ చిరునామా నమోదై ఉంటే, రీసెట్ లింక్ పంపబడుతుంది.';

  @override
  String get authUnavailableTitle => 'ఈ బిల్డ్‌లో సైన్-ఇన్ సెటప్ కాలేదు';

  @override
  String get authUnavailableBody =>
      'ఈ యాప్ Firebase ఆధారాలు లేకుండా నిర్మించబడింది, కాబట్టి ఖాతాలు అందుబాటులో లేవు. మిగతావన్నీ ఎప్పటిలాగే ఆఫ్‌లైన్‌లో పనిచేస్తాయి.';

  @override
  String get authErrInvalidEmail => 'ఆ ఇమెయిల్ చిరునామా సరిగ్గా లేదు';

  @override
  String get authErrWrongPassword => 'ఇమెయిల్ లేదా పాస్‌వర్డ్ తప్పు';

  @override
  String get authErrUserNotFound => 'ఆ ఇమెయిల్‌కు ఖాతా కనుగొనబడలేదు';

  @override
  String get authErrEmailInUse => 'ఆ ఇమెయిల్‌కు ఇప్పటికే ఖాతా ఉంది';

  @override
  String get authErrWeakPassword => 'కనీసం 6 అక్షరాలు వాడండి';

  @override
  String get authErrNetwork =>
      'కనెక్షన్ లేదు. మీ నెట్‌వర్క్ తనిఖీ చేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String get authErrUnknown =>
      'ఏదో తప్పు జరిగింది. దయచేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String get authSignOut => 'సైన్ అవుట్';

  @override
  String authSignedInAs(String email) {
    return '$email గా సైన్ ఇన్ అయ్యారు';
  }

  @override
  String get authWelcomeBack => 'మళ్లీ స్వాగతం';

  @override
  String get authCreateAccountTitle => 'మీ ఖాతాను సృష్టించండి';

  @override
  String get authHeroTagline => 'మీ ఫోన్ భద్రత, ఒకే చోట';

  @override
  String get authTabSignIn => 'సైన్ ఇన్';

  @override
  String get authTabRegister => 'నమోదు';

  @override
  String get authSecuredNote =>
      'ఎండ్-టు-ఎండ్ ఎన్క్రిప్టెడ్ సైన్-ఇన్ ద్వారా రక్షించబడింది';

  @override
  String get authSigningIn => 'సైన్ ఇన్ చేస్తోంది…';

  @override
  String get verifyEmailTitle => 'మీ ఇమెయిల్ చిరునామాను నిర్ధారించండి';

  @override
  String verifyEmailBody(String email) {
    return '$email కు ఒక లింక్ పంపాము. ఈ చిరునామా మీదేనని నిర్ధారించడానికి దానిపై క్లిక్ చేయండి.';
  }

  @override
  String get verifyEmailResend => 'లింక్ మళ్లీ పంపు';

  @override
  String get verifyEmailSent =>
      'ధృవీకరణ లింక్ పంపబడింది. మీ ఇన్‌బాక్స్ మరియు స్పామ్ చూడండి.';

  @override
  String get verifyEmailFailed =>
      'లింక్ పంపలేకపోయాం. కొన్ని నిమిషాల్లో మళ్లీ ప్రయత్నించండి.';

  @override
  String get verifyEmailDone => 'ఇమెయిల్ నిర్ధారించబడింది. ధన్యవాదాలు!';

  @override
  String get qrRetryCamera => 'మళ్లీ ప్రయత్నించండి';

  @override
  String get qrGalleryStillWorks =>
      'గ్యాలరీ నుండి QR చిత్రాన్ని ఇప్పటికీ అప్‌లోడ్ చేయవచ్చు.';
}
