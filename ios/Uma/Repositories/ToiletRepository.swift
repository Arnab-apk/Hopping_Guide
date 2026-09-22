// Repositories/ToiletRepository.swift — loads toilets.json

import Foundation

final class ToiletRepository: @unchecked Sendable {
    static let shared = ToiletRepository()

    private(set) var entries: [ToiletEntry] = []
    private(set) var byPandal: [String: PandalToilets] = [:]

    private init() {}

    func load() {
        guard let url = Bundle.main.url(forResource: "toilets", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            entries = try JSONDecoder().decode([ToiletEntry].self, from: data)
        } catch {
            print("[ToiletRepository] decode error: \(error)")
        }
    }
}
