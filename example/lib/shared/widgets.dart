// Small pieces of chrome shared by both screens, plus the colours.

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

/// The orange of the route line and markers, and the casing under it.
const int activityOrange = 0xFFF26B1D;
const int activityOrangeDark = 0xFF8A3A0C;

/// The navigation blues.
const int navBlue = 0xFF3B82F6;
const int navBlueDark = 0xFF1D4ED8;

/// The part of the route already driven.
const int navTraveled = 0xFFB7C0D3;

/// The maneuver banner background.
const Color bannerNavy = Color(0xFF2E3A52);

/// Monospace font for the journal captions, per platform.
String get monoFont => Platform.isIOS ? 'Menlo' : 'monospace';

/// A round glass button with an icon, as on the journal screen.
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.background,
    required this.foreground,
    this.size = 52,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GlassEffectContainer(
      borderRadius: BorderRadius.circular(99),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: foreground),
        ),
      ),
    );
  }
}

/// A white floating circle button with a shadow, as on the navigation
/// screen (mute, overview, recenter).
class FloatingButton extends StatelessWidget {
  const FloatingButton({super.key, required this.icon, required this.onTap, this.active = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Icon(icon, size: 22, color: active ? const Color(navBlue) : const Color(0xFF1F2937)),
      ),
    );
  }
}

/// A rounded pill with text, as the History button.
class TextPill extends StatelessWidget {
  const TextPill({
    super.key,
    required this.text,
    required this.onTap,
    required this.background,
    required this.foreground,
  });

  final String text;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(24)),
        child: Text(text, style: TextStyle(color: foreground, fontSize: 15, fontFamily: monoFont)),
      ),
    );
  }
}

/// A centred hint shown while a map is still loading.
class LoadingHint extends StatelessWidget {
  const LoadingHint(this.text, {super.key, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: Text(text, style: TextStyle(color: color, fontSize: 13, fontFamily: monoFont)),
        ),
      ),
    );
  }
}
