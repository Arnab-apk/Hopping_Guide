// Features/Routes/RoutesView.swift — 6 curated circuits with filter chips

import SwiftUI

struct RoutesView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var filter: RouteCategoryFilter = .all
    @State private var searchText: String = ""
    @State private var expanded: String?

    var routes: [HoppingRoute] {
        var list = HoppingRoute.routes(in: filter)
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(q)
                || $0.subtitle.lowercased().contains(q)
                || ($0.bengaliTitle ?? "").lowercased().contains(q)
            }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(RouteCategoryFilter.allCases) { cat in
                                CategoryChip(
                                    title: cat.label,
                                    icon: cat.iconName,
                                    isActive: filter == cat) {
                                    Haptics.selection()
                                    filter = cat
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                    }
                    .padding(.top, 6)

                    LazyVStack(spacing: 12) {
                        ForEach(routes) { route in
                            RouteCard(
                                route: route,
                                isExpanded: expanded == route.id,
                                onExpand: { expanded = (expanded == route.id) ? nil : route.id },
                                onStart: { startTrail(route) }
                            )
                        }
                    }
                    .padding(.horizontal, 14)

                    TipsCard()
                        .padding(.horizontal, 14)
                        .padding(.top, 4)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Curated Routes")
            .searchable(text: $searchText, prompt: "Search by name or area")
        }
    }

    private func startTrail(_ route: HoppingRoute) {
        env.startTrail(route, byId: env.pandals.byId(_:))
    }
}

private struct CategoryChip: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .bold))
                Text(title).font(PujaTypography.rounded(12, weight: .semibold))
            }
            .foregroundStyle(isActive ? .white : .primary)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                Capsule().fill(isActive ? PujaColors.durgaRed : Color.primary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct RouteCard: View {
    let route: HoppingRoute
    let isExpanded: Bool
    let onExpand: () -> Void
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(PujaColors.durgaRed.opacity(0.9))
                        .frame(width: 52, height: 52)
                    Image(systemName: route.iconSystemName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(PujaColors.goldBright)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(route.title)
                            .font(PujaTypography.rounded(16, weight: .bold))
                        Spacer()
                        Text("\(route.pandalIds.count) stops")
                            .font(PujaTypography.rounded(11, weight: .semibold))
                            .padding(.horizontal, 7).padding(.vertical, 2.5)
                            .background(Capsule().fill(PujaColors.festivalGold.opacity(0.25)))
                            .foregroundStyle(PujaColors.festivalGold)
                    }
                    if let bn = route.bengaliTitle {
                        Text(bn)
                            .font(PujaTypography.rounded(11))
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 12) {
                        Label(route.formattedDuration(), systemImage: "clock")
                            .font(PujaTypography.rounded(11))
                        Label(route.formattedDistance(), systemImage: "figure.walk")
                            .font(PujaTypography.rounded(11))
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Text(route.subtitle)
                .font(PujaTypography.rounded(13))
                .foregroundStyle(.secondary)
                .lineLimit(isExpanded ? nil : 2)
                .multilineTextAlignment(.leading)

            if isExpanded {
                Label(route.bestTime, systemImage: "clock.badge.checkmark")
                    .font(PujaTypography.rounded(12, weight: .medium))
                    .foregroundStyle(PujaColors.festivalGold)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(PujaColors.festivalGold.opacity(0.18)))
                ForEach(Array(route.pandalIds.enumerated()), id: \.offset) { idx, pid in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(PujaColors.durgaRed)
                                .frame(width: 22, height: 22)
                            Text("\(idx + 1)")
                                .font(PujaTypography.rounded(11, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                        Text(pid.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(PujaTypography.rounded(13))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Button(action: onExpand) {
                    Text(isExpanded ? "Hide stops" : "Show stops")
                        .font(PujaTypography.rounded(13, weight: .semibold))
                }
                .buttonStyle(.bordered)
                Spacer()
                Button(action: onStart) {
                    Label("Start Circuit on Map", systemImage: "sparkles")
                        .font(PujaTypography.rounded(13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(PujaColors.durgaRed))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct TipsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Hopping & Metro Tips", systemImage: "info.circle.fill")
                .font(PujaTypography.rounded(14, weight: .bold))
                .foregroundStyle(PujaColors.festivalGold)
            tip("Metro runs till ~4 AM during Pujo nights — schedule your circuit accordingly.")
            tip("Best windows: post-Ashtami night (peak lights) and early-morning Dashami.")
            tip("Wear comfortable footwear — Kolkata pandal-hopping averages 6–9 km on foot.")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(PujaColors.festivalGold.opacity(0.1))
        )
    }

    private func tip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 11))
                .foregroundStyle(PujaColors.festivalGold)
                .padding(.top, 3)
            Text(text)
                .font(PujaTypography.rounded(12))
                .foregroundStyle(.primary)
        }
    }
}
