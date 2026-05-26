import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alert.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
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
    final cameras = ref.watch(camerasProvider).valueOrNull ?? [];
    final alerts = ref.watch(alertsProvider).valueOrNull ?? [];
    final analytics = ref.watch(analyticsProvider).valueOrNull;
    final online = cameras.where((camera) => camera.isOnline).length;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          MainOverflowMenu(
            onNavigate: onNavigate,
            currentIndex: currentIndex,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              _MetricCard(
                icon: Icons.people_alt_rounded,
                color: Colors.lightBlueAccent,
                value:
                    '${analytics?.aiDetectionsTotal ?? alerts.length * 8 + online * 12}',
                label: 'AI Detections',
              ),
              _MetricCard(
                icon: Icons.directions_car_rounded,
                color: Colors.greenAccent,
                value: '$online/${cameras.length}',
                label: 'Online Cameras',
              ),
              _MetricCard(
                icon: Icons.notifications_active_rounded,
                color: Colors.orangeAccent,
                value: '${analytics?.eventsTriggered ?? alerts.length}',
                label: 'Events Triggered',
              ),
              _MetricCard(
                icon: Icons.schedule_rounded,
                color: accentColor,
                value:
                    '${(analytics?.avgDwellTimeHours ?? 12.5).toStringAsFixed(1)}h',
                label: 'Avg. Dwell Time',
              ),
            ],
          ),
          const SizedBox(height: 18),
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
          const SizedBox(height: 18),
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
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(sample.typeIcon, color: sample.typeColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sample.typeLabel,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
      AlertType.fire => 'fire_detected',
      AlertType.smoke => 'smoke_detected',
      AlertType.liquidSpill => 'liquid_spill',
      AlertType.suspicious => 'suspicious_activity',
      AlertType.fall => 'person_fall',
      AlertType.cameraOffline => 'camera_offline',
      AlertType.cameraOnline => 'camera_online',
      AlertType.storageWarning => 'storage_warning',
      AlertType.storageCritical => 'storage_critical',
    };
    return analytics?.topCategories[key] ??
        alerts.where((alert) => alert.type == type).length;
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
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
                  widthFactor: 0.72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
