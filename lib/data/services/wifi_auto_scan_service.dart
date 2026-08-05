import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../repositories/wifi_repository.dart';
import 'hive_service.dart';
import 'platform_channel_service.dart';

/// Backs the "Auto Wi-Fi Scan — Scan on network change" switch in Settings.
///
/// The switch was stored in Hive but nothing ever read it, so it did nothing
/// at all. This is the behaviour it advertises: watch for connectivity
/// transitions and scan the network the device just joined.
///
/// Deliberately event-driven rather than polled — it wakes only when Android
/// reports a change, so an idle device costs nothing. Three guards keep it
/// from doing surprise work:
///
///  * the setting must be on (it is re-read per event, so toggling it in
///    Settings takes effect immediately, with no restart and no listener
///    juggling);
///  * the new connection must actually be Wi-Fi;
///  * a permission that can read the SSID must already be granted — this
///    never prompts, because a system dialog appearing on a network change
///    would be indefensible.
class WifiAutoScanService {
  WifiAutoScanService._();

  static final WifiAutoScanService instance = WifiAutoScanService._();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _scanning = false;

  /// Set of results seen on the previous event, used to fire only on an
  /// actual transition onto Wi-Fi rather than on every redundant emission.
  bool _wasOnWifi = false;

  void start() {
    if (_sub != null) return;
    _sub = Connectivity().onConnectivityChanged.listen(
          _onChange,
          onError: (_) {},
        );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _onChange(List<ConnectivityResult> results) async {
    final onWifi = results.contains(ConnectivityResult.wifi);

    // Only act on the edge into Wi-Fi. Android re-emits the same state for
    // unrelated transitions (VPN up, metered change), and rescanning the
    // network the user is already on has no value.
    final joined = onWifi && !_wasOnWifi;
    _wasOnWifi = onWifi;
    if (!joined || _scanning) return;

    if (!_autoScanEnabled) return;
    if (!await _canReadSsid()) return;

    _scanning = true;
    try {
      await WifiRepository(PlatformChannelService()).analyzeCurrentNetwork();
    } catch (_) {
      // Wi-Fi dropped again mid-scan, location switched off, DNS probe
      // failed — a background convenience scan must never surface an error.
    } finally {
      _scanning = false;
    }
  }

  bool get _autoScanEnabled {
    try {
      return HiveService.getSettings().wifiAutoScan;
    } catch (_) {
      // Settings box not open yet — do nothing rather than scan unasked.
      return false;
    }
  }

  /// Either permission unlocks the SSID; mirrors PermissionService. Checked,
  /// never requested — see the class doc.
  Future<bool> _canReadSsid() async =>
      await Permission.location.isGranted ||
      await Permission.nearbyWifiDevices.isGranted;
}
