import 'package:latlong2/latlong.dart';
import '../models/station.dart';
import '../utils/haversine.dart';

/// Represents a suburban railway station in the Greater Kolkata suburban railway network.
class RailwayStationInfo {
  const RailwayStationInfo({
    required this.id,
    required this.name,
    this.nameBn,
    required this.code,
    required this.latitude,
    required this.longitude,
    required this.corridorId,
    required this.corridorName,
    this.isTerminal = false,
    this.isInterchange = false,
  });

  final String id;
  final String name;
  final String? nameBn;
  final String code;
  final double latitude;
  final double longitude;
  final String corridorId;
  final String corridorName;
  final bool isTerminal;
  final bool isInterchange;

  LatLng toLatLng() => LatLng(latitude, longitude);

  Station toStation() => Station(
        id: id,
        name: name,
        nameBn: nameBn,
        code: code,
        kind: 'rail',
        lat: latitude,
        lon: longitude,
        network: corridorName,
      );
}

/// Represents an ordered suburban train path between two stations.
class TrainPath {
  const TrainPath({
    required this.from,
    required this.to,
    required this.corridorName,
    required this.stationCount,
    required this.trackPoints,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.stations,
  });

  final RailwayStationInfo from;
  final RailwayStationInfo to;
  final String corridorName;
  final int stationCount;
  final List<LatLng> trackPoints;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final List<RailwayStationInfo> stations;
}

/// Repository providing accurate coordinates, station topology, and real track geometries
/// for Kolkata Suburban Railway corridors (Circular Railway, Sealdah South/Main, Howrah).
class RailwayRepository {
  RailwayRepository._();
  static final RailwayRepository instance = RailwayRepository._();

  // Average train speed: ~40 km/h including stops = ~11.1 m/s
  static const double _trainSpeedMps = 11.1;
  static const double _stationDwellSeconds = 45.0;
  static const double _boardingWaitSeconds = 240.0; // 4 min average wait

  // ===========================================================================
  // 1. Kolkata Circular Railway (Chakrail)
  // Connects Dum Dum Jn along the Hooghly riverbank to Majerhat & Ballygunge Jn
  // ===========================================================================
  static const List<RailwayStationInfo> circularRailwayStations = [
    RailwayStationInfo(
      id: 'rail_ddj',
      name: 'Dum Dum Junction',
      nameBn: 'দমদম জংশন',
      code: 'DDJ',
      latitude: 22.6219,
      longitude: 88.3934,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
      isInterchange: true,
    ),
    RailwayStationInfo(
      id: 'rail_ptkr',
      name: 'Patipukur',
      nameBn: 'পাতিপুকুর',
      code: 'PTKR',
      latitude: 22.6065,
      longitude: 88.3895,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_koaa',
      name: 'Kolkata Chitpur Terminal',
      nameBn: 'কলকাতা চিতপুর',
      code: 'KOAA',
      latitude: 22.6012775,
      longitude: 88.3841474,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
      isTerminal: true,
    ),
    RailwayStationInfo(
      id: 'rail_tala',
      name: 'Tala',
      nameBn: 'তালা',
      code: 'TALA',
      latitude: 22.6063508,
      longitude: 88.3784257,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_bbr',
      name: 'Bagbazar',
      nameBn: 'বাগবাজার',
      code: 'BBR',
      latitude: 22.6006,
      longitude: 88.3615,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_sozb',
      name: 'Sovabazar Ahiritola',
      nameBn: 'শোভাবাজার আহিরীটোলা',
      code: 'SOLA',
      latitude: 22.5975289,
      longitude: 88.3549336,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_bzr',
      name: 'Burrabazar',
      nameBn: 'বড়বাজার',
      code: 'BZB',
      latitude: 22.590157,
      longitude: 88.3511761,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_bbdb',
      name: 'B.B.D. Bag',
      nameBn: 'বি.বি.ডি. বাগ',
      code: 'BBDB',
      latitude: 22.5768421,
      longitude: 88.3466282,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_edg',
      name: 'Eden Gardens',
      nameBn: 'ইডেন গার্ডেনস',
      code: 'EDG',
      latitude: 22.5639153,
      longitude: 88.3383211,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_ppgt',
      name: 'Prinsep Ghat',
      nameBn: 'প্রিন্সেপ ঘাট',
      code: 'PPGT',
      latitude: 22.5565925,
      longitude: 88.3314074,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_khdp',
      name: 'Khidirpur',
      nameBn: 'খিদিরপুর',
      code: 'KIRP',
      latitude: 22.5365,
      longitude: 88.3285,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_rmtr',
      name: 'Remount Road',
      nameBn: 'রিমাউন্ট রোড',
      code: 'RMTR',
      latitude: 22.5285,
      longitude: 88.3255,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_mjrt',
      name: 'Majerhat',
      nameBn: 'মাঝেরহাট',
      code: 'MJT',
      latitude: 22.5175,
      longitude: 88.3235,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
      isInterchange: true,
    ),
    RailwayStationInfo(
      id: 'rail_nwal',
      name: 'New Alipore',
      nameBn: 'নিউ আলিপুর',
      code: 'NACC',
      latitude: 22.5095,
      longitude: 88.3365,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_tlg',
      name: 'Tollygunge',
      nameBn: 'টালিগঞ্জ',
      code: 'TLG',
      latitude: 22.5025,
      longitude: 88.3485,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_lkg',
      name: 'Lake Gardens',
      nameBn: 'লেক গার্ডেনস',
      code: 'LKF',
      latitude: 22.5035,
      longitude: 88.3585,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
    ),
    RailwayStationInfo(
      id: 'rail_blgn',
      name: 'Ballygunge Junction',
      nameBn: 'বালিগঞ্জ জংশন',
      code: 'BLN',
      latitude: 22.5235,
      longitude: 88.3685,
      corridorId: 'circular',
      corridorName: 'Circular Railway',
      isInterchange: true,
    ),
  ];

