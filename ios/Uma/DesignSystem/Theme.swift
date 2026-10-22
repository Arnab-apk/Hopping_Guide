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
    /// Display face bundled from the Android app's shared asset set.
    static func festival(_ size: CGFloat) -> Font {
        .custom("SamarkanNormal", size: size, relativeTo: .title)
    }

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
        let name: String
        if weight == .black || weight == .heavy {
            name = "PlusJakartaSans-ExtraBold"
        } else if weight == .bold {
            name = "PlusJakartaSans-Bold"
        } else if weight == .semibold {
            name = "PlusJakartaSans-SemiBold"
        } else if weight == .medium {
            name = "PlusJakartaSans-Medium"
        } else {
            name = "PlusJakartaSans-Regular"
        }
        return .custom(name, size: size, relativeTo: .body)
    }

    static func bengali(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "HindSiliguri-Bold" : "HindSiliguri-Regular", size: size, relativeTo: .body)
    }

    static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = weight == .bold || weight == .heavy || weight == .black
            ? "JetBrainsMono-Bold"
            : weight == .medium || weight == .semibold
                ? "JetBrainsMono-Medium"
                : "JetBrainsMono-Regular"
        return .custom(name, size: size, relativeTo: .body)
    }
}

extension View {
    /// Soft golden glow (used behind title text on the welcome screen).
    func goldGlow() -> some View {
        self.shadow(color: PujaColors.goldBright.opacity(0.45), radius: 14)
            .shadow(color: PujaColors.festivalGold.opacity(0.3), radius: 6)
    }
}
