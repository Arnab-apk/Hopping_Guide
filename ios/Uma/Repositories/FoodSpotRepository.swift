// Repositories/FoodSpotRepository.swift — loads food_spots.json (66 entries)

import Foundation

final class FoodSpotRepository: @unchecked Sendable {
    static let shared = FoodSpotRepository()
    private(set) var all: [FoodSpot] = []
    private(set) var isLoaded = false

    private init() {}

    func load() {
        guard !isLoaded else { return }
        guard let url = Bundle.main.url(forResource: "food_spots", withExtension: "json") else {
            isLoaded = true
            return
        }
        do {
            let data = try Data(contentsOf: url)
            all = try JSONDecoder().decode([FoodSpot].self, from: data)
            isLoaded = true
        } catch {
            print("[FoodSpotRepository] decode error: \(error)")
            isLoaded = true
        }
    }

    func within(_ meters: Double, of center: (latitude: Double, longitude: Double)) -> [FoodSpot] {
        all.filter {
            haversineMeters(center.latitude, center.longitude, $0.lat, $0.lng) <= meters
        }
    }
}
