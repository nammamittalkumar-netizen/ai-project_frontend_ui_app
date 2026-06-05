import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_ui.dart';
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
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          MainOverflowMenu(onNavigate: onNavigate, currentIndex: currentIndex),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  config.isDemo ? 'Demo mode' : 'Server & preferences',
                  style: TextStyle(
                    color: colors.onSurfaceDim,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const _SectionTitle('Appearance'),
          const _ThemeModeToggle(),
          const SizedBox(height: 8),
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
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.border),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: appButtonShape,
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Storage'),
          const _StoragePanel(),
          const SizedBox(height: 24),
          const _SectionTitle('PPE Violation Alerts'),
          const _SettingsToggle(
            settingKey: 'no_helmet',
            title: 'No Helmet',
            icon: Icons.engineering_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'no_vest',
            title: 'No Safety Vest',
            icon: Icons.checkroom_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'no_gloves',
            title: 'No Gloves',
            icon: Icons.back_hand_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'no_goggles',
            title: 'No Goggles',
            icon: Icons.visibility_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'no_face_mask',
            title: 'No Face Mask',
            icon: Icons.masks_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'no_safety_shoes',
            title: 'No Safety Shoes',
            icon: Icons.hiking_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'no_harness',
            title: 'No Harness',
            icon: Icons.link_rounded,
          ),
          const _SettingsToggle(
            settingKey: 'no_ear_protection',
            title: 'No Ear Protection',
            icon: Icons.hearing_rounded,
          ),
          const SizedBox(height: 24),
          const _SectionTitle('System Notifications'),
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
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: appButtonShape,
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
    final colors = AppColors.of(context);
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
                  style: TextStyle(color: colors.onSurface),
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
                if (!formKey.currentState!.validate()) return;
                await ref.read(serverConfigProvider.notifier).save(
                      ip: ipController.text.trim(),
                      apiPort: int.parse(apiPortController.text.trim()),
                      streamPort: int.parse(streamPortController.text.trim()),
                    );
                ref.invalidate(camerasProvider);
                ref.invalidate(alertsProvider);
                ref.invalidate(storageStatusProvider);
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
    ref.invalidate(storageStatusProvider);

    if (!context.mounted) return;

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
    final colors = AppColors.of(context);
    return TextFormField(
      controller: controller,
      style: TextStyle(color: colors.onSurface),
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
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.onSurfaceDim,
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
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: appCard(colors, radius: kTileRadius),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceDim, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: colors.onSurface, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurfaceDim, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeToggle extends ConsumerWidget {
  const _ThemeModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: appCard(colors, radius: kTileRadius),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: colors.onSurfaceDim,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isDark ? 'Dark Mode' : 'Light Mode',
              style: TextStyle(color: colors.onSurface, fontSize: 13),
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) =>
                ref.read(themeModeProvider.notifier).toggle(),
            activeThumbColor: Theme.of(context).colorScheme.primary,
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
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: appCard(colors, radius: kTileRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_rounded, color: colors.onSurfaceDim, size: 20),
              const SizedBox(width: 12),
              Text(
                'Theme Color',
                style: TextStyle(color: colors.onSurface, fontSize: 13),
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
                        color:
                            isSelected ? Colors.white : Colors.transparent,
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
  bool _cleaning = false;

  void _refresh() {
    ref.invalidate(storageStatusProvider);
  }

  Future<void> _cleanup(StorageStatus? storage) async {
    if (storage != null && storage.status == 'critical') {
      final confirmed = await _showEmergencyDialog(storage);
      if (!mounted || confirmed != true) return;
    }

    setState(() => _cleaning = true);
    final result = await ref.read(apiServiceProvider).cleanupStorage();
    if (!mounted) return;
    setState(() => _cleaning = false);
    ref.invalidate(storageStatusProvider);

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
      SnackBar(content: Text(text), duration: const Duration(seconds: 5)),
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
            child: const Text('Emergency Cleanup',
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
    final colors = AppColors.of(context);
    final isCritical = storage?.status == 'critical';
    final isWarning = storage?.status == 'warning';
    final borderColor = isCritical
        ? Colors.redAccent
        : isWarning
            ? Colors.amber
            : colors.border;
    final label = _cleaning
        ? 'Cleaning...'
        : isCritical
            ? 'Emergency Cleanup'
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
        style: TextStyle(
            color: isCritical ? Colors.redAccent : colors.onSurface),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.onSurface,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: appButtonShape,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = ref.watch(serverConfigProvider).isDemo;
    final storageAsync = ref.watch(storageStatusProvider);
    final storage = storageAsync.valueOrNull;
    final isLoading = storageAsync.isLoading && storage == null;
    final hasError = storageAsync.hasError && storage == null;
    final statusColor = _statusColor(storage?.status);
    final isCritical = storage?.status == 'critical';
    final isWarning = storage?.status == 'warning';
    final colors = AppColors.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: appCardShadow,
        border: Border.all(
          color: isCritical
              ? Colors.redAccent.withValues(alpha: 0.5)
              : isWarning
                  ? Colors.amber.withValues(alpha: 0.4)
                  : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded, color: statusColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  storage == null
                      ? 'Storage'
                      : 'Storage  ${storage.usedPercent.toStringAsFixed(1)}% used',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (storage != null) _StorageStatusBadge(status: storage.status),
              if (storage != null) ...[
                const SizedBox(width: 6),
                const _StorageLiveBadge(),
              ],
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: isLoading ? null : _refresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  color: colors.onSurface.withValues(alpha: 0.4),
                  tooltip: 'Refresh',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: storage == null ? 0 : storage.usedPercent / 100,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          if (storage != null)
            Row(
              children: [
                _StorageStatBox(
                    label: 'Used', value: storage.usedText, color: statusColor),
                const SizedBox(width: 8),
                _StorageStatBox(
                    label: 'Free',
                    value: storage.freeText,
                    color: colors.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                _StorageStatBox(
                    label: 'Total',
                    value: storage.totalText,
                    color: colors.onSurface.withValues(alpha: 0.4)),
              ],
            )
          else
            Text(
              isLoading
                  ? 'Loading storage info...'
                  : hasError
                      ? 'Live storage connection unavailable'
                      : 'Storage info unavailable',
              style: TextStyle(color: colors.onSurfaceDim, fontSize: 12),
            ),
          if (storage != null &&
              (storage.recordingsCount > 0 ||
                  storage.clipsCount > 0 ||
                  storage.snapshotsCount > 0)) ...[
            const SizedBox(height: 14),
            _StorageDivider(),
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
          if (storage != null) ...[
            const SizedBox(height: 12),
            _StorageDivider(),
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
            const _StorageInfoRow(
              icon: Icons.sync_rounded,
              text: 'Live updates via WebSocket',
            ),
            if (storage.path.isNotEmpty)
              _StorageInfoRow(
                icon: Icons.folder_outlined,
                text: storage.path,
                overflow: true,
              ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildCleanupButton(context, isDemo, storage),
          ),
        ],
      ),
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

class _StorageLiveBadge extends StatelessWidget {
  const _StorageLiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.45)),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Colors.lightBlueAccent,
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
    final colors = AppColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
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
                style:
                    TextStyle(color: colors.onSurfaceDim, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _StorageDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(color: AppColors.of(context).border, height: 1);
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
    final colors = AppColors.of(context);
    return Row(
      children: [
        Icon(icon, color: colors.onSurface.withValues(alpha: 0.3), size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.7),
                  fontSize: 12)),
        ),
        Text(size,
            style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Text('$count files',
            style: TextStyle(color: colors.onSurfaceDim, fontSize: 11)),
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
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurface.withValues(alpha: 0.25), size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: overflow ? 1 : null,
              overflow: overflow ? TextOverflow.ellipsis : null,
              style: TextStyle(color: colors.onSurfaceDim, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: appCard(colors, radius: kTileRadius),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceDim, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: colors.onSurface, fontSize: 13),
            ),
          ),
          Switch(
            value: value,
            onChanged: (enabled) async {
              if (isDemo) return;
              final next = {...?settings, settingKey: enabled};
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