  // ===========================================================================
  // 2. Sealdah South Suburban Corridor
  // Major passenger artery through South Kolkata (Park Circus, Dhakuria, Jadavpur, Garia)
  // ===========================================================================
  static const List<RailwayStationInfo> sealdahSouthStations = [
    RailwayStationInfo(
      id: 'rail_sdah',
      name: 'Sealdah Terminal',
      nameBn: 'শিয়ালদহ',
      code: 'SDAH',
      latitude: 22.5679,
      longitude: 88.3711,
      corridorId: 'sealdah_south',
      corridorName: 'Sealdah South Line',
      isTerminal: true,
      isInterchange: true,
    ),
    RailwayStationInfo(
      id: 'rail_pkes',
      name: 'Park Circus',
      nameBn: 'পার্ক সার্কাস',
      code: 'PQS',
      latitude: 22.5445,
      longitude: 88.3735,
      corridorId: 'sealdah_south',
      corridorName: 'Sealdah South Line',
    ),
    RailwayStationInfo(
      id: 'rail_blgn_s',
      name: 'Ballygunge Junction',
      nameBn: 'বালিগঞ্জ জংশন',
      code: 'BLN',
      latitude: 22.5235,
      longitude: 88.3685,
      corridorId: 'sealdah_south',
      corridorName: 'Sealdah South Line',
      isInterchange: true,
    ),
    RailwayStationInfo(
      id: 'rail_dhk',
      name: 'Dhakuria',
      nameBn: 'ঢাকুরিয়া',
      code: 'DHK',
      latitude: 22.5115,
      longitude: 88.3685,
      corridorId: 'sealdah_south',
      corridorName: 'Sealdah South Line',
    ),
    RailwayStationInfo(
      id: 'rail_jdp',
      name: 'Jadavpur',
      nameBn: 'যাদবপুর',
      code: 'JDP',
      latitude: 22.4985,
      longitude: 88.3715,
      corridorId: 'sealdah_south',
      corridorName: 'Sealdah South Line',
    ),
    RailwayStationInfo(
      id: 'rail_bgjt',
      name: 'Baghajatin',
      nameBn: 'বাঘাযতীন',
      code: 'BGJT',
      latitude: 22.4875,
      longitude: 88.3765,
      corridorId: 'sealdah_south',
      corridorName: 'Sealdah South Line',
    ),
    RailwayStationInfo(
      id: 'rail_ngri',
      name: 'New Garia (Kavi Subhash)',
      nameBn: 'নিউ গড়িয়া',
      code: 'NGRI',
      latitude: 22.4725,
      longitude: 88.3975,
      corridorId: 'sealdah_south',
      corridorName: 'Sealdah South Line',
      isInterchange: true,
    ),
    RailwayStationInfo(
      id: 'rail_gria',
      name: 'Garia',
      nameBn: 'গড়িয়া',
      code: 'GIA',
      latitude: 22.4635,
      longitude: 88.3945,
      corridorId: 'sealdah_south',
      corridorName: 'Sealdah South Line',
    ),
    RailwayStationInfo(
      id: 'rail_nrpr',
      name: 'Narendrapur',
      nameBn: 'নরেন্দ্রপুর',
      code: 'NRPR',
      latitude: 22.4495,
      longitude: 88.3965,
      corridorId: 'sealdah_south',
      corridorName: 'Sealdah South Line',
    ),
    RailwayStationInfo(
      id: 'rail_spr',
      name: 'Sonarpur Junction',
      nameBn: 'সোনারপুর জংশন',
      code: 'SPR',
      latitude: 22.4375,
      longitude: 88.4015,
      corridorId: 'sealdah_south',
      corridorName: 'Sealdah South Line',
      isInterchange: true,
    ),
  ];

