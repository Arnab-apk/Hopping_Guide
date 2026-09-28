import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/live_tracking_enhancements.dart';
import '../services/location_service.dart';

/// Map type enum (since flutter_map doesn't expose one)
enum MapType { standard, satellite, terrain, hybrid }

/// Location mode for MyLocationButton
enum LocationMode { none, centered, following, compass }

/// Google Maps-style floating action button with customizable actions
class MapFloatingActionButton extends StatelessWidget {
  const MapFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
    this.label,
    this.onLongPress,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;
  final String? label;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primaryContainer;
    final fg = foregroundColor ?? theme.colorScheme.onPrimaryContainer;

    Widget btn;
    if (isExtended) {
      btn = FloatingActionButton.extended(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: bg,
        foregroundColor: fg,
        icon: Icon(icon),
        label: Text(label!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
    } else {
      btn = FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(icon),
      );
    }

    // Wrap with GestureDetector for long press if needed
    if (onLongPress != null) {
      btn = GestureDetector(
        onLongPress: onLongPress,
        child: btn,
      );
    }

    return Semantics(
      button: true,
      label: tooltip ?? label ?? '',
      child: btn,
    );
  }
}

/// Google Maps-style map type selector (Default, Satellite, Terrain, Traffic)
class MapTypeSelector extends StatefulWidget {
  const MapTypeSelector({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
    this.showTrafficToggle = true,
    this.showCrowdToggle = true,
    this.show3DToggle = true,
    this.showStationsToggle = true,
    this.stationsEnabled = false,
    this.onStationsToggled,
  });

  final MapType currentType;
  final ValueChanged<MapType> onTypeChanged;
  final bool showTrafficToggle;
  final bool showCrowdToggle;
  final bool show3DToggle;
  final bool showStationsToggle;
  final bool stationsEnabled;
  final ValueChanged<bool>? onStationsToggled;

  @override
  State<MapTypeSelector> createState() => _MapTypeSelectorState();
}

class _MapTypeSelectorState extends State<MapTypeSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _expanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Collapsed: Current map type button
        Material(
          color: theme.colorScheme.surfaceContainerHigh,
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getMapTypeIcon(widget.currentType), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _getMapTypeLabel(widget.currentType),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnimation),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Expanded: Map type options + toggles
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Map type options
                ...MapType.values.map((type) => _MapTypeOption(
                      type: type,
                      selected: type == widget.currentType,
                      onTap: () {
                        widget.onTypeChanged(type);
                        _toggle();
                      },
                    )),
                if (widget.showTrafficToggle || widget.showCrowdToggle || widget.show3DToggle || widget.showStationsToggle)
                  const Divider(height: 16),
                // Toggles
                if (widget.showStationsToggle)
                  _MapToggleOption(
                    icon: Icons.train_rounded,
                    label: 'Railway & Metro',
                    value: widget.stationsEnabled,
                    onChanged: (v) {
                      widget.onStationsToggled?.call(v);
                    },
                  ),
                if (widget.showTrafficToggle)
                  _MapToggleOption(
                    icon: Icons.traffic_rounded,
                    label: 'Live Traffic',
                    value: false,
                    onChanged: (v) {},
                  ),
                if (widget.showCrowdToggle)
                  _MapToggleOption(
                    icon: Icons.people_alt_rounded,
                    label: 'Crowd Density',
                    value: false,
                    onChanged: (v) {},
                  ),
                if (widget.show3DToggle)
                  _MapToggleOption(
                    icon: Icons.terrain_rounded,
                    label: '3D Buildings',
                    value: false,
                    onChanged: (v) {},
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getMapTypeIcon(MapType type) {
    switch (type) {
      case MapType.standard:
        return Icons.map_rounded;
      case MapType.satellite:
        return Icons.satellite_alt_rounded;
      case MapType.terrain:
        return Icons.terrain_rounded;
      case MapType.hybrid:
        return Icons.layers_rounded;
    }
  }

  String _getMapTypeLabel(MapType type) {
    switch (type) {
      case MapType.standard:
        return 'Default';
      case MapType.satellite:
        return 'Satellite';
      case MapType.terrain:
        return 'Terrain';
      case MapType.hybrid:
        return 'Hybrid';
    }
  }
}

class _MapTypeOption extends StatelessWidget {
  const _MapTypeOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final MapType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              _getIcon(type),
              size: 22,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getLabel(type),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 20, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(MapType type) {
    switch (type) {
      case MapType.standard:
        return Icons.map_rounded;
      case MapType.satellite:
        return Icons.satellite_alt_rounded;
      case MapType.terrain:
        return Icons.terrain_rounded;
      case MapType.hybrid:
        return Icons.layers_rounded;
    }
  }

  String _getLabel(MapType type) {
    switch (type) {
      case MapType.standard:
        return 'Default';
      case MapType.satellite:
        return 'Satellite';
      case MapType.terrain:
        return 'Terrain';
      case MapType.hybrid:
        return 'Hybrid';
    }
  }
}

