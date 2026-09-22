// UmaTests/OmniSearchTests.swift

import XCTest
import CoreLocation
@testable import Uma

final class OmniSearchTests: XCTestCase {

    private func samplePandals() -> [Pandal] {
        [
            Pandal(id: "1", name: "Ekdalia Evergreen", lat: 22.520, lng: 88.366,
                   zone: .southKolkata, theme: "Traditional Bengali", timings: "",
                   imageUrl: nil, description: "",
                   area: "Ballygunge", region: nil, rating: 4.7,
                   crowdLevel: "high", nearestMetro: "Kalighat",
                   nearestMetroList: [], nearestRailway: nil,
                   nearestRailwayList: [], transport: [], specialFeatures: []),
            Pandal(id: "2", name: "Shyambazar 5 Point Crossing", lat: 22.595, lng: 88.370,
                   zone: .northKolkata, theme: "Heritage", timings: "",
                   imageUrl: nil, description: "",
                   area: "Shyambazar", region: nil, rating: 4.5,
                   crowdLevel: "high", nearestMetro: "Shyambazar",
                   nearestMetroList: [], nearestRailway: nil,
                   nearestRailwayList: [], transport: [], specialFeatures: []),
            Pandal(id: "3", name: "College Square", lat: 22.572, lng: 88.363,
                   zone: .centralKolkata, theme: "Iconic", timings: "",
                   imageUrl: nil, description: "",
                   area: nil, region: nil, rating: 4.6,
                   crowdLevel: "medium", nearestMetro: nil,
                   nearestMetroList: [], nearestRailway: nil,
                   nearestRailwayList: [], transport: [], specialFeatures: []),
        ]
    }

    private func sampleFood() -> [FoodSpot] {
        [
            FoodSpot(id: "f1", name: "Golbari", type: "Kosha Mangsho",
                     lat: 22.601, lng: 88.370, nearbyPandal: "Shyambazar",
                     mustTry: "Kasha Mangsho", priceRange: "₹₹", rating: 4.4),
            FoodSpot(id: "f2", name: "Mitra Cafe", type: "Heritage Snacks",
                     lat: 22.599, lng: 88.371, nearbyPandal: "Shyambazar",
                     mustTry: "Fish Fry", priceRange: "₹₹", rating: 4.5),
        ]
    }

    private func sampleMetro() -> [MetroStation] {
        MetroRepository.allStations
    }

    func test_shyambazarRanksShyambazar5Point_first() {
        let service = OmniSearchService.shared
        let results = service.search(
            query: "shyam",
            pandals: samplePandals(),
            foodSpots: sampleFood(),
            metroStations: sampleMetro())
        XCTAssertFalse(results.isEmpty)
        // First should be the Shyambazar pandal or metro
        XCTAssertTrue(results.first?.title.lowercased().contains("shyam") ?? false)
    }

    func test_mangshoRanksGolbari_first() {
        let service = OmniSearchService.shared
        let results = service.search(
            query: "mangsho",
            pandals: samplePandals(),
            foodSpots: sampleFood(),
            metroStations: sampleMetro())
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.first?.title.lowercased().contains("golbari") ?? false)
    }

    func test_kalighatMatchesMetroAndPandal() {
        let service = OmniSearchService.shared
        let results = service.search(
            query: "kalighat",
            pandals: samplePandals(),
            foodSpots: sampleFood(),
            metroStations: sampleMetro())
        let titles = results.map(\.title).map { $0.lowercased() }
        XCTAssertTrue(titles.contains(where: { $0.contains("kalighat") }))
    }

    func test_emptyQueryReturnsEmpty() {
        let results = OmniSearchService.shared.search(
            query: "",
            pandals: samplePandals(),
            foodSpots: sampleFood(),
            metroStations: sampleMetro())
        XCTAssertTrue(results.isEmpty)
    }
}
