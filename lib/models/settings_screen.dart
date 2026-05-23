import 'package:flutter/material.dart';

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
        children: [
          _sectionTitle('Server'),
          _settingsTile(Icons.computer,  'Mini PC IP',    '192.168.1.100'),
          _settingsTile(Icons.api,        'API Server',    'http://192.168.1.100:8000'),
          _settingsTile(Icons.videocam,   'Stream Server', 'http://192.168.1.100:8888'),
          const SizedBox(height: 24),
          _sectionTitle('Notifications'),
          const _SettingsToggle(title: 'Fire Detection',      icon: Icons.local_fire_department),
          const _SettingsToggle(title: 'Intrusion Detection', icon: Icons.directions_run),
          const _SettingsToggle(title: 'Unknown Face',        icon: Icons.face),
          const _SettingsToggle(title: 'Object Detection',    icon: Icons.warning),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1)),
  );

  Widget _settingsTile(IconData icon, String title, String subtitle) => Container(
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
        Expanded(child: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 13))),
        Switch(value: _value, onChanged: (v) => setState(() => _value = v), activeThumbColor: Colors.red),
      ]),
    );
  }
}