class _MapToggleOption extends StatelessWidget {
  const _MapToggleOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Google Maps-style "My Location" button with multiple modes
class MyLocationButton extends StatefulWidget {
  const MyLocationButton({
    super.key,
    required this.mapController,
    required this.locationService,
    this.onModeChanged,
  });

  final MapController mapController;
  final LocationService locationService;
  final ValueChanged<LocationMode>? onModeChanged;

  @override
  State<MyLocationButton> createState() => _MyLocationButtonState();
}

class _MyLocationButtonState extends State<MyLocationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  LocationMode _mode = LocationMode.none;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _updateModeFromLocation();
    widget.locationService.addListener(_updateModeFromLocation);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    widget.locationService.removeListener(_updateModeFromLocation);
    super.dispose();
  }

  void _updateModeFromLocation() {
    final hasLocation = widget.locationService.hasRealLocation;
    final isTracking = widget.locationService.isLiveTracking;

    LocationMode newMode;
    if (!hasLocation) {
      newMode = LocationMode.none;
    } else if (isTracking) {
      newMode = LocationMode.following;
    } else {
      newMode = LocationMode.centered;
    }

    if (newMode != _mode) {
      setState(() => _mode = newMode);
      widget.onModeChanged?.call(newMode);
    }
  }

  void _cycleMode() {
    final modes = LocationMode.values.where((m) => m != LocationMode.none).toList();
    final currentIndex = modes.indexOf(_mode);
    final nextIndex = (currentIndex + 1) % modes.length;
    final nextMode = modes[nextIndex];
    _applyMode(nextMode);
  }

  void _applyMode(LocationMode mode) {
    switch (mode) {
      case LocationMode.centered:
        _centerOnLocation();
        break;
      case LocationMode.following:
        if (!widget.locationService.isLiveTracking) {
          widget.locationService.startLiveTracking();
        }
        _centerOnLocation();
        break;
      case LocationMode.compass:
        if (!widget.locationService.isLiveTracking) {
          widget.locationService.startLiveTracking();
        }
        _centerOnLocation();
        break;
      case LocationMode.none:
        break;
    }
  }

  void _centerOnLocation() {
    final pos = widget.locationService.currentPositionSync;
    if (pos != null) {
      widget.mapController.move(
        LatLng(pos.latitude, pos.longitude),
        widget.mapController.camera.zoom.clamp(16.0, 19.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation = widget.locationService.hasRealLocation;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring when following
        if (_mode == LocationMode.following || _mode == LocationMode.compass)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) => Container(
              width: 56 + _pulseController.value * 16,
              height: 56 + _pulseController.value * 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.15 * (1 - _pulseController.value)),
              ),
            ),
          ),
        // Main button
        Material(
          color: _getBackgroundColor(theme),
          elevation: 4,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: hasLocation ? _cycleMode : null,
            onLongPress: hasLocation ? _showModeSheet : null,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: Icon(
                _getIcon(_mode),
                size: 24,
                color: hasLocation ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        // Tooltip badge
        if (_mode == LocationMode.following || _mode == LocationMode.compass)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _mode == LocationMode.compass ? '3D' : 'Follow',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (!widget.locationService.hasRealLocation) {
      return theme.colorScheme.surfaceContainerHigh;
    }
    switch (_mode) {
      case LocationMode.none:
      case LocationMode.centered:
        return theme.colorScheme.primaryContainer;
      case LocationMode.following:
        return theme.colorScheme.primary;
      case LocationMode.compass:
        return theme.colorScheme.secondary;
    }
  }

  IconData _getIcon(LocationMode mode) {
    switch (mode) {
      case LocationMode.none:
        return Icons.my_location_rounded;
      case LocationMode.centered:
        return Icons.my_location_rounded;
      case LocationMode.following:
        return Icons.navigation_rounded;
      case LocationMode.compass:
        return Icons.explore_rounded;
    }
  }

  void _showModeSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _LocationModeSheet(
        currentMode: _mode,
        onSelected: (mode) {
          Navigator.pop(ctx);
          _applyMode(mode);
        },
      ),
    );
  }
}

class _LocationModeSheet extends StatelessWidget {
  const _LocationModeSheet({
    required this.currentMode,
    required this.onSelected,
  });

