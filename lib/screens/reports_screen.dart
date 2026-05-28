import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/main_overflow_menu.dart';

class ReportsScreen extends ConsumerWidget {
  final ValueChanged<int> onNavigate;
  final int currentIndex;

  const ReportsScreen({
    super.key,
    required this.onNavigate,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameras = ref.watch(camerasProvider).valueOrNull ?? [];
    final alerts = ref.watch(alertsProvider).valueOrNull ?? [];
    final isDemo = ref.watch(serverConfigProvider).isDemo;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Reports',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w600),
        ),
        actions: [
          MainOverflowMenu(onNavigate: onNavigate, currentIndex: currentIndex),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReportCard(
            icon: Icons.videocam_rounded,
            title: 'Camera Activity Report',
            subtitle:
                '${cameras.length} cameras · ${cameras.where((c) => c.isOnline).length} online',
            reportKey: 'camera-activity',
            isDemo: isDemo,
            ref: ref,
          ),
          _ReportCard(
            icon: Icons.notifications_active_rounded,
            title: 'Alert Summary',
            subtitle: '${alerts.length} alerts in current feed',
            reportKey: 'alert-summary',
            isDemo: isDemo,
            ref: ref,
          ),
          _ReportCard(
            icon: Icons.psychology_rounded,
            title: 'AI Detection Report',
            subtitle: 'Fire, smoke, spill, fall, suspicious detections',
            reportKey: 'detection-report',
            isDemo: isDemo,
            ref: ref,
          ),
          _ReportCard(
            icon: Icons.health_and_safety_rounded,
            title: 'System Performance',
            subtitle: 'Uptime, stream health, and device status',
            reportKey: 'system-performance',
            isDemo: isDemo,
            ref: ref,
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String reportKey;
  final bool isDemo;
  final WidgetRef ref;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.reportKey,
    required this.isDemo,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: isDemo
            ? () => _showDemoNotice(context)
            : () => _openReport(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                          color: colors.onSurfaceDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceDim),
            ],
          ),
        ),
      ),
    );
  }

  void _showDemoNotice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Reports are not available in demo mode')),
    );
  }

  Future<void> _openReport(BuildContext context) async {
    final colors = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ReportSheet(
        title: title,
        reportKey: reportKey,
        ref: ref,
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  final String title;
  final String reportKey;
  final WidgetRef ref;

  const _ReportSheet({
    required this.title,
    required this.reportKey,
    required this.ref,
  });

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          await widget.ref.read(apiServiceProvider).getReport(widget.reportKey);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load report';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colors.onSurfaceDim,
                      ))
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red)))
                      : _data == null
                          ? Center(
                              child: Text('No data',
                                  style: TextStyle(
                                      color: colors.onSurfaceDim)))
                          : _buildContent(scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    final data = _data!;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: _buildRows(data),
    );
  }

  List<Widget> _buildRows(Map<String, dynamic> data) {
    switch (widget.reportKey) {
      case 'camera-activity':
        return _cameraActivityRows(data);
      case 'alert-summary':
        return _alertSummaryRows(data);
      case 'detection-report':
        return _detectionRows(data);
      case 'system-performance':
        return _systemRows(data);
      default:
        return _genericRows(data);
    }
  }

  List<Widget> _cameraActivityRows(Map<String, dynamic> data) {
    final summary = data['summary'];
    final cameras = data['cameras'];

    return [
      if (summary is Map<String, dynamic>) ...[
        _SummaryRow('Total Cameras', '${summary['total_cameras'] ?? 0}'),
        _SummaryRow('Online', '${summary['online'] ?? 0}',
            color: Colors.greenAccent),
        _SummaryRow('Offline', '${summary['offline'] ?? 0}',
            color: Colors.redAccent),
        const _SheetDivider(),
      ],
      const _SheetSectionTitle('Camera Details — Last 30 Days'),
      if (cameras is List)
        ...cameras.whereType<Map<String, dynamic>>().map(
              (cam) => _DataRow(
                leading: Icon(
                  cam['connected'] == true
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded,
                  color: cam['connected'] == true
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  size: 18,
                ),
                title: cam['name']?.toString() ?? '',
                subtitle: cam['zone']?.toString() ?? '',
                trailing: '${cam['events_30d'] ?? 0} events',
              ),
            ),
    ];
  }

  List<Widget> _alertSummaryRows(Map<String, dynamic> data) {
    final byCategory = data['by_category'];

    return [
      _SummaryRow('Total Alerts', '${data['total_alerts'] ?? 0}'),
      const _SheetDivider(),
      const _SheetSectionTitle('By Detection Type'),
      if (byCategory is Map<String, dynamic>)
        ...byCategory.entries.map(
          (e) => _DataRow(
            leading:
                const Icon(Icons.circle, size: 8, color: Colors.white38),
            title: e.key.replaceAll('_', ' ').toUpperCase(),
            trailing: '${e.value}',
          ),
        ),
    ];
  }

  List<Widget> _detectionRows(Map<String, dynamic> data) {
    final byCategory = data['by_category'];
    final byCamera = data['by_camera'];

    return [
      _SummaryRow('Total Detections', '${data['total_detections'] ?? 0}'),
      const _SheetDivider(),
      const _SheetSectionTitle('By Detection Type'),
      if (byCategory is Map<String, dynamic>)
        ...byCategory.entries.map(
          (e) => _DataRow(
            leading:
                const Icon(Icons.circle, size: 8, color: Colors.white38),
            title: e.key.replaceAll('_', ' ').toUpperCase(),
            trailing: '${e.value}',
          ),
        ),
      if (byCamera is List && (byCamera).isNotEmpty) ...[
        const _SheetDivider(),
        const _SheetSectionTitle('By Camera'),
        ...byCamera.whereType<Map<String, dynamic>>().map(
              (c) => _DataRow(
                leading: const Icon(Icons.videocam_rounded,
                    size: 18, color: Colors.white38),
                title: c['camera_name']?.toString() ?? '',
                trailing: '${c['event_count'] ?? 0} events',
              ),
            ),
      ],
    ];
  }

  List<Widget> _systemRows(Map<String, dynamic> data) {
    final uptimeSecs = (data['uptime_seconds'] as num?)?.toInt() ?? 0;
    final uptimeH = uptimeSecs ~/ 3600;
    final uptimeM = (uptimeSecs % 3600) ~/ 60;

    return [
      _SummaryRow('Uptime',
          '${data['uptime_percent'] ?? 0}%  ($uptimeH h $uptimeM m)'),
      _SummaryRow('Cameras Total', '${data['cameras_total'] ?? 0}'),
      _SummaryRow('Cameras Online', '${data['cameras_online'] ?? 0}',
          color: Colors.greenAccent),
      _SummaryRow(
          'Events Processed', '${data['total_events_processed'] ?? 0}'),
    ];
  }

  List<Widget> _genericRows(Map<String, dynamic> data) {
    return data.entries
        .map((e) => _SummaryRow(
            e.key.replaceAll('_', ' ').toUpperCase(), '${e.value}'))
        .toList();
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: colors.onSurfaceDim, fontSize: 13)),
          Text(value,
              style: TextStyle(
                color: color ?? colors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final String? trailing;

  const _DataRow({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: colors.onSurface, fontSize: 13)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(
                          color: colors.onSurfaceDim, fontSize: 11)),
              ],
            ),
          ),
          if (trailing != null)
            Text(trailing!,
                style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 12)),
        ],
      ),
    );
  }
}

class _SheetDivider extends StatelessWidget {
  const _SheetDivider();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: colors.border),
    );
  }
}

class _SheetSectionTitle extends StatelessWidget {
  final String title;
  const _SheetSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
