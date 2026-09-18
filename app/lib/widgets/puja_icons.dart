import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Cultural icon identifiers for the 14 Durga Puja festival symbols.
enum PujaIconType {
  shankha('assets/icons/shankha.png', 'Shankha (Conch Shell)'),
  dhaki('assets/icons/dhaki.png', 'Dhaki (Dhak Drummer)'),
  dhunuchiPriest('assets/icons/dhunuchi_priest.png', 'Priest with Dhunuchi'),
  durgaFace('assets/icons/durga_face.png', 'Durga Face'),
  ashtabhujaDevi('assets/icons/ashtabhuja_devi.png', 'Ashtabhuja Devi (Multi-armed Goddess)'),
  durgaEyes('assets/icons/durga_eyes.png', 'Durga Eyes'),
  trishulEyes('assets/icons/trishul_eyes.png', 'Trishul with Eyes'),
  durgaSunTrishul('assets/icons/durga_sun_trishul.png', 'Durga Face with Trishuls'),
  gada('assets/icons/gada.png', 'Gada (Mace)'),
  kalash('assets/icons/kalash.png', 'Kalash (Sacred Pot)'),
  ashtabhujaVariant('assets/icons/ashtabhuja_variant.png', 'Multi-armed Goddess (Variant)'),
  dhakDrum('assets/icons/dhak_drum.png', 'Dhak with Sticks'),
  bhogSweets('assets/icons/bhog_sweets.png', 'Bhog / Sweets Bowl'),
  trishulDiya('assets/icons/trishul_diya.png', 'Trishul with Diya');

  final String assetPath;
  final String label;
  const PujaIconType(this.assetPath, this.label);

  String get goldAssetPath => assetPath.replaceAll('.png', '_gold.png');
  String get crimsonAssetPath => assetPath.replaceAll('.png', '_crimson.png');
}

/// A creative, themed Flutter icon widget displaying authentic Durga Puja festival symbols.
class PujaIcon extends StatelessWidget {
  final PujaIconType type;
  final double size;
  final Color? color;
  final String? semanticLabel;

  const PujaIcon(
    this.type, {
    super.key,
    this.size = 30.0,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final effectiveColor = color ?? iconTheme.color ?? PujaColors.festivalGold;
    final effectiveSize = size;

    return Semantics(
      label: semanticLabel ?? type.label,
      child: Image.asset(
        type.assetPath,
        width: effectiveSize,
        height: effectiveSize,
        fit: BoxFit.contain,
        color: effectiveColor,
        colorBlendMode: BlendMode.srcIn,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  // --- Static helper constructors for quick inline use ---

  static Widget durgaEyes({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.durgaEyes, size: size, color: color, key: key);

  static Widget durgaFace({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.durgaFace, size: size, color: color, key: key);

  static Widget ashtabhujaDevi({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.ashtabhujaDevi, size: size, color: color, key: key);

  static Widget ashtabhujaVariant({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.ashtabhujaVariant, size: size, color: color, key: key);

  static Widget dhaki({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.dhaki, size: size, color: color, key: key);

  static Widget dhakDrum({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.dhakDrum, size: size, color: color, key: key);

  static Widget trishulEyes({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.trishulEyes, size: size, color: color, key: key);

  static Widget trishulDiya({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.trishulDiya, size: size, color: color, key: key);

  static Widget durgaSunTrishul({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.durgaSunTrishul, size: size, color: color, key: key);

  static Widget bhogSweets({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.bhogSweets, size: size, color: color, key: key);

  static Widget shankha({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.shankha, size: size, color: color, key: key);

  static Widget dhunuchiPriest({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.dhunuchiPriest, size: size, color: color, key: key);

  static Widget kalash({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.kalash, size: size, color: color, key: key);

  static Widget gada({double size = 30, Color? color, Key? key}) =>
      PujaIcon(PujaIconType.gada, size: size, color: color, key: key);

  /// ImageProvider for use with NavigationDestination, Tab, or standard ImageIcon
  static ImageProvider provider(PujaIconType type) => AssetImage(type.assetPath);
}

/// Circular or rounded badge showcasing a Durga Puja icon with glowing border
class PujaIconBadge extends StatelessWidget {
  final PujaIconType type;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final BoxBorder? border;

  const PujaIconBadge(
    this.type, {
    super.key,
    this.size = 52.0,
    this.iconSize = 34.0,
    this.backgroundColor,
    this.iconColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark
            ? PujaColors.festivalGold.withValues(alpha: 0.12)
            : PujaColors.goldSoft);
    final ic = iconColor ?? (isDark ? PujaColors.festivalGold : PujaColors.crimsonVelvet);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border ??
            Border.all(
              color: PujaColors.festivalGold.withValues(alpha: 0.35),
              width: 1.0,
            ),
      ),
      alignment: Alignment.center,
      child: PujaIcon(
        type,
        size: iconSize,
        color: ic,
      ),
    );
  }
}
