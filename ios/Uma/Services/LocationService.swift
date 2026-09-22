// Services/LocationService.swift — CLLocationManager wrapper (foreground whenInUse)

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class LocationService: NSObject {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private(set) var lastCoordinate: CLLocationCoordinate2D?
    private(set) var lastHeading: Double = 0
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var isTracking = false
    var onUpdate: ((CLLocationCoordinate2D) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.activityType = .fitness
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func startLiveTracking() {
        requestPermission()
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                manager.startUpdatingHeading()
            }
            isTracking = true
        }
    }

    func stopLiveTracking() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        isTracking = false
    }

    /// Returns the most recent coordinate, or nil if unavailable.
    /// (Apple's Core Location does not expose a synchronous single-shot API;
    /// callers should rely on `lastCoordinate` updated via live tracking.)
    func currentPosition() -> CLLocationCoordinate2D? { lastCoordinate }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.authorizationStatus = status }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.lastCoordinate = loc.coordinate
            self.onUpdate?(loc.coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let h = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in self.lastHeading = h }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Permission denied / disabled — non-fatal in demo mode.
    }
}
