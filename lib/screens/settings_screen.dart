import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
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
          const _SectionTitle('Notifications'),
          const _SettingsToggle(
            title: 'Fire Detection',
            icon: Icons.local_fire_department_rounded,
          ),
          const _SettingsToggle(
            title: 'Smoke Detection',
            icon: Icons.cloud_rounded,
          ),
          const _SettingsToggle(
            title: 'Liquid Spill',
            icon: Icons.water_drop_rounded,
          ),
          const _SettingsToggle(
            title: 'Suspicious Activity',
            icon: Icons.visibility_rounded,
          ),
          const _SettingsToggle(
            title: 'Fall Detection',
            icon: Icons.personal_injury_rounded,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _disconnect(context, ref),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Disconnect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

class _SettingsToggle extends StatefulWidget {
  final IconData icon;
  final String title;

  const _SettingsToggle({
    required this.icon,
    required this.title,
  });

  @override
  State<_SettingsToggle> createState() => _SettingsToggleState();
}

class _SettingsToggleState extends State<_SettingsToggle> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
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
          Icon(widget.icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Switch(
            value: _value,
            onChanged: (value) => setState(() => _value = value),
            activeThumbColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
