// SquadMember.swift — port of models/squad_member.dart

import Foundation
import SwiftUI

enum MemberMarkerState {
    case fresh      // 🟢 Online + sharing (< 15s)
    case stale      // 🟡 Online + location stale (15–60s)
    case old        // ⚫ Stale location (> 60s)
    case notSharing // ⚫ Online + not sharing
    case offline    // ⚪ Offline
}

struct SquadMember: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var status: String
    var lastSeen: Date
    var photoUrl: String?
    var phoneNumber: String?
    var isHost: Bool
    var isUser: Bool
    var shareLocation: Bool
    var isOnline: Bool
    var batteryLevel: Int
    var avatarColorHex: Int  // 0xAARRGGBB

    var avatarColor: Color { Color(hex: UInt32(avatarColorHex & 0xFFFFFF)) }

    var ageSinceLastSeen: TimeInterval { Date().timeIntervalSince(lastSeen) }

    var markerState: MemberMarkerState {
        if !isOnline { return .offline }
        if !shareLocation { return .notSharing }
        let sec = ageSinceLastSeen
        if sec < 15 { return .fresh }
        if sec <= 60 { return .stale }
        return .old
    }

    var markerStateDot: String {
        switch markerState {
        case .fresh:      return "🟢"
        case .stale:      return "🟡"
        case .notSharing, .old: return "⚫"
        case .offline:    return "⚪"
        }
    }

    var lastSeenText: String {
        let diff = ageSinceLastSeen
        if diff < 15 { return "Live now" }
        if diff < 60 { return "\(Int(diff))s ago" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        return "\(Int(diff / 3600))h ago"
    }

    var initials: String {
        let parts = name.split(separator: " ").map(String.init)
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return name.isEmpty ? "M" : String(name.prefix(1)).uppercased()
    }

    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }

    init(id: String, name: String, latitude: Double, longitude: Double,
         status: String = "Active • Pandal Hopping",
         lastSeen: Date = Date(), photoUrl: String? = nil, phoneNumber: String? = nil,
         isHost: Bool = false, isUser: Bool = false,
         shareLocation: Bool = true, isOnline: Bool = true,
         batteryLevel: Int = 90, avatarColorHex: Int = 0xFFFFB300) {
        self.id = id; self.name = name
        self.latitude = latitude; self.longitude = longitude
        self.status = status; self.lastSeen = lastSeen
        self.photoUrl = photoUrl; self.phoneNumber = phoneNumber
        self.isHost = isHost; self.isUser = isUser
        self.shareLocation = shareLocation; self.isOnline = isOnline
        self.batteryLevel = batteryLevel; self.avatarColorHex = avatarColorHex
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
