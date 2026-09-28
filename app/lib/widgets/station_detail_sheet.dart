import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../models/station.dart';
import '../repositories/local_pandal_repository.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/haversine.dart';
import 'custom_trail_planner_dialog.dart';

/// Modal bottom sheet displaying station information, nearby pandals,
/// walking route actions, and official train status deep links.
class StationDetailSheet extends StatefulWidget {
  const StationDetailSheet({
    super.key,
    required this.station,
    this.onRouteToPandal,
    this.onClose,
  });

  final Station station;
  final void Function(Pandal pandal)? onRouteToPandal;
  final VoidCallback? onClose;

  static Future<void> show(
    BuildContext context, {
    required Station station,
    void Function(Pandal pandal)? onRouteToPandal,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StationDetailSheet(
        station: station,
        onRouteToPandal: onRouteToPandal,
      ),
    );
  }

  @override
  State<StationDetailSheet> createState() => _StationDetailSheetState();
}

class _StationDetailSheetState extends State<StationDetailSheet> {
  final LocalAssetPandalRepository _pandalRepo = LocalAssetPandalRepository();
  List<({Pandal pandal, int distanceM})> _nearbyPandals = [];
  bool _isLoadingPandals = true;

  @override
  void initState() {
    super.initState();
    _loadNearbyPandals();
  }

  Future<void> _loadNearbyPandals() async {
    final all = await _pandalRepo.all();
    final stnLoc = widget.station.toLatLng();

    final mapped = all.map((p) {
      final d = haversineMeters(stnLoc.latitude, stnLoc.longitude, p.lat, p.lng);
      return (pandal: p, distanceM: d.toInt());
    }).toList();

    mapped.sort((a, b) => a.distanceM.compareTo(b.distanceM));

    if (mounted) {
      setState(() {
        _nearbyPandals = mapped.take(6).toList();
        _isLoadingPandals = false;
      });
    }
  }

  Future<void> _openLiveTrainStatus() async {
    final isRail = widget.station.isRail;
    final Uri url;
    if (isRail) {
      // Official National Train Enquiry System (NTES)
      final code = widget.station.code;
      if (code != null && code.isNotEmpty) {
        url = Uri.parse('https://enquiry.indianrail.gov.in/mntes/');
      } else {
        url = Uri.parse('https://enquiry.indianrail.gov.in/');
      }
    } else {
      // Official Kolkata Metro portal
      url = Uri.parse('https://mtp.indianrailways.gov.in/');
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[StationDetailSheet] Error opening URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stn = widget.station;
    final livePos = LocationService.instance.currentPositionSync;

    double? distFromUserKm;
    if (livePos != null) {
      distFromUserKm = haversineMeters(
            livePos.latitude,
            livePos.longitude,
            stn.lat,
            stn.lon,
          ) /
          1000.0;
    }

    final accentColor = stn.isRail ? PujaColors.railwayPurple : const Color(0xFF0057B8);

    return DraggableScrollableSheet(
      initialChildSize: 0.60,
      minChildSize: 0.35,
      maxChildSize: 0.90,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141013) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                      ),
                      child: Icon(
                        stn.isRail ? Icons.train_rounded : Icons.subway_rounded,
                        color: accentColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  stn.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (stn.code != null && stn.code!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    stn.code!,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (stn.nameBn != null && stn.nameBn!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              stn.nameBn!,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            [
                              stn.network ?? (stn.isRail ? 'Eastern Railway' : 'Kolkata Metro'),
                              if (distFromUserKm != null) '${distFromUserKm.toStringAsFixed(1)} km away',
                            ].join(' • '),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Action buttons row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    // Start Trail here
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.alt_route_rounded, size: 18),
                        label: const Text('Start Hopping Here'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PujaColors.durgaRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          CustomTrailPlannerDialog.show(
                            context,
                            initialLocation: stn.toLatLng(),
                            initialLocationLabel: stn.displayName,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // External Train Status Deep Link
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(stn.isRail ? 'Live NTES' : 'Metro Info'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _openLiveTrainStatus,
                    ),
                  ],
                ),
              ),

              // Nearby Pandals section
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    Text(
                      'Nearby Pandals (Walkable)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingPandals)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ))
                    else if (_nearbyPandals.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No pandals found in the vicinity.'),
                      )
                    else
                      ..._nearbyPandals.map((item) {
                        final p = item.pandal;
                        final d = item.distanceM;
                        final dStr = d < 1000 ? '$d m' : '${(d / 1000).toStringAsFixed(1)} km';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          color: isDark ? const Color(0xFF1E191E) : const Color(0xFFF7F5F7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              p.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${p.zone.label} • $dStr walk',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(60, 32),
                              ),
                              child: const Text('Walk', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onRouteToPandal?.call(p);
                              },
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 16),
                    // Attribution Notice (ODbL Requirement)
                    Center(
                      child: Text(
                        'Station geometry © OpenStreetMap contributors (ODbL)\nStation codes courtesy of Wikidata (CC0)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
