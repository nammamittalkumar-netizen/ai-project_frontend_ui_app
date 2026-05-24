import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/camera.dart';
import '../providers/providers.dart';
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

  @override
  Widget build(BuildContext context) {
    final cameras = ref.watch(camerasProvider).valueOrNull ?? [];
    final selected = _selectedCamera(cameras);

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
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Center(
              child: Icon(
                _playing
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                color: Colors.white70,
                size: 74,
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
                      onPressed: () {},
                      icon: const Icon(Icons.skip_previous_rounded),
                      color: Colors.white,
                    ),
                    IconButton.filled(
                      onPressed: () => setState(() => _playing = !_playing),
                      icon: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      style: IconButton.styleFrom(backgroundColor: Colors.red),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.skip_next_rounded),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Slider(
                        value: _playing ? 0.62 : 0.28,
                        onChanged: (_) {},
                        activeColor: Colors.red,
                        inactiveColor: const Color(0xFF333333),
                      ),
                    ),
                    const Text(
                      '14:32',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
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
              ],
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
}
