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
    @State private var isNearbyFilterEnabled = false
    @State private var isShowingZonePicker = false
    @State private var selectedZone: KolkataZone?
    @State private var searchText: String = ""
    @State private var searchFocused: Bool = false
    @State private var searchResults: [OmniSearchResult] = []
    @State private var followUser: Bool = false
    @AppStorage("map_three_dimensional") private var isThreeDimensional = true
    @AppStorage("map_more_place_names") private var showsMapLabels = true
    @State private var cameraRequest: MapCameraRequest?
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
                metroStations: focusedMetroStations,
                foodSpots: showFoodSpots ? env.foodSpots.all : [],
                squadMembers: env.squad.companionMembers.filter(\.shareLocation),
                showFoodSpots: showFoodSpots,
                showMetroStations: showMetroStations || env.activeTrail != nil,
                followUser: followUser,
                userLocation: env.location.currentPosition(),
                cameraRequest: cameraRequest,
                activeTrail: env.activeTrail,
                isThreeDimensional: isThreeDimensional,
                showsMapLabels: showsMapLabels,
                onTapPandal: { pandal in
                    Haptics.selection()
                    followUser = false
                    selectedPandal = pandal
                    Task { await computeRoute(to: pandal) }
                },
                onTapMetro: { station in
                    showStatus("🚇 \(station.name) · \(station.subtitle)", icon: "tram.fill", color: station.line.color)
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
            env.location.startLiveTracking(for: .map)
        }
        .onChange(of: env.location.authorizationStatus) { _, status in
            if (status == .denied || status == .restricted), followUser {
                followUser = false
                showStatus("Location access is off. Enable it in Settings to follow your position.",
                           icon: "location.slash")
            }
        }
        .onDisappear {
            env.location.stopLiveTracking(for: .map)
        }
        .sheet(isPresented: $isShowingZonePicker) {
            zonePickerSheet
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
                           isActive: isNearbyFilterEnabled) { toggleNearbyFilter() }
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
                FilterChip(title: isThreeDimensional ? "3D" : "2D",
                           icon: "cube.transparent",
                           isActive: isThreeDimensional) {
                    isThreeDimensional.toggle()
                    Haptics.selection()
                }
                FilterChip(title: "Labels", icon: "text.bubble",
                           isActive: showsMapLabels) {
                    showsMapLabels.toggle()
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
        if isNearbyFilterEnabled {
            let center = env.location.currentPosition() ?? CLLocationCoordinate2D(
                latitude: AppConfig.defaultLat,
                longitude: AppConfig.defaultLng)
            list = list.filter {
                haversineMeters(center, $0.coordinate) <= AppConfig.nearbyRadius
            }
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

    private var focusedMetroStations: [MetroStation] {
        if let trail = env.activeTrail {
            let stopTokens = Set(trail.stops.compactMap { $0.nearestMetro?.lowercased().trimmingCharacters(in: .whitespaces) })
            var activeLines: Set<KolkataMetroLine> = []
            var keyStations: [MetroStation] = []

            for st in MetroRepository.allStations {
                if stopTokens.contains(where: { token in
                    st.name.lowercased().contains(token) || token.contains(st.name.lowercased()) || st.matchesId(token)
                }) {
                    keyStations.append(st)
                    activeLines.insert(st.line)
                    for cl in st.connectingLines { activeLines.insert(cl) }
                }
            }

            // Suppress unrelated stations: show intermediate, boarding, and interchange stations strictly for active legs
            if let first = trail.stops.first {
                let lats = trail.stops.map(\.lat)
                let lngs = trail.stops.map(\.lng)
                let minLat = (lats.min() ?? first.lat) - 0.025
                let maxLat = (lats.max() ?? first.lat) + 0.025
                let minLng = (lngs.min() ?? first.lng) - 0.025
                let maxLng = (lngs.max() ?? first.lng) + 0.025

                let filtered = MetroRepository.allStations.filter { st in
                    activeLines.contains(st.line) &&
                    st.latitude >= minLat && st.latitude <= maxLat &&
                    st.longitude >= minLng && st.longitude <= maxLng
                }
                return filtered.isEmpty ? keyStations : filtered
            }
            return keyStations
        } else if showMetroStations {
            return MetroRepository.allStations
        } else {
            return []
        }
    }

    // MARK: - Actions

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        let userCoordinate = env.location.currentPosition()
        searchResults = env.omniSearch.search(
            query: searchText,
            pandals: env.pandals.allPandals,
            foodSpots: env.foodSpots.all,
            metroStations: MetroRepository.allStations,
            userLat: userCoordinate?.latitude, userLng: userCoordinate?.longitude)
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
                followUser = false
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
        let userLoc = env.location.currentPosition()
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
        cameraRequest = MapCameraRequest(action: delta >= 0 ? .zoomIn : .zoomOut)
    }

    private func locateUser() {
        if followUser {
            followUser = false
            showStatus("Free-roam mode", icon: "scope")
            return
        }

        if env.location.authorizationStatus == .denied || env.location.authorizationStatus == .restricted {
            showStatus("Location access is off. Enable it in Settings to follow your position.",
                       icon: "location.slash")
            return
        }

        followUser = true
        env.location.startLiveTracking(for: .map)
        if let coordinate = env.location.currentPosition() {
            cameraRequest = MapCameraRequest(action: .center(coordinate))
            showStatus("Following your location", icon: "location.fill")
        } else {
            showStatus("Getting your location…", icon: "location.circle")
        }
    }

    private func showZonePicker() {
        isShowingZonePicker = true
    }

    private var zonePickerSheet: some View {
        NavigationStack {
            List {
                Section {
                    zonePickerRow(title: "All zones", isSelected: selectedZone == nil) {
                            followUser = false
                        selectedZone = nil
                            cameraRequest = MapCameraRequest(action: .region(MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: AppConfig.defaultLat,
                                                               longitude: AppConfig.defaultLng),
                                span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.6))))
                        isShowingZonePicker = false
                    }
                }

                Section("Kolkata zones") {
                    ForEach(KolkataZone.allCases, id: \.self) { zone in
                        zonePickerRow(title: zone.label, isSelected: selectedZone == zone) {
                            followUser = false
                            selectedZone = zone
                            let latitude = zone.centerCoordinate.latitude
                            let longitude = zone.centerCoordinate.longitude
                            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            let latitudeDelta = 360.0 / pow(2.0, zone.defaultZoom)
                            let longitudeDelta = latitudeDelta / max(0.1, cos(latitude * .pi / 180.0))
                            cameraRequest = MapCameraRequest(action: .region(MKCoordinateRegion(
                                center: center,
                                span: MKCoordinateSpan(latitudeDelta: latitudeDelta,
                                                       longitudeDelta: longitudeDelta))))
                            isShowingZonePicker = false
                        }
                    }
                }
            }
            .navigationTitle("Choose a zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isShowingZonePicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func zonePickerRow(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(PujaColors.durgaRed)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggleNearbyFilter() {
        isNearbyFilterEnabled.toggle()
        if isNearbyFilterEnabled {
            env.location.startLiveTracking(for: .map)
            let currentCoordinate = env.location.currentPosition()
            let center = currentCoordinate ?? CLLocationCoordinate2D(
                latitude: AppConfig.defaultLat,
                longitude: AppConfig.defaultLng)
            let candidates = selectedZone.map { env.pandals.filter(by: $0) } ?? env.pandals.allPandals
            let count = candidates.filter {
                haversineMeters(center, $0.coordinate) <= AppConfig.nearbyRadius
            }.count
            if currentCoordinate != nil {
                showStatus("\(count) pandals within 10 km", icon: "location.circle")
            } else if env.location.authorizationStatus == .denied || env.location.authorizationStatus == .restricted {
                showStatus("Showing \(count) near Kolkata; enable location for nearby results.",
                           icon: "location.slash")
            } else {
                showStatus("Showing \(count) near Kolkata while location loads.",
                           icon: "location.circle")
            }
        } else {
            showStatus("Nearby filter off", icon: "map")
        }
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
