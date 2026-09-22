// UmaTests/HaversineTests.swift

import XCTest
import CoreLocation
@testable import Uma

final class HaversineTests: XCTestCase {
    func test_kolkataToHowrah_isApproximately6km() {
        let kolkata = CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639)
        let howrah  = CLLocationCoordinate2D(latitude: 22.5958, longitude: 88.3101)
        let d = haversineMeters(kolkata.latitude, kolkata.longitude,
                                howrah.latitude, howrah.longitude)
        // True distance ~6.6 km
        XCTAssertEqual(d / 1000, 6.6, accuracy: 1.0)
    }

    func test_samePointIsZero() {
        let p = CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639)
        let d = haversineMeters(p, p)
        XCTAssertEqual(d, 0, accuracy: 0.001)
    }

    func test_bearingNorthIs360() {
        let p = CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639)
        let north = CLLocationCoordinate2D(latitude: 22.5826, longitude: 88.3639)
        let b = calculateBearing(lat1: p.latitude, lng1: p.longitude,
                                 lat2: north.latitude, lng2: north.longitude)
        XCTAssertEqual(b, 0, accuracy: 1.0)
    }

    func test_bearingEastIs90() {
        let p = CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639)
        let east = CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3739)
        let b = calculateBearing(lat1: p.latitude, lng1: p.longitude,
                                 lat2: east.latitude, lng2: east.longitude)
        XCTAssertEqual(b, 90, accuracy: 1.0)
    }

    func test_formatDistance() {
        XCTAssertEqual(formatDistance(850),  "850 m")
        XCTAssertEqual(formatDistance(999),  "999 m")
        XCTAssertEqual(formatDistance(1500), "1.5 km")
        XCTAssertEqual(formatDistance(8500), "8.5 km")
    }
}
