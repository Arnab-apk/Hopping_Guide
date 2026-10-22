import Foundation

@MainActor
final class PandalPhotoRepository {
    static let shared = PandalPhotoRepository()

    private var photosByPandalID: [String: [PandalPhoto]] = [:]
    private var normalizedIDs: [String: [PandalPhoto]] = [:]
    private(set) var isLoaded = false

    private init() {}

    func load() {
        guard !isLoaded else { return }
        defer { isLoaded = true }
        guard let url = Bundle.main.url(forResource: "pandal_photos", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(PandalPhotoManifest.self, from: data) else { return }

        photosByPandalID = manifest.pandals.mapValues { photos in
            var seen = Set<String>()
            return photos.filter { photo in
                photo.imageURL != nil && seen.insert(photo.url).inserted
            }
        }
        normalizedIDs = Dictionary(grouping: photosByPandalID, by: { Self.normalized($0.key) })
            .mapValues { groups in groups.first?.value ?? [] }
    }

    func photos(for pandalID: String) -> [PandalPhoto] {
        photosByPandalID[pandalID] ?? normalizedIDs[Self.normalized(pandalID)] ?? []
    }

    func cover(for pandalID: String) -> PandalPhoto? { photos(for: pandalID).first }

    private static func normalized(_ id: String) -> String {
        id.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}

private struct PandalPhotoManifest: Decodable {
    let pandals: [String: [PandalPhoto]]
}
