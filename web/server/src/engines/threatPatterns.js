/**
 * Port of `lib/core/constants/threat_patterns.dart`.
 *
 * Kept literally identical to the Dart source, entry for entry. The phone and
 * the browser have to reach the same verdict on the same URL — a user who
 * scans a link on their laptop and again on their phone and gets two different
 * answers has no reason to trust either. When the Dart list changes, this one
 * changes with it; `test/parity.test.js` fails if the two ever diverge in size.
 */

export const indianPhishingKeywords = [
  'verify-now', 'login-update', 'otp-confirm', 'kyc-update',
  'aadhaar-verify', 'upi-reward', 'claim-prize', 'secure-hdfc',
  'sbi-alert', 'paytm-verify', 'free-jio', 'win-prize', 'trai-notice',
  'account-suspended', 'urgent-action', 'click-now', 'lucky-winner',
  'reward-claim', 'expire-today', 'update-kyc', 'bank-alert',
  'refund-claim', 'prize-winner', 'lottery-india', 'gov-scheme',
  'income-tax-refund', 'epf-withdrawal', 'pm-kisan', 'corona-relief',
  'sim-block', 'trai-action', 'demat-verify', 'mutual-fund-claim',
  'aadhaar', 'pan-verify', 'upi-block', 'neft-alert', 'imps-failed',
  'e-kyc', 'digital-wallet', 'free-recharge', 'cashback-win',
  'offer-ends', 'limited-offer', 'click-to-claim', 'verify-account',
];

export const smsPhishingKeywords = [
  'your account', 'will be blocked', 'verify now', 'click here',
  'dear customer', 'urgent', 'immediately', 'otp', 'link',
  'congratulations', 'you have won', 'prize', 'reward',
  'kyc pending', 'account suspended', 'last chance',
  'free gift', 'lottery', 'selected', 'expire',
  'refund', 'income tax', 'claim', 'beneficiary',
  'pm scheme', 'government', 'bank account', 'update your',
];

export const suspiciousTlds = [
  '.xyz', '.tk', '.ml', '.ga', '.cf', '.click', '.top',
  '.work', '.loan', '.gq', '.pw', '.buzz', '.fun',
  '.link', '.site', '.online', '.website', '.store',
  '.info', '.biz', '.ws', '.cc', '.name', '.mobi',
  '.rocks', '.party', '.download', '.win', '.bid',
  '.stream', '.review', '.trade', '.date', '.faith',
  '.life', '.live', '.tel', '.app', '.cam',
];

export const safeDomains = [
  // Google
  'google.com', 'google.co.in', 'gmail.com', 'youtube.com',
  'google.com.au',
  // Indian UPI / banks
  'paytm.com', 'phonepe.com', 'gpay.com',
  'npci.org.in', 'bhimupi.org.in',
  'sbi.co.in', 'sbi.com', 'onlinesbi.sbi', 'onlinesbi.com',
  'hdfcbank.com', 'hdfc.com', 'icicibank.com',
  'axisbank.com', 'kotak.com', 'yesbank.in', 'pnbindia.in',
  'bankofbaroda.in', 'canarabank.com',
  'indusind.com', 'unionbankofindia.co.in',
  // E-commerce
  'amazon.in', 'amazon.com', 'flipkart.com', 'myntra.com',
  'nykaa.com', 'meesho.com', 'snapdeal.com', 'bigbasket.com',
  'grofers.com', 'zepto.com', 'blinkit.com',
  // Food / travel / cabs
  'swiggy.com', 'zomato.com', 'ola.cab', 'uber.com',
  'makemytrip.com', 'goibibo.com', 'yatra.com',
  'bookmyshow.com', 'rapido.bike', 'dunzo.com',
  // Telecom
  'jio.com', 'airtel.in', 'airtel.com', 'vi.in', 'bsnl.co.in',
  // Government & utilities
  'incometax.gov.in', 'uidai.gov.in', 'irctc.co.in',
  'digilocker.gov.in', 'mygov.in', 'india.gov.in',
  'rbi.org.in', 'sebi.gov.in', 'irdai.gov.in', 'pfrda.org.in',
  // Social / messaging
  'facebook.com', 'instagram.com', 'twitter.com', 'x.com',
  'whatsapp.com', 'linkedin.com', 'snapchat.com', 'telegram.org',
  'truecaller.com',
  // Tech / dev
  'apple.com', 'microsoft.com', 'samsung.com',
  'github.com', 'stackoverflow.com',
  // First-party infrastructure domains of brands already protected above.
  // The impersonation rule matches a brand name *anywhere* in the URL, so
  // without these `login.microsoftonline.com` and `s3.amazonaws.com` score
  // 20 for "impersonates microsoft/amazon". On their own that stays under
  // the 35-point threshold, but a single further signal tips them over — and
  // the commonest one is an OAuth `redirect_uri`, which is percent-encoded
  // and worth 15. That combination is exactly what an enterprise sign-in URL
  // looks like, so these belong on the whitelist.
  'microsoftonline.com', 'azure.com', 'windows.net',
  'amazonaws.com', 'awsstatic.com',
  'googleapis.com', 'googleusercontent.com', 'gstatic.com',
  // Finance / insurance
  'bajajfinserv.in', 'lendingkart.com',
  'policybazaar.com', 'coverfox.com', 'acko.com', 'digit.in',
];

