// SpatialCorridor.swift — port of utils/spatial_corridor.dart
// The "10 km nearby" filter logic with off-corridor fallback.

import Foundation
import CoreLocation

struct SpatialCorridor {
    /// Effective user position: real GPS if within ~70 km of Kolkata, else default Kolkata center.
    static func effectiveUserLocation(
        userLocation: CLLocationCoordinate2D?,
        fallback: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: AppConfig.defaultLat, longitude: AppConfig.defaultLng)
    ) -> CLLocationCoordinate2D {
        guard let user = userLocation else { return fallback }
        let dist = haversineMeters(user.latitude, user.longitude, AppConfig.defaultLat, AppConfig.defaultLng)
        if dist > AppConfig.offCorridorThreshold { return fallback }
        return user
    }

    /// Reference center for the 10 km radius — the user's effective location.
    static func nearby10kmCenter(
        userLocation: CLLocationCoordinate2D?,
        fallback: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: AppConfig.defaultLat, longitude: AppConfig.defaultLng)
    ) -> CLLocationCoordinate2D {
        effectiveUserLocation(userLocation: userLocation, fallback: fallback)
    }

    /// True when `coord` lies within `meters` of `center`.
    static func isWithin(_ meters: Double, _ coord: CLLocationCoordinate2D, of center: CLLocationCoordinate2D) -> Bool {
        haversineMeters(center, coord) <= meters
    }
}
