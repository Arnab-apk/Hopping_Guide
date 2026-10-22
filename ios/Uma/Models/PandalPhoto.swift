import Foundation

struct PandalPhoto: Decodable, Hashable, Identifiable, Sendable {
    let url: String
    let caption: String
    let credit: String
    let sourceURLString: String
    let rightsStatus: String

    var id: String { url }
    var imageURL: URL? { Self.httpsURL(url) }
    var sourceURL: URL? { Self.httpsURL(sourceURLString) }

    enum CodingKeys: String, CodingKey {
        case url, caption, credit
        case sourceURLString = "source_url"
        case rightsStatus = "rights_status"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = (try? container.decode(String.self, forKey: .url))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        caption = (try? container.decode(String.self, forKey: .caption))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        credit = (try? container.decode(String.self, forKey: .credit))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        sourceURLString = (try? container.decode(String.self, forKey: .sourceURLString))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        rightsStatus = (try? container.decode(String.self, forKey: .rightsStatus)) ?? "unknown"
    }

    static func httpsURL(_ raw: String) -> URL? {
        guard let components = URLComponents(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
              components.scheme?.lowercased() == "https",
              let host = components.host?.lowercased(),
              host == "www.durgapujakolkata.in",
              components.user == nil, components.password == nil else { return nil }
        return components.url
    }
}
