// App/AppEnvironment.swift — single source of truth for repositories and services

import SwiftUI
import Observation

@MainActor
@Observable
final class AppEnvironment {
    // Repositories
    let pandals = PandalRepository.shared
    let pandalPhotos = PandalPhotoRepository.shared
    let metros = MetroRepository.shared
    let stations = TransitStationRepository.shared
    let foodSpots = FoodSpotRepository.shared
    let helplines = HelplineRepository.shared
    let toilets = ToiletRepository.shared

    // Services
    let omniSearch = OmniSearchService.shared
    let userState = UserStateService.shared
    let squad = SquadService.shared
    let chat = ChatService.shared
    let location = LocationService.shared
    let theme = ThemeService.shared

    // Routing service (actor — accessed via `await` from views)
    let routing = RoutingService.shared

    // App-level navigation state
    var selectedTab: AppTab = .map
    var hasOnboarded: Bool = UserDefaults.standard.bool(forKey: "uma.hasOnboarded")
    var activeTrail: ActiveCustomTrail?

    var themeMode: ThemeService.Mode {
        get { theme.mode }
        set { theme.mode = newValue }
    }

    init() {
        let squadService = squad
        location.onUpdate = { [weak squadService] coordinate in
            squadService?.updateUserLocation(coordinate)
        }
    }

    func loadBundles() {
        pandals.load()
        pandalPhotos.load()
        metros  // static
        stations.load()
        foodSpots.load()
        helplines.load()
        toilets.load()
    }

    func enterApp(as name: String) {
        userState.signInGuest(name: name)
        UserDefaults.standard.set(true, forKey: "uma.hasOnboarded")
        hasOnboarded = true
        selectedTab = .map
        Haptics.notifySuccess()
    }

    func startTrail(_ route: HoppingRoute, byId: (String) -> Pandal?) {
        let stops = route.pandalIds.compactMap(byId)
        guard !stops.isEmpty else { return }
        activeTrail = ActiveCustomTrail(name: route.title, stops: stops)
        selectedTab = .map
        Haptics.notifySuccess()
    }
}

enum AppTab: Hashable {
    case welcome, map, pandals, routes, squads, helplines, settings
}
