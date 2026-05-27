import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';
import '../providers/providers.dart';
import '../widgets/alert_popup.dart';
import '../widgets/main_overflow_menu.dart';

enum AlertSectionFocus { aiDetections, systemAlerts }

class AlertsScreen extends ConsumerWidget {
  final ValueChanged<int> onNavigate;
  final int currentIndex;
  final AlertSectionFocus focus;

  const AlertsScreen({
    super.key,
    required this.onNavigate,
    required this.currentIndex,
    this.focus = AlertSectionFocus.aiDetections,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final connection = ref.watch(connectionStatusProvider).valueOrNull;
    final isOffline = connection == ConnectionStatus.reconnecting;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text(
          "Today's Alerts",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          MainOverflowMenu(
            onNavigate: onNavigate,
            currentIndex: currentIndex,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: accentColor,
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: () async {
          ref.invalidate(alertsProvider);
          await ref.read(alertsProvider.future);
        },
        child: alertsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: accentColor),
          ),
          error: (error, _) => ListView(
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.35),
              Center(
                child: Text(
                  '$error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          data: (alerts) {
            if (isOffline) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: Colors.grey,
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Alerts paused',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Server is offline. The app will reconnect automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            if (alerts.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.35),
                  const Center(
                    child: Text(
                      'No alerts today',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            final detectionAlerts = alerts.where((a) => a.isDetection).toList();
            final systemAlerts = alerts.where((a) => a.isSystem).toList();
            final detectionSection = _AlertSection(
              icon: Icons.psychology_rounded,
              title: 'AI Detections',
              count: detectionAlerts.length,
              color: accentColor,
              emptyMessage: 'No detections today',
              alerts: detectionAlerts,
            );
            const sectionGap = SizedBox(height: 20);
            final systemSection = _AlertSection(
              icon: Icons.settings_rounded,
              title: 'System Alerts',
              count: systemAlerts.length,
              color: Colors.amber,
              emptyMessage: 'No system alerts today',
              alerts: systemAlerts,
            );

            return ListView(
              padding: const EdgeInsets.all(12),
              children: focus == AlertSectionFocus.systemAlerts
                  ? [systemSection, sectionGap, detectionSection]
                  : [detectionSection, sectionGap, systemSection],
            );
          },
        ),
      ),
    );
  }
}

class _AlertSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final String emptyMessage;
  final List<Alert> alerts;

  const _AlertSection({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    required this.emptyMessage,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: icon,
          title: title,
          count: count,
          color: color,
        ),
        if (alerts.isEmpty)
          _EmptySection(message: emptyMessage)
        else
          ...alerts.map((alert) => _AlertTile(alert: alert)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;

  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final Alert alert;

  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (_) => AlertPopup(alert: alert),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: alert.typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(alert.typeIcon, color: alert.typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.typeLabelWithEmoji,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alert.cameraName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM d').format(alert.timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('hh:mm a').format(alert.timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                alert.isDetection
                    ? Icons.play_circle_outline_rounded
                    : Icons.info_outline_rounded,
                color: Colors.grey,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
