// DesignSystem/Theme.swift — color tokens matching PujaColors from theme.dart

import SwiftUI

enum PujaColors {
    // Crimson & Burgundy
    static let durgaRed      = Color(hex: 0xB71C1C)
    static let durgaRedDark  = Color(hex: 0x5B0E1B)
    static let crimsonVelvet = Color(hex: 0x3A0810)
    static let durgaRedLight = Color(hex: 0xD32F2F)

    // Sacred Gold
    static let festivalGold  = Color(hex: 0xDCA830)
    static let goldBright    = Color(hex: 0xF3C759)
    static let goldSoft      = Color(hex: 0xF6EEDC)

    // Surfaces
    static let ivoryBg       = Color(hex: 0xFDF8F7)
    static let nightBg       = Color(hex: 0x141213)
    static let nightCard     = Color(hex: 0x1E1A1B)
    static let nightSurface  = Color(hex: 0x2B2425)
    static let nightBorder   = Color(hex: 0x44383A)

    // Status
    static let crowdLow      = Color(hex: 0x1E8E3E)
    static let crowdMedium   = Color(hex: 0xE37400)
    static let crowdHigh     = Color(hex: 0xD93025)

    // Transit
    static let metroBlue     = Color(hex: 0x1A73E8)
    static let railwayPurple = Color(hex: 0x9334E6)

    // Brand background
    static let bgDark        = Color(hex: 0x0E0B0C)
}

enum PujaTypography {
    /// Display title — uses Bodoni 72 (system preinstalled) with rounded fallback.
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        if UIFont(name: "Bodoni 72", size: size) != nil {
            return .custom("Bodoni 72", size: size, relativeTo: .largeTitle)
                .weight(weight)
        }
        return .system(size: size, weight: weight, design: .serif)
    }

    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension View {
    /// Soft golden glow (used behind title text on the welcome screen).
    func goldGlow() -> some View {
        self.shadow(color: PujaColors.goldBright.opacity(0.45), radius: 14)
            .shadow(color: PujaColors.festivalGold.opacity(0.3), radius: 6)
    }
}
