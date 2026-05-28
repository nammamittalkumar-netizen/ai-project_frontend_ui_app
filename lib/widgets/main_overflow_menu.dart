import 'package:flutter/material.dart';

class MainOverflowMenu extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  final int currentIndex;

  const MainOverflowMenu({
    super.key,
    required this.onNavigate,
    required this.currentIndex,
  });

  static const reportsIndex = 4;
  static const settingsIndex = 5;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'More',
      color: const Color(0xFF1A1A1A),
      onSelected: onNavigate,
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: reportsIndex,
          enabled: currentIndex != reportsIndex,
          child: const Row(
            children: [
              Icon(Icons.description_rounded, color: Colors.white70),
              SizedBox(width: 12),
              Text('Reports'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: settingsIndex,
          enabled: currentIndex != settingsIndex,
          child: const Row(
            children: [
              Icon(Icons.settings_rounded, color: Colors.white70),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
      ],
    );
  }
}
