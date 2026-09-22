// Services/UserStateService.swift — visited/favorites persistence (UserDefaults)

import Foundation
import Observation

@MainActor
@Observable
final class UserStateService {
    static let shared = UserStateService()

    private(set) var visitedIds: Set<String> = []
    private(set) var favoriteIds: Set<String> = []
    private(set) var currentUserName: String = "Pujo Hopper"
    private(set) var isGuest: Bool = true

    private let visitedKey = "uma.visitedPandalIds"
    private let favoriteKey = "uma.favoritePandalIds"
    private let userKey = "uma.currentUserName"
    private let guestKey = "uma.isGuest"

    init() {
        load()
    }

    func load() {
        let defaults = UserDefaults.standard
        if let arr = defaults.array(forKey: visitedKey) as? [String] {
            visitedIds = Set(arr)
        }
        if let arr = defaults.array(forKey: favoriteKey) as? [String] {
            favoriteIds = Set(arr)
        }
        currentUserName = defaults.string(forKey: userKey) ?? "Pujo Hopper"
        isGuest = defaults.object(forKey: guestKey) as? Bool ?? true
    }

    func toggleVisited(_ id: String) {
        if visitedIds.contains(id) { visitedIds.remove(id) } else { visitedIds.insert(id) }
        persist(visitedKey, value: Array(visitedIds))
        Haptics.light()
    }

    func toggleFavorite(_ id: String) {
        if favoriteIds.contains(id) { favoriteIds.remove(id) } else { favoriteIds.insert(id) }
        persist(favoriteKey, value: Array(favoriteIds))
        Haptics.soft()
    }

    func isVisited(_ id: String) -> Bool { visitedIds.contains(id) }
    func isFavorite(_ id: String) -> Bool { favoriteIds.contains(id) }

    func signInGuest(name: String) {
        currentUserName = name
        isGuest = true
        defaults().set(name, forKey: userKey)
        defaults().set(true, forKey: guestKey)
    }

    func setUserName(_ name: String) {
        currentUserName = name
        defaults().set(name, forKey: userKey)
    }

    private func defaults() -> UserDefaults { .standard }
    private func persist(_ key: String, value: [String]) { defaults().set(value, forKey: key) }
}

@MainActor
@Observable
final class ThemeService {
    static let shared = ThemeService()
    enum Mode: String, CaseIterable { case system, light, dark }
    var mode: Mode = .system {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: "uma.themeMode") }
    }
    init() {
        if let raw = UserDefaults.standard.string(forKey: "uma.themeMode"),
           let m = Mode(rawValue: raw) {
            mode = m
        }
    }
}
