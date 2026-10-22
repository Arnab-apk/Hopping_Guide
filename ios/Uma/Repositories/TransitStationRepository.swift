import Foundation

@MainActor
final class TransitStationRepository {
    static let shared = TransitStationRepository()

    private(set) var allStations: [TransitStation] = []
    private(set) var isLoaded = false

    private init() {}

    func load() {
        guard !isLoaded else { return }
        defer { isLoaded = true }
        guard let url = Bundle.main.url(forResource: "stations", withExtension: "geojson"),
              let data = try? Data(contentsOf: url),
              let collection = try? JSONDecoder().decode(StationsGeoJSON.self, from: data) else { return }
        allStations = collection.features.compactMap { $0.station() }
            .sorted { lhs, rhs in
                if lhs.isMetro != rhs.isMetro { return lhs.isMetro }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    func byId(_ id: String) -> TransitStation? {
        let query = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allStations.first {
            $0.id.lowercased() == query || $0.code?.lowercased() == query
        }
    }
}
