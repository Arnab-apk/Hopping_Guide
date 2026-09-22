// DesignSystem/LiquidGlass.swift — centralized glass-background modifier
// iOS 18-25: SwiftUI materials (.ultraThinMaterial, .regularMaterial)
// iOS 26+:   Liquid Glass API (.glassEffect(...) in GlassEffectContainer)

import SwiftUI

public enum GlassKind {
    case ultraThin, regular, clear, interactive
}

public extension View {
    /// Apply a translucent glass background, routed to the system Liquid Glass API on iOS 26+
    /// or to SwiftUI's `.background(_:in:)` material on iOS 18-25.
    @ViewBuilder
    func liquidBackground(_ kind: GlassKind = .ultraThin, in shape: some Shape = Capsule()) -> some View {
        if #available(iOS 26.0, *) {
            switch kind {
            case .ultraThin:    self.glassEffect(.regular, in: shape)
            case .regular:      self.glassEffect(.regular, in: shape)
            case .clear:        self.glassEffect(.clear, in: shape)
            case .interactive:  self.glassEffect(.regular.interactive(), in: shape)
            }
        } else {
            switch kind {
            case .ultraThin:    self.background(.ultraThinMaterial, in: shape)
            case .regular:      self.background(.regularMaterial, in: shape)
            case .clear:        self.background(Color.white.opacity(0.001), in: shape)
            case .interactive:  self.background(.regularMaterial, in: shape)
            }
        }
    }

    /// A rectangular Liquid Glass card — RoundedRectangle 22 pt corner, ultra-thin material.
    @ViewBuilder
    func liquidCard(cornerRadius: CGFloat = 22) -> some View {
        self.liquidBackground(.ultraThin, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Tab-style pill (capsule) — ultra-thin material.
    @ViewBuilder
    func liquidPill() -> some View {
        self.liquidBackground(.ultraThin, in: Capsule())
    }
}

/// Wraps content in a GlassEffectContainer on iOS 26+ so multiple glass surfaces
/// can be merged into a single rendering pass for proper specular highlights.
public struct LiquidGlassCluster<Content: View>: View {
    public let spacing: CGFloat
    public let content: Content

    public init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}
