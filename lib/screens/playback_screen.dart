import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../models/camera.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import '../widgets/main_overflow_menu.dart';

class PlaybackScreen extends ConsumerStatefulWidget {
  final ValueChanged<int> onNavigate;
  final int currentIndex;

  const PlaybackScreen({
    super.key,
    required this.onNavigate,
    required this.currentIndex,
  });

  @override
  ConsumerState<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends ConsumerState<PlaybackScreen> {
  String? _cameraId;
  DateTime _date = DateTime.now();
  String _range = 'Last 24 Hours';
  bool _playing = false;
  bool _loadingRecordings = false;
  List<RecordingItem> _recordings = const [];
  VideoPlayerController? _videoController;
  int _currentRecordingIndex = -1;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameras = ref.watch(camerasProvider).valueOrNull ?? [];
    final selected = _selectedCamera(cameras);
    final connection = ref.watch(connectionStatusProvider).valueOrNull;
    final isOffline = connection == ConnectionStatus.reconnecting;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text(
          'Playback',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          MainOverflowMenu(
            onNavigate: widget.onNavigate,
            currentIndex: widget.currentIndex,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isOffline) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1D1D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5A2A2A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off_rounded, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Server offline. Playback will reconnect automatically.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _videoController != null &&
                      _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : Center(
                      child: Icon(
                        _playing
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: Colors.white70,
                        size: 74,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentRecordingIndex > 0
                          ? () => _playRecording(
                                _recordings[_currentRecordingIndex - 1],
                              )
                          : null,
                      icon: const Icon(Icons.skip_previous_rounded),
                      color: _currentRecordingIndex > 0
                          ? Colors.white
                          : Colors.white24,
                    ),
                    IconButton.filled(
                      onPressed: _togglePlayback,
                      icon: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: accentColor,
                      ),
                    ),
                    IconButton(
                      onPressed: _currentRecordingIndex >= 0 &&
                              _currentRecordingIndex <
                                  _recordings.length - 1
                          ? () => _playRecording(
                                _recordings[_currentRecordingIndex + 1],
                              )
                          : null,
                      icon: const Icon(Icons.skip_next_rounded),
                      color: _currentRecordingIndex >= 0 &&
                              _currentRecordingIndex < _recordings.length - 1
                          ? Colors.white
                          : Colors.white24,
                    ),
                    Expanded(
                      child: Slider(
                        value: _videoProgress(),
                        onChanged: _seekVideo,
                        activeColor: accentColor,
                        inactiveColor: const Color(0xFF333333),
                      ),
                    ),
                    Text(
                      _videoTime(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF2A2A2A)),
                DropdownButtonFormField<String>(
                  initialValue: selected?.id,
                  dropdownColor: const Color(0xFF1A1A1A),
                  decoration: const InputDecoration(labelText: 'Select Camera'),
                  items: cameras
                      .map(
                        (camera) => DropdownMenuItem(
                          value: camera.id,
                          child: Text(camera.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _cameraId = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _date = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_month_rounded),
                        label:
                            Text('${_date.day}/${_date.month}/${_date.year}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF2A2A2A)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _range,
                        dropdownColor: const Color(0xFF1A1A1A),
                        decoration: const InputDecoration(labelText: 'Range'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Last 24 Hours',
                            child: Text('Last 24 Hours'),
                          ),
                          DropdownMenuItem(
                            value: 'Last 7 Days',
                            child: Text('Last 7 Days'),
                          ),
                          DropdownMenuItem(
                            value: 'Last 30 Days',
                            child: Text('Last 30 Days'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _range = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadingRecordings
                        ? null
                        : () => _loadRecordings(selected),
                    icon: _loadingRecordings
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.manage_search_rounded),
                    label: Text(
                        _loadingRecordings ? 'Loading...' : 'Load Recordings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!isOffline)
            ..._recordings.map(
              (recording) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.movie_rounded, color: Colors.grey),
                  title: Text(
                    DateFormat('MMM d, hh:mm a').format(recording.startTime),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${recording.cameraName} - ${recording.durationSeconds.round()}s',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.grey,
                  ),
                  onTap: () => _playRecording(recording),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Camera? _selectedCamera(List<Camera> cameras) {
    if (cameras.isEmpty) {
      return null;
    }
    final id = _cameraId;
    if (id == null) {
      return cameras.first;
    }
    for (final camera in cameras) {
      if (camera.id == id) {
        return camera;
      }
    }
    return cameras.first;
  }

  int _rangeHours() {
    return switch (_range) {
      'Last 7 Days' => 24 * 7,
      'Last 30 Days' => 24 * 30,
      _ => 24,
    };
  }

  Future<void> _loadRecordings(Camera? selected) async {
    final cameraId = _cameraId ?? selected?.id;
    if (cameraId == null || cameraId.isEmpty) {
      return;
    }
    setState(() => _loadingRecordings = true);
    final recordings = await ref.read(apiServiceProvider).getPlayback(
          cameraId: cameraId,
          date: _date,
          rangeHours: _rangeHours(),
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _recordings = recordings;
      _loadingRecordings = false;
      _currentRecordingIndex = -1;
    });
  }

  Future<void> _playRecording(RecordingItem recording) async {
    final oldController = _videoController;
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(recording.videoUrl));
    setState(() {
      _videoController = controller;
      _playing = false;
      _currentRecordingIndex = _recordings.indexOf(recording);
    });
    await oldController?.dispose();
    await controller.initialize();
    await controller.play();
    controller.addListener(() {
      if (mounted) {
        setState(() => _playing = controller.value.isPlaying);
      }
    });
    if (mounted) {
      setState(() => _playing = true);
    }
  }

  double _videoProgress() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return _playing ? 0.62 : 0.28;
    }
    final duration = controller.value.duration.inMilliseconds;
    if (duration <= 0) {
      return 0;
    }
    return (controller.value.position.inMilliseconds / duration)
        .clamp(0, 1)
        .toDouble();
  }

  void _seekVideo(double value) {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    final target = Duration(
      milliseconds: (controller.value.duration.inMilliseconds * value).round(),
    );
    controller.seekTo(target);
  }

  Future<void> _togglePlayback() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      setState(() => _playing = !_playing);
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) {
      setState(() => _playing = controller.value.isPlaying);
    }
  }

  String _videoTime() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return '14:32';
    }
    final pos = controller.value.position;
    return '${pos.inMinutes}:${(pos.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