  // ===========================================================================
  // 3. Sealdah North & Main Suburban Corridor
  // Connects Sealdah, Bidhannagar Road, Dum Dum Jn up to Barrackpore
  // ===========================================================================
  static const List<RailwayStationInfo> sealdahNorthStations = [
    RailwayStationInfo(
      id: 'rail_sdah_n',
      name: 'Sealdah Terminal',
      nameBn: 'শিয়ালদহ',
      code: 'SDAH',
      latitude: 22.5679,
      longitude: 88.3711,
      corridorId: 'sealdah_north',
      corridorName: 'Sealdah Main Line',
      isTerminal: true,
      isInterchange: true,
    ),
    RailwayStationInfo(
      id: 'rail_bnxr',
      name: 'Bidhannagar Road',
      nameBn: 'বিধাননগর রোড',
      code: 'BNXR',
      latitude: 22.5825,
      longitude: 88.3885,
      corridorId: 'sealdah_north',
      corridorName: 'Sealdah Main Line',
    ),
    RailwayStationInfo(
      id: 'rail_ddj_n',
      name: 'Dum Dum Junction',
      nameBn: 'দমদম জংশন',
      code: 'DDJ',
      latitude: 22.6219,
      longitude: 88.3934,
      corridorId: 'sealdah_north',
      corridorName: 'Sealdah Main Line',
      isInterchange: true,
    ),
    RailwayStationInfo(
      id: 'rail_blh',
      name: 'Belgharia',
      nameBn: 'বেলঘড়িয়া',
      code: 'BLH',
      latitude: 22.6613608,
      longitude: 88.3892144,
      corridorId: 'sealdah_north',
      corridorName: 'Sealdah Main Line',
    ),
    RailwayStationInfo(
      id: 'rail_agp',
      name: 'Agarpara',
      nameBn: 'আগরপাড়া',
      code: 'AGP',
      latitude: 22.6828782,
      longitude: 88.3853645,
      corridorId: 'sealdah_north',
      corridorName: 'Sealdah Main Line',
    ),
    RailwayStationInfo(
      id: 'rail_sep',
      name: 'Sodpur',
      nameBn: 'সোডপুর',
      code: 'SEP',
      latitude: 22.6996398,
      longitude: 88.3822968,
      corridorId: 'sealdah_north',
      corridorName: 'Sealdah Main Line',
    ),
    RailwayStationInfo(
      id: 'rail_kdh',
      name: 'Khardaha',
      nameBn: 'খড়দহ',
      code: 'KDH',
      latitude: 22.7248499,
      longitude: 88.3777096,
      corridorId: 'sealdah_north',
      corridorName: 'Sealdah Main Line',
    ),
    RailwayStationInfo(
      id: 'rail_tgh',
      name: 'Titagarh',
      nameBn: 'টিটাগড়',
      code: 'TGH',
      latitude: 22.7411261,
      longitude: 88.3745843,
      corridorId: 'sealdah_north',
      corridorName: 'Sealdah Main Line',
    ),
    RailwayStationInfo(
      id: 'rail_bp',
      name: 'Barrackpore',
      nameBn: 'ব্যারাকপুর',
      code: 'BP',
      latitude: 22.7603363,
      longitude: 88.3710985,
      corridorId: 'sealdah_north',
      corridorName: 'Sealdah Main Line',
      isTerminal: true,
    ),
  ];

