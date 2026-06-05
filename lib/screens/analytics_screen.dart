import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alert.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_ui.dart';
import '../widgets/main_overflow_menu.dart';

class AnalyticsScreen extends ConsumerWidget {
  final ValueChanged<int> onNavigate;
  final int currentIndex;

  const AnalyticsScreen({
    super.key,
    required this.onNavigate,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider).valueOrNull ?? [];
    final analytics = ref.watch(analyticsProvider).valueOrNull;
    final accentColor = Theme.of(context).colorScheme.primary;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          MainOverflowMenu(
            onNavigate: onNavigate,
            currentIndex: currentIndex,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Detection insights & trends',
                  style: TextStyle(
                    color: colors.onSurfaceDim,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _Panel(
            title: 'Detection Trends',
            child: SizedBox(
              height: 190,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ..._trendBars(analytics, accentColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            title: 'Top Detection Categories',
            child: Column(
              children: AlertType.values.map((type) {
                final count = _categoryCount(analytics, alerts, type);
                final sample = Alert(
                  id: '',
                  type: type,
                  cameraId: '',
                  cameraName: '',
                  timestamp: DateTime.now(),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: sample.typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(sample.typeIcon,
                            color: sample.typeColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sample.typeLabel,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _trendBars(AnalyticsSummary? analytics, Color color) {
    final trends = analytics?.detectionTrends ?? const [];
    if (trends.isEmpty) {
      return const [
        _TrendBar(label: 'Mon', value: 45, color: Colors.redAccent),
        _TrendBar(label: 'Tue', value: 72, color: Colors.redAccent),
        _TrendBar(label: 'Wed', value: 58, color: Colors.redAccent),
        _TrendBar(label: 'Thu', value: 91, color: Colors.redAccent),
        _TrendBar(label: 'Fri', value: 68, color: Colors.redAccent),
        _TrendBar(label: 'Sat', value: 52, color: Colors.redAccent),
        _TrendBar(label: 'Sun', value: 38, color: Colors.redAccent),
      ];
    }
    final maxCount = trends
        .map((trend) => trend.count)
        .fold<int>(1, (max, count) => count > max ? count : max);
    return trends.map((trend) {
      final value =
          maxCount == 0 ? 0 : ((trend.count / maxCount) * 100).round();
      return _TrendBar(
          label: trend.day, value: value.clamp(8, 100), color: color);
    }).toList();
  }

  int _categoryCount(
    AnalyticsSummary? analytics,
    List<Alert> alerts,
    AlertType type,
  ) {
    final key = switch (type) {
      AlertType.noHelmet => 'no_helmet',
      AlertType.noVest => 'no_vest',
      AlertType.noGloves => 'no_gloves',
      AlertType.noGoggles => 'no_goggles',
      AlertType.noFaceMask => 'no_face_mask',
      AlertType.noSafetyShoes => 'no_safety_shoes',
      AlertType.noHarness => 'no_harness',
      AlertType.noEarProtection => 'no_ear_protection',
      AlertType.helmet => 'helmet',
      AlertType.safetyVest => 'safety_vest',
      AlertType.gloves => 'gloves',
      AlertType.goggles => 'goggles',
      AlertType.faceMask => 'face_mask',
      AlertType.safetyShoes => 'safety_shoes',
      AlertType.harness => 'harness',
      AlertType.earProtection => 'ear_protection',
      AlertType.protectiveSuit => 'protective_suit',
      AlertType.apron => 'apron',
      AlertType.faceShield => 'face_shield',
      AlertType.cameraOffline => 'camera_offline',
      AlertType.cameraOnline => 'camera_online',
      AlertType.storageWarning => 'storage_warning',
      AlertType.storageCritical => 'storage_critical',
    };
    return analytics?.topCategories[key] ??
        alerts.where((alert) => alert.type == type).length;
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: appCard(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _TrendBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: value / 100,
                  widthFactor: 0.66,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color, color.withValues(alpha: 0.45)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(color: colors.onSurfaceDim, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
