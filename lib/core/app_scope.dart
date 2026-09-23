import 'package:flutter/widgets.dart';

import '../services/stats_service.dart';

/// Exposes [StatsService] to the widget tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<StatsService> {
  const AppScope({super.key, required StatsService stats, required super.child})
    : super(notifier: stats);

  static StatsService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads without subscribing to changes (for callbacks).
  static StatsService read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
