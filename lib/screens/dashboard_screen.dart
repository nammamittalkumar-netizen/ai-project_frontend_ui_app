import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/camera.dart';
import '../models/alert.dart';
import '../providers/providers.dart';
import '../widgets/alert_popup.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(camerasProvider);
    final alertsAsync  = ref.watch(alertsProvider);

    // Detect new alert → show popup
    ref.listen(alertsProvider, (_, next) {
      next.whenData((alerts) {
        if (alerts.isEmpty) return;
        final latest     = alerts.first;
        final lastSeenId = ref.read(lastAlertIdProvider);
        if (latest.id != lastSeenId) {
          ref.read(lastAlertIdProvider.notifier).state = latest.id;
          Future.microtask(() => _showAlertPopup(context, latest));
        }
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Security Hub',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        actions: [
          alertsAsync.whenData((list) => Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.red, borderRadius: BorderRadius.circular(20)),
            child: Text('${list.length} alerts',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          )).valueOrNull ?? const SizedBox(),
        ],
      ),
      body: camerasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
        error:   (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data:    (cameras) => cameras.isEmpty
            ? const Center(child: Text('No cameras found', style: TextStyle(color: Colors.grey)))
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 8,
                  mainAxisSpacing: 8, childAspectRatio: 0.95,
                ),
                itemCount: cameras.length,
                itemBuilder: (ctx, i) => _CameraCard(camera: cameras[i]),
              ),
      ),
    );
  }

  void _showAlertPopup(BuildContext context, Alert alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertPopup(alert: alert),
    );
  }
}

// ── Camera card with live MJPEG stream ───────────────────
class _CameraCard extends ConsumerWidget {
  final Camera camera;
  const _CameraCard({required this.camera});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamUrl = ref.watch(apiServiceProvider).streamUrlForCamera(camera.id);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _FullscreenCamera(camera: camera, streamUrl: streamUrl))),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(children: [
                camera.isOnline
                    // MJPEG stream rendered as Image.network
                    ? Image.network(
                        streamUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => const _NoFeedPlaceholder(),
                      )
                    : const _NoFeedPlaceholder(),
                if (camera.isOnline)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: const Text('REC',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(camera.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.circle, size: 8, color: camera.isOnline ? Colors.green : Colors.red),
                const SizedBox(width: 4),
                Text(camera.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                        color: camera.isOnline ? Colors.green : Colors.red, fontSize: 10)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _NoFeedPlaceholder extends StatelessWidget {
  const _NoFeedPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF222222),
    child: const Center(child: Icon(Icons.videocam_off, size: 36, color: Color(0xFF444444))),
  );
}

// ── Fullscreen camera view ────────────────────────────────
class _FullscreenCamera extends StatelessWidget {
  final Camera camera;
  final String streamUrl;
  const _FullscreenCamera({required this.camera, required this.streamUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(camera.name, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: camera.isOnline
            ? Image.network(streamUrl, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Text('Stream unavailable', style: TextStyle(color: Colors.grey)))
            : const Text('Camera Offline', style: TextStyle(color: Colors.grey, fontSize: 16)),
      ),
    );
  }
}