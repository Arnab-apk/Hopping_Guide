// Repositories/MetroRepository.swift — 41+ Kolkata Metro stations hardcoded

import Foundation
import CoreLocation

final class MetroRepository: @unchecked Sendable {
    static let shared = MetroRepository()
    private init() {}

    static let allStations: [MetroStation] = [
        // Blue Line (North-South)
        MetroStation(id: "dakshineswar", name: "Dakshineswar", nameBn: "দক্ষিণেশ্বর",
                     latitude: 22.6545, longitude: 88.3575, line: .blue),
        MetroStation(id: "baranagar", name: "Baranagar", latitude: 22.6440, longitude: 88.3602, line: .blue),
        MetroStation(id: "noapara", name: "Noapara", latitude: 22.6393, longitude: 88.3789,
                     isInterchange: true, connectingLines: [.yellow], line: .blue),
        MetroStation(id: "dum_dum", name: "Dum Dum", latitude: 22.6328, longitude: 88.3922, line: .blue),
        MetroStation(id: "beleghata", name: "Beleghata", latitude: 22.5641, longitude: 88.3944,
                     isInterchange: true, connectingLines: [.orange], line: .blue),
        MetroStation(id: "shyambazar", name: "Shyambazar", nameBn: "শ্যামবাজার",
                     latitude: 22.5970, longitude: 88.3708, line: .blue),
        MetroStation(id: "sovabazar_sutanuti", name: "Sovabazar-Sutanuti", latitude: 22.5955, longitude: 88.3770, line: .blue),
        MetroStation(id: "girish_park", name: "Girish Park", latitude: 22.5858, longitude: 88.3625, line: .blue),
        MetroStation(id: "mg_road", name: "M.G. Road", latitude: 22.5808, longitude: 88.3635, line: .blue),
        MetroStation(id: "central", name: "Central", latitude: 22.5710, longitude: 88.3645,
                     isInterchange: true, connectingLines: [.green], line: .blue),
        MetroStation(id: "chandni_chowk", name: "Chandni Chowk", latitude: 22.5683, longitude: 88.3640, line: .blue),
        MetroStation(id: "esplanade", name: "Esplanade", latitude: 22.5645, longitude: 88.3663, line: .blue),
        MetroStation(id: "park_street", name: "Park Street", latitude: 22.5542, longitude: 88.3635, line: .blue),
        MetroStation(id: "maidan", name: "Maidan", latitude: 22.5497, longitude: 88.3645, line: .blue),
        MetroStation(id: "rabindra_sadan", name: "Rabindra Sadan", latitude: 22.5418, longitude: 88.3658, line: .blue),
        MetroStation(id: "netaji_bhawan", name: "Netaji Bhavan", latitude: 22.5348, longitude: 88.3665, line: .blue),
        MetroStation(id: "jatin_das_park", name: "Jatin Das Park", latitude: 22.5260, longitude: 88.3660, line: .blue),
        MetroStation(id: "kalighat", name: "Kalighat", latitude: 22.5183, longitude: 88.3660, line: .blue),
        MetroStation(id: "rabindra_sarobar", name: "Rabindra Sarobar", latitude: 22.5105, longitude: 88.3645, line: .blue),
        MetroStation(id: "mahanayak_uttam_kumar", name: "Mahanayak Uttam Kumar", latitude: 22.5048, longitude: 88.3622, line: .blue),
        MetroStation(id: "netaji", name: "Netaji", latitude: 22.4975, longitude: 88.3610, line: .blue),
        MetroStation(id: "masterda_surya_sen", name: "Masterda Surya Sen", latitude: 22.4908, longitude: 88.3587, line: .blue),
        MetroStation(id: "gitanjali", name: "Gitanjali", latitude: 22.4836, longitude: 88.3578, line: .blue),
        MetroStation(id: "kavi_subhash", name: "Kavi Subhash", latitude: 22.4788, longitude: 88.3570,
                     isInterchange: true, connectingLines: [.orange], line: .blue),
        MetroStation(id: "shahid_khudiram", name: "Shahid Khudiram", latitude: 22.4680, longitude: 88.3578, line: .blue),

        // Green Line (East-West)
        MetroStation(id: "howrah_maidan", name: "Howrah Maidan", latitude: 22.5845, longitude: 88.3110, line: .green),
        MetroStation(id: "howrah_station", name: "Howrah Station", latitude: 22.5825, longitude: 88.3208, line: .green),
        MetroStation(id: "mahakaran", name: "Mahakaran", latitude: 22.5755, longitude: 88.3388, line: .green),
        MetroStation(id: "esplanade_green", name: "Esplanade", latitude: 22.5645, longitude: 88.3663,
                     isInterchange: true, connectingLines: [.blue], line: .green),
        MetroStation(id: "sealdah", name: "Sealdah", latitude: 22.5698, longitude: 88.3710, line: .green),
        MetroStation(id: "phoolbagan", name: "Phoolbagan", latitude: 22.5718, longitude: 88.3850, line: .green),
        MetroStation(id: "salt_lake_stadium", name: "Salt Lake Stadium", latitude: 22.5720, longitude: 88.4040, line: .green),
        MetroStation(id: "bengal_chemical", name: "Bengal Chemical", latitude: 22.5720, longitude: 88.4140, line: .green),
        MetroStation(id: "city_centre_1", name: "City Centre 1", latitude: 22.5725, longitude: 88.4230, line: .green),
        MetroStation(id: "salt_lake_sector_v", name: "Salt Lake Sector-V", latitude: 22.5740, longitude: 88.4360, line: .green),

        // Purple Line (Joka-Majerhat)
        MetroStation(id: "joka", name: "Joka", latitude: 22.4528, longitude: 88.3070, line: .purple),
        MetroStation(id: "thakurpukur", name: "Thakurpukur", latitude: 22.4610, longitude: 88.3135, line: .purple),
        MetroStation(id: "sakher_bazar", name: "Sakher Bazar", latitude: 22.4695, longitude: 88.3210, line: .purple),
        MetroStation(id: "behala_chowrasta", name: "Behala Chowrasta", latitude: 22.4780, longitude: 88.3285, line: .purple),
        MetroStation(id: "behala_bazar", name: "Behala Bazar", latitude: 22.4835, longitude: 88.3320, line: .purple),
        MetroStation(id: "taratala", name: "Taratala", latitude: 22.4900, longitude: 88.3385, line: .purple),
        MetroStation(id: "majerhat", name: "Majerhat", latitude: 22.4970, longitude: 88.3450, line: .purple),

        // Orange Line
        MetroStation(id: "beleghata_orange", name: "Beleghata", latitude: 22.5641, longitude: 88.3944, line: .orange),
        MetroStation(id: "kavi_subhash_orange", name: "Kavi Subhash", latitude: 22.4788, longitude: 88.3570, line: .orange),

        // Yellow Line (Airport)
        MetroStation(id: "noapara_yellow", name: "Noapara", latitude: 22.6393, longitude: 88.3789, line: .yellow),
        MetroStation(id: "dum_dum_cantonment", name: "Dum Dum Cantonment", latitude: 22.6450, longitude: 88.4080, line: .yellow),
        MetroStation(id: "jai_hind", name: "Jai Hind (Airport)", latitude: 22.6420, longitude: 88.4358, line: .yellow),
    ]

    func byId(_ id: String) -> MetroStation? {
        Self.allStations.first { $0.matchesId(id) }
    }
}
