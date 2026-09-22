// Services/RoutingService.swift — port of services/routing_service.dart
// Uses MKDirections for native walking routes; geodesic fallback when network unavailable.

import Foundation
import CoreLocation
import MapKit

actor RoutingService {
    static let shared = RoutingService()
    private init() {}

    private struct CachedRoute {
        let route: WalkingRoute
        let timestamp: Date
    }
    private var cache: [String: CachedRoute] = [:]
    private let cacheLimit = 100
    private var consecutiveFailures = 0
    private var circuitBreakerUntil: Date?

    func clearCache() { cache.removeAll() }
    func resetCircuitBreaker() { consecutiveFailures = 0; circuitBreakerUntil = nil }

    /// Get a walking route between two coordinates.
    func getWalkingRoute(
        start: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        destinationName: String
    ) async -> WalkingRoute {
        let cacheKey = Self.cacheKey(from: start, to: destination)
        if let hit = cache[cacheKey],
           Date().timeIntervalSince(hit.timestamp) < 900 {
            return WalkingRoute(
                points: hit.route.points,
                distanceMeters: hit.route.distanceMeters,
                durationSeconds: hit.route.durationSeconds,
                drivingDurationSeconds: hit.route.drivingDurationSeconds,
                destinationTitle: destinationName,
                isFallback: hit.route.isFallback,
                legs: hit.route.legs)
        }

        // Circuit-breaker check
        if let until = circuitBreakerUntil, Date() < until {
            return geodesicFallback(start: start, destination: destination,
                                    destinationName: destinationName)
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking
        request.requestsAlternateRoutes = false

        do {
            let response = try await MKDirections(request: request).calculate()
            guard let route = response.routes.first else {
                return recordFailureAndFallback(start: start, destination: destination,
                                                destinationName: destinationName)
            }
            let coords = route.polyline.points()
            let points = (0..<route.polyline.pointCount).map { i -> CLLocationCoordinate2D in
                coords[i].coordinate
            }
            let simplified = simplifyRoute(points, tolerance: 0.00005)

            let walkSeconds = route.expectedTravelTime
            let driveSeconds = route.distance / 11.1 // ~40 km/h fallback

            let wr = WalkingRoute(
                points: simplified,
                distanceMeters: route.distance,
                durationSeconds: walkSeconds,
                drivingDurationSeconds: driveSeconds > 0 ? driveSeconds : nil,
                destinationTitle: destinationName,
                isFallback: false)

            consecutiveFailures = 0
            circuitBreakerUntil = nil
            if cache.count >= cacheLimit { cache.removeAll() }
            cache[cacheKey] = CachedRoute(route: wr, timestamp: Date())
            return wr
        } catch {
            return recordFailureAndFallback(start: start, destination: destination,
                                            destinationName: destinationName)
        }
    }

    /// Multi-stop route through waypoints. Falls back to geodesic chain if MKDirections fails.
    func getMultiStopRoute(waypoints: [CLLocationCoordinate2D], routeTitle: String) async -> WalkingRoute {
        guard waypoints.count >= 2 else {
            return WalkingRoute(points: waypoints, distanceMeters: 0,
                                durationSeconds: 0, destinationTitle: routeTitle)
        }
        let cacheKey = waypoints.map { Self.coordKey($0) }.joined(separator: ";")
        if let hit = cache[cacheKey],
           Date().timeIntervalSince(hit.timestamp) < 900 {
            return hit.route
        }
        if let until = circuitBreakerUntil, Date() < until {
            return multiStopGeodesicFallback(waypoints, title: routeTitle)
        }

        // Build leg-by-leg route; MKDirections doesn't natively chain many waypoints well,
        // so we stitch consecutive leg routes.
        var stitched: [CLLocationCoordinate2D] = [waypoints.first!]
        var totalDist: Double = 0
        var totalWalk: Double = 0

        for i in 0..<(waypoints.count - 1) {
            let leg = await getWalkingRoute(
                start: waypoints[i],
                destination: waypoints[i + 1],
                destinationName: "Leg \(i + 1)")
            if leg.points.count > 1 {
                stitched.append(contentsOf: leg.points.dropFirst())
            } else {
                stitched.append(waypoints[i + 1])
            }
            totalDist += leg.distanceMeters
            totalWalk += leg.durationSeconds
        }

        let wr = WalkingRoute(
            points: stitched,
            distanceMeters: totalDist,
            durationSeconds: totalWalk,
            drivingDurationSeconds: totalDist / 11.1,
            destinationTitle: routeTitle,
            isFallback: false)
        if cache.count >= cacheLimit { cache.removeAll() }
        cache[cacheKey] = CachedRoute(route: wr, timestamp: Date())
        return wr
    }

    // MARK: - Internals

    private func recordFailureAndFallback(start: CLLocationCoordinate2D,
                                          destination: CLLocationCoordinate2D,
                                          destinationName: String) -> WalkingRoute {
        consecutiveFailures += 1
        if consecutiveFailures >= 3 {
            circuitBreakerUntil = Date().addingTimeInterval(20)
        }
        return geodesicFallback(start: start, destination: destination,
                                destinationName: destinationName)
    }

    private func geodesicFallback(start: CLLocationCoordinate2D,
                                  destination: CLLocationCoordinate2D,
                                  destinationName: String) -> WalkingRoute {
        let directMeters = haversineMeters(start, destination)
        let streetMeters = directMeters * AppConfig.circuityFactor
        let walkSeconds = streetMeters / AppConfig.walkingSpeedMS
        let driveSeconds = streetMeters / 11.1
        return WalkingRoute(
            points: [start, destination],
            distanceMeters: streetMeters,
            durationSeconds: walkSeconds,
            drivingDurationSeconds: driveSeconds,
            destinationTitle: destinationName,
            isFallback: true)
    }

    private func multiStopGeodesicFallback(_ waypoints: [CLLocationCoordinate2D], title: String) -> WalkingRoute {
        var total: Double = 0
        for i in 0..<(waypoints.count - 1) {
            total += haversineMeters(waypoints[i], waypoints[i + 1])
        }
        let street = total * AppConfig.circuityFactor
        return WalkingRoute(
            points: waypoints,
            distanceMeters: street,
            durationSeconds: street / AppConfig.walkingSpeedMS,
            drivingDurationSeconds: street / 11.1,
            destinationTitle: title,
            isFallback: true)
    }

    private static func cacheKey(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> String {
        "\(coordKey(a))->\(coordKey(b))"
    }
    private static func coordKey(_ c: CLLocationCoordinate2D) -> String {
        "\((c.latitude * 1000).rounded() / 1000),\((c.longitude * 1000).rounded() / 1000)"
    }
}
