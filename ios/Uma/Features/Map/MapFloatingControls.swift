// Features/Map/MapFloatingControls.swift — zoom + locate + compass buttons

import SwiftUI

struct MapFloatingControls: View {
    @Binding var followUser: Bool
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onLocate: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            ControlButton(systemName: "plus", action: onZoomIn)
            ControlButton(systemName: "minus", action: onZoomOut)
            ControlButton(
                systemName: followUser ? "location.fill" : "location",
                tint: followUser ? PujaColors.durgaRedLight : nil,
                action: onLocate
            )
        }
    }
}

private struct ControlButton: View {
    let systemName: String
    var tint: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: { Haptics.light(); action() }) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(tint ?? .white)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(tint ?? PujaColors.festivalGold.opacity(0.45),
                                lineWidth: tint == nil ? 1 : 1.5)
                )
                .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}
