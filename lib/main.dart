import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/alert.dart';
import 'providers/providers.dart';
import 'screens/alerts_screen.dart';
import 'screens/ai_search_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/setup_screen.dart';
import 'services/background_service.dart';
import 'services/alert_navigation_intent.dart';
import 'services/alert_review_state.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';
import 'widgets/alert_popup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();
  await initBackgroundService();

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

  // Load reviewed alerts before the widget tree builds so reconnect/login
  // cannot replay already-reviewed alerts as fresh popups.
  final reviewedAlertIds = await loadReviewedAlertIds();
  final savedAlertId = prefs.getString(kBgLastAlertId) ?? '';

  runApp(
    ProviderScope(
      overrides: [
        initialServerConfigProvider.overrideWithValue(initialConfig),
        if (savedAlertId.isNotEmpty)
          lastAlertIdProvider.overrideWith((ref) => savedAlertId),
        reviewedAlertIdsProvider.overrideWith((ref) => reviewedAlertIds),
      ],
      child: SecurityApp(hasConfig: hasConfig),
    ),
  );
}

ThemeData _buildTheme(Color accentColor, AppColors colors) {
  final isDark = identical(colors, AppColors.dark);
  final base = isDark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);

  return base.copyWith(
    extensions: [colors],
    colorScheme: (isDark ? ColorScheme.dark : ColorScheme.light)(
      primary: accentColor,
      secondary: accentColor,
      surface: colors.surface,
      onSurface: colors.onSurface,
      onSurfaceVariant: colors.onSurfaceDim,
    ),
    scaffoldBackgroundColor: colors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentColor),
      ),
      labelStyle: TextStyle(color: colors.onSurfaceDim),
      helperStyle: TextStyle(color: colors.onSurfaceDim),
      hintStyle: TextStyle(color: colors.onSurfaceDim),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surface,
      textStyle: TextStyle(color: colors.onSurface),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colors.navBg,
      selectedItemColor: accentColor,
      unselectedItemColor: colors.onSurfaceDim,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

class SecurityApp extends ConsumerWidget {
  final bool hasConfig;

