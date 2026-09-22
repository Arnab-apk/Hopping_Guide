// ChatMessage.swift — text-only for v1

import Foundation

enum ChatMessageType: String, Codable, Sendable {
    case text, image, video

    static func from(_ s: String?) -> ChatMessageType {
        switch s {
        case "image": return .image
        case "video": return .video
        default:      return .text
        }
    }
}

struct ChatMessage: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let squadId: String
    let senderId: String
    let senderName: String
    let senderPhotoUrl: String?
    let type: ChatMessageType
    let text: String?
    let mediaUrl: String?
    let thumbnailUrl: String?
    let timestamp: Date

    func isUser(_ uid: String) -> Bool { senderId == uid }
    var isVideo: Bool { type == .video }
    var isImage: Bool { type == .image }

    var senderInitials: String {
        let parts = senderName.split(separator: " ").map(String.init)
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return senderName.isEmpty ? "H" : String(senderName.prefix(1)).uppercased()
    }

    enum CodingKeys: String, CodingKey {
        case id, squadId, senderId, senderName, senderPhotoUrl
        case type, text, mediaUrl, thumbnailUrl, timestamp
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id))
            ?? "msg_\(Int(Date().timeIntervalSince1970 * 1000))"
        squadId = (try? c.decode(String.self, forKey: .squadId)) ?? ""
        senderId = (try? c.decode(String.self, forKey: .senderId)) ?? "unknown"
        senderName = (try? c.decode(String.self, forKey: .senderName)) ?? "Hopper"
        senderPhotoUrl = try? c.decode(String.self, forKey: .senderPhotoUrl)
        type = ChatMessageType.from(try? c.decode(String.self, forKey: .type))
        text = try? c.decode(String.self, forKey: .text)
        mediaUrl = try? c.decode(String.self, forKey: .mediaUrl)
        thumbnailUrl = try? c.decode(String.self, forKey: .thumbnailUrl)
        if let ts = try? c.decode(Double.self, forKey: .timestamp) {
            timestamp = Date(timeIntervalSince1970: ts / 1000.0)
        } else if let s = try? c.decode(String.self, forKey: .timestamp),
                  let d = ISO8601DateFormatter().date(from: s) {
            timestamp = d
        } else {
            timestamp = Date()
        }
    }

    init(id: String, squadId: String, senderId: String, senderName: String,
         senderPhotoUrl: String? = nil, type: ChatMessageType = .text,
         text: String? = nil, mediaUrl: String? = nil, thumbnailUrl: String? = nil,
         timestamp: Date = Date()) {
        self.id = id; self.squadId = squadId
        self.senderId = senderId; self.senderName = senderName
        self.senderPhotoUrl = senderPhotoUrl; self.type = type
        self.text = text; self.mediaUrl = mediaUrl; self.thumbnailUrl = thumbnailUrl
        self.timestamp = timestamp
    }
}
