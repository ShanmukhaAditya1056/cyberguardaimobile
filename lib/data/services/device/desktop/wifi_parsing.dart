/// Whether a network's advertised security counts as encrypted, plus the
/// label to show the user.
class WifiSecurity {
  final bool isSecured;
  final String label;

  const WifiSecurity(this.isSecured, this.label);

  static const unknown = WifiSecurity(true, 'Unknown');
  static const open = WifiSecurity(false, 'Open (no encryption)');
}

/// Value-shape parsing for the `key: value` blocks that `netsh`, `nmcli` and
/// `airport` print.
///
/// The obvious approach — look up the line labelled "SSID" — breaks on every
/// non-English Windows, where `netsh` translates all of its labels. Since the
/// Wi-Fi module's whole job is to tell someone their network is unencrypted,
/// silently reporting "Unknown" on a Hindi or Tamil install would be the worst
/// possible failure. So values are identified by what they look like: a MAC
/// address is a BSSID whatever the label says, `72%` is a signal quality,
/// `WPA2-Personal` is a cipher name.
class WifiParsing {
  WifiParsing._();

  static final _macPattern =
      RegExp(r'^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$', caseSensitive: false);
  static final _percentPattern = RegExp(r'^(\d{1,3})\s*%$');

  /// Splits `key : value` lines into an ordered list of pairs.
  ///
  /// Kept as a list rather than a map because these outputs legitimately repeat
  /// keys — `netsh` prints one block per adapter, `airport` repeats fields per
  /// BSS — and collapsing them would silently keep whichever came last.
  static List<(String key, String value)> parseColonBlock(String output) {
    final pairs = <(String, String)>[];
    for (final line in output.split(RegExp(r'\r?\n'))) {
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final key = line.substring(0, idx).trim();
      final value = line.substring(idx + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;
      pairs.add((key, value));
    }
    return pairs;
  }

  /// The access point's MAC. Identified purely by value shape.
  static String? pickBssid(List<(String, String)> fields) {
    for (final (_, value) in fields) {
      if (_macPattern.hasMatch(value)) return value.toLowerCase();
    }
    return null;
  }

  /// The network name.
  ///
  /// This is the one field that needs the key, because an SSID is arbitrary
  /// text and could look like anything. "SSID" survives localisation as an
  /// untranslated acronym in every `netsh` language pack shipped so far, so we
  /// match on it — but only after excluding "BSSID", which contains it.
  static String? pickSsid(List<(String, String)> fields) {
    for (final (key, value) in fields) {
      final upper = key.toUpperCase();
      if (!upper.contains('SSID') || upper.contains('BSSID')) continue;
      if (_macPattern.hasMatch(value)) continue;
      return value;
    }
    return null;
  }

  /// Signal quality as a percentage, 0–100, or null when not reported.
  static int? pickPercentage(List<(String, String)> fields) {
    for (final (_, value) in fields) {
      final match = _percentPattern.firstMatch(value);
      if (match == null) continue;
      final parsed = int.tryParse(match.group(1)!);
      if (parsed != null && parsed <= 100) return parsed;
    }
    return null;
  }

  /// Radio channel number, or null.
  ///
  /// Requires the key to name the channel: a bare integer on its own could be
  /// almost any field in these outputs, so shape alone is not enough here.
  /// "Channel" does get translated, hence the small set of forms below plus a
  /// numeric sanity range that rejects a mistaken match.
  static int? pickChannel(List<(String, String)> fields) {
    const keyForms = ['channel', 'canal', 'kanal', 'chaîne', 'canale', 'चैनल'];
    for (final (key, value) in fields) {
      final lower = key.toLowerCase();
      if (!keyForms.any(lower.contains)) continue;
      final parsed = int.tryParse(value.trim());
      if (parsed != null && parsed > 0 && parsed <= 233) return parsed;
    }
    return null;
  }

  /// Cipher/authentication mode, read from the value side.
  ///
  /// Absence of any recognised token is reported as [WifiSecurity.unknown] with
  /// `isSecured: true`. Defaulting the other way would show "OPEN network — no
  /// encryption!" to someone sitting on WPA3 whose OS phrased it unexpectedly,
  /// and a security tool that cries wolf gets ignored when it matters.
  static WifiSecurity pickSecurity(List<(String, String)> fields) {
    for (final (_, value) in fields) {
      final v = value.trim();
      final upper = v.toUpperCase();

      if (upper.startsWith('WPA3') || upper.contains('SAE')) {
        return WifiSecurity(true, v);
      }
      if (upper.startsWith('WPA2')) return WifiSecurity(true, v);
      if (upper.startsWith('WPA')) return WifiSecurity(true, v);
      if (upper == 'WEP' || upper.startsWith('WEP-')) {
        // WEP is encrypted in name only — trivially broken since 2001. It is
        // reported as insecure so the trust score treats it like an open
        // network, which is what it effectively is.
        return const WifiSecurity(false, 'WEP (broken encryption)');
      }
      if (upper == 'OPEN' || upper == 'NONE' || upper == 'OPEN-NONE') {
        return WifiSecurity.open;
      }
    }
    return WifiSecurity.unknown;
  }

  /// Converts a 0–100 quality percentage to dBm.
  ///
  /// Windows reports quality, not RSSI, and the mapping the WLAN API documents
  /// is linear across -100 dBm (0 %) to -50 dBm (100 %). The rest of the app
  /// reasons in dBm, so the conversion happens here rather than leaking a
  /// second signal unit into `WifiRepository`.
  static int percentToRssi(int? percent) {
    if (percent == null) return -100;
    return (percent.clamp(0, 100) ~/ 2) - 100;
  }

  /// Channel number to centre frequency in MHz, matching what Android's
  /// `WifiInfo.getFrequency()` returns.
  static int channelToFrequency(int? channel) {
    if (channel == null) return 0;
    if (channel == 14) return 2484; // Japan-only 2.4 GHz channel, off the grid.
    if (channel >= 1 && channel <= 13) return 2407 + channel * 5;
    if (channel >= 32 && channel <= 177) return 5000 + channel * 5; // 5 GHz
    if (channel >= 1 && channel <= 233) return 5950 + channel * 5; // 6 GHz
    return 0;
  }

  /// Frequency in MHz straight from a tool that already reports it, tolerating
  /// both `2437` and `2437 MHz` and nmcli's `2437 MHz` with a non-breaking
  /// space.
  static int parseFrequency(String? raw) {
    if (raw == null) return 0;
    final match = RegExp(r'(\d{3,5})').firstMatch(raw);
    if (match == null) return 0;
    final mhz = int.tryParse(match.group(1)!) ?? 0;
    // Reject values that are clearly a channel or a rate rather than a band.
    if (mhz < 2000 || mhz > 7200) return 0;
    return mhz;
  }
}
