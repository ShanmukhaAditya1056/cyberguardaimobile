import 'dart:typed_data';

class AppInfoModel {
  final String packageName;
  final String appName;
  final String versionName;
  final int targetSdk;
  final int minSdk;
  final int installTime;
  final int updateTime;
  final List<String> permissions;
  final int apkSize;
  final String installerPackage;

  /// Human-readable provenance, when the host can describe it better than
  /// [installerPackage] can.
  ///
  /// The desktop probes reuse Android's installer ids so that
  /// [isFromTrustedStore] — and through it the trust discount the risk engine
  /// applies — keeps working unchanged. Those ids are the right *signal* but
  /// the wrong *words*: without this field the App Scanner told a Windows user
  /// that 89 of their programs came from the Google Play Store. The scoring
  /// stays shared; only the label is per-platform.
  final String sourceLabel;

  Uint8List? iconBytes;

  AppInfoModel({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.targetSdk,
    required this.minSdk,
    required this.installTime,
    required this.updateTime,
    required this.permissions,
    required this.apkSize,
    this.installerPackage = '',
    this.sourceLabel = '',
    this.iconBytes,
  });

  factory AppInfoModel.fromMap(Map<String, dynamic> map) {
    return AppInfoModel(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? 'Unknown App',
      versionName: map['versionName'] as String? ?? '',
      targetSdk: map['targetSdk'] as int? ?? 0,
      minSdk: map['minSdk'] as int? ?? 0,
      installTime: map['installTime'] as int? ?? 0,
      updateTime: map['updateTime'] as int? ?? 0,
      permissions: (map['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      apkSize: (map['apkSize'] as num?)?.toInt() ?? 0,
      installerPackage: map['installerPackage'] as String? ?? '',
    );
  }

  /// True if the app was installed from a recognized trusted source
  /// (Google Play, Samsung Galaxy Store, Amazon, system).
  bool get isFromTrustedStore {
    const trusted = {
      'com.android.vending', // Google Play
      'com.google.android.feedback',
      'com.sec.android.app.samsungapps', // Samsung Galaxy Store
      'com.amazon.venezia', // Amazon Appstore
      'com.huawei.appmarket',
      'com.xiaomi.market',
      'com.android.packageinstaller', // pre-installed
      'com.google.android.packageinstaller',
    };
    return trusted.contains(installerPackage);
  }

  String get installSourceLabel {
    // A host that described its own provenance wins — see [sourceLabel].
    if (sourceLabel.isNotEmpty) return sourceLabel;

    switch (installerPackage) {
      case 'com.android.vending':
      case 'com.google.android.feedback':
        return 'Google Play Store';
      case 'com.sec.android.app.samsungapps':
        return 'Samsung Galaxy Store';
      case 'com.amazon.venezia':
        return 'Amazon Appstore';
      case 'com.huawei.appmarket':
        return 'Huawei AppGallery';
      case 'com.xiaomi.market':
        return 'Mi Store';
      case 'com.android.packageinstaller':
      case 'com.google.android.packageinstaller':
        return 'System / Pre-installed';
      case '':
        return 'Sideloaded (unknown source)';
      default:
        return 'Sideloaded ($installerPackage)';
    }
  }

  DateTime get installDate =>
      DateTime.fromMillisecondsSinceEpoch(installTime);

  DateTime get updateDate =>
      DateTime.fromMillisecondsSinceEpoch(updateTime);
}
