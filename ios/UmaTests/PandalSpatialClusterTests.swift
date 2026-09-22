// UmaTests/PandalSpatialClusterTests.swift

import XCTest
import CoreLocation
@testable import Uma

final class PandalSpatialClusterTests: XCTestCase {
    private func pandalsInZones() -> [Pandal] {
        [
            Pandal(id: "1", name: "A", lat: 22.520, lng: 88.366, zone: .southKolkata,
                   theme: "", timings: "", imageUrl: nil, description: "",
                   area: nil, region: nil, rating: 4.5, crowdLevel: nil,
                   nearestMetro: nil, nearestMetroList: [], nearestRailway: nil,
                   nearestRailwayList: [], transport: [], specialFeatures: []),
            Pandal(id: "2", name: "B", lat: 22.595, lng: 88.370, zone: .northKolkata,
                   theme: "", timings: "", imageUrl: nil, description: "",
                   area: nil, region: nil, rating: 4.0, crowdLevel: nil,
                   nearestMetro: nil, nearestMetroList: [], nearestRailway: nil,
                   nearestRailwayList: [], transport: [], specialFeatures: []),
            Pandal(id: "3", name: "C", lat: 22.572, lng: 88.363, zone: .centralKolkata,
                   theme: "", timings: "", imageUrl: nil, description: "",
                   area: nil, region: nil, rating: 4.6, crowdLevel: nil,
                   nearestMetro: nil, nearestMetroList: [], nearestRailway: nil,
                   nearestRailwayList: [], transport: [], specialFeatures: []),
        ]
    }

    func test_zoneCountsCoverAllZones() {
        let counts = PandalSpatialCluster.zoneCounts(pandalsInZones())
        XCTAssertEqual(counts[.southKolkata], 1)
        XCTAssertEqual(counts[.northKolkata], 1)
        XCTAssertEqual(counts[.centralKolkata], 1)
        XCTAssertEqual(counts[.saltLake], 0)
    }

    func test_filterByZone() {
        let result = PandalSpatialCluster.filter(pandalsInZones(), by: .southKolkata)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "1")
    }

    func test_withinRadius() {
        let center = CLLocationCoordinate2D(latitude: 22.572, longitude: 88.363)
        let nearby = PandalSpatialCluster.withinRadius(pandalsInZones(),
                                                       radiusMeters: 5_000,
                                                       of: center)
        // The central and south pandals are close enough; north is further.
        XCTAssertGreaterThanOrEqual(nearby.count, 1)
        XCTAssertFalse(nearby.contains(where: { $0.zone == .northKolkata }))
    }

    func test_sortByRatingDescending() {
        let sorted = PandalSpatialCluster.sortByRating(pandalsInZones())
        XCTAssertEqual(sorted.first?.rating, 4.6)
        XCTAssertEqual(sorted.last?.rating, 4.0)
    }

    func test_sortByDistanceAscending() {
        let origin = CLLocationCoordinate2D(latitude: 22.572, longitude: 88.363)
        let sorted = PandalSpatialCluster.sortByDistance(pandalsInZones(), from: origin)
        XCTAssertEqual(sorted.first?.zone, .centralKolkata)
    }
}
