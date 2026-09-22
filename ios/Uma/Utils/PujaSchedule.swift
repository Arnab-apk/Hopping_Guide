// Utils/PujaSchedule.swift — port of utils/puja_schedule.dart

import Foundation

struct PujaDay: Hashable, Identifiable {
    let date: Date
    let name: String
    let subtitle: String?
    let description: String

    var id: String { "\(name)-\(date.timeIntervalSince1970)" }

    init(date: Date, name: String, subtitle: String? = nil, description: String) {
        self.date = date
        self.name = name
        self.subtitle = subtitle
        self.description = description
    }
}

/// Official 10-day (12-entry) Durga Puja 2026 schedule.
let pujaSchedule2026: [PujaDay] = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current

    func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 0)) ?? Date()
    }
    return [
        PujaDay(date: date(2026, 10, 10), name: "Mahalaya",
                description: "The start of Devi Paksha — tarpan rituals and the inviting of Goddess Durga."),
        PujaDay(date: date(2026, 10, 11), name: "Pratipada",
                description: "Day 1 of Navratri — Ghatasthapana."),
        PujaDay(date: date(2026, 10, 12), name: "Dwitiya",
                description: "Devi Brahmacharini puja."),
        PujaDay(date: date(2026, 10, 13), name: "Tritiya",
                description: "Devi Chandraghanta puja."),
        PujaDay(date: date(2026, 10, 14), name: "Maha Chaturthi",
                description: "Pandal structures open for their first viewing."),
        PujaDay(date: date(2026, 10, 15), name: "Maha Panchami",
                description: "Preparations conclude; traditional welcoming rituals begin."),
        PujaDay(date: date(2026, 10, 16), name: "Maha Shashthi", subtitle: "Bodhon",
                description: "The formal festival kickoff — Bodhon unveils the idol's face."),
        PujaDay(date: date(2026, 10, 17), name: "Maha Saptami",
                description: "Bathing of the Kola Bou / Nabapatrika snan before sunrise."),
        PujaDay(date: date(2026, 10, 18), name: "Maha Saptami",
                description: "Saptami rituals continue through the second day."),
        PujaDay(date: date(2026, 10, 19), name: "Maha Ashtami",
                description: "Peak devotion — Anjali, Kumari Puja, and the critical Sandhi Puja."),
        PujaDay(date: date(2026, 10, 20), name: "Maha Navami",
                description: "The dhunuchi naach carries the night toward Dashami."),
        PujaDay(date: date(2026, 10, 21), name: "Vijaya Dashami",
                description: "Sindoor Khela, and the idol immersion — Visarjan."),
    ]
}()

/// Maha Shasthi 2026 — the festival kickoff at 06:00 IST.
let mahaShasthiStart: Date = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
    return calendar.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 6)) ?? Date()
}()

/// Returns the puja day matching today, or nil if outside the schedule.
func getTodaysPujaDay(now: Date = Date()) -> PujaDay? {
    let calendar = Calendar(identifier: .gregorian)
    let today = calendar.startOfDay(for: now)
    return pujaSchedule2026.first { calendar.isDate($0.date, inSameDayAs: today) }
}

/// Builds the personalized greeting string.
func buildGreeting(day: PujaDay?, userName: String, now: Date = Date()) -> String {
    let cleanName = userName.trimmingCharacters(in: .whitespaces).isEmpty
        ? "Pujo Hopper"
        : userName.trimmingCharacters(in: .whitespaces)
    if let day = day {
        let subtitlePart = day.subtitle.map { " (\($0))" } ?? ""
        return "Shubho \(day.name)\(subtitlePart), \(cleanName)"
    }
    let calendar = Calendar(identifier: .gregorian)
    let today = calendar.startOfDay(for: now)
    let mahalayaDay = calendar.startOfDay(for: pujaSchedule2026.first!.date)
    let daysUntilMahalaya = calendar.dateComponents([.day], from: today, to: mahalayaDay).day ?? 0
    if daysUntilMahalaya > 0 {
        return "Welcome back, \(cleanName) — \(daysUntilMahalaya) days to Mahalaya"
    }
    return "Welcome back, \(cleanName) — see you next Durga Puja!"
}

/// Live countdown to Maha Shasthi.
struct CountdownTime {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
    let isLive: Bool

    static func toPuja(from now: Date = Date()) -> CountdownTime {
        let diff = mahaShasthiStart.timeIntervalSince(now)
        guard diff > 0 else { return CountdownTime(days: 0, hours: 0, minutes: 0, seconds: 0, isLive: true) }
        let total = Int(diff)
        return CountdownTime(
            days: total / 86_400,
            hours: (total / 3600) % 24,
            minutes: (total / 60) % 60,
            seconds: total % 60,
            isLive: false)
    }
}
