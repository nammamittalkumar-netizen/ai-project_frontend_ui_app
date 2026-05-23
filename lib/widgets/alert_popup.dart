import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/alert.dart';

class AlertPopup extends StatefulWidget {
  final Alert alert;

  const AlertPopup({super.key, required this.alert});

  @override
  State<AlertPopup> createState() => _AlertPopupState();
}

class _AlertPopupState extends State<AlertPopup> {
  static const int _durationSeconds = 5;

  VideoPlayerController? _controller;
  Timer? _timer;
  int _secondsLeft = _durationSeconds;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _playAlertSignal();
    _startCountdown();
    _initializeVideo();
  }

  Future<void> _playAlertSignal() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.vibrate();
    } catch (_) {
      // Some platforms do not expose system alert audio or vibration.
    }
  }

  Future<void> _initializeVideo() async {
    final clipUrl = widget.alert.clipUrl;
    if (clipUrl == null || clipUrl.isEmpty) {
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(clipUrl));
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _videoFailed = true);
      }
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft <= 1) {
        timer.cancel();
        Navigator.of(context).maybePop();
        return;
      }

      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.alert.typeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.alert.typeIcon,
                    color: widget.alert.typeColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.alert.typeLabelWithEmoji,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.alert.typeColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.alert.cameraName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _secondsLeft / _durationSeconds,
                        color: widget.alert.typeColor,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        strokeWidth: 3,
                      ),
                      Text(
                        '$_secondsLeft',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.alert.clipUrl != null &&
                widget.alert.clipUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _VideoPreview(
                controller: _controller,
                failed: _videoFailed,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Color(0xFF3A3A3A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Alert'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool failed;

  const _VideoPreview({
    required this.controller,
    required this.failed,
  });

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return const _VideoShell(
        child: Text(
          'Clip unavailable',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final controller = this.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const _VideoShell(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _VideoShell extends StatelessWidget {
  final Widget child;

  const _VideoShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Center(child: child),
    );
  }
}
