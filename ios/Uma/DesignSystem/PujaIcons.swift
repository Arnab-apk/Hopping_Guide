// DesignSystem/PujaIcons.swift — loaders for the 14 Durga Puja festival icons.
// All icons live as PNGs in Resources/Icons/ — accessed via Bundle.

import SwiftUI
import UIKit

public enum PujaIconName: String, CaseIterable, Identifiable, Sendable {
    case shankha, dhaki, dhunuchiPriest, durgaFace, ashtabhujaDevi,
         durgaEyes, trishulEyes, durgaSunTrishul, gada, kalash,
         ashtabhujaVariant, dhakDrum, bhogSweets, trishulDiya

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .shankha:            return "Shankha (Conch Shell)"
        case .dhaki:              return "Dhaki (Dhak Drummer)"
        case .dhunuchiPriest:     return "Priest with Dhunuchi"
        case .durgaFace:          return "Durga Face"
        case .ashtabhujaDevi:     return "Ashtabhuja Devi"
        case .durgaEyes:          return "Durga Eyes"
        case .trishulEyes:        return "Trishul with Eyes"
        case .durgaSunTrishul:    return "Durga Face with Trishuls"
        case .gada:               return "Gada (Mace)"
        case .kalash:             return "Kalash (Sacred Pot)"
        case .ashtabhujaVariant:  return "Multi-armed Goddess (Variant)"
        case .dhakDrum:           return "Dhak with Sticks"
        case .bhogSweets:         return "Bhog / Sweets Bowl"
        case .trishulDiya:        return "Trishul with Diya"
        }
    }

    public var baseFileName: String {
        switch self {
        case .shankha:            return "shankha"
        case .dhaki:              return "dhaki"
        case .dhunuchiPriest:     return "dhunuchi_priest"
        case .durgaFace:          return "durga_face"
        case .ashtabhujaDevi:     return "ashtabhuja_devi"
        case .durgaEyes:          return "durga_eyes"
        case .trishulEyes:        return "trishul_eyes"
        case .durgaSunTrishul:    return "durga_sun_trishul"
        case .gada:               return "gada"
        case .kalash:             return "kalash"
        case .ashtabhujaVariant:  return "ashtabhuja_variant"
        case .dhakDrum:           return "dhak_drum"
        case .bhogSweets:         return "bhog_sweets"
        case .trishulDiya:        return "trishul_diya"
        }
    }

    public enum Variant: String, Sendable {
        case base, gold, crimson
        public var suffix: String {
            switch self {
            case .base:    return ""
            case .gold:    return "_gold"
            case .crimson: return "_crimson"
            }
        }
    }
}

public struct PujaIcon: View {
    public let name: PujaIconName
    public let variant: PujaIconName.Variant
    public let size: CGFloat
    public let tintColor: Color?

    public init(_ name: PujaIconName,
                variant: PujaIconName.Variant = .base,
                size: CGFloat = 30,
                tintColor: Color? = nil) {
        self.name = name
        self.variant = variant
        self.size = size
        self.tintColor = tintColor
    }

    public var body: some View {
        let assetName = "\(name.baseFileName)\(variant.suffix)"
        if let uiImage = UIImage(named: assetName) {
            let img = Image(uiImage: uiImage)
                .resizable()
                .renderingMode(tintColor == nil ? .original : .template)
                .foregroundStyle(tintColor ?? .clear)
                .frame(width: size, height: size)
                .accessibilityLabel(name.displayName)
            img
        } else {
            // Fallback glyph if PNG missing
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.7, weight: .bold))
                .foregroundStyle(tintColor ?? PujaColors.festivalGold)
                .frame(width: size, height: size)
                .accessibilityLabel(name.displayName)
        }
    }
}

/// Resolve a Puja icon by raw asset name (e.g. "durga_eyes") — used by the tab bar.
public func pujaIconImage(_ assetName: String, size: CGFloat = 24, tint: Color? = nil) -> some View {
    Group {
        if let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage)
                .resizable()
                .renderingMode(tint == nil ? .original : .template)
                .foregroundStyle(tint ?? .clear)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.7, weight: .bold))
                .foregroundStyle(tint ?? PujaColors.festivalGold)
                .frame(width: size, height: size)
        }
    }
}

public extension PujaIcon {
    static func shankha(size: CGFloat = 30, color: Color? = nil) -> some View {
        PujaIcon(.shankha, size: size, tintColor: color)
    }
    static func dhaki(size: CGFloat = 30, color: Color? = nil) -> some View {
        PujaIcon(.dhaki, size: size, tintColor: color)
    }
    static func durgaEyes(size: CGFloat = 30, color: Color? = nil) -> some View {
        PujaIcon(.durgaEyes, size: size, tintColor: color)
    }
    static func durgaFace(size: CGFloat = 30, color: Color? = nil) -> some View {
        PujaIcon(.durgaFace, size: size, tintColor: color)
    }
    static func ashtabhujaDevi(size: CGFloat = 30, color: Color? = nil) -> some View {
        PujaIcon(.ashtabhujaDevi, size: size, tintColor: color)
    }
    static func ashtabhujaVariant(size: CGFloat = 30, color: Color? = nil) -> some View {
        PujaIcon(.ashtabhujaVariant, size: size, tintColor: color)
    }
    static func trishulEyes(size: CGFloat = 30, color: Color? = nil) -> some View {
        PujaIcon(.trishulEyes, size: size, tintColor: color)
    }
    static func trishulDiya(size: CGFloat = 30, color: Color? = nil) -> some View {
        PujaIcon(.trishulDiya, size: size, tintColor: color)
    }
    static func kalash(size: CGFloat = 30, color: Color? = nil) -> some View {
        PujaIcon(.kalash, size: size, tintColor: color)
    }
}