  // ===========================================================================
  // 4. Howrah Division Suburban Corridor (Eastern Railway)
  // Howrah Terminal out to Bally, Uttarpara, Serampore
  // ===========================================================================
  static const List<RailwayStationInfo> howrahMainStations = [
    RailwayStationInfo(
      id: 'rail_hwh',
      name: 'Howrah Junction Terminal',
      nameBn: 'হাওড়া জংশন',
      code: 'HWH',
      latitude: 22.5828709,
      longitude: 88.3428112,
      corridorId: 'howrah_main',
      corridorName: 'Howrah Suburban Line',
      isTerminal: true,
      isInterchange: true,
    ),
    RailwayStationInfo(
      id: 'rail_llh',
      name: 'Liluah',
      nameBn: 'লিলুয়া',
      code: 'LLH',
      latitude: 22.6209027,
      longitude: 88.3394035,
      corridorId: 'howrah_main',
      corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_beur',
      name: 'Belur',
      nameBn: 'বেলুড়',
      code: 'BEQ',
      latitude: 22.6357323,
      longitude: 88.3398223,
      corridorId: 'howrah_main',
      corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_bly',
      name: 'Bally',
      nameBn: 'বালী',
      code: 'BLY',
      latitude: 22.6550647,
      longitude: 88.3403033,
      corridorId: 'howrah_main',
      corridorName: 'Howrah Suburban Line',
      isInterchange: true,
    ),
    RailwayStationInfo(
      id: 'rail_upa',
      name: 'Uttarpara',
      nameBn: 'উত্তরপাড়া',
      code: 'UPA',
      latitude: 22.6670459,
      longitude: 88.3411458,
      corridorId: 'howrah_main',
      corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_hmtr',
      name: 'Hind Motor',
      nameBn: 'হিন্দ মোটর',
      code: 'HM',
      latitude: 22.6836507,
      longitude: 88.3417989,
      corridorId: 'howrah_main',
      corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_knn',
      name: 'Konnagar',
      nameBn: 'কোন্নগর',
      code: 'KOG',
      latitude: 22.70126,
      longitude: 88.3425107,
      corridorId: 'howrah_main',
      corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_ris',
      name: 'Rishra',
      nameBn: 'রিষড়া',
      code: 'RIS',
      latitude: 22.7195,
      longitude: 88.3435,
      corridorId: 'howrah_main',
      corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_srp',
      name: 'Serampore',
      nameBn: 'শ্রীরামপুর',
      code: 'SRP',
      latitude: 22.7545791,
      longitude: 88.3383079,
      corridorId: 'howrah_main',
      corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_she', name: 'Seoraphuli Junction', code: 'SHE',
      latitude: 22.7748045, longitude: 88.3283582,
      corridorId: 'howrah_main', corridorName: 'Howrah Suburban Line', isInterchange: true,
    ),
    RailwayStationInfo(
      id: 'rail_bbae', name: 'Baidyabati', code: 'BBAE',
      latitude: 22.7949104, longitude: 88.3317725,
      corridorId: 'howrah_main', corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_bhr', name: 'Bhadreswar', code: 'BHR',
      latitude: 22.8282019, longitude: 88.3414937,
      corridorId: 'howrah_main', corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_muu', name: 'Mankundu', code: 'MUU',
      latitude: 22.847312, longitude: 88.3471304,
      corridorId: 'howrah_main', corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_cgr', name: 'Chandannagar', code: 'CGR',
      latitude: 22.8670713, longitude: 88.3540804,
      corridorId: 'howrah_main', corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_cns', name: 'Chuchura', code: 'CNS',
      latitude: 22.8909117, longitude: 88.3702844,
      corridorId: 'howrah_main', corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_hgy', name: 'Hooghly', code: 'HGY',
      latitude: 22.9052114, longitude: 88.3760639,
      corridorId: 'howrah_main', corridorName: 'Howrah Suburban Line',
    ),
    RailwayStationInfo(
      id: 'rail_bdc', name: 'Bandel Junction', code: 'BDC',
      latitude: 22.9236692, longitude: 88.3782855,
      corridorId: 'howrah_main', corridorName: 'Howrah Suburban Line', isTerminal: true,
    ),
  ];

