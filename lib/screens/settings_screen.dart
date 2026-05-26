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

  Future<void> _cleanup() async {
    setState(() => _cleaning = true);
    final result = await ref.read(apiServiceProvider).cleanupStorage();
    if (!mounted) {
      return;
    }
    setState(() {
      _cleaning = false;
      _future = ref.read(apiServiceProvider).getStorageStatus();
    });
    final text = result == null
        ? 'Cleanup failed'
        : 'Cleanup complete: ${result.deletedFiles} files, '
            '${result.deletedEvents} events, '
            '${result.deletedRecordings} recordings removed';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
              Row(
                children: [
                  Icon(Icons.storage_rounded, color: statusColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      storage == null
                          ? 'Storage'
                          : 'Storage ${storage.usedPercent.toStringAsFixed(1)}% used',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    onPressed: isLoading ? null : _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    color: Colors.white70,
                    tooltip: 'Refresh storage',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: storage == null ? 0 : storage.usedPercent / 100,
                  backgroundColor: const Color(0xFF2A2A2A),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                storage == null
                    ? isLoading
                        ? 'Loading storage status...'
                        : 'Storage status unavailable'
                    : '${storage.freeText} free of ${storage.totalText} | '
                        'Retention: ${storage.retentionText}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (storage != null && storage.path.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  storage.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isDemo || _cleaning ? null : _cleanup,
                      icon: _cleaning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cleaning_services_rounded),
                      label: Text(_cleaning ? 'Cleaning...' : 'Clean Old Data'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2A2A2A)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
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
