// Services/ChatService.swift — local mock chat (text-only v1)

import Foundation
import Observation

@MainActor
@Observable
final class ChatService {
    static let shared = ChatService()
    private var messagesBySquad: [String: [ChatMessage]] = [:]

    private init() {
        seedDemoMessages()
    }

    func messages(for squadId: String) -> [ChatMessage] {
        messagesBySquad[squadId] ?? []
    }

    func send(squadId: String, senderId: String, senderName: String, text: String) {
        let msg = ChatMessage(
            id: "msg_\(Int(Date().timeIntervalSince1970 * 1000))",
            squadId: squadId,
            senderId: senderId,
            senderName: senderName,
            text: text,
            timestamp: Date())
        messagesBySquad[squadId, default: []].append(msg)
        Haptics.light()
    }

    private func seedDemoMessages() {
        let demoSquad = "PUJA1234"
        let now = Date()
        messagesBySquad[demoSquad] = [
            ChatMessage(id: "m1", squadId: demoSquad,
                        senderId: "u1", senderName: "Anika Sen",
                        text: "Hoppers, meeting at Shyambazar 5 Point in 30 mins! 🪔",
                        timestamp: now.addingTimeInterval(-3600)),
            ChatMessage(id: "m2", squadId: demoSquad,
                        senderId: "u2", senderName: "Rohan Mukherjee",
                        text: "On my way. Bringing mishti from Girish.",
                        timestamp: now.addingTimeInterval(-3500)),
            ChatMessage(id: "m3", squadId: demoSquad,
                        senderId: "u3", senderName: "Priya Das",
                        text: "Found parking near Hatibagan. See you!",
                        timestamp: now.addingTimeInterval(-1800)),
            ChatMessage(id: "m4", squadId: demoSquad,
                        senderId: "u1", senderName: "Anika Sen",
                        text: "Beautiful dhak tonight. Mahalaya feels close 🔔",
                        timestamp: now.addingTimeInterval(-300)),
        ]
    }
}