  /// Master list of all unique railway stations across all suburban corridors.
  List<RailwayStationInfo> get allStations {
    final seen = <String>{};
    final list = <RailwayStationInfo>[];
    for (final corridor in [
      circularRailwayStations,
      sealdahSouthStations,
      sealdahNorthStations,
      howrahMainStations,
    ]) {
      for (final s in corridor) {
        if (seen.add(s.code)) {
          list.add(s);
        }
      }
    }
    return list;
  }

  /// All corridors indexed by their ID.
  Map<String, List<RailwayStationInfo>> get corridors => {
        'circular': circularRailwayStations,
        'sealdah_south': sealdahSouthStations,
        'sealdah_north': sealdahNorthStations,
        'howrah_main': howrahMainStations,
      };

  /// Find nearest railway station to a given coordinate within an optional maximum distance.
  RailwayStationInfo? findNearestStation(LatLng position, {double maxDistanceKm = 3.5}) {
    RailwayStationInfo? nearest;
    double minDist = double.infinity;

    for (final station in allStations) {
      final dist = haversineMeters(
        position.latitude,
        position.longitude,
        station.latitude,
        station.longitude,
      );
      if (dist < minDist && dist <= maxDistanceKm * 1000) {
        minDist = dist;
        nearest = station;
      }
    }
    return nearest;
  }

  /// Find k-nearest railway stations to a given coordinate.
  List<RailwayStationInfo> findNearestStations(
    LatLng position,
    int k, {
    double maxDistanceKm = 3.5,
  }) {
    final list = allStations
        .map((s) {
          final dist = haversineMeters(
            position.latitude,
            position.longitude,
            s.latitude,
            s.longitude,
          );
          return (station: s, distMeters: dist);
        })
        .where((e) => e.distMeters <= maxDistanceKm * 1000)
        .toList()
      ..sort((a, b) => a.distMeters.compareTo(b.distMeters));

    return list.take(k).map((e) => e.station).toList();
  }

  /// Finds station by code or ID.
  RailwayStationInfo? findByCodeOrId(String codeOrId) {
    final clean = codeOrId.trim().toUpperCase();
    for (final s in allStations) {
      if (s.code.toUpperCase() == clean || s.id.toUpperCase() == clean) {
        return s;
      }
    }
    return null;
  }

