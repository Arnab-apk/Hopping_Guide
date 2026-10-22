// Features/Pandals/PandalsListView.swift — browseable list of pandals + filters

import SwiftUI
import CoreLocation

enum PandalSortOption: String, CaseIterable, Identifiable {
    case `default`, nearestFirst, ratingHighToLow, lowCrowdFirst
    var id: String { rawValue }
    var label: String {
        switch self {
        case .default:           return "Default"
        case .nearestFirst:      return "Nearest first"
        case .ratingHighToLow:   return "Top rated"
        case .lowCrowdFirst:     return "Low crowd first"
        }
    }
    var iconName: String {
        switch self {
        case .default:           return "circle.dotted"
        case .nearestFirst:      return "location.north.line"
        case .ratingHighToLow:   return "star.fill"
        case .lowCrowdFirst:     return "person.fill.viewfinder"
        }
    }
}

struct PandalsListView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sort: PandalSortOption = .default
    @State private var zoneFilter: KolkataZone?
    @State private var searchText: String = ""
    @State private var detailPandal: Pandal?

    var filtered: [Pandal] {
        var list = env.pandals.allPandals
        if let z = zoneFilter { list = list.filter { $0.zone == z } }
        if !searchText.isEmpty {
            let tokens = SearchNormalize.normalize(searchText).split(separator: " ").map(String.init)
            list = list.filter { pandal in
                let indexedText = env.pandals.normalizedSearchTextByID[pandal.id] ?? ""
                return tokens.allSatisfy(indexedText.contains)
            }
        }

        switch sort {
        case .default:
            break
        case .nearestFirst:
            let currentCoordinate = env.location.currentPosition() ?? CLLocationCoordinate2D(
                latitude: AppConfig.defaultLat,
                longitude: AppConfig.defaultLng)
            let distanceMap = Dictionary(uniqueKeysWithValues: list.map {
                ($0.id, haversineMeters(currentCoordinate, $0.coordinate))
            })
            list.sort { a, b in
                let da = distanceMap[a.id] ?? Double.infinity
                let db = distanceMap[b.id] ?? Double.infinity
                return da < db
            }
        case .ratingHighToLow:
            list = PandalSpatialCluster.sortByRating(list)
        case .lowCrowdFirst:
            list.sort { (a, b) in
                let ca = (a.crowdLevel?.lowercased() == "high") ? 3
                        : (a.crowdLevel?.lowercased() == "medium") ? 2 : 1
                let cb = (b.crowdLevel?.lowercased() == "high") ? 3
                        : (b.crowdLevel?.lowercased() == "medium") ? 2 : 1
                return ca < cb
            }
        }

        return list
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "building.columns.fill")
                            .foregroundStyle(PujaColors.durgaRed)
                        Text("\(env.pandals.totalCount) pandals across Kolkata")
                            .font(PujaTypography.rounded(13, weight: .semibold))
                        Spacer()
                        Text("OFFLINE READY")
                            .font(PujaTypography.rounded(9, weight: .heavy))
                            .tracking(0.5)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 3)
                }

                if let day = getTodaysPujaDay() {
                    Section {
                        HStack(spacing: 10) {
                            PujaIcon.durgaFace(size: 36, color: PujaColors.durgaRedLight)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Shubho \(day.name)")
                                    .font(PujaTypography.rounded(15, weight: .bold))
                                Text(day.description)
                                    .font(PujaTypography.rounded(11))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }

                Section {
                    Picker("Sort", selection: $sort) {
                        ForEach(PandalSortOption.allCases) { opt in
                            Label(opt.label, systemImage: opt.iconName).tag(opt)
                        }
                    }
                    Picker("Zone", selection: $zoneFilter) {
                        Text("All Zones").tag(KolkataZone?.none)
                        ForEach(KolkataZone.allCases, id: \.self) { z in
                            Text(z.label).tag(KolkataZone?.some(z))
                        }
                    }
                }

                Section {
                    ForEach(filtered) { pandal in
                        PandalCard(
                            pandal: pandal,
                            isVisited: env.userState.isVisited(pandal.id),
                            isFavorite: env.userState.isFavorite(pandal.id),
                            onTap: { detailPandal = pandal },
                            onToggleVisited: { env.userState.toggleVisited(pandal.id) },
                            onToggleFavorite: { env.userState.toggleFavorite(pandal.id) }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Pandals")
            .searchable(text: $searchText, prompt: "Search by name, theme, or metro")
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: filtered.map(\.id))
            .sheet(item: $detailPandal) { p in
                PandalDetailView(pandal: p)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(PandalSortOption.allCases) {
                                Label($0.label, systemImage: $0.iconName).tag($0)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }
            }
            .onAppear {
                if sort == .nearestFirst {
                    env.location.startLiveTracking(for: .pandalDirectory)
                }
            }
            .onChange(of: sort) { oldSort, newSort in
                if oldSort == .nearestFirst && newSort != .nearestFirst {
                    env.location.stopLiveTracking(for: .pandalDirectory)
                } else if oldSort != .nearestFirst && newSort == .nearestFirst {
                    env.location.startLiveTracking(for: .pandalDirectory)
                }
            }
            .onDisappear {
                env.location.stopLiveTracking(for: .pandalDirectory)
            }
        }
    }
}

#Preview {
    PandalsListView()
        .environment(AppEnvironment())
}
