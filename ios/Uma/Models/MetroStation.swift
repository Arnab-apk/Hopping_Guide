// MetroStation.swift — port of app/lib/models/metro_station.dart

import Foundation
import SwiftUI
import CoreLocation

enum KolkataMetroLine: String, Codable, CaseIterable, Hashable {
    case blue, green, purple, orange, yellow

    var code: String { rawValue }

    var label: String {
        switch self {
        case .blue:   return "Blue Line (Line 1)"
        case .green:  return "Green Line (Line 2)"
        case .purple: return "Purple Line (Line 3)"
        case .orange: return "Orange Line (Line 6)"
        case .yellow: return "Yellow Line (Line 4)"
        }
    }

    var corridor: String {
        switch self {
        case .blue:   return "Dakshineswar ⇄ Kavi Subhash"
        case .green:  return "Howrah Maidan ⇄ Salt Lake Sector-V"
        case .purple: return "Joka ⇄ Majerhat"
        case .orange: return "Kavi Subhash ⇄ Beleghata"
        case .yellow: return "Noapara ⇄ Jai Hind (Airport)"
        }
    }

    var color: Color {
        switch self {
        case .blue:   return Color(red: 0.0,  green: 0.34, blue: 0.72)
        case .green:  return Color(red: 0.18, green: 0.62, blue: 0.31)
        case .purple: return Color(red: 0.48, green: 0.25, blue: 0.63)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.12)
        case .yellow: return Color(red: 0.90, green: 0.72, blue: 0.0)
        }
    }

    static func fromCode(_ code: String?) -> KolkataMetroLine? {
        guard let code = code?.lowercased().trimmingCharacters(in: .whitespaces) else { return nil }
        return KolkataMetroLine(rawValue: code)
    }
}

struct MetroStation: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let nameBn: String?
    let code: String?
    let layout: String?
    let latitude: Double
    let longitude: Double
    let isInterchange: Bool
    let connectingLines: [KolkataMetroLine]
    let popularPandalsNearby: [String]
    let aliases: [String]
    let line: KolkataMetroLine

    enum CodingKeys: String, CodingKey {
        case id, name, nameBn, code, layout
        case latitude = "lat"
        case longitude = "lng"
        case isInterchange = "interchange"
        case connectingLines
        case popularPandalsNearby
        case aliases
        case line
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        nameBn = try? c.decode(String.self, forKey: .nameBn)
        code = try? c.decode(String.self, forKey: .code)
        layout = try? c.decode(String.self, forKey: .layout)
        latitude = try c.decode(Double.self, forKey: .latitude)
        longitude = try c.decode(Double.self, forKey: .longitude)
        let rawLines = (try? c.decode([String].self, forKey: .connectingLines)) ?? []
        let primaryLine: KolkataMetroLine = (try? c.decode(KolkataMetroLine.self, forKey: .line)) ?? .blue
        isInterchange = (try? c.decode(Bool.self, forKey: .isInterchange)) ?? !rawLines.isEmpty
        connectingLines = rawLines.compactMap { KolkataMetroLine(rawValue: $0) }.filter { $0 != primaryLine }
        popularPandalsNearby = (try? c.decode([String].self, forKey: .popularPandalsNearby)) ?? []
        aliases = (try? c.decode([String].self, forKey: .aliases)) ?? []
        line = primaryLine
    }

    init(id: String, name: String, nameBn: String? = nil, code: String? = nil,
         layout: String? = nil, latitude: Double, longitude: Double,
         isInterchange: Bool = false, connectingLines: [KolkataMetroLine] = [],
         popularPandalsNearby: [String] = [], aliases: [String] = [],
         line: KolkataMetroLine) {
        self.id = id; self.name = name; self.nameBn = nameBn; self.code = code
        self.layout = layout; self.latitude = latitude; self.longitude = longitude
        self.isInterchange = isInterchange
        self.connectingLines = connectingLines
        self.popularPandalsNearby = popularPandalsNearby
        self.aliases = aliases; self.line = line
    }

    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var displayName: String { name }
    var fullDisplayName: String { (nameBn?.isEmpty == false) ? "\(name) (\(nameBn!))" : name }

    var subtitle: String {
        if isInterchange {
            let others = connectingLines.map(\.label).joined(separator: ", ")
            return "Interchange (\(line.label) & \(others))"
        }
        return line.label
    }

    func matchesId(_ queryId: String) -> Bool {
        if id == queryId { return true }
        let cleanQuery = queryId.hasPrefix("m_") ? String(queryId.dropFirst(2)) : queryId
        let normalizedId = id.replacingOccurrences(of: "-", with: "_")
        let normalizedQuery = cleanQuery.replacingOccurrences(of: "-", with: "_")
        if normalizedId == normalizedQuery { return true }
        return aliases.contains { $0.lowercased() == queryId.lowercased() }
    }
}
