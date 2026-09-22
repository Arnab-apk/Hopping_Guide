// Repositories/HelplineRepository.swift — loads helplines.json + safety_first_aid.json

import Foundation

final class HelplineRepository: @unchecked Sendable {
    static let shared = HelplineRepository()

    private(set) var helplines: [Helpline] = []
    private(set) var safetyGuides: [SafetyGuide] = []

    private init() {}

    func load() {
        if let url = Bundle.main.url(forResource: "helplines", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let items = try? JSONDecoder().decode([Helpline].self, from: data) {
            helplines = items
        }
        if let url = Bundle.main.url(forResource: "safety_first_aid", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let items = try? JSONDecoder().decode([SafetyGuide].self, from: data) {
            safetyGuides = items
        }
    }
}
