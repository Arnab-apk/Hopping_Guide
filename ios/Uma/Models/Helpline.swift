// Helpline.swift — port from supplementary_repository.dart

import Foundation

struct Helpline: Identifiable, Codable, Hashable, Sendable {
    let label: String
    let number: String

    var id: String { "\(label)|\(number)" }

    enum CodingKeys: String, CodingKey {
        case label, number
    }
}

struct SafetyGuide: Identifiable, Codable, Hashable, Sendable {
    let title: String
    let icon: String?       // keyword matched in HelplinesView for icon
    let content: [String]

    var id: String { title }

    enum CodingKeys: String, CodingKey {
        case title, icon, content
    }
}
