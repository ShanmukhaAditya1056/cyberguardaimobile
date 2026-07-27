'use strict';

const ExcelJS = require('exceljs');
const path = require('path');

/**
 * Emits `findings.xlsx` from the structured finding set below.
 *
 * The findings live here as data rather than being scraped out of the Markdown
 * so that the spreadsheet and the report cannot drift: `security-review.md` is
 * the prose version of exactly these records.
 *
 * Run: node security/generate-findings-xlsx.js
 */

const FINDINGS = [
  {
    id: 'MOB-001',
    severity: 'High',
    title: 'Release builds are signed with the debug keystore',
    category: 'Build & Release',
    masvs: 'MASVS-CODE-1',
    cwe: 'CWE-798',
    owasp: 'M8 — Security Misconfiguration',
    file: 'android/app/build.gradle:33-37',
    description:
      'The release build type sets signingConfig signingConfigs.debug. The debug keystore uses the publicly known password "android" and alias "androiddebugkey".',
    impact:
      'Anyone can re-sign a modified APK with the same public key; Android update signature continuity is meaningless. Play refuses debug-signed uploads.',
    remediation:
      'Create a release keystore, load credentials from the gitignored android/key.properties, and point signingConfigs.release at it.',
    verification:
      'apksigner verify --print-certs app-release.apk — certificate DN must not be CN=Android Debug.',
    effort: '30 min',
  },
  {
    id: 'MOB-002',
    severity: 'High',
    title: 'Third-party API key compiled into the APK as a string constant',
    category: 'Secrets Management',
    masvs: 'MASVS-STORAGE-1',
    cwe: 'CWE-798',
    owasp: 'M1 — Improper Credential Usage',
    file: 'lib/core/config/api_keys.dart:12',
    description:
      'The Google Safe Browsing key is a Dart const, embedded verbatim in the app snapshot and recoverable with strings. Mitigating: the file is gitignored and was never committed.',
    impact:
      'Quota theft against the project billing account; denial of the reputation feature for real users. No user data is exposed by this key.',
    remediation:
      'Apply API + Android app restrictions in Google Cloud Console (highest value, 15 min). Inject via --dart-define at build time. Long term, migrate to the Safe Browsing Update API which never sends the full URL.',
    verification: 'strings app-release.apk | grep -c AIza  → expect 0',
    effort: '15 min (restrictions) / 1 hr (dart-define)',
  },
  {
    id: 'MOB-003',
    severity: 'High',
    title: 'HIBP API key stored in plaintext despite a secure-storage dependency',
    category: 'Data Storage',
    masvs: 'MASVS-STORAGE-1',
    cwe: 'CWE-312',
    owasp: 'M9 — Insecure Data Storage',
    file: 'lib/data/models/settings_model.dart:20',
    description:
      "The user's paid HIBP API key is written to an unencrypted Hive box. flutter_secure_storage ^9.0.0 is declared in pubspec.yaml but has zero usages in lib/.",
    impact:
      "Theft of a paid third-party credential belonging to the user. Reachable without root when combined with MOB-005.",
    remediation:
      'Store the key via flutter_secure_storage with encryptedSharedPreferences enabled; remove hibpApiKey from SettingsModel and migrate existing values.',
    verification:
      'adb shell run-as com.cyberguard.ai cat files/settings.hive | strings | grep <key> → no match',
    effort: '2 hrs',
  },
  {
    id: 'MOB-004',
    severity: 'Medium',
    title: 'All local Hive databases are unencrypted',
    category: 'Data Storage',
    masvs: 'MASVS-STORAGE-1',
    cwe: 'CWE-312',
    owasp: 'M9 — Insecure Data Storage',
    file: 'lib/data/services/hive_service.dart:48-54',
    description:
      'Seven boxes are opened with no encryptionCipher: scan results, alerts, Wi-Fi scans, score history, settings, app-scan cache, prefs.',
    impact:
      'Cleartext browsing history, Wi-Fi BSSID list (resolvable to physical locations via public geolocation databases) and a full installed-app inventory (a strong device fingerprint).',
    remediation:
      'Open every box with HiveAesCipher, keyed from a secret held in the Android Keystore via flutter_secure_storage. Ship a one-time migration.',
    verification: 'Hex-dump each .hive file; readable URLs/SSIDs must be absent.',
    effort: '4 hrs',
  },
  {
    id: 'MOB-005',
    severity: 'Medium',
    title: 'Android backup enabled by default',
    category: 'Data Storage',
    masvs: 'MASVS-STORAGE-2',
    cwe: 'CWE-530',
    owasp: 'M9 — Insecure Data Storage',
    file: 'android/app/src/main/AndroidManifest.xml',
    description:
      'No allowBackup, fullBackupContent or dataExtractionRules is declared, so allowBackup defaults to true and the whole data directory is backup-eligible.',
    impact:
      'adb backup extracts all unencrypted local data from an unrooted device; Auto Backup copies it to the user Google Drive.',
    remediation:
      'Set android:allowBackup="false", or supply dataExtractionRules excluding the sensitive .hive files.',
    verification: 'adb backup -f test.ab com.cyberguard.ai → archive contains no app data.',
    effort: '15 min',
  },
  {
    id: 'MOB-006',
    severity: 'Medium',
    title: 'Code shrinking and obfuscation disabled in release builds',
    category: 'Build & Release',
    masvs: 'MASVS-RESILIENCE-3',
    cwe: 'CWE-656',
    owasp: 'M7 — Insufficient Binary Protections',
    file: 'android/app/build.gradle:35-36',
    description:
      'minifyEnabled false and shrinkResources false; the Dart layer is also built without --obfuscate.',
    impact:
      'Trivial reverse engineering. Detection thresholds and the domain whitelist are readable, enabling an attacker to craft URLs scoring just under the 35-point phishing threshold.',
    remediation:
      'Enable minifyEnabled/shrinkResources with a proguard-rules.pro that keeps Flutter, ML Kit and the platform-channel classes; build with --obfuscate --split-debug-info.',
    verification: 'Decompile the release APK; app class names should be unreadable.',
    effort: '1 hr',
  },
  {
    id: 'MOB-007',
    severity: 'Medium',
    title: 'No certificate pinning on outbound HTTPS',
    category: 'Network Security',
    masvs: 'MASVS-NETWORK-2',
    cwe: 'CWE-295',
    owasp: 'M5 — Insecure Communication',
    file: 'lib/data/services/threat_intel/safe_browsing_source.dart:29-34',
    description:
      'Dio is constructed with default TLS validation and no pinning. Mitigating: network_security_config restricts trust to system CAs, so user-added certs are already rejected.',
    impact:
      'A compromised or coerced public CA could intercept HIBP requests carrying the user API key, or tamper with Safe Browsing verdicts.',
    remediation:
      'Pin SPKI SHA-256 hashes for the leaf/intermediate, always including a backup pin. Both services already accept an injected Dio instance.',
    verification: 'mitmproxy with a system-trusted CA installed must fail to intercept.',
    effort: '3 hrs',
  },
  {
    id: 'MOB-008',
    severity: 'Medium',
    title: 'QUERY_ALL_PACKAGES grants a full installed-app inventory',
    category: 'Privacy & Permissions',
    masvs: 'MASVS-PRIVACY-1',
    cwe: 'CWE-250',
    owasp: 'M6 — Inadequate Privacy Controls',
    file: 'android/app/src/main/AndroidManifest.xml',
    description:
      'A Play-restricted permission requiring an approved declaration. Functionally justified by the malware scanner, but yields a high-value fingerprint stored unencrypted.',
    impact:
      'Play policy rejection risk; the inventory can reveal banking, health, dating and political app usage.',
    remediation:
      'Submit the Play Console declaration (security scanner is an approved use case); prefer a <queries> element where possible; encrypt appScanCacheBox; consider hashing package names.',
    verification: 'Play Console pre-submission check passes.',
    effort: 'Declaration only',
  },
  {
    id: 'MOB-009',
    severity: 'Low',
    title: 'Exported activity accepts arbitrary http/https VIEW intents',
    category: 'Platform Interaction',
    masvs: 'MASVS-PLATFORM-1',
    cwe: 'CWE-926',
    owasp: 'M8 — Security Misconfiguration',
    file: 'android/app/src/main/AndroidManifest.xml',
    description:
      'MainActivity is exported with VIEW/BROWSABLE filters for http and https and a SEND text/plain filter. This is inherent to the Smart Link Interceptor feature.',
    impact:
      'Any app can launch the interceptor screen with an arbitrary URL — a UI nuisance. No privileged action is reachable from the intent alone.',
    remediation:
      'Continue validating and length-capping incoming URIs. Do not add autoVerify. Consider rate-limiting interceptor launches.',
    verification: 'adb shell am start -a android.intent.action.VIEW -d "<malformed>" → no crash.',
    effort: 'Already largely mitigated',
  },
  {
    id: 'MOB-010',
    severity: 'Low',
    title: 'SMS read permissions expand the privacy blast radius',
    category: 'Privacy & Permissions',
    masvs: 'MASVS-PRIVACY-1',
    cwe: 'CWE-359',
    owasp: 'M6 — Inadequate Privacy Controls',
    file: 'android/app/src/main/AndroidManifest.xml',
    description:
      'READ_SMS and RECEIVE_SMS are Play-restricted. Mitigating: the receiver is dynamically registered, scanning is on-device in Kotlin, and PhishingGuardService is not exported.',
    impact:
      'Any future compromise of this app inherits SMS access, which is sufficient to defeat SMS-based 2FA.',
    remediation:
      'Submit the Play SMS declaration; never persist message bodies; redact OTP-shaped digit runs before any body reaches a log or alert.',
    verification: 'Inspect alertsBox — no full SMS bodies present.',
    effort: 'Declaration + review',
  },
  {
    id: 'MOB-011',
    severity: 'Low',
    title: 'Displayed version string does not match the build version',
    category: 'Code Quality',
    masvs: 'MASVS-CODE-2',
    cwe: 'CWE-1059',
    owasp: 'M8 — Security Misconfiguration',
    file: 'lib/features/settings/view/settings_screen.dart:523',
    description:
      "The About screen hardcodes '1.0.0' while pubspec.yaml declares 2.0.0+1. package_info_plus is already a dependency.",
    impact:
      'Bug reports quote the wrong version; incident response cannot identify the affected build.',
    remediation: 'Read the value from PackageInfo.fromPlatform().',
    verification: 'About screen shows 2.0.0+1.',
    effort: '10 min',
  },
  {
    id: 'MOB-012',
    severity: 'Low',
    title: 'No root, emulator or tamper detection',
    category: 'Resilience',
    masvs: 'MASVS-RESILIENCE-1',
    cwe: 'CWE-919',
    owasp: 'M7 — Insufficient Binary Protections',
    file: 'Application-wide',
    description:
      'No integrity self-checks. Notable for a security product, whose users are disproportionately likely to be on compromised devices.',
    impact:
      'On a rooted device every storage finding becomes trivially exploitable and the app cannot warn the user.',
    remediation:
      'Detect and warn (not block) using freerasp or flutter_jailbreak_detection; add Play Integrity if a backend is ever introduced.',
    verification: 'Launch on a rooted emulator → warning banner appears.',
    effort: '2 hrs',
  },
  {
    id: 'MOB-013',
    severity: 'Informational',
    title: 'No integrity verification on bundled ML model assets',
    category: 'Resilience',
    masvs: 'MASVS-RESILIENCE-4',
    cwe: 'CWE-345',
    owasp: 'M7 — Insufficient Binary Protections',
    file: 'lib/data/services/phishing_ml_service.dart:48',
    description:
      'Model weights are loaded from the asset bundle with no checksum or signature check. Only reachable via APK tampering, which MOB-001 currently enables.',
    impact:
      'A repackaged APK could ship altered weights that classify the attacker’s phishing domains as safe.',
    remediation: 'Embed an expected SHA-256 per model and fall back to the rules engine on mismatch.',
    verification: 'Modify a weights file in the APK → app falls back and logs an integrity error.',
    effort: '1 hr',
  },
  {
    id: 'MOB-014',
    severity: 'Informational',
    title: 'Debug logging present in production code paths',
    category: 'Data Storage',
    masvs: 'MASVS-STORAGE-3',
    cwe: 'CWE-532',
    owasp: 'M9 — Insecure Data Storage',
    file: 'lib/ (10 call sites)',
    description:
      'print/debugPrint calls reach logcat in release builds. Android 11+ prevents cross-app log reads, so exposure needs physical/ADB access.',
    impact:
      'Low today; the risk is a future edit adding a URL or SMS body to one of these statements.',
    remediation:
      'Route through a kDebugMode-guarded wrapper and enable the avoid_print lint so it cannot regress.',
    verification: 'flutter analyze reports no avoid_print violations.',
    effort: '1 hr',
  },
  {
    id: 'MOB-015',
    severity: 'Informational',
    title: 'No automated dependency vulnerability scanning',
    category: 'Supply Chain',
    masvs: 'MASVS-CODE-3',
    cwe: 'CWE-1104',
    owasp: 'M2 — Inadequate Supply Chain Security',
    file: 'Repository-wide',
    description:
      'No CI workflows existed at assessment time; 40+ direct dependencies, several touching camera, OCR and secure storage.',
    impact: 'A vulnerable transitive dependency could ship unnoticed.',
    remediation:
      'Adopt .github/workflows/security-review.yml (supplied): flutter pub outdated, Gitleaks, Trivy and Semgrep on every push.',
    verification: 'Workflow runs green and uploads a report artifact.',
    effort: 'Supplied',
  },
];

