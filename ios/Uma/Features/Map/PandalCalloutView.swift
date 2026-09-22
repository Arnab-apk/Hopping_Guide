// Features/Map/PandalCalloutView.swift — speech-bubble card shown for the selected pandal

import SwiftUI

struct PandalCalloutView: View {
    let pandal: Pandal
    let isVisited: Bool
    let onClose: () -> Void
    let onDirections: () -> Void
    let onToggleVisited: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pandal.name)
                        .font(PujaTypography.rounded(15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Text(pandal.zone.shortLabel.uppercased())
                            .font(PujaTypography.rounded(9.5, weight: .heavy))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(PujaColors.durgaRed))
                            .foregroundStyle(.white)
                        if let r = pandal.rating {
                            Label(String(format: "%.1f", r), systemImage: "star.fill")
                                .font(PujaTypography.rounded(11, weight: .semibold))
                                .foregroundStyle(PujaColors.goldBright)
                        }
                        if let c = pandal.crowdLevel {
                            Text(c.capitalized)
                                .font(PujaTypography.rounded(10, weight: .semibold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(crowdColor(pandal.crowdLevel).opacity(0.25)))
                                .foregroundStyle(crowdColor(pandal.crowdLevel))
                        }
                    }
                }
                Spacer(minLength: 4)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
            if !pandal.theme.isEmpty {
                Text(pandal.theme)
                    .font(PujaTypography.rounded(11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            HStack(spacing: 8) {
                Button(action: onDirections) {
                    Label("Walk", systemImage: "figure.walk")
                        .font(PujaTypography.rounded(12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(PujaColors.durgaRed))
                }
                .buttonStyle(.plain)
                Button(action: onToggleVisited) {
                    Label(isVisited ? "Hopped" : "Mark Hopped",
                          systemImage: isVisited ? "checkmark.seal.fill" : "checkmark.seal")
                        .font(PujaTypography.rounded(12, weight: .semibold))
                        .foregroundStyle(isVisited ? PujaColors.goldBright : .white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(maxWidth: 280)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PujaColors.festivalGold.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 18, y: 6)
    }

    private func crowdColor(_ level: String?) -> Color {
        switch level?.lowercased() {
        case "high":   return PujaColors.crowdHigh
        case "medium": return PujaColors.crowdMedium
        default:        return PujaColors.crowdLow
        }
    }
}
