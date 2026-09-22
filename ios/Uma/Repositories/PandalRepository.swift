// Repositories/PandalRepository.swift — loads pandals.json (387 entries)

import Foundation

final class PandalRepository: @unchecked Sendable {
    static let shared = PandalRepository()

    private(set) var allPandals: [Pandal] = []
    private(set) var isLoaded = false

    private init() {}

    func load() {
        guard !isLoaded else { return }
        guard let url = Bundle.main.url(forResource: "pandals", withExtension: "json") else {
            print("[PandalRepository] pandals.json missing in bundle")
            isLoaded = true
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            allPandals = try decoder.decode([Pandal].self, from: data)
            isLoaded = true
        } catch {
            print("[PandalRepository] Failed to decode: \(error)")
            isLoaded = true
        }
    }

    func byId(_ id: String) -> Pandal? {
        allPandals.first { $0.id == id }
    }

    func filter(by zone: KolkataZone?) -> [Pandal] {
        guard let zone else { return allPandals }
        return allPandals.filter { $0.zone == zone }
    }

    func within(_ meters: Double, of center: (latitude: Double, longitude: Double)) -> [Pandal] {
        allPandals.filter {
            haversineMeters(center.latitude, center.longitude, $0.lat, $0.lng) <= meters
        }
    }
}
