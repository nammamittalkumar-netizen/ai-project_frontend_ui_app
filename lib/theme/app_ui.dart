import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared premium design-system tokens & helpers (visual layer only).
///
/// These widgets/constants give every screen the same matte, large-radius,
/// softly-shadowed "bento dashboard" aesthetic without touching any
/// business logic, data bindings, routes, or state.

// ── Accent palette ─────────────────────────────────────────────────────────
const appAccentLime = Color(0xFFC6F24E);
const appAccentYellow = Color(0xFFF5D24C);
const appAccentLavender = Color(0xFFCEC2F2);
const appAccentBlue = Color(0xFF63A8FF);
const appOnFilled = Color(0xFF14140E);

// ── Geometry ───────────────────────────────────────────────────────────────
const double kCardRadius = 24;
const double kTileRadius = 20;
const double kButtonRadius = 16;
const EdgeInsets kScreenPadding = EdgeInsets.fromLTRB(20, 4, 20, 28);

const List<BoxShadow> appCardShadow = [
  BoxShadow(color: Color(0x2E000000), blurRadius: 22, offset: Offset(0, 10)),
];

/// Standard floating card decoration.
BoxDecoration appCard(
  AppColors colors, {
  double radius = kCardRadius,
  Color? color,
  Color? borderColor,
  bool shadow = true,
}) {
  return BoxDecoration(
    color: color ?? colors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? colors.border),
    boxShadow: shadow ? appCardShadow : null,
  );
}

/// Premium rounded button shape used across the app.
RoundedRectangleBorder get appButtonShape =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius));

/// Large hero header (big bold title + optional subtitle), matching the Live
/// screen. Use as the first child of a screen's scroll view.
class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: colors.onSurfaceDim,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Section heading used between cards (22px bold).
class AppSectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsets padding;

  const AppSectionTitle(
    this.title, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 26, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: padding,
      child: Text(
        title,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
    );
  }
}
