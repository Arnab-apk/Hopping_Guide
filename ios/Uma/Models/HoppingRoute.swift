// HoppingRoute.swift — 6 curated routes hardcoded (port of routes_screen.dart)

import Foundation
import SwiftUI

enum HoppingStyle: String, Codable, CaseIterable {
    case express, heritage, family, bonedi, modern
}

enum RouteCategoryFilter: String, CaseIterable, Identifiable {
    case all, north, south, bonedi, east, express
    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:    return "All"
        case .north:  return "North"
        case .south:  return "South"
        case .bonedi: return "Bonedi"
        case .east:   return "East"
        case .express:return "Express"
        }
    }

    var iconName: String {
        switch self {
        case .all:    return "sparkles"
        case .north:  return "arrow.up"
        case .south:  return "arrow.down"
        case .bonedi: return "building.columns"
        case .east:   return "arrow.right"
        case .express:return "bolt"
        }
    }
}

struct HoppingRoute: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let bengaliTitle: String?
    let subtitle: String
    let durationMinutes: Int
    let distanceKm: Double
    let bestTime: String
    let pandalIds: [String]
    let iconSystemName: String
    let zoneTag: String
    let category: RouteCategoryFilter

    /// Hardcoded curated routes — mirrors routes_screen.dart line 79.
    static let all: [HoppingRoute] = [
        HoppingRoute(
            id: "north_heritage_walk",
            title: "North Kolkata Heritage Walk",
            bengaliTitle: "উত্তর কলকাতা ঐতিহ্য",
            subtitle: "Walk through centuries-old North Kolkata — Kumartuli, Sovabazar, Bagbazar, Jorasanko. Heritage pandals meet artisan workshops.",
            durationMinutes: 280, distanceKm: 6.8, bestTime: "Evening 6 PM – 9 PM (post-Ashtami)",
            pandalIds: ["kumartuli_park", "sovabazar_rajbari", "bagbazar_sarbojanin",
                        "jorasanko_thakur_bari", "ahiritola_sarbojanin"],
            iconSystemName: "building.columns",
            zoneTag: "North", category: .north),

        HoppingRoute(
            id: "south_grand_circuit",
            title: "South Kolkata Grand Circuit",
            bengaliTitle: "দক্ষিণ কলকাতা মহাপরিক্রমা",
            subtitle: "Iconic south pandals — Ekdalia Evergreen, Ballygunge Cultural, College Square. Lights, themes, and family crowds.",
            durationMinutes: 360, distanceKm: 9.4, bestTime: "Night 8 PM – 11 PM (post-Sandhi Puja)",
            pandalIds: ["ekdalia_evergreen", "ballygunge_cultural", "college_square",
                        "gariahat_mohila", "bose_pukur_sarbojanin"],
            iconSystemName: "sparkles",
            zoneTag: "South", category: .south),

        HoppingRoute(
            id: "south_west_thematic",
            title: "South-West Thematic Wonder Trail",
            bengaliTitle: "দক্ষিণ-পশ্চিম থিম ট্রেইল",
            subtitle: "Behala & Jadavpur theme kings. Larger-than-life installations and modern art pandals.",
            durationMinutes: 300, distanceKm: 8.2, bestTime: "Day 4 PM – 8 PM",
            pandalIds: ["11_pally_club", "behala_notun_pally", "tollygunge_aurobandhu",
                        "jadavpur_25_pally", "princep_ashu_bose"],
            iconSystemName: "paintpalette",
            zoneTag: "South-West", category: .south),

        HoppingRoute(
            id: "bonedi_zamindari",
            title: "Zamindar & Bonedi Bari Trail",
            bengaliTitle: "বনেদি বাড়ি পরিক্রমা",
            subtitle: "Aristocratic family pandals — Shobhabazar Rajbari, Chatu Babu Latu Babu Thakur Bari, Khelat Babu — old-world charm.",
            durationMinutes: 240, distanceKm: 5.6, bestTime: "Day 11 AM – 4 PM",
            pandalIds: ["sovabazar_rajbari", "chatu_babu_latu_babus_thakur_bari",
                        "khelat_babu", "jorasanko_thakur_bari", "pathuriaghata_tagore_castle"],
            iconSystemName: "crown",
            zoneTag: "Central", category: .bonedi),

        HoppingRoute(
            id: "salt_lake_modern",
            title: "Salt Lake & VIP Road Modern Marvels",
            bengaliTitle: "সল্টলেক আধুনিক পরিক্রমা",
            subtitle: "Steel-and-glass themed marvels in Salt Lake Sector-I, II, III and the new EC blocks. Family-friendly.",
            durationMinutes: 220, distanceKm: 7.1, bestTime: "Evening 5 PM – 9 PM",
            pandalIds: ["salt_lake_b_1_block", "salt_lake_fe_block", "salt_lake_cj_block",
                        "ec_block_sarbojanin", "laboni_sarbojanin"],
            iconSystemName: "building.2",
            zoneTag: "Salt Lake", category: .east),

        HoppingRoute(
            id: "first_timer_express",
            title: "First-Timer's Essential Express",
            bengaliTitle: "প্রথমবারের এক্সপ্রেস",
            subtitle: "If you only have one evening — these 5 pandals capture the best of Kolkata's Puja in one circuit.",
            durationMinutes: 180, distanceKm: 4.2, bestTime: "Evening 7 PM – 10 PM",
            pandalIds: ["ekdalia_evergreen", "ballygunge_cultural", "s_k_das_grove",
                        "maddox_square", "ashwini_nagarik"],
            iconSystemName: "bolt",
            zoneTag: "All Kolkata", category: .express),
    ]

    static func routes(in category: RouteCategoryFilter) -> [HoppingRoute] {
        category == .all ? all : all.filter { $0.category == category }
    }

    func formattedDuration() -> String {
        if durationMinutes < 60 { return "\(durationMinutes) min" }
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    func formattedDistance() -> String {
        String(format: "%.1f km", distanceKm)
    }
}

/// An active trail the user is currently hopping.
struct ActiveCustomTrail: Identifiable, Hashable {
    let id: String
    let name: String
    let stops: [Pandal]
    let startedAt: Date
    let style: HoppingStyle

    init(name: String, stops: [Pandal], style: HoppingStyle = .express) {
        self.id = "trail_\(UUID().uuidString.prefix(8))"
        self.name = name
        self.stops = stops
        self.startedAt = Date()
        self.style = style
    }
}