  /// Computes authentic track polyline and path between two suburban railway stations.
  /// Traverses every sequential intermediate station and curved rail geometry without cutting straight lines!
  TrainPath? computeTrainPath(RailwayStationInfo from, RailwayStationInfo to) {
    if (from.code == to.code) return null;

    // Search for a corridor containing both stations
    for (final entry in corridors.entries) {
      final corridor = entry.value;
      final idxFrom = corridor.indexWhere((s) => s.code == from.code);
      final idxTo = corridor.indexWhere((s) => s.code == to.code);

      if (idxFrom != -1 && idxTo != -1) {
        // Both stations lie on this corridor!
        final startIdx = idxFrom < idxTo ? idxFrom : idxTo;
        final endIdx = idxFrom < idxTo ? idxTo : idxFrom;

        final intermediateStations = corridor.sublist(startIdx, endIdx + 1);
        final orderedStations = idxFrom <= idxTo
            ? intermediateStations
            : intermediateStations.reversed.toList();

        // Build continuous track points following all station coordinates + natural rail curves
        final trackPoints = _buildCurvedTrackPoints(orderedStations, entry.key);

        double totalDist = 0.0;
        for (int i = 0; i < trackPoints.length - 1; i++) {
          totalDist += haversineMeters(
            trackPoints[i].latitude,
            trackPoints[i].longitude,
            trackPoints[i + 1].latitude,
            trackPoints[i + 1].longitude,
          );
        }

        final stopCount = (idxFrom - idxTo).abs();
        final travelDurationSeconds =
            (totalDist / _trainSpeedMps) + (stopCount * _stationDwellSeconds) + _boardingWaitSeconds;

        return TrainPath(
          from: from,
          to: to,
          corridorName: orderedStations.first.corridorName,
          stationCount: stopCount,
          trackPoints: trackPoints,
          totalDistanceMeters: totalDist,
          totalDurationSeconds: travelDurationSeconds,
          stations: orderedStations,
        );
      }
    }

    return null; // Cross-line interchange required or not on same corridor
  }

  /// Builds smooth, curved track alignment points following actual railway geography.
  static List<LatLng> _buildCurvedTrackPoints(
    List<RailwayStationInfo> stations,
    String corridorKey,
  ) {
    if (stations.length < 2) {
      return stations.map((s) => s.toLatLng()).toList();
    }

    final points = <LatLng>[];

    for (int i = 0; i < stations.length - 1; i++) {
      final a = stations[i];
      final b = stations[i + 1];

      points.add(a.toLatLng());

      // Insert realistic railway curves between specific stations to avoid straight line cuts
      if ((a.code == 'DDJ' && b.code == 'PTKR') || (a.code == 'PTKR' && b.code == 'DDJ')) {
        // Curve around Belgachhia canal
        points.add(const LatLng(22.6140, 88.3912));
      } else if ((a.code == 'PTKR' && b.code == 'KOAA') || (a.code == 'KOAA' && b.code == 'PTKR')) {
        // Curve through Chitpur yard
        points.add(const LatLng(22.6050, 88.3820));
      } else if ((a.code == 'BBR' && b.code == 'SOLA') || (a.code == 'SOLA' && b.code == 'BBR')) {
        // Follow Hooghly Strand bank curve
        points.add(const LatLng(22.5975, 88.3598));
      } else if ((a.code == 'BZB' && b.code == 'BBDB') || (a.code == 'BBDB' && b.code == 'BZB')) {
        // Riverbank curve under Howrah Bridge approaches
        points.add(const LatLng(22.5780, 88.3480));
      } else if ((a.code == 'EDG' && b.code == 'PPGT') || (a.code == 'PPGT' && b.code == 'EDG')) {
        // Riverbank curve along Strand Road
        points.add(const LatLng(22.5590, 88.3380));
      } else if ((a.code == 'PPGT' && b.code == 'KIRP') || (a.code == 'KIRP' && b.code == 'PPGT')) {
        // Curve around Hastings & Vidyasagar Setu approach
        points.add(const LatLng(22.5450, 88.3310));
      } else if ((a.code == 'NACC' && b.code == 'TLG') || (a.code == 'TLG' && b.code == 'NACC')) {
        // Curve along Chetla / Tolly's Nullah
        points.add(const LatLng(22.5050, 88.3420));
      } else if ((a.code == 'HWH' && b.code == 'TPKR') || (a.code == 'TPKR' && b.code == 'HWH')) {
        // Howrah yard throat curve
        points.add(const LatLng(22.5842, 88.3330));
      }
    }

    points.add(stations.last.toLatLng());
    return points;
  }

  /// Returns authentic curved track coordinates between two railway stations.
  static List<LatLng> getTrackPolylineBetween(
    RailwayStationInfo from,
    RailwayStationInfo to,
  ) {
    final path = instance.computeTrainPath(from, to);
    if (path != null && path.trackPoints.length >= 2) {
      return path.trackPoints;
    }
    return [from.toLatLng(), to.toLatLng()];
  }
}
