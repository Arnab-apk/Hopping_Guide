// Services/OmniSearchService.swift — port of services/omni_search_service.dart
// Phonetic / token-weighted bilingual search across Pandals, Metro, Food.

import Foundation
import SwiftUI
import CoreLocation

enum OmniCategory: String, CaseIterable, Identifiable {
    case all, pandals, metro, food
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all:     return "All"
        case .pandals: return "Pandals"
        case .metro:   return "Metro"
        case .food:    return "Food"
        }
    }
    var iconName: String {
        switch self {
        case .all:     return "sparkles"
        case .pandals: return "building.columns"
        case .metro:   return "tram.fill"
        case .food:    return "fork.knife"
        }
    }
}

enum OmniResultType: String, Codable, Sendable {
    case pandal, metro, food
}

struct OmniSearchResult: Identifiable, Hashable, Sendable {
    let type: OmniResultType
    let id: String
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let score: Double
    let matchedField: String
    let distanceMeters: Double?
    let badgeText: String?
    let badgeColorHex: UInt32?
    let rating: Double?
    let pandalId: String?
    let metroStationId: String?
    let foodSpotId: String?

    var iconName: String {
        switch type {
        case .pandal: return "building.columns"
        case .metro:  return "tram.fill"
        case .food:   return "fork.knife"
        }
    }

    var badgeColor: Color? {
        guard let h = badgeColorHex else { return nil }
        return Color(hex: h)
    }

    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}

/// Normalizes text for comparison: lowercase, strips punctuation, collapses whitespace.
enum SearchNormalize {
    static func normalize(_ raw: String) -> String {
        let lowered = raw.lowercased()
        let scalars = lowered.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
        }
        let collapsed = String(scalars).split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")
        return collapsed
    }

    static func buildHighlightSpans(text: String, query: String,
                                    normalStyle: AttributedString = .init(),
                                    highlightStyle: AttributedString = .init()) -> AttributedString {
        var result = AttributedString(text)
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return result }
        let lower = text.lowercased()
        var searchStart = lower.startIndex
        while let range = lower.range(of: q, range: searchStart..<lower.endIndex) {
            if let attrRange = Range(range, in: result) {
                result[attrRange].foregroundColor = .primary
            }
            searchStart = range.upperBound
        }
        _ = (normalStyle, highlightStyle)
        return result
    }
}

final class OmniSearchService: @unchecked Sendable {
    static let shared = OmniSearchService()
    private init() {}

    private var searchCache: [String: [OmniSearchResult]] = [:]
    private let cacheLimit = 80

    /// Search across pandals, food spots, and metro stations.
    /// Default cap of 8 results per query, like the Flutter source.
    func search(
        query: String,
        pandals: [Pandal],
        foodSpots: [FoodSpot] = [],
        metroStations: [MetroStation] = [],
        category: OmniCategory = .all,
        limit: Int = 8,
        userLat: Double? = nil,
        userLng: Double? = nil
    ) -> [OmniSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        let cacheKey = "\(category.rawValue)|\(trimmed.lowercased())|\(limit)|\(pandals.count)|\(foodSpots.count)|\(metroStations.count)|\(userLat?.description ?? "")|\(userLng?.description ?? "")"
        if let cached = searchCache[cacheKey] { return cached }

        var results: [OmniSearchResult] = []
        if category == .all || category == .pandals {
            for p in pandals {
                if let r = scorePandal(p, query: trimmed, userLat: userLat, userLng: userLng) {
                    results.append(r)
                }
            }
        }
        if category == .all || category == .metro {
            for st in metroStations {
                if let r = scoreMetroStation(st, query: trimmed, userLat: userLat, userLng: userLng) {
                    results.append(r)
                }
            }
        }
        if (category == .all || category == .food), !foodSpots.isEmpty {
            for f in foodSpots {
                if let r = scoreFoodSpot(f, query: trimmed, userLat: userLat, userLng: userLng) {
                    results.append(r)
                }
            }
        }
        results.sort { $0.score > $1.score }
        let final = Array(results.prefix(limit))

        if searchCache.count >= cacheLimit { searchCache.removeAll() }
        searchCache[cacheKey] = final
        return final
    }

