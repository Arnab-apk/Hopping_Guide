// FoodSpot.swift — port of FoodSpot class from supplementary_repository.dart
// JSON has either {coordinates:{lat,lng}} or top-level {lat,lng}.

import Foundation
import CoreLocation

struct FoodSpot: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let type: String
    let lat: Double
    let lng: Double
    let nearbyPandal: String
    let rating: Double?
    let mustTry: String?
    let priceRange: String?
    let source: String?

    var latitude: Double { lat }
    var longitude: Double { lng }
    var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lng) }

    enum CodingKeys: String, CodingKey {
        case id, name, type
        case coordinates
        case nearbyPandal, rating, mustTry, priceRange, source
        case lat, lng // tolerate top-level lat/lng as fallback
    }

    struct Coordinates: Codable, Hashable {
        let lat: Double
        let lng: Double
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        type = (try? c.decode(String.self, forKey: .type)) ?? ""
        if let coords = try? c.decode(Coordinates.self, forKey: .coordinates) {
            lat = coords.lat; lng = coords.lng
        } else {
            lat = (try? c.decode(Double.self, forKey: .lat)) ?? 0
            lng = (try? c.decode(Double.self, forKey: .lng)) ?? 0
        }
        nearbyPandal = (try? c.decode(String.self, forKey: .nearbyPandal)) ?? ""
        rating = try? c.decode(Double.self, forKey: .rating)
        mustTry = try? c.decode(String.self, forKey: .mustTry)
        priceRange = try? c.decode(String.self, forKey: .priceRange)
        source = try? c.decode(String.self, forKey: .source)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(type, forKey: .type)
        try c.encode(Coordinates(lat: lat, lng: lng), forKey: .coordinates)
        try c.encode(nearbyPandal, forKey: .nearbyPandal)
        try c.encodeIfPresent(rating, forKey: .rating)
        try c.encodeIfPresent(mustTry, forKey: .mustTry)
        try c.encodeIfPresent(priceRange, forKey: .priceRange)
        try c.encodeIfPresent(source, forKey: .source)
    }

    init(id: String, name: String, type: String, lat: Double, lng: Double,
         nearbyPandal: String, rating: Double? = nil, mustTry: String? = nil,
         priceRange: String? = nil, source: String? = nil) {
        self.id = id; self.name = name; self.type = type
        self.lat = lat; self.lng = lng
        self.nearbyPandal = nearbyPandal; self.rating = rating
        self.mustTry = mustTry; self.priceRange = priceRange; self.source = source
    }
}
