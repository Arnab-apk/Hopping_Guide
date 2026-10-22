import CoreLocation
import Foundation

struct TransitStation: Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let nameBn: String?
    let code: String?
    let kind: String
    let latitude: Double
    let longitude: Double
    let network: String?
    let lines: [String]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    var isMetro: Bool { kind == "metro" }
    var typeLabel: String { isMetro ? "Metro" : "Railway" }
    var displayName: String { code.map { isMetro ? name : "\(name) (\($0))" } ?? name }

    static func == (lhs: TransitStation, rhs: TransitStation) -> Bool {
        lhs.id == rhs.id && lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

struct StationsGeoJSON: Decodable {
    let features: [StationFeature]
}

struct StationFeature: Decodable {
    let id: String?
    let geometry: StationGeometry
    let properties: StationProperties

    func station() -> TransitStation? {
        let coordinates = geometry.coordinates
        guard coordinates.count >= 2 else { return nil }
        let stationID = properties.id ?? id ?? ""
        let lat = coordinates[1]
        let lng = coordinates[0]
        guard !stationID.isEmpty, !properties.name.isEmpty,
              lat.isFinite, lng.isFinite, (-90...90).contains(lat), (-180...180).contains(lng) else { return nil }
        return TransitStation(
            id: stationID,
            name: properties.name,
            nameBn: properties.nameBn,
            code: properties.code,
            kind: properties.kind,
            latitude: lat,
            longitude: lng,
            network: properties.network,
            lines: properties.lines
        )
    }
}

struct StationGeometry: Decodable {
    let coordinates: [Double]
}

struct StationProperties: Decodable {
    let id: String?
    let name: String
    let nameBn: String?
    let code: String?
    let kind: String
    let network: String?
    let lines: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, code, kind, network, lines
        case nameBn = "name_bn"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decode(String.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        nameBn = try? container.decode(String.self, forKey: .nameBn)
        code = try? container.decode(String.self, forKey: .code)
        kind = (try? container.decode(String.self, forKey: .kind)) ?? "rail"
        network = try? container.decode(String.self, forKey: .network)
        lines = (try? container.decode([String].self, forKey: .lines)) ?? []
    }
}
