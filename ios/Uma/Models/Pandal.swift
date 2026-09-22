// Pandal.swift
// Port of app/lib/models/pandal.dart — 15 fields, snake_case JSON keys.

import Foundation
import CoreLocation

struct Pandal: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let lat: Double
    let lng: Double
    let zone: KolkataZone
    let theme: String
    let timings: String
    let imageUrl: String?
    let description: String
    let area: String?
    let region: String?
    let rating: Double?
    let crowdLevel: String?
    let nearestMetro: String?
    let nearestMetroList: [String]
    let nearestRailway: String?
    let nearestRailwayList: [String]
    let transport: [String]
    let specialFeatures: [String]

    var latitude: Double { lat }
    var longitude: Double { lng }
    var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lng) }
    var entryFee: String { "Free entry" }
    var zoneLabel: String { zone.label }
    var bengaliName: String? { nil }
    var hasHighRating: Bool { (rating ?? 0) >= 4.5 }
    var isCrowded: Bool { crowdLevel?.lowercased() == "high" }

    enum CodingKeys: String, CodingKey {
        case id, name, lat, lng, zone, theme, timings
        case imageUrl       = "image_url"
        case description
        case area, region, rating
        case crowdLevel     = "crowd_level"
        case nearestMetro   = "nearest_metro"
        case nearestMetroList = "nearest_metro_list"
        case nearestRailway = "nearest_railway"
        case nearestRailwayList = "nearest_railway_list"
        case transport
        case specialFeatures = "special_features"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        lat = (try? c.decode(Double.self, forKey: .lat)) ?? 0
        lng = (try? c.decode(Double.self, forKey: .lng)) ?? 0
        let zoneRaw = try? c.decode(String.self, forKey: .zone)
        zone = KolkataZone.parse(zoneRaw)
        theme = (try? c.decode(String.self, forKey: .theme)) ?? ""
        timings = (try? c.decode(String.self, forKey: .timings)) ?? ""
        imageUrl = try? c.decode(String.self, forKey: .imageUrl)
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        area = try? c.decode(String.self, forKey: .area)
        region = try? c.decode(String.self, forKey: .region)
        rating = try? c.decode(Double.self, forKey: .rating)
        crowdLevel = try? c.decode(String.self, forKey: .crowdLevel)
        nearestMetro = try? c.decode(String.self, forKey: .nearestMetro)
        nearestMetroList = (try? c.decode([String].self, forKey: .nearestMetroList)) ?? []
        nearestRailway = try? c.decode(String.self, forKey: .nearestRailway)
        nearestRailwayList = (try? c.decode([String].self, forKey: .nearestRailwayList)) ?? []
        transport = (try? c.decode([String].self, forKey: .transport)) ?? []
        specialFeatures = (try? c.decode([String].self, forKey: .specialFeatures)) ?? []
    }

    init(id: String, name: String, lat: Double, lng: Double, zone: KolkataZone,
         theme: String, timings: String, imageUrl: String?, description: String,
         area: String?, region: String?, rating: Double?, crowdLevel: String?,
         nearestMetro: String?, nearestMetroList: [String], nearestRailway: String?,
         nearestRailwayList: [String], transport: [String], specialFeatures: [String]) {
        self.id = id; self.name = name; self.lat = lat; self.lng = lng
        self.zone = zone; self.theme = theme; self.timings = timings
        self.imageUrl = imageUrl; self.description = description
        self.area = area; self.region = region; self.rating = rating
        self.crowdLevel = crowdLevel
        self.nearestMetro = nearestMetro; self.nearestMetroList = nearestMetroList
        self.nearestRailway = nearestRailway; self.nearestRailwayList = nearestRailwayList
        self.transport = transport; self.specialFeatures = specialFeatures
    }
}
