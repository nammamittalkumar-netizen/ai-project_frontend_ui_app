import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
    final colors = AppColors.of(context);
    return PopupMenuButton<int>(
      icon: Icon(Icons.more_vert_rounded, color: colors.onSurface),
      tooltip: 'More',
      color: colors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border),
      ),
      onSelected: onNavigate,
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: reportsIndex,
          enabled: currentIndex != reportsIndex,
          child: Row(
            children: [
              Icon(Icons.description_rounded, color: colors.onSurface),
              const SizedBox(width: 12),
              Text('Reports', style: TextStyle(color: colors.onSurface)),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: settingsIndex,
          enabled: currentIndex != settingsIndex,
          child: Row(
            children: [
              Icon(Icons.settings_rounded, color: colors.onSurface),
              const SizedBox(width: 12),
              Text('Settings', style: TextStyle(color: colors.onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}
