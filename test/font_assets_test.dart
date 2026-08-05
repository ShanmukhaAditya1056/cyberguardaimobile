import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression guard for the font assets declared in pubspec.yaml.
///
/// The Inter files were once WOFF2 web fonts that had simply been renamed to
/// `.ttf`. Flutter's font loader only understands the sfnt container (TTF/OTF),
/// so the whole `Inter` family failed to register and every `fontFamily:
/// 'Inter'` style silently fell back to the platform default. Nothing failed
/// loudly — not `flutter analyze`, not the build, not the test suite — so the
/// only way to catch a repeat is to assert on the file headers directly.

/// First four bytes of every container Flutter accepts.
const _sfntMagics = <String, String>{
  '00010000': 'TrueType',
  '74727565': 'TrueType ("true")',
  '4f54544f': 'OpenType/CFF ("OTTO")',
  '74746366': 'TrueType collection ("ttcf")',
};

/// Web-only wrappers. These are the ones that get mistakenly renamed to .ttf.
const _webFontMagics = <String, String>{
  '774f4632': 'WOFF2 ("wOF2")',
  '774f4646': 'WOFF ("wOFF")',
};

String _magicOf(File f) {
  final bytes = f.openSync().readSync(4);
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Pulls the `asset:` paths out of the `fonts:` block of pubspec.yaml.
List<String> _declaredFontAssets(String pubspec) {
  final fontsBlock = RegExp(r'^\s{2}fonts:\s*$', multiLine: true)
      .firstMatch(pubspec);
  if (fontsBlock == null) return const [];

  // Read to the next top-level-ish key (two-space indent) after `  fonts:`.
  final rest = pubspec.substring(fontsBlock.end);
  final end = RegExp(r'^\s{2}\w', multiLine: true).firstMatch(rest);
  final block = end == null ? rest : rest.substring(0, end.start);

  return RegExp(r'-\s*asset:\s*(\S+)')
      .allMatches(block)
      .map((m) => m.group(1)!)
      .toList();
}

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final assets = _declaredFontAssets(pubspec);

  group('declared font assets are loadable by Flutter', () {
    test('pubspec.yaml actually declares font assets', () {
      expect(assets, isNotEmpty,
          reason: 'no `- asset:` entries found under the fonts: block');
    });

    for (final asset in assets) {
      test('$asset is a real sfnt font', () {
        final file = File(asset);
        expect(file.existsSync(), isTrue, reason: '$asset is missing on disk');

        final magic = _magicOf(file);

        expect(
          _webFontMagics.containsKey(magic),
          isFalse,
          reason: '$asset is a ${_webFontMagics[magic]} file. Flutter cannot '
              'load web font containers — every style using this family will '
              'silently fall back to the platform font. Decompress it to a '
              'real TTF/OTF before committing.',
        );

        expect(
          _sfntMagics.containsKey(magic),
          isTrue,
          reason: '$asset has unrecognised magic bytes 0x$magic; expected one '
              'of ${_sfntMagics.keys.join(", ")}',
        );
      });
    }
  });
}
