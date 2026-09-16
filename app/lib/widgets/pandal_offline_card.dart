import 'dart:ui';
import 'package:flutter/material.dart';

import '../config/pandal_theme_tokens.dart';
import '../models/pandal.dart';

enum OfflineSyncStatus { fullyCached, servingStale, offlineOnly }

class PandalOfflineCard extends StatelessWidget {
  final Pandal pandal;
  final double distanceMeters;
  final String walkingEtaText;
  final OfflineSyncStatus syncStatus;
  final VoidCallback onStartRoute;
  final VoidCallback onShowMetro;
  final VoidCallback onToggleBookmark;
  final bool isBookmarked;
  final VoidCallback? onClose;

  const PandalOfflineCard({
    super.key,
    required this.pandal,
    required this.distanceMeters,
    required this.walkingEtaText,
    this.syncStatus = OfflineSyncStatus.fullyCached,
    required this.onStartRoute,
    required this.onShowMetro,
    required this.onToggleBookmark,
    this.isBookmarked = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PandalOfflineThemeTokens>() ??
        const PandalOfflineThemeTokens();

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surfaceCard.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.borderSubtle, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(tokens),
                const SizedBox(height: 12),
                _buildTitle(tokens),
                const SizedBox(height: 12),
                _buildMetadataPills(tokens),
                const SizedBox(height: 10),
                _buildTelemetryAlert(tokens),
                const SizedBox(height: 16),
                _buildActions(tokens),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PandalOfflineThemeTokens tokens) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tokens.offlineBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tokens.offlineFg.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.offlineFg,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'AVAILABLE OFFLINE',
                style: TextStyle(
                  color: tokens.offlineFg,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          pandal.zoneLabel,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onToggleBookmark,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              isBookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isBookmarked ? tokens.crimsonVelvet : Colors.white54,
              size: 22,
            ),
          ),
        ),
        if (onClose != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.close_rounded, color: Colors.white54, size: 20),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitle(PandalOfflineThemeTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                pandal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (pandal.themeType != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Text(
                  pandal.themeType!,
                  style: TextStyle(
                    color: tokens.festivalGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (pandal.bengaliName != null && pandal.bengaliName!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            pandal.bengaliName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              fontFamily: 'Anek Bangla',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataPills(PandalOfflineThemeTokens tokens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildChip(
            icon: Icons.directions_walk_rounded,
            label: '$walkingEtaText (${(distanceMeters / 1000).toStringAsFixed(1)} km)',
            iconColor: tokens.festivalGold,
          ),
          const SizedBox(width: 8),
          if (pandal.nearestMetro != null) ...[
            _buildChip(
              icon: Icons.subway_rounded,
              label: pandal.nearestMetro!,
              iconColor: Colors.lightBlueAccent,
            ),
            const SizedBox(width: 8),
          ],
          if (pandal.rating != null)
            _buildChip(
              icon: Icons.star_rounded,
              label: pandal.rating!.toStringAsFixed(1),
              iconColor: Colors.amberAccent,
            ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xFF22232C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE4E4E7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryAlert(PandalOfflineThemeTokens tokens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tokens.staleBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.staleFg.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 13, color: tokens.staleFg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Congested cell towers detected. Routing using offline geodesic model.',
              style: TextStyle(
                color: tokens.staleFg,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(PandalOfflineThemeTokens tokens) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: onStartRoute,
            icon: const Icon(Icons.navigation_rounded, size: 16),
            label: const Text(
              'Walk Guide',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.crimsonVelvet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: onShowMetro,
            icon: const Icon(Icons.train_rounded, size: 15),
            label: const Text(
              'Metro Route',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.festivalGold,
              side: BorderSide(color: tokens.festivalGold.withValues(alpha: 0.4), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
