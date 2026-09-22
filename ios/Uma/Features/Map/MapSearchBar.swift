// Features/Map/MapSearchBar.swift — floating omni-search HUD

import SwiftUI

struct MapSearchBar: View {
    @Binding var text: String
    @Binding var focused: Bool
    let results: [OmniSearchResult]
    let onSubmit: () -> Void
    let onSelect: (OmniSearchResult) -> Void

    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(PujaColors.goldBright)
                TextField("Search pandals, metro, food spots…", text: $text)
                    .focused($fieldFocused)
                    .submitLabel(.search)
                    .onSubmit(onSubmit)
                    .foregroundStyle(.white)
                    .tint(PujaColors.goldBright)
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(
                Capsule().fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule().stroke(PujaColors.festivalGold.opacity(0.45), lineWidth: 1)
            )
            .onChange(of: fieldFocused) { _, isFocused in
                focused = isFocused
            }

            if focused && !results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(results.prefix(6).enumerated()), id: \.element.id) { idx, r in
                        Button(action: { onSelect(r) }) {
                            HStack(spacing: 10) {
                                Image(systemName: r.iconName)
                                    .foregroundStyle(r.badgeColor ?? PujaColors.goldBright)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.title)
                                        .font(PujaTypography.rounded(14, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text(r.subtitle)
                                        .font(PujaTypography.rounded(11))
                                        .foregroundStyle(.white.opacity(0.7))
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 4)
                                if let badge = r.badgeText {
                                    Text(badge)
                                        .font(PujaTypography.rounded(10, weight: .heavy))
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(
                                            Capsule().fill((r.badgeColor ?? PujaColors.goldBright).opacity(0.25))
                                        )
                                        .foregroundStyle(r.badgeColor ?? PujaColors.goldBright)
                                }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        if idx < min(results.count, 6) - 1 {
                            Divider().overlay(Color.white.opacity(0.08))
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(PujaColors.festivalGold.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}
