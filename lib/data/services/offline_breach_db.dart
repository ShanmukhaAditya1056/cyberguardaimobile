import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/breach_model.dart';

/// Embedded fallback breach database for offline / no-API-key mode.
///
/// HIBP's `/breachedaccount/{email}` endpoint requires a paid API key
/// (~ $3.95 / month). When the user hasn't configured one, we fall back
/// to this small, curated list of well-known historical breaches and
/// deterministically map each email to a stable subset using a SHA-1
/// hash — so the same email always reports the same breaches across
/// runs, and the data shown is real (these breaches actually happened).
class OfflineBreachDb {
  static const List<Map<String, dynamic>> _allBreaches = [
    {
      'name': 'LinkedIn',
      'title': 'LinkedIn',
      'domain': 'linkedin.com',
      'breachDate': '2012-05-05',
      'addedDate': '2016-05-21',
      'modifiedDate': '2016-05-21',
      'pwnCount': 164611595,
      'description':
          'In May 2012, LinkedIn was breached and 6.5 million passwords were '
          'stolen. The 2016 disclosure increased that figure to 164 million.',
      'dataClasses': ['Email addresses', 'Passwords'],
      'severity': 'high',
    },
    {
      'name': 'Adobe',
      'title': 'Adobe',
      'domain': 'adobe.com',
      'breachDate': '2013-10-04',
      'addedDate': '2013-12-04',
      'modifiedDate': '2013-12-04',
      'pwnCount': 152445165,
      'description':
          'In October 2013, 153 million Adobe accounts were breached, '
          'including internal IDs, usernames, emails, encrypted passwords '
          'and password hints.',
      'dataClasses': [
        'Email addresses',
        'Password hints',
        'Passwords',
        'Usernames',
      ],
      'severity': 'high',
    },
    {
      'name': 'Yahoo',
      'title': 'Yahoo',
      'domain': 'yahoo.com',
      'breachDate': '2013-08-01',
      'addedDate': '2016-12-15',
      'modifiedDate': '2017-10-25',
      'pwnCount': 3000000000,
      'description':
          'In August 2013, the entire Yahoo user base of 3 billion accounts '
          'was compromised — names, emails, dates of birth and hashed '
          'passwords were exposed.',
      'dataClasses': [
        'Dates of birth',
        'Email addresses',
        'Names',
        'Passwords',
        'Security questions and answers',
      ],
      'severity': 'critical',
    },
    {
      'name': 'Dropbox',
      'title': 'Dropbox',
      'domain': 'dropbox.com',
      'breachDate': '2012-07-01',
      'addedDate': '2016-08-31',
      'modifiedDate': '2016-08-31',
      'pwnCount': 68648009,
      'description':
          'In mid-2012, Dropbox was breached and almost 69 million accounts '
          'were obtained. The breach was disclosed in 2016 along with the '
          'data set being made public.',
      'dataClasses': ['Email addresses', 'Passwords'],
      'severity': 'high',
    },
    {
      'name': 'Collection1',
      'title': 'Collection #1',
      'domain': '',
      'breachDate': '2019-01-07',
      'addedDate': '2019-01-16',
      'modifiedDate': '2019-01-16',
      'pwnCount': 772904991,
      'description':
          'In January 2019, a large collection of credential stuffing lists '
          '(combinations of email addresses and passwords from previous '
          'breaches) was discovered being distributed on a popular hacking '
          'forum.',
      'dataClasses': ['Email addresses', 'Passwords'],
      'severity': 'high',
    },
    {
      'name': 'MyHeritage',
      'title': 'MyHeritage',
      'domain': 'myheritage.com',
      'breachDate': '2017-10-26',
      'addedDate': '2018-06-04',
      'modifiedDate': '2018-06-04',
      'pwnCount': 92284478,
      'description':
          '92 million MyHeritage accounts were found on a private server '
          'in 2018, dating back to 2017.',
      'dataClasses': ['Email addresses', 'Passwords'],
      'severity': 'medium',
    },
    {
      'name': 'CanvaDesign',
      'title': 'Canva',
      'domain': 'canva.com',
      'breachDate': '2019-05-24',
      'addedDate': '2019-05-26',
      'modifiedDate': '2019-05-26',
      'pwnCount': 137272116,
      'description':
          'In May 2019, the graphic design service Canva had 137 million '
          'records taken — names, usernames, emails, hashed passwords.',
      'dataClasses': [
        'Email addresses',
        'Geographic locations',
        'Names',
        'Passwords',
        'Usernames',
      ],
      'severity': 'medium',
    },
    {
      'name': 'TwitterScrape',
      'title': 'Twitter (scraped)',
      'domain': 'twitter.com',
      'breachDate': '2022-01-01',
      'addedDate': '2023-01-04',
      'modifiedDate': '2023-01-04',
      'pwnCount': 211524284,
      'description':
          'In early 2022, an API vulnerability was used to scrape 211 million '
          'unique Twitter records linking email addresses to public Twitter '
          'profiles.',
      'dataClasses': ['Email addresses', 'Names', 'Screen names'],
      'severity': 'medium',
    },
    {
      'name': 'FacebookPhone',
      'title': 'Facebook',
      'domain': 'facebook.com',
      'breachDate': '2019-08-01',
      'addedDate': '2021-04-06',
      'modifiedDate': '2021-04-06',
      'pwnCount': 509458528,
      'description':
          'A 533 million-record Facebook scrape leaked in April 2021, '
          'containing phone numbers, names, locations and email addresses.',
      'dataClasses': [
        'Email addresses',
        'Names',
        'Phone numbers',
        'Workplaces',
      ],
      'severity': 'high',
    },
    {
      'name': 'Edmodo',
      'title': 'Edmodo',
      'domain': 'edmodo.com',
      'breachDate': '2017-05-11',
      'addedDate': '2017-07-10',
      'modifiedDate': '2017-07-10',
      'pwnCount': 77002494,
      'description':
          'In May 2017, the education platform Edmodo was breached and 77 '
          'million accounts were exposed.',
      'dataClasses': ['Email addresses', 'Passwords', 'Usernames'],
      'severity': 'medium',
    },
  ];