  final LocationMode currentMode;
  final ValueChanged<LocationMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Location Mode',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          ...LocationMode.values
              .where((m) => m != LocationMode.none)
              .map((mode) => ListTile(
                    leading: Icon(_getIcon(mode)),
                    title: Text(_getLabel(mode), style: GoogleFonts.plusJakartaSans()),
                    subtitle: Text(_getDescription(mode), style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                    trailing: mode == currentMode
                        ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                        : null,
                    onTap: () => onSelected(mode),
                  )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getIcon(LocationMode mode) {
    switch (mode) {
      case LocationMode.centered:
        return Icons.center_focus_strong_rounded;
      case LocationMode.following:
        return Icons.navigation_rounded;
      case LocationMode.compass:
        return Icons.explore_rounded;
      case LocationMode.none:
        return Icons.my_location_rounded;
    }
  }

  String _getLabel(LocationMode mode) {
    switch (mode) {
      case LocationMode.centered:
        return 'Center Once';
      case LocationMode.following:
        return 'Follow Me';
      case LocationMode.compass:
        return 'Follow + Compass';
      case LocationMode.none:
        return 'None';
    }
  }

  String _getDescription(LocationMode mode) {
    switch (mode) {
      case LocationMode.centered:
        return 'Center map on your location once';
      case LocationMode.following:
        return 'Keep map centered as you move';
      case LocationMode.compass:
        return 'Follow with map rotation matching your heading';
      case LocationMode.none:
        return 'Location not available';
    }
  }
}

/// Live route progress HUD (Google Maps-style bottom sheet)
class LiveRouteProgressHUD extends StatelessWidget {
  const LiveRouteProgressHUD({
    super.key,
    required this.metrics,
    required this.destinationName,
    this.onStopNavigation,
    this.onPreviewRoute,
    this.onShareETA,
  });

  final LiveWalkingMetrics metrics;
  final String destinationName;
  final VoidCallback? onStopNavigation;
  final VoidCallback? onPreviewRoute;
  final VoidCallback? onShareETA;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMoving = metrics.isMoving;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Destination header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To $destinationName',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (metrics.etaToDestination != null)
                      Text(
                        'ETA: ${metrics.formattedEta} · ${metrics.formattedDistance}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (onPreviewRoute != null)
                IconButton(
                  onPressed: onPreviewRoute,
                  icon: const Icon(Icons.preview_rounded, size: 20),
                  tooltip: 'Preview Route',
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Live metrics row
          if (isMoving) ...[
            Row(
              children: [
                _MetricChip(
                  icon: Icons.speed_rounded,
                  label: 'Pace',
                  value: metrics.formattedPace,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _MetricChip(
                  icon: Icons.directions_walk_rounded,
                  label: 'Speed',
                  value: metrics.formattedSpeed,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                _MetricChip(
                  icon: Icons.straighten_rounded,
                  label: 'Progress',
                  value:
                      '${((metrics.distanceTraveledMeters / (metrics.distanceTraveledMeters + (metrics.etaToDestination?.inSeconds ?? 0) * metrics.averageSpeedMps)).clamp(0, 1) * 100).round()}%',
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Progress bar
          LinearProgressIndicator(
            value: metrics.distanceTraveledMeters > 0 && metrics.etaToDestination != null
                ? (metrics.distanceTraveledMeters /
                        (metrics.distanceTraveledMeters +
                            metrics.averageSpeedMps * metrics.etaToDestination!.inSeconds))
                    .clamp(0.0, 1.0)
                : 0,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              if (onShareETA != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShareETA,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text('Share ETA', style: GoogleFonts.plusJakartaSans()),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              if (onShareETA != null) const SizedBox(width: 12),
              Expanded(
                flex: onShareETA != null ? 1 : 2,
                child: FilledButton.icon(
                  onPressed: onStopNavigation,
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: Text('Stop', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}

/// Crowd density heatmap layer widget
class CrowdDensityLayer extends StatelessWidget {
  const CrowdDensityLayer({
    super.key,
    required this.reports,
    this.maxRadius = 150.0,
    this.opacity = 0.6,
  });

  final List<CrowdDensityReport> reports;
  final double maxRadius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: reports.map((report) => _DensityCircle(report: report, maxRadius: maxRadius, opacity: opacity)).toList(),
    );
  }
}

class _DensityCircle extends StatelessWidget {
  const _DensityCircle({
    required this.report,
    required this.maxRadius,
    required this.opacity,
  });

  final CrowdDensityReport report;
  final double maxRadius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    // Size based on nearby count, color based on level
    final radius = (report.nearbyCount * 15.0).clamp(30.0, maxRadius);

    return Positioned(
      left: 0,
      top: 0,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              report.level.color.withValues(alpha: opacity),
              report.level.color.withValues(alpha: opacity * 0.3),
              report.level.color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Speed/pace indicator widget for map toolbar
class PaceIndicator extends StatelessWidget {
  const PaceIndicator({super.key, required this.metrics});

  final LiveWalkingMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMoving = metrics.isMoving;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMoving
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
        ),
        boxShadow: [
          if (isMoving)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isMoving ? Icons.directions_run_rounded : Icons.directions_walk_rounded,
              key: ValueKey(isMoving),
              size: 18,
              color: isMoving ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isMoving ? metrics.formattedPace : 'Stationary',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isMoving ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (isMoving) ...[
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}