import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/camera.dart';
import '../providers/providers.dart';
import '../widgets/main_overflow_menu.dart';

class DashboardScreen extends ConsumerWidget {
  final ValueChanged<int> onNavigate;
  final int currentIndex;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(camerasProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final isDemo =
        ref.watch(serverConfigProvider.select((config) => config.isDemo));
    final accentColor = Theme.of(context).colorScheme.primary;

    final alertCount = alertsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text(
          'Security Hub',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$alertCount alerts',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
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
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: () async {
          ref.invalidate(camerasProvider);
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
            if (cameras.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.35),
                  const Center(
                    child: Text(
                      'No cameras found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            final onlineCount =
                cameras.where((camera) => camera.isOnline).length;
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.45,
                    children: [
                      _StatTile(
                        icon: Icons.videocam_rounded,
                        value: '$onlineCount/${cameras.length}',
                        label: 'Active Cameras',
                        color: Colors.lightBlueAccent,
                      ),
                      _StatTile(
                        icon: Icons.warning_amber_rounded,
                        value: '$alertCount',
                        label: 'Events Today',
                        color: Colors.orangeAccent,
                      ),
                      _StatTile(
                        icon: Icons.psychology_rounded,
                        value: '${alertCount * 3}',
                        label: 'AI Detections',
                        color: Colors.greenAccent,
                      ),
                      _StatTile(
                        icon: Icons.dns_rounded,
                        value: '98.5%',
                        label: 'System Uptime',
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: accentColor,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'AI search, playback, analytics, and alerts are available from the bottom menu. Reports and settings are in the top menu.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 18, 12, 8),
                    child: Text(
                      'Live Camera Feeds',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9,
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

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
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

    return InkWell(
      borderRadius: BorderRadius.circular(12),
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
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
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
                            const _NoFeedPlaceholder(),
                      )
                    else
                      const _NoFeedPlaceholder(),
                    if (camera.isOnline)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'REC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    camera.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    camera.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: camera.isOnline ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        camera.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: camera.isOnline ? Colors.green : Colors.red,
                          fontSize: 11,
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
  const _NoFeedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF222222),
      child: const Center(
        child: Icon(
          Icons.videocam_off_rounded,
          size: 36,
          color: Color(0xFF555555),
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