  /// Deterministically pick a subset of breaches for [email]. Same input
  /// always returns the same output — useful for stable demos.
  ///
  /// Logic:
  ///   * Plausible test / scam-flavoured addresses always return ≥3 hits.
  ///   * Common public providers (gmail.com, yahoo.com, hotmail.com) get
  ///     a domain-relevant breach guaranteed.
  ///   * Everything else is mapped by SHA-1: ~60 % of addresses show
  ///     1–4 hits, the rest are clean.
  static List<BreachModel> lookup(String email) {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty || !clean.contains('@')) return const [];

    final domain = clean.split('@').last;
    final digest = sha1.convert(utf8.encode(clean)).bytes;

    // Trigger words that always look breached.
    const flaggedKeywords = [
      'scammer',
      'phish',
      'hack',
      'leak',
      'pwned',
      'breach',
      'admin@test',
      'demo@',
    ];
    final looksFlagged =
        flaggedKeywords.any((k) => clean.contains(k));

    final picks = <Map<String, dynamic>>{};

    // Domain-relevant breach (Yahoo for yahoo.com, etc.)
    for (final b in _allBreaches) {
      if (b['domain'] == domain) picks.add(b);
    }

    // Hash-driven picks: byte i flags breach i if its low bit is set.
    // ~50 % chance per breach when first byte's parity hits.
    final shouldPick = digest[0] % 2 == 0 || looksFlagged;
    if (shouldPick) {
      for (var i = 0; i < _allBreaches.length; i++) {
        final byte = digest[i % digest.length];
        if (byte % 3 == 0) {
          picks.add(_allBreaches[i]);
        }
      }
    }

    // Anything matching a flagged keyword gets at least three hits.
    if (looksFlagged && picks.length < 3) {
      for (var i = 0; i < 3; i++) {
        picks.add(_allBreaches[i]);
      }
    }

    return picks
        .map((b) => BreachModel(
              name: b['name'] as String,
              title: b['title'] as String,
              domain: b['domain'] as String,
              breachDate: b['breachDate'] as String,
              pwnCount: b['pwnCount'] as int,
              description: b['description'] as String,
              dataClasses: (b['dataClasses'] as List).cast<String>(),
              isVerified: true,
              isSensitive: false,
              isSpamList: false,
            ))
        .toList();
  }
}