const SEVERITY_FILL = {
  Critical: 'FF7F1D1D',
  High: 'FFFFD9DE',
  Medium: 'FFFFF3CD',
  Low: 'FFE0EBFF',
  Informational: 'FFEFEFEF',
};
const SEVERITY_FONT = {
  Critical: 'FFFFFFFF',
  High: 'FFDC2626',
  Medium: 'FFD97706',
  Low: 'FF1A73E8',
  Informational: 'FF64748B',
};

function styleHeader(row) {
  row.eachCell((cell) => {
    cell.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1A73E8' } };
    cell.alignment = { vertical: 'middle', wrapText: true };
  });
  row.height = 24;
}

function autoFit(sheet, max = 70) {
  sheet.columns.forEach((c) => {
    let w = c.header ? String(c.header).length : 10;
    c.eachCell({ includeEmpty: false }, (cell) => {
      const len = cell.value ? String(cell.value).length : 0;
      if (len > w) w = len;
    });
    c.width = Math.min(Math.max(w + 2, 10), max);
  });
}

async function main() {
  const wb = new ExcelJS.Workbook();
  wb.creator = 'CyberGuard AI — Mobile Security Assessment';
  wb.created = new Date();

  // Sheet 1 — Security findings
  const findings = wb.addWorksheet('Security Findings', {
    views: [{ state: 'frozen', ySplit: 1 }],
  });
  findings.columns = [
    { header: 'Finding ID', key: 'id', width: 12 },
    { header: 'Severity', key: 'severity', width: 14 },
    { header: 'Title', key: 'title', width: 55 },
    { header: 'Category', key: 'category', width: 22 },
    { header: 'MASVS', key: 'masvs', width: 22 },
    { header: 'CWE', key: 'cwe', width: 12 },
    { header: 'OWASP Mobile Top 10', key: 'owasp', width: 34 },
    { header: 'File / Location', key: 'file', width: 46 },
    { header: 'Description', key: 'description', width: 70 },
    { header: 'Impact', key: 'impact', width: 60 },
    { header: 'Remediation', key: 'remediation', width: 70 },
    { header: 'Verification', key: 'verification', width: 55 },
    { header: 'Effort', key: 'effort', width: 16 },
  ];
  styleHeader(findings.getRow(1));
  FINDINGS.forEach((f) => {
    const row = findings.addRow(f);
    row.alignment = { vertical: 'top', wrapText: true };
    const cell = row.getCell('severity');
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: SEVERITY_FILL[f.severity] } };
    cell.font = { bold: true, color: { argb: SEVERITY_FONT[f.severity] } };
  });
  findings.autoFilter = { from: 'A1', to: { row: 1, column: findings.columns.length } };

  // Sheet 2 — Risk summary
  const risk = wb.addWorksheet('Risk Summary');
  risk.columns = [
    { header: 'Metric', key: 'metric', width: 38 },
    { header: 'Value', key: 'value', width: 30 },
  ];
  styleHeader(risk.getRow(1));
  const counts = FINDINGS.reduce((acc, f) => {
    acc[f.severity] = (acc[f.severity] || 0) + 1;
    return acc;
  }, {});
  [
    ['Application', 'CyberGuard AI (com.cyberguard.ai)'],
    ['Version', '2.0.0+1'],
    ['Assessment date', '2026-07-27'],
    ['Standard', 'OWASP MASVS v2 / Mobile Top 10 2024'],
    ['', ''],
    ['Critical findings', counts.Critical || 0],
    ['High findings', counts.High || 0],
    ['Medium findings', counts.Medium || 0],
    ['Low findings', counts.Low || 0],
    ['Informational', counts.Informational || 0],
    ['Total findings', FINDINGS.length],
    ['', ''],
    ['Overall security score', '68 / 100'],
    ['Risk rating', 'MEDIUM'],
    ['', ''],
    ['Backend assessed', 'None — application is fully on-device'],
    ['Load test against live endpoints', 'Not performed — third-party services'],
  ].forEach(([metric, value]) => {
    const row = risk.addRow({ metric, value });
    if (metric && value === '') row.font = { bold: true };
  });

  // Sheet 3 — MASVS coverage
  const coverage = wb.addWorksheet('MASVS Coverage', { views: [{ state: 'frozen', ySplit: 1 }] });
  coverage.columns = [
    { header: 'MASVS Control', key: 'control', width: 24 },
    { header: 'Area', key: 'area', width: 26 },
    { header: 'Status', key: 'status', width: 18 },
    { header: 'Findings', key: 'findings', width: 26 },
    { header: 'Note', key: 'note', width: 70 },
  ];
  styleHeader(coverage.getRow(1));
  [
    ['MASVS-STORAGE-1', 'Sensitive data storage', 'FAIL', 'MOB-002, MOB-003, MOB-004', 'Credentials and user data stored unencrypted'],
    ['MASVS-STORAGE-2', 'Data in backups', 'FAIL', 'MOB-005', 'allowBackup defaults to true with no extraction rules'],
    ['MASVS-STORAGE-3', 'Data in logs', 'PARTIAL', 'MOB-014', 'print calls present but no sensitive data currently logged'],
    ['MASVS-CRYPTO-1', 'Cryptographic primitives', 'PASS', '—', 'SHA-1 used only for HIBP k-anonymity, which the API mandates'],
    ['MASVS-NETWORK-1', 'Encrypted traffic', 'PASS', '—', 'Cleartext disabled at manifest and network-security-config level'],
    ['MASVS-NETWORK-2', 'Certificate validation', 'PARTIAL', 'MOB-007', 'System-CA-only trust, no user CAs; pinning absent'],
    ['MASVS-PLATFORM-1', 'IPC / component export', 'PARTIAL', 'MOB-009', 'Exports are intentional and reasoned; input validated'],
    ['MASVS-PLATFORM-2', 'WebView security', 'N/A', '—', 'The application uses no WebView'],
    ['MASVS-CODE-1', 'App signing', 'FAIL', 'MOB-001', 'Release signed with the debug keystore'],
    ['MASVS-CODE-2', 'Dependency and version hygiene', 'PARTIAL', 'MOB-011, MOB-015', 'Version mismatch; no dependency scanning at assessment time'],
    ['MASVS-CODE-3', 'Third-party components', 'PARTIAL', 'MOB-015', '40+ direct dependencies, unscanned'],
    ['MASVS-RESILIENCE-1', 'Device integrity', 'FAIL', 'MOB-012', 'No root or tamper detection'],
    ['MASVS-RESILIENCE-3', 'Obfuscation', 'FAIL', 'MOB-006', 'R8 and Dart obfuscation both disabled'],
    ['MASVS-RESILIENCE-4', 'Runtime integrity', 'PARTIAL', 'MOB-013', 'ML model assets unverified'],
    ['MASVS-PRIVACY-1', 'Data minimisation', 'PARTIAL', 'MOB-008, MOB-010', 'Broad permissions, each functionally justified'],
    ['MASVS-PRIVACY-2', 'User consent', 'PASS', '—', 'Cloud intel default-off behind an explicit consent dialog'],
  ].forEach(([control, area, status, f, note]) => {
    const row = coverage.addRow({ control, area, status, findings: f, note });
    row.alignment = { vertical: 'top', wrapText: true };
    const cell = row.getCell('status');
    const fill = { PASS: 'FFD4F5E2', FAIL: 'FFFFD9DE', PARTIAL: 'FFFFF3CD', 'N/A': 'FFEFEFEF' }[status];
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: fill } };
    cell.font = { bold: true };
  });

  // Sheet 4 — Not applicable
  const na = wb.addWorksheet('Not Applicable', { views: [{ state: 'frozen', ySplit: 1 }] });
  na.columns = [
    { header: 'Requested Test Category', key: 'item', width: 44 },
    { header: 'Cases In Brief', key: 'count', width: 16 },
    { header: 'Reason Not Applicable', key: 'reason', width: 96 },
  ];
  styleHeader(na.getRow(1));
  [
    ['Endpoint inventory', '—', 'No server component; no routes or controllers exist in this codebase.'],
    ['SQL / NoSQL injection', '60', 'No SQL or NoSQL database. Hive is a local key-value store with a typed Dart API and no query language.'],
    ['Authentication testing', '30', 'The application has no login, no accounts and no credentials of its own.'],
    ['Authorization / RBAC / IDOR', '40', 'No server-side objects, no roles, no multi-tenancy; exactly one local user.'],
    ['JWT security', '20', 'No tokens are issued, parsed or validated anywhere in the codebase.'],
    ['Session management', '20', 'No sessions exist.'],
    ['Server-side rate limiting', '15', 'No server to rate-limit.'],
    ['SSRF / XXE / template injection', '—', 'No server-side request construction, no XML parsing, no template engine.'],
    ['Mass assignment', '—', 'No request-body deserialisation into persisted server models.'],
    ['CORS / security headers', '—', 'The application serves no HTTP responses.'],
    ['100-VU load test vs production', '—', 'Only remote endpoints belong to Google and HIBP. Load-testing third-party production infrastructure is abuse and violates their terms. Covered against a local mock instead.'],
  ].forEach(([item, count, reason]) => {
    na.addRow({ item, count, reason }).alignment = { vertical: 'top', wrapText: true };
  });

  for (const sheet of wb.worksheets) autoFit(sheet);

  const out = path.join(__dirname, 'findings.xlsx');
  await wb.xlsx.writeFile(out);
  console.log(`Wrote ${FINDINGS.length} findings -> ${out}`);
  console.log(
    `  Critical ${counts.Critical || 0} · High ${counts.High || 0} · Medium ${counts.Medium || 0} · Low ${counts.Low || 0} · Info ${counts.Informational || 0}`
  );
}

if (require.main === module) {
  main().catch((err) => {
    console.error('Failed:', err.message);
    process.exit(1);
  });
}

module.exports = { FINDINGS };
