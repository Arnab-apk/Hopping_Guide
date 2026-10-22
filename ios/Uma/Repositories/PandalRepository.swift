// Repositories/PandalRepository.swift — bundled directory used by map and search.

import Foundation

final class PandalRepository: @unchecked Sendable {
    static let shared = PandalRepository()

    private(set) var allPandals: [Pandal] = []
    private(set) var normalizedSearchTextByID: [String: String] = [:]
    private(set) var isLoaded = false
    var totalCount: Int { allPandals.count }

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
            normalizedSearchTextByID = Dictionary(uniqueKeysWithValues: allPandals.map { pandal in
                let stationNames = pandal.nearestStations.flatMap { [$0.name, $0.nameBn ?? "", $0.code ?? ""] }
                let terms = ([pandal.name, pandal.nameBn ?? "", pandal.theme, pandal.area ?? "",
                              pandal.nearestMetro ?? "", pandal.nearestRailway ?? "", pandal.zone.label]
                             + stationNames)
                    .joined(separator: " ")
                return (pandal.id, SearchNormalize.normalize(terms))
            })
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
