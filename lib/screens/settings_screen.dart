import 'package:flutter/material.dart';
import '../config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionTitle('Server'),
          _SettingsTile(icon: Icons.computer, title: 'Mini PC IP', subtitle: AppConfig.serverIP),
          _SettingsTile(icon: Icons.api, title: 'API Server', subtitle: AppConfig.apiBase),
          _SettingsTile(icon: Icons.videocam, title: 'Stream Server', subtitle: AppConfig.hlsBase),
          SizedBox(height: 24),
          _SectionTitle('Notifications'),
          _SettingsToggle(title: 'Fire Detection', icon: Icons.local_fire_department),
          _SettingsToggle(title: 'Intrusion Detection', icon: Icons.directions_run),
          _SettingsToggle(title: 'Unknown Face', icon: Icons.face),
          _SettingsToggle(title: 'Object Detection', icon: Icons.warning),
        ],
      ),
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
      child: Text(title,
        style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle});
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
      child: Row(children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _SettingsToggle extends StatefulWidget {
  final IconData icon;
  final String title;
  const _SettingsToggle({required this.icon, required this.title});
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
      child: Row(children: [
        Icon(widget.icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 13))),
        Switch(
          value: _value,
          onChanged: (v) => setState(() => _value = v),
          activeThumbColor: Colors.red,
        ),
      ]),
    );
  }
}
