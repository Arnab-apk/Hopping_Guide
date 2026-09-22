// PandalSpatialCluster.swift — cluster pandals by zone for list view
// (Different from MapClusterManager which clusters by viewport.)

import Foundation
import CoreLocation

struct PandalSpatialCluster {
    /// Maps a zone to its pandal count.
    static func zoneCounts(_ pandals: [Pandal]) -> [KolkataZone: Int] {
        var counts: [KolkataZone: Int] = [:]
        for zone in KolkataZone.allCases { counts[zone] = 0 }
        for p in pandals { counts[p.zone, default: 0] += 1 }
        return counts
    }

    /// Filters pandals to those in a specific zone. Returns full list if zone is nil.
    static func filter(_ pandals: [Pandal], by zone: KolkataZone?) -> [Pandal] {
        guard let zone = zone else { return pandals }
        return pandals.filter { $0.zone == zone }
    }

    /// Filters to pandals within `radiusMeters` of `center`.
    static func withinRadius(_ pandals: [Pandal], radiusMeters: Double, of center: CLLocationCoordinate2D) -> [Pandal] {
        pandals.filter { haversineMeters(center, $0.coordinate) <= radiusMeters }
    }

    /// Sort by Haversine distance ascending.
    static func sortByDistance(_ pandals: [Pandal], from origin: CLLocationCoordinate2D) -> [Pandal] {
        pandals.sorted { a, b in
            haversineMeters(origin, a.coordinate) < haversineMeters(origin, b.coordinate)
        }
    }

    /// Sort by rating descending (highest first), ties broken by name.
    static func sortByRating(_ pandals: [Pandal]) -> [Pandal] {
        pandals.sorted { a, b in
            let ra = a.rating ?? -1
            let rb = b.rating ?? -1
            if ra != rb { return ra > rb }
            return a.name < b.name
        }
    }
}