    func clearCache() { searchCache.removeAll() }

    // MARK: - Scoring

    func scorePandal(_ p: Pandal, query: String, userLat: Double? = nil, userLng: Double? = nil) -> OmniSearchResult? {
        let q = SearchNormalize.normalize(query)
        let tokens = q.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return nil }

        let normName = SearchNormalize.normalize(p.name)
        let normTheme = SearchNormalize.normalize(p.theme)
        let normArea = SearchNormalize.normalize(p.area ?? "")
        let normMetro = SearchNormalize.normalize(p.nearestMetro ?? "")

        var score: Double = 0
        var matchedField = "Name"

        if normName == q { score += 1300 }
        else if normName.hasPrefix(q) { score += 850 }
        else if normName.contains(q) { score += 480 }

        var tokensMatched = 0
        for t in tokens {
            var matched = false
            for w in normName.split(separator: " ").map(String.init) {
                if w == t { score += 320; matched = true; break }
                if w.hasPrefix(t) { score += 220; matched = true; break }
            }
            if !matched && normName.contains(t) { score += 160; matched = true }
            if !matched && (normTheme.contains(t) || normArea.contains(t) || normMetro.contains(t)) {
                score += 140
                matched = true
                matchedField = "Theme / Metro"
            }
            if matched { tokensMatched += 1 }
        }
        guard tokensMatched >= tokens.count else { return nil }

        // Rating boost
        if let r = p.rating { score += r * 5 }

        // Distance bonus
        var distMeters: Double?
        if let ulat = userLat, let ulng = userLng {
            let d = haversineMeters(ulat, ulng, p.lat, p.lng)
            distMeters = d
            let km = d / 1000
            score += max(0, (15 - km) * 5)
        }

        var subtitleParts: [String] = [p.zone.label]
        if let m = p.nearestMetro, !m.isEmpty { subtitleParts.append("🚇 \(m)") }
        if !p.theme.isEmpty { subtitleParts.append(p.theme) }