export const dangerousPermissions = {
  'android.permission.READ_SMS': 'critical',
  'android.permission.SEND_SMS': 'critical',
  'android.permission.RECEIVE_SMS': 'critical',
  'android.permission.READ_CALL_LOG': 'high',
  'android.permission.WRITE_CALL_LOG': 'high',
  'android.permission.PROCESS_OUTGOING_CALLS': 'high',
  'android.permission.CALL_PHONE': 'high',
  'android.permission.BIND_ACCESSIBILITY_SERVICE': 'critical',
  'android.permission.BIND_DEVICE_ADMIN': 'critical',
  'android.permission.REQUEST_INSTALL_PACKAGES': 'high',
  'android.permission.RECORD_AUDIO': 'medium',
  'android.permission.CAMERA': 'medium',
  'android.permission.READ_CONTACTS': 'medium',
  'android.permission.WRITE_CONTACTS': 'medium',
  'android.permission.ACCESS_FINE_LOCATION': 'medium',
  'android.permission.ACCESS_BACKGROUND_LOCATION': 'high',
  'android.permission.READ_EXTERNAL_STORAGE': 'low',
  'android.permission.WRITE_EXTERNAL_STORAGE': 'medium',
  'android.permission.RECEIVE_BOOT_COMPLETED': 'medium',
  'android.permission.FOREGROUND_SERVICE': 'low',
  'android.permission.SYSTEM_ALERT_WINDOW': 'high',
  'android.permission.CHANGE_NETWORK_STATE': 'medium',
  'android.permission.READ_PHONE_STATE': 'medium',
  'android.permission.READ_PHONE_NUMBERS': 'medium',
  'android.permission.ANSWER_PHONE_CALLS': 'high',
  'android.permission.USE_BIOMETRIC': 'low',
  'android.permission.USE_FINGERPRINT': 'low',
  'android.permission.NFC': 'medium',
  'android.permission.BLUETOOTH': 'low',
  'android.permission.BLUETOOTH_ADMIN': 'medium',
  'android.permission.MANAGE_EXTERNAL_STORAGE': 'high',
  'android.permission.REQUEST_DELETE_PACKAGES': 'medium',
  'android.permission.KILL_BACKGROUND_PROCESSES': 'medium',
  'android.permission.VIBRATE': 'low',
  'android.permission.WAKE_LOCK': 'low',
};

export const spywareClusters = [
  ['RECORD_AUDIO', 'CAMERA', 'READ_CONTACTS'],
  ['READ_SMS', 'READ_CONTACTS', 'FOREGROUND_SERVICE'],
  ['BIND_ACCESSIBILITY_SERVICE', 'READ_SMS'],
  ['BIND_DEVICE_ADMIN', 'RECEIVE_BOOT_COMPLETED'],
  ['ACCESS_FINE_LOCATION', 'FOREGROUND_SERVICE', 'RECEIVE_BOOT_COMPLETED'],
  ['READ_CALL_LOG', 'RECORD_AUDIO', 'READ_CONTACTS'],
  ['SYSTEM_ALERT_WINDOW', 'BIND_ACCESSIBILITY_SERVICE'],
  ['READ_SMS', 'SEND_SMS', 'CALL_PHONE'],
];

/**
 * The bare-domain branch matches the FULL multi-label host so that
 * `myaadhaar.uidai.gov.in` is not truncated to `myaadhaar.uidai` — a
 * truncation that broke the safe-domain whitelist and produced false phishing
 * verdicts on official .gov.in links.
 */
export const urlPattern =
  'https?://[^\\s<>"{}|\\\\^`\\[\\]]+|www\\.[^\\s<>"{}|\\\\^`\\[\\]]+|(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}(?:/[^\\s]*)?';

export const suspiciousUrlPatterns = [
  String.raw`\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}`,
  String.raw`[0-9a-f]{32}`,
  String.raw`(?:login|signin|account|verify|secure|update|confirm).*(?:\.php|\.asp|\.aspx)`,
  String.raw`(?:paypal|apple|amazon|google|facebook|microsoft|bank|sbi|hdfc|icici).*\.(?:xyz|tk|ml|ga|cf)`,
];
