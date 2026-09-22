// KolkataZone.swift
// 8 Kolkata zones — port of constants.dart

import Foundation
import SwiftUI

enum KolkataZone: String, Codable, CaseIterable, Hashable {
    case northKolkata
    case centralKolkata
    case southKolkata
    case saltLake
    case newTown
    case nadiaKalyani
    case hooghlyChinsurah
    case hooghlyBandel

    var label: String {
        switch self {
        case .northKolkata:      return "North Kolkata"
        case .centralKolkata:     return "Central Kolkata"
        case .southKolkata:      return "South Kolkata"
        case .saltLake:          return "Salt Lake"
        case .newTown:           return "New Town"
        case .nadiaKalyani:      return "Kalyani (Nadia)"
        case .hooghlyChinsurah:  return "Chinsurah (Hooghly)"
        case .hooghlyBandel:     return "Bandel (Hooghly)"
        }
    }

    var shortLabel: String {
        switch self {
        case .northKolkata:      return "North"
        case .centralKolkata:     return "Central"
        case .southKolkata:      return "South"
        case .saltLake:          return "Salt Lake"
        case .newTown:           return "New Town"
        case .nadiaKalyani:      return "Kalyani"
        case .hooghlyChinsurah:  return "Chinsurah"
        case .hooghlyBandel:     return "Bandel"
        }
    }

    var isKolkataCity: Bool {
        switch self {
        case .northKolkata, .centralKolkata, .southKolkata, .saltLake, .newTown:
            return true
        case .nadiaKalyani, .hooghlyChinsurah, .hooghlyBandel:
            return false
        }
    }

    /// Geographic center used to zoom the map when this zone is selected.
    var centerCoordinate: (latitude: Double, longitude: Double) {
        switch self {
        case .northKolkata:      return (22.597, 88.368)
        case .centralKolkata:     return (22.571, 88.363)
        case .southKolkata:      return (22.520, 88.358)
        case .saltLake:          return (22.588, 88.415)
        case .newTown:           return (22.585, 88.468)
        case .nadiaKalyani:      return (22.980, 88.433)
        case .hooghlyChinsurah:  return (22.896, 88.389)
        case .hooghlyBandel:     return (22.919, 88.381)
        }
    }

    var defaultZoom: Double {
        switch self {
        case .nadiaKalyani:      return 13.5
        case .hooghlyChinsurah, .hooghlyBandel: return 13.8
        default:                 return 13.5
        }
    }
}

extension KolkataZone {
    /// Parse zone from JSON value (string or zone enum-name). Falls back to centralKolkata.
    static func parse(_ raw: String?) -> KolkataZone {
        guard let raw = raw?.lowercased() else { return .centralKolkata }
        return KolkataZone(rawValue: raw) ?? .centralKolkata
    }
}
