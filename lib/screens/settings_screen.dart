import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/api_service.dart';
import '../widgets/main_overflow_menu.dart';
import 'setup_screen.dart';

class SettingsScreen extends ConsumerWidget {
  final ValueChanged<int> onNavigate;
  final int currentIndex;

  const SettingsScreen({
    super.key,
    required this.onNavigate,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(serverConfigProvider);
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text(
          'Settings',
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
          const _SectionTitle('Appearance'),
          const _AccentColorPicker(),
          const SizedBox(height: 24),
          const _SectionTitle('Server'),
          _SettingsTile(
            icon: Icons.computer_rounded,
            title: config.isDemo ? 'Mode' : 'Mini PC IP',
            subtitle:
                config.serverIp.isEmpty ? 'Not configured' : config.serverIp,
          ),
          _SettingsTile(
            icon: Icons.api_rounded,
            title: 'API Port',
            subtitle: '${config.apiPort}',
          ),
          _SettingsTile(
            icon: Icons.videocam_rounded,
            title: 'Stream Port',
            subtitle: '${config.streamPort}',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: config.isDemo
                ? null
                : () => _showEditServerDialog(context, ref, config),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit Server IP'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF2A2A2A)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Storage'),
          const _StoragePanel(),
          const SizedBox(height: 24),
          const _SectionTitle('Notifications'),
          const _SettingsToggle(
            settingKey: 'fire',
            title: 'Fire Detection',
            icon: Icons.local_fire_department_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'smoke',
            title: 'Smoke Detection',
            icon: Icons.cloud_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'liquid_spill',
            title: 'Liquid Spill',
            icon: Icons.water_drop_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'suspicious_activity',
            title: 'Suspicious Activity',
            icon: Icons.visibility_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'fall_down',
            title: 'Fall Detection',
            icon: Icons.personal_injury_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'camera_offline',
            title: 'Camera Offline',
            icon: Icons.videocam_off_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'camera_online',
            title: 'Camera Recovery',
            icon: Icons.videocam_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'storage_warning',
            title: 'Storage Warning',
            icon: Icons.storage_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'storage_critical',
            title: 'Storage Critical',
            icon: Icons.sd_storage_rounded,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _disconnect(context, ref),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Disconnect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditServerDialog(
    BuildContext context,
    WidgetRef ref,
    ServerConfig config,
  ) async {
    final accentColor = Theme.of(context).colorScheme.primary;
    final ipController = TextEditingController(text: config.serverIp);
    final apiPortController = TextEditingController(text: '${config.apiPort}');
    final streamPortController =
        TextEditingController(text: '${config.streamPort}');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Server'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: ipController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Mini PC IP'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the Mini PC IP address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DialogPortField(
                        controller: apiPortController,
                        label: 'API port',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialogPortField(
                        controller: streamPortController,
                        label: 'Stream port',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                await ref.read(serverConfigProvider.notifier).save(
                      ip: ipController.text.trim(),
                      apiPort: int.parse(apiPortController.text.trim()),
                      streamPort: int.parse(streamPortController.text.trim()),
                    );
                ref.invalidate(camerasProvider);
                ref.invalidate(alertsProvider);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    ipController.dispose();
    apiPortController.dispose();
    streamPortController.dispose();
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    await ref.read(serverConfigProvider.notifier).clear();
    ref.read(lastAlertIdProvider.notifier).state = null;
    ref.invalidate(camerasProvider);
    ref.invalidate(alertsProvider);

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SetupScreen()),
      (_) => false,
    );
  }
}

class _DialogPortField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _DialogPortField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final port = int.tryParse(value ?? '');
        if (port == null || port < 1 || port > 65535) {
          return 'Invalid port';
        }
        return null;
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          letterSpacing: 1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentColorPicker extends ConsumerWidget {
  const _AccentColorPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = ref.watch(accentColorProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette_rounded, color: Colors.grey, size: 20),
              SizedBox(width: 12),
              Text(
                'Theme Color',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: appAccentColors.map((accent) {
              final color = Color(accent.value);
              final isSelected = selectedColor == accent.value;

              return Tooltip(
                message: accent.name,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    ref.read(accentColorProvider.notifier).save(accent.value);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StoragePanel extends ConsumerStatefulWidget {
  const _StoragePanel();

  @override
  ConsumerState<_StoragePanel> createState() => _StoragePanelState();
}

class _StoragePanelState extends ConsumerState<_StoragePanel> {
  late Future<StorageStatus?> _future;
  bool _cleaning = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(apiServiceProvider).getStorageStatus();
  }

  void _refresh() {
    setState(() {
      _future = ref.read(apiServiceProvider).getStorageStatus();
    });
  }

  Future<void> _cleanup(StorageStatus? storage) async {
    // When storage is critical, warn the user that recent files will be deleted.
    if (storage != null && storage.status == 'critical') {
      final confirmed = await _showEmergencyDialog(storage);
      if (!mounted || confirmed != true) return;
    }

    setState(() => _cleaning = true);
    final result = await ref.read(apiServiceProvider).cleanupStorage();
    if (!mounted) return;
    setState(() {
      _cleaning = false;
      _future = ref.read(apiServiceProvider).getStorageStatus();
    });

    final String text;
    if (result == null) {
      text = 'Cleanup failed — check server connection';
    } else if (result.emergencyCleanup) {
      text = '⚠️ Emergency cleanup: ${result.deletedFiles} files, '
          '${result.deletedEvents} events, '
          '${result.deletedRecordings} recordings removed '
          '(oldest files deleted to free space)';
    } else if (result.deletedFiles == 0 &&
        result.deletedEvents == 0 &&
        result.deletedRecordings == 0) {
      text = 'Nothing to clean — all files are within the retention window';
    } else {
      text = 'Cleanup complete: ${result.deletedFiles} files, '
          '${result.deletedEvents} events, '
          '${result.deletedRecordings} recordings removed';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<bool?> _showEmergencyDialog(StorageStatus storage) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Storage Critical'),
          ],
        ),
        content: Text(
          'Disk is ${storage.usedPercent.toStringAsFixed(1)}% full '
          '(${storage.freeText} free).\n\n'
          'The server will delete the OLDEST recordings, clips, and '
          'snapshots first — regardless of age — until enough space is '
          'freed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Free Space Now',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanupButton(
    BuildContext context,
    bool isDemo,
    StorageStatus? storage,
  ) {
    final isCritical = storage?.status == 'critical';
    final isWarning = storage?.status == 'warning';
    final borderColor = isCritical
        ? Colors.redAccent
        : isWarning
            ? Colors.amber
            : const Color(0xFF2A2A2A);
    final label = _cleaning
        ? 'Cleaning...'
        : isCritical
            ? 'Free Space Now'
            : 'Clean Old Data';
    final icon = _cleaning
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(
            isCritical
                ? Icons.warning_amber_rounded
                : Icons.cleaning_services_rounded,
            color: isCritical ? Colors.redAccent : null,
          );

    return OutlinedButton.icon(
      onPressed: isDemo || _cleaning ? null : () => _cleanup(storage),
      icon: icon,
      label: Text(
        label,
        style: TextStyle(color: isCritical ? Colors.redAccent : Colors.white),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = ref.watch(serverConfigProvider).isDemo;
    return FutureBuilder<StorageStatus?>(
      future: _future,
      builder: (context, snapshot) {
        final storage = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final statusColor = _statusColor(storage?.status);
        final isCritical = storage?.status == 'critical';
        final isWarning = storage?.status == 'warning';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCritical
                  ? Colors.redAccent.withValues(alpha: 0.5)
                  : isWarning
                      ? Colors.amber.withValues(alpha: 0.4)
                      : const Color(0xFF2A2A2A),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ───────────────────────────
              Row(
                children: [
                  Icon(Icons.storage_rounded, color: statusColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      storage == null
                          ? 'Storage'
                          : 'Storage  ${storage.usedPercent.toStringAsFixed(1)}% used',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (storage != null) _StorageStatusBadge(status: storage.status),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: isLoading ? null : _refresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      color: Colors.white54,
                      tooltip: 'Refresh',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Progress bar ─────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: storage == null ? 0 : storage.usedPercent / 100,
                  backgroundColor: const Color(0xFF2A2A2A),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 12),

              // ── Used / Free / Total ──────────────────
              if (storage != null)
                Row(
                  children: [
                    _StorageStatBox(label: 'Used', value: storage.usedText, color: statusColor),
                    const SizedBox(width: 8),
                    _StorageStatBox(label: 'Free', value: storage.freeText, color: Colors.white70),
                    const SizedBox(width: 8),
                    _StorageStatBox(label: 'Total', value: storage.totalText, color: Colors.white38),
                  ],
                )
              else
                Text(
                  isLoading ? 'Loading storage info...' : 'Storage info unavailable',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

              // ── Breakdown: recordings / clips / snapshots ──
              if (storage != null &&
                  (storage.recordingsCount > 0 ||
                      storage.clipsCount > 0 ||
                      storage.snapshotsCount > 0)) ...[
                const SizedBox(height: 14),
                const _StorageDivider(),
                const SizedBox(height: 10),
                _StorageBreakdownRow(
                  icon: Icons.videocam_rounded,
                  label: 'Recordings',
                  size: storage.recordingsSizeText,
                  count: storage.recordingsCount,
                ),
                const SizedBox(height: 6),
                _StorageBreakdownRow(
                  icon: Icons.movie_filter_rounded,
                  label: 'Alert Clips',
                  size: storage.clipsSizeText,
                  count: storage.clipsCount,
                ),
                const SizedBox(height: 6),
                _StorageBreakdownRow(
                  icon: Icons.photo_camera_rounded,
                  label: 'Snapshots',
                  size: storage.snapshotsSizeText,
                  count: storage.snapshotsCount,
                ),
              ],

              // ── Info: oldest file age + retention + path ──
              if (storage != null) ...[
                const SizedBox(height: 12),
                const _StorageDivider(),
                const SizedBox(height: 8),
                if (storage.oldestFileDays != null)
                  _StorageInfoRow(
                    icon: Icons.access_time_rounded,
                    text:
                        'Oldest file: ${storage.oldestFileDays!.toStringAsFixed(1)} days old',
                  ),
                _StorageInfoRow(
                  icon: Icons.autorenew_rounded,
                  text: 'Auto-cleanup every ${storage.retentionText}',
                ),
                if (storage.path.isNotEmpty)
                  _StorageInfoRow(
                    icon: Icons.folder_outlined,
                    text: storage.path,
                    overflow: true,
                  ),
              ],
              const SizedBox(height: 12),

              // ── Cleanup button ───────────────────────
              SizedBox(
                width: double.infinity,
                child: _buildCleanupButton(context, isDemo, storage),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'critical':
        return Colors.redAccent;
      case 'warning':
        return Colors.amber;
      default:
        return Colors.greenAccent;
    }
  }
}

// ── Storage panel helper widgets ────────────────────────────────────────────

class _StorageStatusBadge extends StatelessWidget {
  final String status;
  const _StorageStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status) {
      case 'critical':
        color = Colors.redAccent;
        label = 'CRITICAL';
        break;
      case 'warning':
        color = Colors.amber;
        label = 'WARNING';
        break;
      default:
        color = Colors.greenAccent;
        label = 'OK';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _StorageStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StorageStatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _StorageDivider extends StatelessWidget {
  const _StorageDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: Color(0xFF2A2A2A), height: 1);
  }
}

class _StorageBreakdownRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String size;
  final int count;
  const _StorageBreakdownRow({
    required this.icon,
    required this.label,
    required this.size,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Text(size,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Text('$count files',
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}

class _StorageInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool overflow;
  const _StorageInfoRow({
    required this.icon,
    required this.text,
    this.overflow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white30, size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: overflow ? 1 : null,
              overflow: overflow ? TextOverflow.ellipsis : null,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification toggle ──────────────────────────────────────────────────────

class _SettingsToggle extends ConsumerWidget {
  final String settingKey;
  final IconData icon;
  final String title;

  const _SettingsToggle({
    required this.settingKey,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider).valueOrNull;
    final isDemo = ref.watch(serverConfigProvider).isDemo;
    final value = settings?[settingKey] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Switch(
            value: value,
            onChanged: (enabled) async {
              if (isDemo) {
                return;
              }
              final next = {
                ...?settings,
                settingKey: enabled,
              };
              await ref
                  .read(apiServiceProvider)
                  .updateNotificationSettings(next);
              ref.invalidate(notificationSettingsProvider);
            },
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
