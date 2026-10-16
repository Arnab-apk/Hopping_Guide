import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/station.dart';
import '../repositories/station_repository.dart';
import '../services/journey_planner.dart';
import '../services/location_service.dart';
import '../services/multimodal_routing_service.dart';
import '../services/return_home_service.dart';

class ReturnHomeScreen extends StatefulWidget {
  const ReturnHomeScreen({super.key});

  @override
  State<ReturnHomeScreen> createState() => _ReturnHomeScreenState();
}

class _ReturnHomeScreenState extends State<ReturnHomeScreen> {
  List<Station> _stations = [];
  List<VerifiedTransitRun> _timetable = [];
  Station? _home, _origin;
  int _buffer = 20;
  DateTime _date = DateTime.now().toUtc().add(
    const Duration(hours: 5, minutes: 30),
  );
  bool _loading = true, _busy = false;
  String? _error;
  MultimodalRoute? _route;
  ReturnHomeCheck? _check;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stations = await StationRepository.instance.allStations();
      final prefs = await SharedPreferences.getInstance();
      final runs = await ReturnHomeService.loadTimetable();
      if (!mounted) return;
      setState(() {
        _stations = stations;
        _timetable = runs;
        _home = StationRepository.instance.findById(
          prefs.getString(ReturnHomeService.homeKey) ?? '',
        );
        _buffer = (prefs.getInt(ReturnHomeService.bufferKey) ?? 20).clamp(
          5,
          60,
        );
        _loading = false;
        if (stations.isEmpty) {
          _error = 'Station data could not be loaded. Please retry.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Return planner data could not be loaded. Please retry.';
        });
      }
    }
  }

  void _invalidate() {
    _route = null;
    _check = null;
    _error = null;
  }

  Future<void> _pickStation(bool home) async {
    final selected = await showSearch<Station?>(
      context: context,
      delegate: _StationSearch(_stations),
    );
    if (!mounted || selected == null) return;
    setState(() {
      if (home) {
        _home = selected;
      } else {
        _origin = selected;
      }
      _invalidate();
    });
  }

  Future<void> _plan() async {
    final home = _home;
    if (home == null) return;
    setState(() {
      _busy = true;
      _invalidate();
    });
    try {
      await ReturnHomeService.save(home.id, _buffer);
      LatLng origin;
      if (_origin != null) {
        origin = _origin!.toLatLng();
      } else {
        final position = await LocationService.instance.updateLiveLocation();
        if (position == null) {
          throw StateError(
            'Location unavailable. Choose a starting station or enable location access.',
          );
        }
        origin = LatLng(position.latitude, position.longitude);
      }
      final route = await JourneyPlanner.instance.plan(
        origin: origin,
        destination: home.toLatLng(),
        destinationName: home.displayName,
      );
      final check = ReturnHomeService.check(
        route: route,
        timetable: _timetable,
        serviceDate: _dateLabel(_date),
        now: DateTime.now().toUtc(),
        buffer: Duration(minutes: _buffer),
      );
      if (mounted) {
        setState(() {
          _route = route;
          _check = check;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is StateError
              ? e.message.toString()
              : 'Could not plan your return. Check your connection and retry.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  static String _dateLabel(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String _kolkata(DateTime d) {
    final ist = d.toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${_dateLabel(ist)} ${ist.hour.toString().padLeft(2, '0')}:${ist.minute.toString().padLeft(2, '0')} IST';
  }

  Future<void> _source(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      /* Show a recoverable error below. */
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the operator website. Please retry.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final check = _check;
    return Scaffold(
      appBar: AppBar(title: const Text('Get home')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Plan your return before you hop',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Save your home station. Check the route from your current location or a starting station. Dates refer to the Kolkata operating day; night services may depart the next morning.',
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Home station'),
                        subtitle: Text(
                          _home?.displayName ??
                              'Choose a metro or railway station',
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: _busy ? null : () => _pickStation(true),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Starting point'),
                        subtitle: Text(
                          _origin?.displayName ?? 'Current location',
                        ),
                        trailing: const Icon(Icons.search),
                        onTap: _busy ? null : () => _pickStation(false),
                      ),
                      if (_origin != null)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  _origin = null;
                                  _invalidate();
                                }),
                          child: const Text('Use current location'),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Operating date'),
                        subtitle: Text(_dateLabel(_date)),
                        trailing: const Icon(Icons.calendar_month_outlined),
                        onTap: _busy
                            ? null
                            : () async {
                                final now = DateTime.now().toUtc().add(
                                  const Duration(hours: 5, minutes: 30),
                                );
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                  ).subtract(const Duration(days: 1)),
                                  lastDate: now.add(const Duration(days: 90)),
                                );
                                if (date != null && mounted) {
                                  setState(() {
                                    _date = date;
                                    _invalidate();
                                  });
                                }
                              },
                      ),
                      Text('Boarding buffer: $_buffer minutes per connection'),
                      Slider(
                        value: _buffer.toDouble(),
                        min: 5,
                        max: 60,
                        divisions: 11,
                        label: '$_buffer minutes',
                        onChanged: _busy
                            ? null
                            : (value) => setState(() {
                                _buffer = value.round();
                                _invalidate();
                              }),
                      ),
                      FilledButton.icon(
                        onPressed: _busy || _home == null || _stations.isEmpty
                            ? null
                            : _plan,
                        icon: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.home_outlined),
                        label: Text(
                          _busy ? 'Planning return…' : 'Save and plan return',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        if (_stations.isEmpty)
                          TextButton(
                            onPressed: _load,
                            child: const Text('Retry loading'),
                          ),
                      ],
                      const SizedBox(height: 16),
                      if (_timetable.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Schedule unverified: official station-specific departures have not been added. UMA cannot confirm the last service or a safe leave-by time. Check with the operator before travelling.',
                            ),
                          ),
                        ),
                      if (route != null && check != null) ...[
                        Text(
                          'Estimated route · ${route.formattedTotalDuration}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (check.leaveBy != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Leave by ${_kolkata(check.leaveBy!)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Text(
                            'Based on published departures and estimated walks. Not a live service guarantee.',
                          ),
                        ],
                        if (check.reason != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(check.reason!),
                          ),
                        for (final leg in route.legs)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              leg is MetroLeg
                                  ? Icons.subway_outlined
                                  : leg is TrainLeg
                                  ? Icons.train_outlined
                                  : Icons.directions_walk,
                            ),
                            title: Text(leg.instructions),
                            subtitle: Text(
                              '${leg.formattedDuration} · ${leg.formattedDistance}',
                            ),
                          ),
                        for (final run in check.runs)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Departure ${_kolkata(run.departure)}'),
                                  Text('Arrival ${_kolkata(run.arrival)}'),
                                  Text('Verified ${_kolkata(run.verifiedAt)}'),
                                  TextButton(
                                    onPressed: () => _source(run.source),
                                    child: const Text(
                                      'Official timetable source',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _StationSearch extends SearchDelegate<Station?> {
  _StationSearch(this.stations)
    : super(searchFieldLabel: 'Station name or code');
  final List<Station> stations;
  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      tooltip: 'Clear search',
      onPressed: () {
        query = '';
      },
      icon: const Icon(Icons.clear),
    ),
  ];
  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: 'Back',
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );
  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);
  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.trim().toLowerCase();
    final matches = stations
        .where(
          (s) => '${s.name} ${s.nameBn ?? ''} ${s.code ?? ''}'
              .toLowerCase()
              .contains(q),
        )
        .take(60)
        .toList();
    if (matches.isEmpty) {
      return const Center(
        child: Text('No matching stations. Try another name or code.'),
      );
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final station = matches[index];
        return ListTile(
          title: Text(station.displayName),
          subtitle: Text(station.isMetro ? 'Metro' : 'Railway'),
          onTap: () => close(context, station),
        );
      },
    );
  }
}
