// WalkingRoute.swift + TrailLeg.swift — ported from routing_service.dart

import Foundation
import CoreLocation

struct TrailLeg: Hashable, Codable, Sendable {
    enum Mode: String, Codable { case walking, metro }

    let mode: Mode
    let distanceMeters: Double
    let durationSeconds: Double
    /// Optional metro segment details (nil if walking).
    let metroDetail: MetroSegment?

    var isMetro: Bool { mode == .metro }
    var isWalking: Bool { mode == .walking }

    struct MetroSegment: Hashable, Codable {
        let fromStation: String
        let toStation: String
        let lineCode: String
        let totalMinutes: Double
        let stopsCount: Int
    }
}

struct WalkingRoute: Hashable, Codable, @unchecked Sendable {
    let points: [CLLocationCoordinate2D]
    let distanceMeters: Double
    let durationSeconds: Double
    let drivingDurationSeconds: Double?
    let destinationTitle: String
    let isFallback: Bool
    let legs: [TrailLeg]

    // Hashable/Equatable by canonical JSON representation since CLLocationCoordinate2D isn't Hashable.
    func hash(into hasher: inout Hasher) {
        hasher.combine(distanceMeters)
        hasher.combine(durationSeconds)
        hasher.combine(drivingDurationSeconds ?? 0)
        hasher.combine(destinationTitle)
        hasher.combine(isFallback)
        hasher.combine(legs)
        hasher.combine(points.map { "\($0.latitude),\($0.longitude)" }.joined(separator: ";"))
    }

    static func == (lhs: WalkingRoute, rhs: WalkingRoute) -> Bool {
        lhs.distanceMeters == rhs.distanceMeters
        && lhs.durationSeconds == rhs.durationSeconds
        && lhs.drivingDurationSeconds == rhs.drivingDurationSeconds
        && lhs.destinationTitle == rhs.destinationTitle
        && lhs.isFallback == rhs.isFallback
        && lhs.legs == rhs.legs
        && lhs.points.count == rhs.points.count
        && zip(lhs.points, rhs.points).allSatisfy {
            $0.latitude == $1.latitude && $0.longitude == $1.longitude
        }
    }

    init(points: [CLLocationCoordinate2D], distanceMeters: Double, durationSeconds: Double,
         drivingDurationSeconds: Double? = nil, destinationTitle: String,
         isFallback: Bool = false, legs: [TrailLeg] = []) {
        self.points = points
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.drivingDurationSeconds = drivingDurationSeconds
        self.destinationTitle = destinationTitle
        self.isFallback = isFallback
        self.legs = legs
    }

    /// Walking-only formatted distance ("850 m" or "1.2 km").
    var formattedDistance: String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters.rounded())) m"
        } else {
            return String(format: "%.1f km", distanceMeters / 1000.0)
        }
    }

    /// True when route is long enough to recommend transit.
    var isTransitRecommended: Bool {
        distanceMeters > 3500 && (drivingDurationSeconds ?? 0) > 0
    }

    var formattedTransitDuration: String? {
        guard let secs = drivingDurationSeconds, secs > 0 else { return nil }
        return Self.formatTime(Int((secs / 60).rounded()), suffix: "drive/transit")
    }

    var formattedDuration: String {
        let walkMins = Int((durationSeconds / 60).rounded())
        let walkStr = Self.formatTime(walkMins, suffix: "walk")
        if isTransitRecommended, let driveStr = formattedTransitDuration {
            return "\(driveStr) · \(walkStr)"
        }
        return walkStr
    }

    static func formatTime(_ totalMinutes: Int, suffix: String) -> String {
        if totalMinutes < 1 { return "< 1 min \(suffix)" }
        if totalMinutes < 60 { return "\(totalMinutes) mins \(suffix)" }
        let hours = totalMinutes / 60
        let rem = totalMinutes % 60
        if rem == 0 { return "\(hours)h \(suffix)" }
        return "\(hours)h \(rem)m \(suffix)"
    }

    // MARK: - Codable (Coordinate isn't Codable by default)
    enum CodingKeys: String, CodingKey {
        case points, distanceMeters, durationSeconds, drivingDurationSeconds
        case destinationTitle, isFallback, legs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try c.decode([Coord].self, forKey: .points)
        points = raw.map { .init(latitude: $0.lat, longitude: $0.lng) }
        distanceMeters = try c.decode(Double.self, forKey: .distanceMeters)
        durationSeconds = try c.decode(Double.self, forKey: .durationSeconds)
        drivingDurationSeconds = try? c.decode(Double.self, forKey: .drivingDurationSeconds)
        destinationTitle = (try? c.decode(String.self, forKey: .destinationTitle)) ?? "Destination"
        isFallback = (try? c.decode(Bool.self, forKey: .isFallback)) ?? false
        legs = (try? c.decode([TrailLeg].self, forKey: .legs)) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        let raw = points.map { Coord(lat: $0.latitude, lng: $0.longitude) }
        try c.encode(raw, forKey: .points)
        try c.encode(distanceMeters, forKey: .distanceMeters)
        try c.encode(durationSeconds, forKey: .durationSeconds)
        try c.encodeIfPresent(drivingDurationSeconds, forKey: .drivingDurationSeconds)
        try c.encode(destinationTitle, forKey: .destinationTitle)
        try c.encode(isFallback, forKey: .isFallback)
        try c.encode(legs, forKey: .legs)
    }

    struct Coord: Codable, Hashable {
        let lat: Double
        let lng: Double
    }
}
