// Haversine.swift — port of utils/haversine.dart

import Foundation
import CoreLocation

/// Great-circle distance in meters between two lat/lng points.
func haversineMeters(_ lat1: Double, _ lng1: Double, _ lat2: Double, _ lng2: Double) -> Double {
    let r = 6_371_000.0 // Earth radius (m)
    let dLat = (lat2 - lat1) * .pi / 180
    let dLng = (lng2 - lng1) * .pi / 180
    let a = sin(dLat / 2) * sin(dLat / 2)
        + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
        * sin(dLng / 2) * sin(dLng / 2)
    let c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return r * c
}

func haversineMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
    haversineMeters(a.latitude, a.longitude, b.latitude, b.longitude)
}

/// Forward bearing in degrees [0..360) from point 1 to point 2.
func calculateBearing(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
    let phi1 = lat1 * .pi / 180
    let phi2 = lat2 * .pi / 180
    let deltaLambda = (lng2 - lng1) * .pi / 180
    let y = sin(deltaLambda) * cos(phi2)
    let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda)
    let theta = atan2(y, x)
    return (theta * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
}

/// Human-readable distance (e.g. "850 m" or "1.2 km").
func formatDistance(_ meters: Double) -> String {
    if meters < 1000 { return "\(Int(meters.rounded())) m" }
    return String(format: "%.1f km", meters / 1000.0)
}

/// App-wide default Kolkata center (used when GPS unavailable or off-corridor).
enum AppConfig {
    /// Central Kolkata reference (College Street area).
    static let defaultLat: Double = 22.5726
    static let defaultLng: Double = 88.3639
    static let defaultZoom: Double = 11.5

    /// If user GPS reports >70km from this point, treat as out-of-town and snap to default.
    static let offCorridorThreshold: Double = 70_000

    /// "Nearby" filter radius for the 10 km list view & map.
    static let nearbyRadius: Double = 10_000

    /// Pedestrian walking speed used for fallback estimates (m/s).
    static let walkingSpeedMS: Double = 1.25  // 4.5 km/h

    /// Urban street circuity factor — accounts for one-way streets & alleyways.
    static let circuityFactor: Double = 1.25
}
