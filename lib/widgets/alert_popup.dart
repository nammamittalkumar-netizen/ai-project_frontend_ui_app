import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/alert.dart';

class AlertPopup extends StatefulWidget {
  final Alert alert;
  const AlertPopup({super.key, required this.alert});
  @override
  State<AlertPopup> createState() => _AlertPopupState();
}

class _AlertPopupState extends State<AlertPopup> {
  VideoPlayerController? _controller;
  int _secondsLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    if (widget.alert.clipUrl != null) _initVideo(widget.alert.clipUrl!);
  }

  void _initVideo(String url) async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await _controller!.initialize();
    _controller!.play();
    setState(() {});
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) Navigator.of(context).pop();
      } else {
        setState(() => _secondsLeft--);
      }
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Alert header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.alert.typeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.alert.typeIcon, color: widget.alert.typeColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.alert.typeLabel,
                  style: TextStyle(color: widget.alert.typeColor,
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(widget.alert.cameraName,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            // Countdown circle
            SizedBox(
              width: 40, height: 40,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: _secondsLeft / 5,
                  color: widget.alert.typeColor,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                ),
                Text('$_secondsLeft',
                    style: const TextStyle(color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),

          const SizedBox(height: 16),

          // 5-second video clip
          if (_controller != null && _controller!.value.isInitialized)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else if (widget.alert.clipUrl != null)
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: CircularProgressIndicator(color: Colors.red)),
            ),

          const SizedBox(height: 16),

          // Buttons
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('View Alert', style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}