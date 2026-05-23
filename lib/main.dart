import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/alert.dart';
import 'providers/providers.dart';
import 'screens/alerts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/setup_screen.dart';
import 'widgets/alert_popup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isDemoMode = prefs.getBool('demo_mode') ?? false;
  final savedIp = prefs.getString('server_ip');
  final savedApiPort = prefs.getInt('api_port') ?? 8000;
  final savedStreamPort = prefs.getInt('stream_port') ?? 8888;
  final hasConfig =
      isDemoMode || (savedIp != null && savedIp.trim().isNotEmpty);

  final initialConfig = isDemoMode
      ? ServerConfig.demo()
      : hasConfig
      ? ServerConfig.fromParts(
          ip: savedIp!.trim(),
          apiPort: savedApiPort,
          streamPort: savedStreamPort,
        )
      : null;

  runApp(
    ProviderScope(
      overrides: [
        initialServerConfigProvider.overrideWithValue(initialConfig),
      ],
      child: SecurityApp(hasConfig: hasConfig),
    ),
  );
}

class SecurityApp extends StatelessWidget {
  final bool hasConfig;

  const SecurityApp({super.key, required this.hasConfig});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Security Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.red,
          secondary: Colors.red,
          surface: Color(0xFF1A1A1A),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF111111),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111111),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          helperStyle: const TextStyle(color: Colors.grey),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161616),
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: hasConfig ? const MainShell() : const SetupScreen(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Alert>>>(alertsProvider, (previous, next) {
      next.whenData((alerts) {
        if (alerts.isEmpty) {
          return;
        }

        final latest = alerts.first;
        final lastSeenId = ref.read(lastAlertIdProvider);
        if (latest.id.isEmpty || latest.id == lastSeenId) {
          return;
        }

        ref.read(lastAlertIdProvider.notifier).state = latest.id;
        Future<void>.microtask(() {
          if (!context.mounted) {
            return;
          }
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertPopup(alert: latest),
          );
        });
      });
    });

    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Cameras',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
