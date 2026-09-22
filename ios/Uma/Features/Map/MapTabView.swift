// Features/Map/MapTabView.swift — SwiftUI wrapper around MapView with search & controls

import SwiftUI
import CoreLocation
import MapKit

struct MapTabView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedPandal: Pandal?
    @State private var highlightedRoute: WalkingRoute?
    @State private var showFoodSpots = false
    @State private var showMetroStations = false
    @State private var selectedZone: KolkataZone?
    @State private var searchText: String = ""
    @State private var searchFocused: Bool = false
    @State private var searchResults: [OmniSearchResult] = []
    @State private var followUser: Bool = false
    @State private var cameraTrigger: UUID = UUID()
    @State private var statusPill: StatusPill?
    @State private var isCalculating = false

    struct StatusPill: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let iconName: String
        let color: Color
    }

    var body: some View {
        @Bindable var env = env
        ZStack(alignment: .top) {
            MapView(
                selectedPandal: $selectedPandal,
                highlightedRoute: $highlightedRoute,
                pandals: visiblePandals,
                metroStations: showMetroStations ? MetroRepository.allStations : [],
                foodSpots: showFoodSpots ? env.foodSpots.all : [],
                squadMembers: env.squad.companionMembers,
                showFoodSpots: showFoodSpots,
                showMetroStations: showMetroStations,
                followUser: followUser,
                userLocation: env.location.lastCoordinate,
                onTapPandal: { pandal in
                    Haptics.selection()
                    selectedPandal = pandal
                    Task { await computeRoute(to: pandal) }
                }
            )
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 8) {
                MapSearchBar(
                    text: $searchText,
                    focused: $searchFocused,
                    results: searchResults,
                    onSubmit: { onSearchSubmit() },
                    onSelect: { onSelectResult($0) }
                )

                if !searchFocused {
                    filterChipRow
                        .transition(.opacity)
                }

                if let pill = statusPill {
                    HStack(spacing: 8) {
                        Image(systemName: pill.iconName)
                        Text(pill.message).lineLimit(1)
                    }
                    .font(PujaTypography.rounded(12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(
                        Capsule().fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule().stroke(pill.color.opacity(0.7), lineWidth: 1)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            VStack {
                Spacer()
                MapFloatingControls(
                    followUser: $followUser,
                    onZoomIn: { zoom(by: +1) },
                    onZoomOut: { zoom(by: -1) },
                    onLocate: { locateUser() }
                )
                .padding(.bottom, 24)
                .padding(.trailing, 12)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            if let pandal = selectedPandal {
                VStack {
                    Spacer()
                    PandalCalloutView(
                        pandal: pandal,
                        isVisited: env.userState.isVisited(pandal.id),
                        onClose: { selectedPandal = nil },
                        onDirections: { Task { await computeRoute(to: pandal) } },
                        onToggleVisited: { env.userState.toggleVisited(pandal.id) }
                    )
                    .padding(.bottom, 110)
                    .padding(.horizontal, 14)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onChange(of: searchText) { _, _ in performSearch() }
        .onChange(of: searchFocused) { _, isFocused in
            if !isFocused { performSearch() }
        }
        .task {
            env.location.requestPermission()
            env.location.startLiveTracking()
        }
        .onDisappear {
            env.location.stopLiveTracking()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: statusPill)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedPandal)
        .animation(.easeInOut(duration: 0.25), value: searchFocused)
    }

    // MARK: - Filter chips

    private var filterChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: selectedZone?.shortLabel ?? "All Zones",
                           icon: "scope",
                           isActive: selectedZone != nil) {
                    Haptics.light()
                    selectedZone = nil
                    showZonePicker()
                }
                FilterChip(title: "Nearby 10km", icon: "location.circle",
                           isActive: false) { showStatus("Nearby filter coming soon", icon: "info.circle") }
                FilterChip(title: "Metro", icon: "tram.fill",
                           isActive: showMetroStations) {
                    showMetroStations.toggle()
                    Haptics.selection()
                }
                FilterChip(title: "Food", icon: "fork.knife",
                           isActive: showFoodSpots) {
                    showFoodSpots.toggle()
                    Haptics.selection()
                }
                if let trail = env.activeTrail {
                    FilterChip(title: "Trail: \(trail.stops.count) stops",
                               icon: "sparkles", isActive: true) {
                        showStatus("Trail active — \(trail.stops.count) pandals queued",
                                   icon: "sparkles", color: PujaColors.goldBright)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var visiblePandals: [Pandal] {
        var list: [Pandal]
        if let zone = selectedZone {
            list = env.pandals.filter(by: zone)
        } else {
            list = env.pandals.allPandals
        }
        if let trail = env.activeTrail {
            for s in trail.stops where !list.contains(where: { $0.id == s.id }) {
                list.append(s)
            }
        }
        if let p = selectedPandal, !list.contains(where: { $0.id == p.id }) {
            list.append(p)
        }
        return list
    }

    // MARK: - Actions

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        let userLat = env.location.lastCoordinate?.latitude
        let userLng = env.location.lastCoordinate?.longitude
        searchResults = env.omniSearch.search(
            query: searchText,
            pandals: env.pandals.allPandals,
            foodSpots: env.foodSpots.all,
            metroStations: MetroRepository.allStations,
            userLat: userLat, userLng: userLng)
    }

    private func onSearchSubmit() {
        if let first = searchResults.first {
            onSelectResult(first)
        }
    }

    private func onSelectResult(_ r: OmniSearchResult) {
        searchFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        searchText = ""
        searchResults = []
        Haptics.light()

        switch r.type {
        case .pandal:
            if let id = r.pandalId, let p = env.pandals.byId(id) {
                selectedPandal = p
                Task { await computeRoute(to: p) }
            }
        case .metro:
            if let id = r.metroStationId, let s = MetroRepository.shared.byId(id) {
                showStatus("🚇 \(s.name) · \(s.line.label)", icon: "tram.fill", color: s.line.color)
            }
        case .food:
            if let id = r.foodSpotId, let f = env.foodSpots.all.first(where: { $0.id == id }) {
                showStatus("🍽️ Found \(f.name)", icon: "fork.knife", color: Color(hex: 0xFF9100))
            }
        }
    }

    private func computeRoute(to pandal: Pandal) async {
        isCalculating = true
        defer { isCalculating = false }
        let userLoc = env.location.lastCoordinate
            ?? CLLocationCoordinate2D(latitude: AppConfig.defaultLat, longitude: AppConfig.defaultLng)
        let route = await env.routing.getWalkingRoute(
            start: userLoc,
            destination: pandal.coordinate,
            destinationName: pandal.name)
        await MainActor.run {
            highlightedRoute = route
            showStatus(
                "🚶 \(pandal.name) · \(route.formattedDistance) · \(route.formattedDuration)",
                icon: "figure.walk",
                color: PujaColors.durgaRed)
        }
    }

    private func zoom(by delta: Double) {
        // Camera zoom is handled implicitly through MapKit region changes on tap.
        // For finer control we'd thread a binding to MKMapView's region.
    }

    private func locateUser() {
        followUser.toggle()
        if followUser, let c = env.location.lastCoordinate {
            showStatus("Following your location", icon: "location.fill")
        } else {
            showStatus("Free-roam mode", icon: "scope")
        }
    }

    private func showZonePicker() {
        // Stub — zone picker could open a sheet; for v1 default to "All"
    }

    private func showStatus(_ message: String, icon: String, color: Color = PujaColors.festivalGold) {
        let pill = StatusPill(message: message, iconName: icon, color: color)
        withAnimation { statusPill = pill }
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                if statusPill?.id == pill.id { statusPill = nil }
            }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(PujaTypography.rounded(12, weight: .semibold))
            }
            .foregroundStyle(isActive ? .white : PujaColors.goldBright)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                Capsule().fill(isActive ? PujaColors.durgaRed : .clear)
            )
            .background(
                Capsule().fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule().stroke(
                    isActive ? PujaColors.festivalGold : PujaColors.festivalGold.opacity(0.4),
                    lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
