import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/camera.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/main_overflow_menu.dart';
import 'alerts_screen.dart';

// ── Premium bento accent palette (visual layer only) ───────────────────────
const _accentLime = Color(0xFFC6F24E);
const _accentYellow = Color(0xFFF5D24C);
const _accentLavender = Color(0xFFCEC2F2);
const _accentBlue = Color(0xFF63A8FF);
const _onFilled = Color(0xFF14140E);

const List<BoxShadow> _cardShadow = [
  BoxShadow(color: Color(0x2E000000), blurRadius: 22, offset: Offset(0, 10)),
];

class DashboardScreen extends ConsumerWidget {
  final ValueChanged<int> onNavigate;
  final ValueChanged<AlertSectionFocus> onOpenAlerts;
  final int currentIndex;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenAlerts,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(camerasProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final status = ref.watch(statusProvider).valueOrNull;
    final connection = ref.watch(connectionStatusProvider).valueOrNull;
    final isOffline = connection == ConnectionStatus.reconnecting;
    final isDemo =
        ref.watch(serverConfigProvider.select((config) => config.isDemo));
    final accentColor = Theme.of(context).colorScheme.primary;
    final colors = AppColors.of(context);

    final alerts = alertsAsync.valueOrNull ?? [];
    final detectionCount = alerts.where((a) => a.isDetection).length;
    final systemCount = alerts.where((a) => a.isSystem).length;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AlertCounterChip(
                    icon: Icons.psychology_rounded,
                    count: detectionCount,
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    tooltip: 'Open AI detections',
                    onTap: () => onOpenAlerts(AlertSectionFocus.aiDetections),
                  ),
                  const SizedBox(width: 6),
                  _AlertCounterChip(
                    icon: Icons.settings_rounded,
                    count: systemCount,
                    backgroundColor: Colors.amber.withValues(alpha: 0.85),
                    foregroundColor: Colors.black87,
                    tooltip: 'Open system alerts',
                    onTap: () => onOpenAlerts(AlertSectionFocus.systemAlerts),
                  ),
                ],
              ),
            ),
          ),
          MainOverflowMenu(
            onNavigate: onNavigate,
            currentIndex: currentIndex,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: accentColor,
        backgroundColor: colors.surface,
        onRefresh: () async {
          ref.invalidate(camerasProvider);
          ref.invalidate(statusProvider);
          await ref.read(camerasProvider.future);
        },
        child: camerasAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: accentColor),
          ),
          error: (error, _) => ListView(
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.35),
              Center(
                child: Text(
                  '$error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          data: (cameras) {
            if (isOffline) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                  const Center(
                    child: Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.grey,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Server unavailable',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Check the Mini PC, network, or restart the server.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceDim),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.invalidate(connectionStatusProvider);
                        ref.invalidate(camerasProvider);
                        ref.invalidate(statusProvider);
                        ref.invalidate(alertsProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              );
            }

            if (cameras.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.35),
                  Center(
                    child: Text(
                      'No cameras found',
                      style: TextStyle(color: colors.onSurfaceDim),
                    ),
                  ),
                ],
              );
            }

            final onlineCount =
                cameras.where((camera) => camera.isOnline).length;
            final totalCount = cameras.length;
            final uptime = status == null
                ? '98.5%'
                : '${status.uptimePercent.toStringAsFixed(1)}%';
            return CustomScrollView(
              slivers: [
                // ── Hero header ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Hub',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: onlineCount > 0
                                    ? _accentLime
                                    : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$onlineCount of $totalCount cameras live',
                              style: TextStyle(
                                color: colors.onSurfaceDim,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Bento stat grid ───────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.28,
                    children: [
                      _BentoStat(
                        icon: Icons.videocam_rounded,
                        value: '$onlineCount/$totalCount',
                        label: 'Active Cameras',
                        accent: _accentBlue,
                      ),
                      _BentoStat(
                        icon: Icons.psychology_rounded,
                        value: '$detectionCount',
                        label: 'AI Detections',
                        accent: _accentLime,
                        filled: true,
                      ),
                      _BentoStat(
                        icon: Icons.settings_rounded,
                        value: '$systemCount',
                        label: 'System Alerts',
                        accent: _accentYellow,
                        filled: true,
                      ),
                      _BentoStat(
                        icon: Icons.dns_rounded,
                        value: uptime,
                        label: 'System Uptime',
                        accent: _accentLavender,
                        filled: true,
                      ),
                    ],
                  ),
                ),
                // ── AI recommendation card ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.border),
                        boxShadow: _cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_accentLime, _accentBlue],
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: _onFilled,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'AI search, analytics, and alerts are available from the bottom menu. Reports and settings are in the top menu.',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 13.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Section title ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: Text(
                      'Live Camera Feeds',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _CameraCard(
                          camera: cameras[index],
                          isDemo: isDemo,
                        );
                      },
                      childCount: cameras.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AlertCounterChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color backgroundColor;
  final Color foregroundColor;
  final String tooltip;
  final VoidCallback onTap;

  const _AlertCounterChip({
    required this.icon,
    required this.count,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foregroundColor, size: 14),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final bool filled;

  const _BentoStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final Color bg = filled ? accent : colors.surface;
    final Color valueColor = filled ? _onFilled : colors.onSurface;
    final Color labelColor =
        filled ? _onFilled.withValues(alpha: 0.62) : colors.onSurfaceDim;
    final Color iconBg =
        filled ? Colors.black.withValues(alpha: 0.12) : accent.withValues(alpha: 0.16);
    final Color iconColor = filled ? _onFilled : accent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: filled ? null : Border.all(color: colors.border),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraCard extends ConsumerWidget {
  final Camera camera;
  final bool isDemo;

  const _CameraCard({required this.camera, required this.isDemo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamUrl = ref.watch(apiServiceProvider).streamUrlForCamera(
          Uri.encodeComponent(camera.id),
        );
    final colors = AppColors.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _FullscreenCamera(
              camera: camera,
              streamUrl: streamUrl,
              isDemo: isDemo,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
          boxShadow: _cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (camera.isOnline && isDemo)
                      _DemoFeed(camera: camera)
                    else if (camera.isOnline)
                      Image.network(
                        streamUrl,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) =>
                            _NoFeedPlaceholder(colors: colors),
                      )
                    else
                      _NoFeedPlaceholder(colors: colors),
                    if (camera.isOnline)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFF4D4D),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'REC',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    camera.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    camera.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.onSurfaceDim, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: camera.isOnline
                              ? const Color(0xFF4ADE80)
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        camera.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: camera.isOnline
                              ? const Color(0xFF4ADE80)
                              : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoFeedPlaceholder extends StatelessWidget {
  final AppColors colors;

  const _NoFeedPlaceholder({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.feedBg,
      child: Center(
        child: Icon(
          Icons.videocam_off_rounded,
          size: 36,
          color: colors.feedIcon,
        ),
      ),
    );
  }
}

class _FullscreenCamera extends StatelessWidget {
  final Camera camera;
  final String streamUrl;
  final bool isDemo;

  const _FullscreenCamera({
    required this.camera,
    required this.streamUrl,
    required this.isDemo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(camera.name),
      ),
      body: Center(
        child: camera.isOnline
            ? isDemo
                ? _DemoFeed(camera: camera, fullscreen: true)
                : Image.network(
                    streamUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text(
                      'Stream unavailable',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
            : const Text(
                'Camera offline',
                style: TextStyle(color: Colors.grey),
              ),
      ),
    );
  }
}

class _DemoFeed extends StatelessWidget {
  final Camera camera;
  final bool fullscreen;

  const _DemoFeed({
    required this.camera,
    this.fullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF242424),
            Color(0xFF151515),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _DemoFeedPainter(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam_rounded,
                  color: Colors.white.withValues(alpha: 0.55),
                  size: fullscreen ? 72 : 34,
                ),
                SizedBox(height: fullscreen ? 12 : 6),
                Text(
                  camera.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: fullscreen ? 18 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Demo Feed',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.85),
                    fontSize: fullscreen ? 13 : 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoFeedPainter extends CustomPainter {
  final Color color;

  const _DemoFeedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 28.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final scanPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height * 0.36),
      Offset(size.width, size.height * 0.36),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
