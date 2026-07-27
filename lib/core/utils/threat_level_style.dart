import 'package:flutter/material.dart';

import '../../data/services/threat_intel/threat_intel_source.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

/// UI mapping for the shared [ThreatLevel] taxonomy — keeps colour/gradient
/// choices consistent across the Fusion, Arbitration and Interceptor screens.
class ThreatLevelStyle {
  ThreatLevelStyle._();

  static Color color(ThreatLevel l) => switch (l) {
        ThreatLevel.critical => AppColors.critical,
        ThreatLevel.dangerous => AppColors.danger,
        ThreatLevel.suspicious => AppColors.warning,
        ThreatLevel.safe => AppColors.safe,
      };

  static LinearGradient gradient(ThreatLevel l) => switch (l) {
        ThreatLevel.critical => AppGradients.critical,
        ThreatLevel.dangerous => AppGradients.danger,
        ThreatLevel.suspicious => AppGradients.warning,
        ThreatLevel.safe => AppGradients.safe,
      };

  /// Category band label from the spec (0-30 Safe … 81-100 Critical).
  static String band(ThreatLevel l) => switch (l) {
        ThreatLevel.safe => 'Safe (0-30)',
        ThreatLevel.suspicious => 'Suspicious (31-60)',
        ThreatLevel.dangerous => 'Dangerous (61-80)',
        ThreatLevel.critical => 'Critical (81-100)',
      };

  static IconData icon(ThreatLevel l) => switch (l) {
        ThreatLevel.safe => Icons.verified_user_rounded,
        ThreatLevel.suspicious => Icons.help_outline_rounded,
        ThreatLevel.dangerous => Icons.warning_amber_rounded,
        ThreatLevel.critical => Icons.dangerous_rounded,
      };
}
