import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.navBg,
    required this.border,
    required this.navBorder,
    required this.onSurface,
    required this.onSurfaceDim,
    required this.buttonBorder,
    required this.feedBg,
    required this.feedIcon,
  });

  final Color background;
  final Color surface;
  final Color navBg;
  final Color border;
  final Color navBorder;
  final Color onSurface;
  final Color onSurfaceDim;
  final Color buttonBorder;
  final Color feedBg;
  final Color feedIcon;

  static const dark = AppColors(
    background: Color(0xFF111111),
    surface: Color(0xFF1A1A1A),
    navBg: Color(0xFF161616),
    border: Color(0xFF2A2A2A),
    navBorder: Color(0xFF242424),
    onSurface: Colors.white,
    onSurfaceDim: Colors.grey,
    buttonBorder: Color(0xFF3A3A3A),
    feedBg: Color(0xFF222222),
    feedIcon: Color(0xFF555555),
  );

  static const light = AppColors(
    background: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    navBg: Color(0xFFF8F8FA),
    border: Color(0xFFE0E0E0),
    navBorder: Color(0xFFE2E2E2),
    onSurface: Color(0xFF1A1A1A),
    onSurfaceDim: Color(0xFF777777),
    buttonBorder: Color(0xFFD0D0D0),
    feedBg: Color(0xFFE8E8E8),
    feedIcon: Color(0xFFAAAAAA),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? navBg,
    Color? border,
    Color? navBorder,
    Color? onSurface,
    Color? onSurfaceDim,
    Color? buttonBorder,
    Color? feedBg,
    Color? feedIcon,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      navBg: navBg ?? this.navBg,
      border: border ?? this.border,
      navBorder: navBorder ?? this.navBorder,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceDim: onSurfaceDim ?? this.onSurfaceDim,
      buttonBorder: buttonBorder ?? this.buttonBorder,
      feedBg: feedBg ?? this.feedBg,
      feedIcon: feedIcon ?? this.feedIcon,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      border: Color.lerp(border, other.border, t)!,
      navBorder: Color.lerp(navBorder, other.navBorder, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceDim: Color.lerp(onSurfaceDim, other.onSurfaceDim, t)!,
      buttonBorder: Color.lerp(buttonBorder, other.buttonBorder, t)!,
      feedBg: Color.lerp(feedBg, other.feedBg, t)!,
      feedIcon: Color.lerp(feedIcon, other.feedIcon, t)!,
    );
  }
}
