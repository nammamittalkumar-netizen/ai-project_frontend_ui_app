import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ProviderScope(child: SecurityApp()));
}

// ─── MODELS ───────────────────────────────────────────────

enum AlertType { intrusion, fire, face, object }

class Camera {
  final String id;
  final String name;
  final String location;
  final bool isOnline;
  Camera({required this.id, required this.name, required this.location, required this.isOnline});
}

class Alert {
  final String id;
  final AlertType type;
  final String cameraName;
  final DateTime timestamp;
  Alert({required this.id, required this.type, required this.cameraName, required this.timestamp});

  String get typeLabel {
    switch (type) {
      case AlertType.fire:      return '🔥 Fire';
      case AlertType.intrusion: return '🚨 Intrusion';
      case AlertType.face:      return '👤 Unknown Face';
      case AlertType.object:    return '⚠️ Object';
    }
  }

  Color get typeColor {
    switch (type) {
      case AlertType.fire:      return Colors.orange;
      case AlertType.intrusion: return Colors.blue;
      case AlertType.face:      return Colors.purple;
      case AlertType.object:    return Colors.red;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case AlertType.fire:      return Icons.local_fire_department;
      case AlertType.intrusion: return Icons.directions_run;
      case AlertType.face:      return Icons.face;
      case AlertType.object:    return Icons.warning;
    }
  }
}

// ─── DUMMY DATA ───────────────────────────────────────────

final camerasProvider = Provider<List<Camera>>((ref) => [
  Camera(id: '1', name: 'Front Door',  location: 'Entrance', isOnline: true),
  Camera(id: '2', name: 'Parking Lot', location: 'Outside',  isOnline: true),
  Camera(id: '3', name: 'Back Gate',   location: 'Rear',     isOnline: false),
  Camera(id: '4', name: 'Warehouse',   location: 'Inside',   isOnline: true),
]);

final alertsProvider = Provider<List<Alert>>((ref) => [
  Alert(id: '1', type: AlertType.fire,      cameraName: 'Warehouse',   timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
  Alert(id: '2', type: AlertType.intrusion, cameraName: 'Front Door',  timestamp: DateTime.now().subtract(const Duration(minutes: 45))),
  Alert(id: '3', type: AlertType.face,      cameraName: 'Parking Lot', timestamp: DateTime.now().subtract(const Duration(hours: 1))),
  Alert(id: '4', type: AlertType.object,    cameraName: 'Back Gate',   timestamp: DateTime.now().subtract(const Duration(hours: 2))),
]);

// ─── APP ──────────────────────────────────────────────────

class SecurityApp extends StatelessWidget {
  const SecurityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Security Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111111),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161616),
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _screens = const [
    DashboardScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view),      label: 'Cameras'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications),  label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings),       label: 'Settings'),
        ],
      ),
    );
  }
}

// ─── DASHBOARD SCREEN ─────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameras = ref.watch(camerasProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Security Hub',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
            child: const Text('3 alerts', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.95,
        ),
        itemCount: cameras.length,
        itemBuilder: (ctx, i) => _CameraCard(camera: cameras[i]),
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  final Camera camera;
  const _CameraCard({required this.camera});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF222222),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Stack(children: [
              const Center(child: Icon(Icons.videocam, size: 40, color: Color(0xFF444444))),
              if (camera.isOnline)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                    child: const Text('REC', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(camera.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.circle, size: 8, color: camera.isOnline ? Colors.green : Colors.red),
              const SizedBox(width: 4),
              Text(camera.isOnline ? 'Online' : 'Offline',
                style: TextStyle(color: camera.isOnline ? Colors.green : Colors.red, fontSize: 10)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─── ALERTS SCREEN ────────────────────────────────────────

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Alerts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: alerts.length,
        itemBuilder: (ctx, i) => _AlertTile(alert: alerts[i]),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final Alert alert;
  const _AlertTile({required this.alert});

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
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: alert.typeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(alert.typeIcon, color: alert.typeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(alert.typeLabel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(alert.cameraName, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ])),
        Text(DateFormat('hh:mm a').format(alert.timestamp),
          style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(width: 8),
        const Icon(Icons.play_circle_outline, color: Colors.grey, size: 24),
      ]),
    );
  }
}

// ─── SETTINGS SCREEN ──────────────────────────────────────

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
