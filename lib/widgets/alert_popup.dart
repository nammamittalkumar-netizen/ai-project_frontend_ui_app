import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/alert.dart';
import '../theme/app_colors.dart';
import '../theme/app_ui.dart';

class AlertPopup extends StatefulWidget {
  final Alert alert;
  final VoidCallback? onViewAlert;
  final bool autoDismiss;

  const AlertPopup({
    super.key,
    required this.alert,
    this.onViewAlert,
    this.autoDismiss = false,
  });

  @override
  State<AlertPopup> createState() => _AlertPopupState();
}

class _AlertPopupState extends State<AlertPopup> {
  static const int _durationSeconds = 5;

  VideoPlayerController? _controller;
  Timer? _timer;
  int _secondsLeft = _durationSeconds;
  bool _videoFailed = false;
  bool _isHeld = false;

  bool get _hasMedia =>
      widget.alert.isDetection &&
      ((widget.alert.clipUrl != null && widget.alert.clipUrl!.isNotEmpty) ||
          (widget.alert.snapshotUrl != null &&
              widget.alert.snapshotUrl!.isNotEmpty));

  bool get _isAutoClosing => widget.autoDismiss && !_isHeld;

  @override
  void initState() {
    super.initState();
    if (widget.autoDismiss) {
      _playAlertSignal();
      _startCountdown();
    }
    _initializeVideo();
  }

  Future<void> _playAlertSignal() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.heavyImpact();
      // Double-tap haptic for critical security alerts
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  Future<void> _initializeVideo() async {
    if (widget.alert.isSystem) return;
    final clipUrl = widget.alert.clipUrl;
    if (clipUrl == null || clipUrl.isEmpty) return;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(clipUrl));
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(!widget.autoDismiss || _isHeld);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isHeld) {
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

  Future<void> _holdAlert() async {
    if (!widget.autoDismiss || _isHeld) return;

    _timer?.cancel();
    if (_controller?.value.isInitialized ?? false) {
      await _controller?.setLooping(true);
    }
    if (mounted) setState(() => _isHeld = true);
  }

  Future<void> _openFullScreen() async {
    await _holdAlert();
    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenIncidentViewer(alert: widget.alert),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.border),
              boxShadow: appCardShadow,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color:
                                widget.alert.typeColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
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
                          widget.alert.displaySource,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceDim,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isAutoClosing) ...[
                    const SizedBox(width: 10),
                    _CountdownHoldControl(
                      secondsLeft: _secondsLeft,
                      durationSeconds: _durationSeconds,
                      color: widget.alert.typeColor,
                      onHold: _holdAlert,
                    ),
                  ],
                ],
              ),
              if (!_isAutoClosing && widget.alert.isDetection) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Review mode',
                    style: TextStyle(
                      color: widget.alert.typeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (widget.alert.isDetection) ...[
                if (widget.alert.clipUrl != null &&
                    widget.alert.clipUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _VideoPreview(
                    controller: _controller,
                    failed: _videoFailed,
                    snapshotUrl: widget.alert.snapshotUrl,
                  ),
                ] else if (widget.alert.snapshotUrl != null &&
                    widget.alert.snapshotUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SnapshotPreview(url: widget.alert.snapshotUrl!),
                ],
              ],
              const SizedBox(height: 16),
              if (_isAutoClosing)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.onSurfaceDim,
                              side: BorderSide(color: colors.buttonBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Dismiss'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).maybePop();
                              widget.onViewAlert?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('View Alert'),
                          ),
                        ),
                      ],
                    ),
                    if (_hasMedia) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openFullScreen,
                          icon: const Icon(Icons.fullscreen_rounded),
                          label: const Text(
                            'Full Screen',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.alert.typeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.onSurfaceDim,
                          side: BorderSide(color: colors.buttonBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    if (_hasMedia) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openFullScreen,
                          icon: const Icon(Icons.fullscreen_rounded),
                          label: const Text(
                            'Full Screen',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.alert.typeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}

class _CountdownHoldControl extends StatelessWidget {
  final int secondsLeft;
  final int durationSeconds;
  final Color color;
  final VoidCallback onHold;

  const _CountdownHoldControl({
    required this.secondsLeft,
    required this.durationSeconds,
    required this.color,
    required this.onHold,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Tooltip(
      message: 'Hold alert',
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: onHold,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              CircularProgressIndicator(
                value: secondsLeft / durationSeconds,
                color: color,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                strokeWidth: 3,
              ),
              Text(
                '$secondsLeft',
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: color, width: 1.4),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.timer_off_rounded,
                    color: color,
                    size: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenIncidentViewer extends StatefulWidget {
  final Alert alert;

  const _FullScreenIncidentViewer({required this.alert});

  @override
  State<_FullScreenIncidentViewer> createState() =>
      _FullScreenIncidentViewerState();
}

class _FullScreenIncidentViewerState extends State<_FullScreenIncidentViewer> {
  VideoPlayerController? _controller;
  bool _videoFailed = false;
  bool get _hasClip =>
      widget.alert.clipUrl != null && widget.alert.clipUrl!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (_hasClip) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final clipUrl = widget.alert.clipUrl;
    if (clipUrl == null || clipUrl.isEmpty) return;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(clipUrl));
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshotUrl = widget.alert.snapshotUrl;
    final hasSnapshot = snapshotUrl != null && snapshotUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: _buildMedia(hasSnapshot, snapshotUrl),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
                color: Colors.black.withValues(alpha: 0.72),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.alert.typeLabelWithEmoji,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.alert.displaySource,
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
                    if (_controller?.value.isInitialized ?? false)
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: _controller!,
                        builder: (context, value, _) {
                          return IconButton(
                            tooltip: value.isPlaying ? 'Pause' : 'Play',
                            onPressed: () {
                              value.isPlaying
                                  ? _controller?.pause()
                                  : _controller?.play();
                            },
                            icon: Icon(
                              value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            color: Colors.white,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(bool hasSnapshot, String? snapshotUrl) {
    final controller = _controller;
    final clipUrl = widget.alert.clipUrl;
    final hasClip = clipUrl != null && clipUrl.isNotEmpty;

    if (!_videoFailed && controller != null && controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      );
    }

    if (!_videoFailed && hasClip) {
      return CircularProgressIndicator(color: widget.alert.typeColor);
    }

    if (hasSnapshot) {
      return InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Image.network(
          snapshotUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const _FullScreenMessage(
            text: 'Snapshot unavailable',
          ),
        ),
      );
    }

    return const _FullScreenMessage(text: 'Incident media unavailable');
  }
}

class _FullScreenMessage extends StatelessWidget {
  final String text;

  const _FullScreenMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.grey, fontSize: 14),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool failed;
  final String? snapshotUrl;

  const _VideoPreview({
    required this.controller,
    required this.failed,
    this.snapshotUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (failed) {
      if (snapshotUrl != null && snapshotUrl!.isNotEmpty) {
        return _SnapshotPreview(url: snapshotUrl!);
      }
      return const _VideoShell(
        child: Text('Clip unavailable', style: TextStyle(color: Colors.grey)),
      );
    }

    final controller = this.controller;
    if (controller == null || !controller.value.isInitialized) {
      return _VideoShell(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
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

class _SnapshotPreview extends StatelessWidget {
  final String url;

  const _SnapshotPreview({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _VideoShell(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        },
        errorBuilder: (_, __, ___) => const _VideoShell(
          child: Text(
            'Snapshot unavailable',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class _VideoShell extends StatelessWidget {
  final Widget child;

  const _VideoShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Center(child: child),
    );
  }
}
