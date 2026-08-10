import 'package:flutter_test/flutter_test.dart';

import 'package:cyberguard_ai/data/services/device/desktop/wifi_parsing.dart';

/// The desktop Wi-Fi probes read `netsh`, `nmcli` and `iw` output by the shape
/// of the values rather than by label text, because `netsh` translates every
/// one of its labels on a localised Windows. These tests pin that behaviour:
/// the app ships in four languages, and a Wi-Fi module that silently reports
/// "Unknown" on a Hindi install would be worse than useless.
void main() {
  group('parseColonBlock', () {
    test('keeps repeated keys instead of collapsing them', () {
      // netsh prints one block per adapter. Collapsing into a map would keep
      // only the last adapter's values, silently mixing two networks.
      const output = '''
    Name                   : Wi-Fi
    SSID                   : HomeNetwork
    Name                   : Wi-Fi 2
    SSID                   : GuestNetwork
''';
      final fields = WifiParsing.parseColonBlock(output);
      final ssids =
          fields.where((f) => f.$1 == 'SSID').map((f) => f.$2).toList();
      expect(ssids, ['HomeNetwork', 'GuestNetwork']);
    });

    test('ignores lines with no value and handles CRLF', () {
      const output = 'There is 1 interface on the system:\r\n'
          '\r\n'
          '    SSID                   : CafeWiFi\r\n'
          '    State                  : \r\n';
      final fields = WifiParsing.parseColonBlock(output);
      expect(fields, [('SSID', 'CafeWiFi')]);
    });
  });

  group('pickBssid', () {
    test('finds a MAC regardless of its label', () {
      // German netsh labels this "BSSID" but French uses "BSSID" too; the
      // point is that the value is recognised without consulting the label.
      final fields = WifiParsing.parseColonBlock('''
    Nom                    : Wi-Fi
    Adresse physique       : A4:2B:8C:00:1F:3E
''');
      expect(WifiParsing.pickBssid(fields), 'a4:2b:8c:00:1f:3e');
    });

    test('accepts hyphen-separated MACs', () {
      final fields = WifiParsing.parseColonBlock('    X : A4-2B-8C-00-1F-3E');
      expect(WifiParsing.pickBssid(fields), 'a4-2b-8c-00-1f-3e');
    });

    test('returns null when no MAC is present', () {
      final fields = WifiParsing.parseColonBlock('    SSID : Home');
      expect(WifiParsing.pickBssid(fields), isNull);
    });
  });

  group('pickSsid', () {
    test('does not mistake the BSSID line for the SSID', () {
      final fields = WifiParsing.parseColonBlock('''
    BSSID                  : a4:2b:8c:00:1f:3e
    SSID                   : HomeNetwork
''');
      expect(WifiParsing.pickSsid(fields), 'HomeNetwork');
    });

    test('skips an SSID-keyed line whose value is a MAC', () {
      // netsh prints BSSID before SSID; a naive "contains SSID" match picks up
      // the BSSID line first and returns a MAC address as the network name.
      final fields = WifiParsing.parseColonBlock('''
    BSSID                  : a4:2b:8c:00:1f:3e
    SSID                   : 00:11:22:33:44:55
''');
      expect(WifiParsing.pickSsid(fields), isNull);
    });

    test('accepts an SSID that looks like other fields', () {
      final fields =
          WifiParsing.parseColonBlock('    SSID : 100% Free WiFi');
      expect(WifiParsing.pickSsid(fields), '100% Free WiFi');
    });
  });

  group('pickPercentage', () {
    test('reads a signal quality with or without a space', () {
      expect(
        WifiParsing.pickPercentage(
            WifiParsing.parseColonBlock('    Signal : 72%')),
        72,
      );
      expect(
        WifiParsing.pickPercentage(
            WifiParsing.parseColonBlock('    Señal : 88 %')),
        88,
      );
    });

    test('rejects an out-of-range value', () {
      expect(
        WifiParsing.pickPercentage(
            WifiParsing.parseColonBlock('    Bogus : 480%')),
        isNull,
      );
    });
  });

  group('pickSecurity', () {
    test('recognises the common ciphers from the value side', () {
      (String, bool) check(String value) {
        final s =
            WifiParsing.pickSecurity(WifiParsing.parseColonBlock('  X : $value'));
        return (s.label, s.isSecured);
      }

      expect(check('WPA3-Personal').$2, isTrue);
      expect(check('WPA2-Personal').$2, isTrue);
      expect(check('Open').$2, isFalse);
    });

    test('treats WEP as unencrypted', () {
      // WEP has been trivially breakable since 2001. Reporting it as
      // "encrypted" would give the user a false sense of safety on exactly the
      // networks most worth warning about.
      final security =
          WifiParsing.pickSecurity(WifiParsing.parseColonBlock('  X : WEP'));
      expect(security.isSecured, isFalse);
      expect(security.label, contains('broken'));
    });

    test('defaults to secured when nothing is recognised', () {
      // Failing the other way would show "OPEN network — no encryption!" to
      // someone on WPA3 whose OS phrased the mode unexpectedly.
      final security = WifiParsing.pickSecurity(
          WifiParsing.parseColonBlock('  Estado : conectado'));
      expect(security.isSecured, isTrue);
      expect(security.label, 'Unknown');
    });
  });

  group('percentToRssi', () {
    test('maps the documented WLAN quality range onto dBm', () {
      expect(WifiParsing.percentToRssi(100), -50);
      expect(WifiParsing.percentToRssi(0), -100);
      expect(WifiParsing.percentToRssi(50), -75);
    });

    test('reports the worst case when quality is unknown', () {
      expect(WifiParsing.percentToRssi(null), -100);
    });
  });

  group('channelToFrequency', () {
    test('maps 2.4 GHz channels', () {
      expect(WifiParsing.channelToFrequency(1), 2412);
      expect(WifiParsing.channelToFrequency(6), 2437);
      expect(WifiParsing.channelToFrequency(11), 2462);
    });

    test('channel 14 is the off-grid Japan-only frequency', () {
      expect(WifiParsing.channelToFrequency(14), 2484);
    });

    test('maps 5 GHz channels', () {
      expect(WifiParsing.channelToFrequency(36), 5180);
      expect(WifiParsing.channelToFrequency(149), 5745);
    });

    test('returns 0 for an unknown channel', () {
      expect(WifiParsing.channelToFrequency(null), 0);
      expect(WifiParsing.channelToFrequency(300), 0);
    });
  });

  group('parseFrequency', () {
    test('reads a band whether or not the unit is present', () {
      expect(WifiParsing.parseFrequency('2437'), 2437);
      expect(WifiParsing.parseFrequency('5745 MHz'), 5745);
    });

    test('rejects a value that is a channel or a bitrate, not a band', () {
      expect(WifiParsing.parseFrequency('11'), 0);
      expect(WifiParsing.parseFrequency('866 Mbit/s'), 0);
      expect(WifiParsing.parseFrequency(null), 0);
    });
  });
}
