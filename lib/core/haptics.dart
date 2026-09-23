import 'package:flutter/services.dart';

import '../services/stats_service.dart';

class Haptics {
  Haptics._();

  static void tap(StatsService stats) {
    if (stats.hapticsEnabled) HapticFeedback.selectionClick();
  }

  static void success(StatsService stats) {
    if (stats.hapticsEnabled) HapticFeedback.lightImpact();
  }

  static void error(StatsService stats) {
    if (stats.hapticsEnabled) HapticFeedback.heavyImpact();
  }
}
