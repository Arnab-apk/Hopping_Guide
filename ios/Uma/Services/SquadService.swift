// Services/SquadService.swift — local mock-only squad (no backend)
// Tracks: current squad identity, members, separation alert threshold.

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class SquadService {
    static let shared = SquadService()

    var currentCode: String?
    var currentName: String?
    var meetupPointName: String?
    var meetupPointCoordinate: CLLocationCoordinate2D?
    var shareLocation: Bool = true
    var separationAlertMeters: Double = 500  // default per Flutter source
    var members: [SquadMember] = []

    var hasActiveSquad: Bool { currentCode != nil && currentName != nil }

    var companionMembers: [SquadMember] {
        members.filter { !$0.isUser }
    }

    var connectionState: ConnectionState = .offline
    enum ConnectionState { case connected, connecting, reconnecting, offline }

    func createSquad(name: String, host: SquadMember) {
        currentCode = "PUJA" + String(Int.random(in: 1000...9999))
        currentName = name
        meetupPointName = "Park Street Metro"
        meetupPointCoordinate = CLLocationCoordinate2D(latitude: 22.5535, longitude: 88.3517)
        members = [host]
        connectionState = .connected
        Haptics.notifySuccess()
    }

    func joinSquad(code: String) {
        currentCode = code
        currentName = "Hop Squad \(code)"
        // Seed with a few mock companions around the central Kolkata area
        members = SquadService.seedCompanions()
        meetupPointCoordinate = CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639)
        meetupPointName = "College Street"
        connectionState = .connected
        Haptics.notifySuccess()
    }

    func leaveSquad() {
        currentCode = nil
        currentName = nil
        meetupPointCoordinate = nil
        meetupPointName = nil
        members = []
        connectionState = .offline
    }

    func updateUserLocation(_ coord: CLLocationCoordinate2D) {
        guard let idx = members.firstIndex(where: { $0.isUser }) else { return }
        members[idx].latitude = coord.latitude
        members[idx].longitude = coord.longitude
        members[idx].lastSeen = Date()
    }

    func toggleLocationSharing() {
        shareLocation.toggle()
        guard let idx = members.firstIndex(where: { $0.isUser }) else { return }
        members[idx].shareLocation = shareLocation
        Haptics.selection()
    }

    func setSeparationAlert(meters: Double) {
        separationAlertMeters = meters
        Haptics.selection()
    }

    func setMeetupPoint(name: String, coordinate: CLLocationCoordinate2D) {
        meetupPointName = name
        meetupPointCoordinate = coordinate
        Haptics.notifySuccess()
    }

    // MARK: - Mock seed

    private static func seedCompanions() -> [SquadMember] {
        [
            SquadMember(id: "u1", name: "Anika Sen",
                        latitude: 22.5726, longitude: 88.3639,
                        lastSeen: Date().addingTimeInterval(-8),
                        isHost: true, isUser: true,
                        shareLocation: true, isOnline: true,
                        batteryLevel: 87, avatarColorHex: 0xFFFFB300),
            SquadMember(id: "u2", name: "Rohan Mukherjee",
                        latitude: 22.5750, longitude: 88.3700,
                        lastSeen: Date().addingTimeInterval(-22),
                        isHost: false, shareLocation: true, isOnline: true,
                        batteryLevel: 64, avatarColorHex: 0xFF1A73E8),
            SquadMember(id: "u3", name: "Priya Das",
                        latitude: 22.5650, longitude: 88.3500,
                        lastSeen: Date().addingTimeInterval(-180),
                        isHost: false, shareLocation: true, isOnline: true,
                        batteryLevel: 42, avatarColorHex: 0xFFD32F2F),
            SquadMember(id: "u4", name: "Arijit Banerjee",
                        latitude: 22.5820, longitude: 88.4095,
                        lastSeen: Date().addingTimeInterval(-30),
                        isHost: false, shareLocation: true, isOnline: true,
                        batteryLevel: 71, avatarColorHex: 0xFF2E9E4F),
        ]
    }
}
