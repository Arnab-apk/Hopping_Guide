// Toilet.swift — port of models/toilet.dart

import Foundation
import CoreLocation

struct ToiletEntry: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let lat: Double
    let lng: Double
    let male: Bool
    let female: Bool
    let fee: Bool
    let distM: Int
    let name: String?
    let access: String
    let source: String

    var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lng) }

    var displayName: String { name ?? "Public Toilet" }
    var distLabel: String {
        distM < 1000 ? "\(distM)m away" : String(format: "%.1fkm away", Double(distM) / 1000.0)
    }
    var genderLabel: String {
        switch (male, female) {
        case (true, true):  return "Male & Female"
        case (true, false): return "Male only"
        case (false, true): return "Female only"
        default:            return "Unspecified"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, lat, lng, male, female, fee, distM, name, access, source
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let rawLat = (try? c.decode(Double.self, forKey: .lat)) ?? 0
        let rawLng = (try? c.decode(Double.self, forKey: .lng)) ?? 0
        id = (try? c.decode(String.self, forKey: .id)) ?? "\(rawLat)_\(rawLng)"
        lat = rawLat; lng = rawLng
        male = (try? c.decode(Bool.self, forKey: .male)) ?? true
        female = (try? c.decode(Bool.self, forKey: .female)) ?? true
        fee = (try? c.decode(Bool.self, forKey: .fee)) ?? false
        distM = (try? c.decode(Int.self, forKey: .distM)) ?? 0
        name = try? c.decode(String.self, forKey: .name)
        access = (try? c.decode(String.self, forKey: .access)) ?? "public"
        source = (try? c.decode(String.self, forKey: .source)) ?? "osm"
    }

    init(id: String, lat: Double, lng: Double, male: Bool, female: Bool,
         fee: Bool, distM: Int, name: String?, access: String, source: String) {
        self.id = id; self.lat = lat; self.lng = lng
        self.male = male; self.female = female
        self.fee = fee; self.distM = distM
        self.name = name; self.access = access; self.source = source
    }
}

struct PandalToilets: Codable, Hashable {
    let pandalId: String
    let pandalName: String?
    let nearestMale: ToiletEntry?
    let nearestFemale: ToiletEntry?
    let allNearby: [ToiletEntry]

    var hasData: Bool {
        !allNearby.isEmpty || nearestMale != nil || nearestFemale != nil
    }
}