  const SecurityApp({super.key, required this.hasConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = Color(ref.watch(accentColorProvider));
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Security Hub',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(accentColor, AppColors.light),
      darkTheme: _buildTheme(accentColor, AppColors.dark),
      themeMode: themeMode,
      home: hasConfig ? const MainShell() : const SetupScreen(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  static const _bottomTabCount = 4;

  late PageController _pageController;
  int _index = 0;
  bool _isBottomTapAnimating = false;
  bool _alertsPrimed = false;
  bool _isInBackground = false;
  StreamSubscription<String>? _notificationTapSub;
  AlertSectionFocus _alertSectionFocus = AlertSectionFocus.aiDetections;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    // Reviewed-alert state is pre-seeded from SharedPreferences in main()
    // before the widget tree builds — no async race possible here.
    // _alertsPrimed stays false so the first poll always primes silently,
    // which prevents a popup for any alert that arrived before this session.
    _notificationTapSub = NotificationService.notificationTaps.listen(
      _handleAlertNavigationPayload,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingAlertNavigation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationTapSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isInBackground = state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden;

    if (state == AppLifecycleState.resumed) {
      _syncReviewedAlertsFromDisk();
    }
  }

  Future<void> _syncReviewedAlertsFromDisk() async {
    final ids = await loadReviewedAlertIds();
    if (!mounted) return;
    ref.read(reviewedAlertIdsProvider.notifier).state = ids;
    if (ids.isNotEmpty) {
      ref.read(lastAlertIdProvider.notifier).state = ids.first;
    }
  }

  void _openMenuTab(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  Future<void> _openBottomTab(int index) async {
    if (_index == index && _pageController.page?.round() == index) return;

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

  Future<void> _openAlertsSection(AlertSectionFocus focus) async {
    setState(() => _alertSectionFocus = focus);
    await _openBottomTab(3);
  }

  Future<void> _openPendingAlertNavigation() async {
    final payload = await takePendingAlertNavigation();
    if (!mounted || payload == null) return;
    await _handleAlertNavigationPayload(payload);
  }

  Future<void> _handleAlertNavigationPayload(String payload) async {
    if (!mounted) return;
    final focus = payload == kAlertNavigationSystem
        ? AlertSectionFocus.systemAlerts
        : AlertSectionFocus.aiDetections;
    await _openAlertsSection(focus);
  }

  Future<void> _markAlertReviewed(Alert alert) async {
    final key = alertReviewKey(alert);
    ref.read(lastAlertIdProvider.notifier).state = key;

    final currentIds = ref.read(reviewedAlertIdsProvider);
    if (currentIds.contains(key)) return;

    final savedIds = await saveReviewedAlertId(currentIds, key);
    ref.read(reviewedAlertIdsProvider.notifier).state = savedIds;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Alert>>>(alertsProvider, (previous, next) {
      next.whenData((alerts) async {
        if (alerts.isEmpty) return;

        final latest = alerts.first;

        if (!_alertsPrimed) {
          _alertsPrimed = true;
          await _markAlertReviewed(latest);
          return;
        }

        final latestKey = alertReviewKey(latest);
        final reviewedIds = ref.read(reviewedAlertIdsProvider);
        final lastSeenId = ref.read(lastAlertIdProvider);
        if (latestKey.isEmpty ||
            latestKey == lastSeenId ||
            reviewedIds.contains(latestKey)) {
          return;
        }

        final persistedReviewedIds = await loadReviewedAlertIds();
        if (persistedReviewedIds.contains(latestKey)) {
          ref.read(reviewedAlertIdsProvider.notifier).state =
              persistedReviewedIds;
          ref.read(lastAlertIdProvider.notifier).state = latestKey;
          return;
        }

        await _markAlertReviewed(latest);

        if (_isInBackground) {
          // Background service handles its own notifications, but if the
          // service hasn't fired yet (race), show one here as a fallback.
          NotificationService.showAlert(
            title: latest.typeLabelWithEmoji,
            body: latest.displaySource,
            payload:
                latest.isSystem ? kAlertNavigationSystem : kAlertNavigationAi,
          );
          return;
        }

        Future<void>.microtask(() {
          if (!context.mounted) return;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertPopup(
              alert: latest,
              autoDismiss: true,
              onViewAlert: () => _openAlertsSection(
                latest.isSystem
                    ? AlertSectionFocus.systemAlerts
                    : AlertSectionFocus.aiDetections,
              ),
            ),
          );
        });
      });
    });

    final bottomScreens = [
      DashboardScreen(
        onNavigate: _openMenuTab,
        onOpenAlerts: _openAlertsSection,
        currentIndex: _index,
      ),
      AiSearchScreen(onNavigate: _openMenuTab, currentIndex: _index),
      AnalyticsScreen(onNavigate: _openMenuTab, currentIndex: _index),
      AlertsScreen(
        onNavigate: _openMenuTab,
        currentIndex: _index,
        focus: _alertSectionFocus,
      ),
    ];

    final Widget body = _index < _bottomTabCount
        ? PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              if (_isBottomTapAnimating) return;
              setState(() => _index = index);
            },
            children: bottomScreens,
          )
        : switch (_index) {
            4 => ReportsScreen(onNavigate: _openMenuTab, currentIndex: _index),
            5 => SettingsScreen(onNavigate: _openMenuTab, currentIndex: _index),
            _ => DashboardScreen(
                onNavigate: _openMenuTab,
                onOpenAlerts: _openAlertsSection,
                currentIndex: _index,
              ),
          };

    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ReconnectBanner(),
          _MainBottomNav(currentIndex: _index, onTap: _openBottomTab),
        ],
      ),
    );
  }
}

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

  const _MainBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: colors.navBg,
          border: Border(top: BorderSide(color: colors.navBorder)),
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
              icon: Icons.search_rounded,
              label: 'AI Search',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _MainBottomNavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Analytics',
              selected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _MainBottomNavItem(
              icon: Icons.notifications_rounded,
              label: 'Alerts',
              selected: currentIndex == 3,
              onTap: () => onTap(3),
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
    final colors = AppColors.of(context);
    final color =
        selected ? Theme.of(context).colorScheme.primary : colors.onSurfaceDim;

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
