// Features/Pandals/PandalDetailView.swift — single pandal detail screen

import SwiftUI

struct PandalDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    let pandal: Pandal

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    VStack(alignment: .leading, spacing: 14) {
                        Text(pandal.name)
                            .font(PujaTypography.display(26, weight: .bold))

                        HStack(spacing: 10) {
                            Badge(text: pandal.zone.shortLabel.uppercased(), color: PujaColors.durgaRed)
                            if let r = pandal.rating {
                                Badge(
                                    text: String(format: "★ %.1f", r),
                                    color: PujaColors.festivalGold)
                            }
                            if let c = pandal.crowdLevel {
                                Badge(text: c.capitalized,
                                      color: crowdColor(c))
                            }
                        }

                        let galleryPhotos = env.pandalPhotos.photos(for: pandal.id)
                        if !galleryPhotos.isEmpty {
                            PandalPhotoGalleryView(photos: galleryPhotos)
                                .padding(.top, 2)
                        }

                        if !pandal.theme.isEmpty {
                            infoRow(icon: "paintbrush.pointed.fill",
                                    title: "Theme",
                                    value: pandal.theme)
                        }
                        if !pandal.timings.isEmpty {
                            infoRow(icon: "clock.fill",
                                    title: "Timings",
                                    value: pandal.timings)
                        }
                        if let area = pandal.area, !area.isEmpty {
                            infoRow(icon: "mappin.and.ellipse",
                                    title: "Area",
                                    value: area)
                        }
                        if let m = pandal.nearestMetro, !m.isEmpty {
                            infoRow(icon: "tram.fill",
                                    title: "Nearest Metro",
                                    value: m)
                        }
                        if let r = pandal.nearestRailway, !r.isEmpty {
                            infoRow(icon: "tram.tunnel.fill",
                                    title: "Nearest Railway",
                                    value: r)
                        }

                        if !pandal.nearestStations.isEmpty {
                            VStack(alignment: .leading, spacing: 9) {
                                Text("Nearby Stations")
                                    .font(PujaTypography.rounded(14, weight: .bold))
                                    .padding(.top, 4)
                                ForEach(pandal.nearestStations.prefix(4)) { station in
                                    HStack(spacing: 10) {
                                        Image(systemName: station.kind == "metro" ? "tram.fill" : "train.side.front.car")
                                            .foregroundStyle(station.kind == "metro" ? PujaColors.metroBlue : PujaColors.railwayPurple)
                                            .frame(width: 20)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(station.name)
                                                .font(PujaTypography.rounded(12, weight: .semibold))
                                            if let nameBn = station.nameBn, !nameBn.isEmpty {
                                                Text(nameBn).font(PujaTypography.bengali(13)).foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        if let distance = station.distanceMeters {
                                            Text(distance >= 1000
                                                 ? String(format: "%.1f km", distance / 1000)
                                                 : "\(Int(distance.rounded())) m")
                                                .font(PujaTypography.rounded(10, weight: .medium))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }

                        if !pandal.specialFeatures.isEmpty {
                            Text("Special Features")
                                .font(PujaTypography.rounded(14, weight: .bold))
                                .padding(.top, 6)
                            ForEach(pandal.specialFeatures, id: \.self) { f in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "sparkle")
                                        .foregroundStyle(PujaColors.goldBright)
                                    Text(f)
                                        .font(PujaTypography.rounded(13))
                                        .foregroundStyle(.primary)
                                }
                            }
                        }

                        if !pandal.description.isEmpty {
                            Divider().padding(.vertical, 6)
                            Text("About")
                                .font(PujaTypography.rounded(14, weight: .bold))
                            Text(pandal.description)
                                .font(PujaTypography.rounded(13.5))
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                        }

                        actionRow
                            .padding(.top, 12)
                    }
                    .padding(.horizontal, 18)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { env.userState.toggleFavorite(pandal.id) }) {
                        Image(systemName: env.userState.isFavorite(pandal.id) ? "heart.fill" : "heart")
                            .foregroundStyle(env.userState.isFavorite(pandal.id) ? PujaColors.durgaRed : .primary)
                    }
                }
            }
        }
    }

    private var hero: some View {
        ZStack {
            if let photo = env.pandalPhotos.cover(for: pandal.id), let url = photo.imageURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        festivalHeroArtwork
                    }
                }
            } else {
                festivalHeroArtwork
            }
            VStack {
                Spacer()
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, Color(.systemBackground).opacity(0.9)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(height: 80)
            }
        }
        .frame(height: 220)
        .clipped()
    }

    private var festivalHeroArtwork: some View {
        ZStack {
            Image("FestivalHero")
                .resizable()
                .scaledToFill()
                .overlay(PujaColors.crimsonVelvet.opacity(0.48))
            Image("FestivalEyes")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 84)
                .opacity(0.82)
        }
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 22, height: 22)
                .foregroundStyle(PujaColors.durgaRed)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(PujaTypography.rounded(11, weight: .heavy))
                    .foregroundStyle(.secondary)
                    .tracking(0.4)
                Text(value)
                    .font(PujaTypography.rounded(14))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button(action: { env.userState.toggleVisited(pandal.id) }) {
                Label(env.userState.isVisited(pandal.id) ? "Hopped" : "Mark Hopped",
                      systemImage: env.userState.isVisited(pandal.id) ? "checkmark.seal.fill" : "checkmark.seal")
                    .font(PujaTypography.rounded(14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(env.userState.isVisited(pandal.id) ? PujaColors.goldBright : PujaColors.durgaRed)
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            Button(action: goToMap) {
                Label("Map", systemImage: "map.fill")
                    .font(PujaTypography.rounded(14, weight: .semibold))
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.primary.opacity(0.1))
                    )
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
    }

    private func goToMap() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            env.selectedTab = .map
        }
    }

    private func crowdColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "high":   return PujaColors.crowdHigh
        case "medium": return PujaColors.crowdMedium
        default:        return PujaColors.crowdLow
        }
    }
}

private struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(PujaTypography.rounded(11, weight: .heavy))
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(Capsule().fill(color))
            .foregroundStyle(.white)
    }
}
