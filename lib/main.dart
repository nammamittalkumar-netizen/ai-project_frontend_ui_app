import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/alert.dart';
import 'providers/providers.dart';
import 'screens/alerts_screen.dart';
import 'screens/ai_search_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/playback_screen.dart';
import 'screens/reports_screen.dart';
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

class SecurityApp extends ConsumerWidget {
  final bool hasConfig;

  const SecurityApp({super.key, required this.hasConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = Color(ref.watch(accentColorProvider));

    return MaterialApp(
      title: 'Security Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.dark(
          primary: accentColor,
          secondary: accentColor,
          surface: const Color(0xFF1A1A1A),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            borderSide: BorderSide(color: accentColor),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          helperStyle: const TextStyle(color: Colors.grey),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF161616),
          selectedItemColor: accentColor,
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
  static const _bottomTabCount = 5;

  late PageController _pageController;
  int _index = 0;
  bool _isBottomTapAnimating = false;
  bool _alertsPrimed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openMenuTab(int index) {
    if (_index == index) {
      return;
    }
    setState(() => _index = index);
  }

  Future<void> _openBottomTab(int index) async {
    if (_index == index && _pageController.page?.round() == index) {
      return;
    }

    if (_index >= _bottomTabCount) {
      _pageController.dispose();
      _pageController = PageController(initialPage: index);
      setState(() => _index = index);
      return;
    }

    _isBottomTapAnimating = true;
    setState(() => _index = index);

    if (!_pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(index);
        }
        _isBottomTapAnimating = false;
      });
      return;
    }

    _pageController.jumpToPage(index);
    _isBottomTapAnimating = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Alert>>>(alertsProvider, (previous, next) {
      next.whenData((alerts) {
        if (alerts.isEmpty) {
          return;
        }

        final latest = alerts.first;
        if (!_alertsPrimed) {
          _alertsPrimed = true;
          if (latest.id.isNotEmpty) {
            ref.read(lastAlertIdProvider.notifier).state = latest.id;
          }
          return;
        }

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

    final bottomScreens = [
      DashboardScreen(onNavigate: _openMenuTab, currentIndex: _index),
      PlaybackScreen(onNavigate: _openMenuTab, currentIndex: _index),
      AiSearchScreen(onNavigate: _openMenuTab, currentIndex: _index),
      AnalyticsScreen(onNavigate: _openMenuTab, currentIndex: _index),
      AlertsScreen(onNavigate: _openMenuTab, currentIndex: _index),
    ];

    final Widget body = _index < _bottomTabCount
        ? PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              if (_isBottomTapAnimating) {
                return;
              }
              setState(() => _index = index);
            },
            children: bottomScreens,
          )
        : switch (_index) {
            5 => ReportsScreen(
                onNavigate: _openMenuTab,
                currentIndex: _index,
              ),
            6 => SettingsScreen(
                onNavigate: _openMenuTab,
                currentIndex: _index,
              ),
            _ => DashboardScreen(
                onNavigate: _openMenuTab,
                currentIndex: _index,
              ),
          };

    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reconnect banner — visible only when server is unreachable
          const _ReconnectBanner(),
          _MainBottomNav(
            currentIndex: _index,
            onTap: _openBottomTab,
          ),
        ],
      ),
    );
  }
}

// ── Reconnect banner ──────────────────────────────────────────────────────
// Shows between the main content and the bottom nav bar whenever the server
// is unreachable. Disappears automatically once connectivity is restored.

class _ReconnectBanner extends ConsumerWidget {
  const _ReconnectBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(connectionStatusProvider);
    final isReconnecting =
        statusAsync.valueOrNull == ConnectionStatus.reconnecting;

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      child: isReconnecting
          ? Container(
              width: double.infinity,
              color: const Color(0xFF1C1400),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: const Row(
                children: [
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Server unreachable — reconnecting automatically…',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MainBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Color(0xFF161616),
          border: Border(top: BorderSide(color: Color(0xFF242424))),
        ),
        child: Row(
          children: [
            _MainBottomNavItem(
              icon: Icons.grid_view_rounded,
              label: 'Live',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _MainBottomNavItem(
              icon: Icons.history_rounded,
              label: 'Playback',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _MainBottomNavItem(
              icon: Icons.search_rounded,
              label: 'AI Search',
              selected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _MainBottomNavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Analytics',
              selected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _MainBottomNavItem(
              icon: Icons.notifications_rounded,
              label: 'Alerts',
              selected: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainBottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MainBottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? Theme.of(context).colorScheme.primary : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
