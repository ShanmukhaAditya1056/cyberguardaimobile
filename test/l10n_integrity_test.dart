import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the four .arb files against the failure modes that ship silently:
/// a key added to English but not the other locales (the string renders as
/// whatever the fallback is), a translation left as the English source, a
/// value written in the wrong script, or a `{placeholder}` dropped during
/// translation — which throws at runtime when the getter is called.
///
/// None of these are caught by `flutter gen-l10n`, `flutter analyze`, or a
/// build. They only show up in front of a user reading that language.

const _locales = ['hi', 'ta', 'te'];

/// Unicode block each locale's text must actually be written in.
const _scripts = <String, ({int lo, int hi, String name})>{
  'hi': (lo: 0x0900, hi: 0x097F, name: 'Devanagari'),
  'ta': (lo: 0x0B80, hi: 0x0BFF, name: 'Tamil'),
  'te': (lo: 0x0C00, hi: 0x0C7F, name: 'Telugu'),
};

/// Keys that legitimately carry no target-script characters.
///
/// The language picker shows every language in its own script, so in the Tamil
/// build `languageHindi` is correctly Devanagari; SSID/BSSID are protocol
/// acronyms; and appName is a product name.
const _sameEverywhere = <String>{
  'appName',
  'scoreSuffix',
  'languageEnglish',
  'languageHindi',
  'languageTamil',
  'languageTelugu',
  'wifiDetailSsid',
  'wifiDetailBssid',
};

Map<String, dynamic> _load(String loc) => jsonDecode(
      File('lib/l10n/app_$loc.arb').readAsStringSync(),
    ) as Map<String, dynamic>;

Iterable<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@'));

final _placeholder = RegExp(r'\{(\w+)\}');

void main() {
  final en = _load('en');
  final enKeys = _messageKeys(en).toSet();

  test('English has messages to check', () {
    expect(enKeys, isNotEmpty);
  });

  for (final loc in _locales) {
    group('app_$loc.arb', () {
      final arb = _load(loc);
      final keys = _messageKeys(arb).toSet();

      test('has exactly the same keys as English', () {
        expect(keys.difference(enKeys), isEmpty,
            reason: 'keys present in $loc but not en');
        expect(enKeys.difference(keys), isEmpty,
            reason: 'keys present in en but missing from $loc');
      });

      test('keeps every declared placeholder', () {
        // Source of truth is the @-metadata, not the English text: an ICU
        // plural like `{n, plural, =1{threat} other{threats}}` contains braces
        // that are literal text to be translated, not placeholder references.
        for (final key in enKeys.intersection(keys)) {
          final meta = en['@$key'];
          if (meta is! Map) continue;
          final declared = (meta['placeholders'] as Map?)?.keys.cast<String>();
          if (declared == null) continue;

          final translated = arb[key];
          if (translated is! String) continue;

          for (final name in declared) {
            // Either a plain {name} or the head of an ICU {name, plural, ...}.
            final used = translated.contains('{$name}') ||
                translated.contains('{$name,');
            expect(used, isTrue,
                reason: '$key is missing {$name} — the generated getter takes '
                    'that argument, and dropping it throws at runtime');
          }
        }
      });

      test('is actually written in ${_scripts[loc]!.name}', () {
        final script = _scripts[loc]!;
        final suspect = <String>[];

        for (final key in enKeys.intersection(keys)) {
          if (_sameEverywhere.contains(key)) continue;
          final source = en[key];
          final translated = arb[key];
          if (source is! String || translated is! String) continue;
          // Strip placeholder references first: a string like `{category}:
          // "{matched}"` is punctuation around substitutions with nothing of
          // its own to translate.
          final translatable = source.replaceAll(_placeholder, '');
          if (!translatable.contains(RegExp(r'[A-Za-z]{3}'))) continue;

          final hasScript = translated.runes
              .any((r) => r >= script.lo && r <= script.hi);
          if (!hasScript) suspect.add('$key = "$translated"');
        }

        expect(suspect, isEmpty,
            reason: 'no ${script.name} characters — left untranslated?');
      });
    });
  }
}
