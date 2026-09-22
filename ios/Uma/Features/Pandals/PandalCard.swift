// Features/Pandals/PandalCard.swift — reusable card for list and detail

import SwiftUI

struct PandalCard: View {
    let pandal: Pandal
    let isVisited: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onToggleVisited: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Theme badge
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(PujaColors.durgaRed.opacity(0.9))
                        .frame(width: 56, height: 56)
                    PujaIcon.durgaEyes(size: 32, color: PujaColors.goldBright)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(pandal.name)
                        .font(PujaTypography.rounded(15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        Text(pandal.zone.shortLabel.uppercased())
                            .font(PujaTypography.rounded(9.5, weight: .heavy))
                            .padding(.horizontal, 5).padding(.vertical, 1.5)
                            .background(Capsule().fill(PujaColors.durgaRed))
                            .foregroundStyle(.white)
                        if let r = pandal.rating {
                            Label(String(format: "%.1f", r), systemImage: "star.fill")
                                .font(PujaTypography.rounded(10.5, weight: .semibold))
                                .foregroundStyle(PujaColors.goldBright)
                        }
                        if let c = pandal.crowdLevel {
                            Label(c.capitalized, systemImage: "person.3.fill")
                                .font(PujaTypography.rounded(10.5))
                                .foregroundStyle(crowdColor(c))
                        }
                    }
                    if !pandal.theme.isEmpty {
                        Text(pandal.theme)
                            .font(PujaTypography.rounded(11.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if let m = pandal.nearestMetro, !m.isEmpty {
                        Label(m, systemImage: "tram.fill")
                            .font(PujaTypography.rounded(11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                VStack(spacing: 6) {
                    Button(action: onToggleVisited) {
                        Image(systemName: isVisited ? "checkmark.seal.fill" : "checkmark.seal")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isVisited ? PujaColors.goldBright : .secondary)
                    }
                    .buttonStyle(.plain)
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isFavorite ? PujaColors.durgaRed : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func crowdColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "high":   return PujaColors.crowdHigh
        case "medium": return PujaColors.crowdMedium
        default:        return PujaColors.crowdLow
        }
    }
}