        return OmniSearchResult(
            type: .pandal,
            id: p.id,
            title: p.name,
            subtitle: subtitleParts.joined(separator: " · "),
            latitude: p.lat,
            longitude: p.lng,
            score: score,
            matchedField: matchedField,
            distanceMeters: distMeters,
            badgeText: p.zone.shortLabel.uppercased(),
            badgeColorHex: 0xB71C1C,
            rating: p.rating,
            pandalId: p.id,
            metroStationId: nil,
            foodSpotId: nil)
    }

    func scoreMetroStation(_ s: MetroStation, query: String, userLat: Double? = nil, userLng: Double? = nil) -> OmniSearchResult? {
        let q = SearchNormalize.normalize(query)
        let tokens = q.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return nil }

        let normName = SearchNormalize.normalize(s.name)
        let normLine = SearchNormalize.normalize(s.line.label)
        let normCorridor = SearchNormalize.normalize(s.line.corridor)
        let normAliases = s.aliases.map { SearchNormalize.normalize($0) }

        var score: Double = 0
        var matchedField = "Name"

        if normName == q || normAliases.contains(q) { score += 1300 }
        else if normName.hasPrefix(q) || normAliases.contains(where: { $0.hasPrefix(q) }) { score += 850 }
        else if normName.contains(q) || normAliases.contains(where: { $0.contains(q) }) { score += 480 }

        var tokensMatched = 0
        for t in tokens {
            var matched = false
            for w in normName.split(separator: " ").map(String.init) {
                if w == t { score += 320; matched = true; break }
                if w.hasPrefix(t) { score += 220; matched = true; break }
            }
            if !matched && normName.contains(t) { score += 160; matched = true }
            if t == "metro" || t == "station" {
                score += 200; matched = true; matchedField = "Metro System"
            }
            if normLine.contains(t) || normCorridor.contains(t) {
                score += 180; matched = true; matchedField = "Metro Line"
            }
            if matched { tokensMatched += 1 }
        }
        guard tokensMatched >= tokens.count else { return nil }

        if s.isInterchange { score += 50 }

        var distMeters: Double?
        if let ulat = userLat, let ulng = userLng {
            let d = haversineMeters(ulat, ulng, s.latitude, s.longitude)
            distMeters = d
            let km = d / 1000
            score += max(0, (15 - km) * 5)
        }

        return OmniSearchResult(
            type: .metro,
            id: s.id,
            title: s.name,
            subtitle: s.subtitle,
            latitude: s.latitude,
            longitude: s.longitude,
            score: score,
            matchedField: matchedField,
            distanceMeters: distMeters,
            badgeText: s.line.code.uppercased(),
            badgeColorHex: hexFromColor(s.line.color),
            rating: nil,
            pandalId: nil,
            metroStationId: s.id,
            foodSpotId: nil)
    }

    func scoreFoodSpot(_ f: FoodSpot, query: String, userLat: Double? = nil, userLng: Double? = nil) -> OmniSearchResult? {
        let q = SearchNormalize.normalize(query)
        let tokens = q.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return nil }

        let normName = SearchNormalize.normalize(f.name)
        let normType = SearchNormalize.normalize(f.type)
        let normMustTry = SearchNormalize.normalize(f.mustTry ?? "")

        var score: Double = 0
        var matchedField = "Name"

        if normName == q { score += 1250 }
        else if normName.hasPrefix(q) { score += 820 }
        else if normName.contains(q) { score += 460 }

        var tokensMatched = 0
        for t in tokens {
            var matched = false
            for w in normName.split(separator: " ").map(String.init) {
                if w == t { score += 310; matched = true; break }
                if w.hasPrefix(t) { score += 210; matched = true; break }
            }
            if !matched && normName.contains(t) { score += 150; matched = true }
            if normType.contains(t) { score += 180; matched = true; matchedField = "Cuisine" }
            if normMustTry.contains(t) { score += 190; matched = true; matchedField = "Specialty" }
            if t == "food" || t == "restaurant" || t == "eat" || t == "eating" {
                score += 120; matched = true; matchedField = "Food Spot"
            }
            if matched { tokensMatched += 1 }
        }
        guard tokensMatched >= tokens.count else { return nil }

        if let r = f.rating { score += r * 5 }

        var distMeters: Double?
        if let ulat = userLat, let ulng = userLng {
            let d = haversineMeters(ulat, ulng, f.lat, f.lng)
            distMeters = d
            let km = d / 1000
            score += max(0, (15 - km) * 5)
        }

        var subtitleParts: [String] = []
        if let m = f.mustTry, !m.isEmpty { subtitleParts.append(m) } else { subtitleParts.append(f.type) }
        if !f.nearbyPandal.isEmpty { subtitleParts.append("Near \(f.nearbyPandal)") }

        return OmniSearchResult(
            type: .food,
            id: f.id,
            title: f.name,
            subtitle: subtitleParts.joined(separator: " · "),
            latitude: f.lat,
            longitude: f.lng,
            score: score,
            matchedField: matchedField,
            distanceMeters: distMeters,
            badgeText: f.priceRange ?? "FOOD",
            badgeColorHex: 0xFF9100,
            rating: f.rating,
            pandalId: nil,
            metroStationId: nil,
            foodSpotId: f.id)
    }
}

/// Extract a hex UInt32 from a SwiftUI Color (best-effort, for color badges).
private func hexFromColor(_ color: Color) -> UInt32 {
    let resolved = color.resolve(in: .init())
    let r = UInt32(max(0, min(255, Int(resolved.red * 255))))
    let g = UInt32(max(0, min(255, Int(resolved.green * 255))))
    let b = UInt32(max(0, min(255, Int(resolved.blue * 255))))
    return (r << 16) | (g << 8) | b
}
