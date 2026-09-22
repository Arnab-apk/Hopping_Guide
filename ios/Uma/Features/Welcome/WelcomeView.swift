// Features/Welcome/WelcomeView.swift — animated onboarding + countdown to Maha Shasthi 2026

import SwiftUI

struct WelcomeView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var countdown = CountdownTime.toPuja()
    @State private var timer: Timer?
    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = -20
    @State private var countdownOpacity: Double = 0
    @State private var cardOpacity: Double = 0
    @State private var cardOffset: CGFloat = 30
    @State private var isLoading = false
    @State private var name: String = ""

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer(minLength: 60)

                // Header — "Uma Asche"
                Text("Uma Asche")
                    .font(PujaTypography.display(48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, PujaColors.goldSoft, PujaColors.goldBright],
                            startPoint: .top, endPoint: .bottom)
                    )
                    .goldGlow()
                    .multilineTextAlignment(.center)
                    .opacity(headerOpacity)
                    .offset(y: headerOffset)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 24)

                // Countdown capsule
                countdownCapsule
                    .opacity(countdownOpacity)

                Spacer()

                // Login card
                loginCard
                    .opacity(cardOpacity)
                    .offset(y: cardOffset)
                    .padding(.horizontal, 20)

                Spacer().frame(height: 20)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            startCountdown()
            withAnimation(.easeOut(duration: 0.9).delay(0.10)) {
                headerOpacity = 1; headerOffset = 0
            }
            withAnimation(.easeOut(duration: 0.9).delay(0.35)) {
                countdownOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.9).delay(0.55)) {
                cardOpacity = 1; cardOffset = 0
            }
        }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            // Dark crimson night base
            PujaColors.bgDark
                .ignoresSafeArea()

            // Soft top vignette for legibility
            LinearGradient(
                colors: [PujaColors.bgDark.opacity(0.6), .clear,
                         .clear, PujaColors.bgDark.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Stylized Maa Durga eyes motif — two glowing concentric arcs.
            GeometryReader { geo in
                ZStack {
                    // Outer halo
                    Circle()
                        .stroke(PujaColors.festivalGold.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 220, height: 220)
                        .blur(radius: 1)
                        .offset(y: -geo.size.height * 0.18)

                    // Inner eye glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [PujaColors.goldBright.opacity(0.55),
                                         PujaColors.festivalGold.opacity(0.18),
                                         .clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 110)
                        )
                        .frame(width: 240, height: 240)
                        .offset(y: -geo.size.height * 0.18)

                    // Bindi dot — third eye
                    Circle()
                        .fill(PujaColors.durgaRedLight.opacity(0.85))
                        .frame(width: 12, height: 12)
                        .offset(y: -geo.size.height * 0.18 - 30)

                    // Soft scattered stars
                    ForEach(0..<25, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(Double.random(in: 0.15...0.6)))
                            .frame(width: .random(in: 1...2.5), height: .random(in: 1...2.5))
                            .position(
                                x: .random(in: 0...geo.size.width),
                                y: .random(in: 0...geo.size.height * 0.55))
                    }
                }
            }
        }
    }

    // MARK: - Countdown

    private var countdownCapsule: some View {
        HStack(spacing: 4) {
            CountdownCell(value: countdown.days, label: "DAYS")
            Divider().frame(height: 22).overlay(Color.white.opacity(0.2))
            CountdownCell(value: countdown.hours, label: "HOURS")
            Divider().frame(height: 22).overlay(Color.white.opacity(0.2))
            CountdownCell(value: countdown.minutes, label: "MINS")
            Divider().frame(height: 22).overlay(Color.white.opacity(0.2))
            CountdownCell(value: countdown.seconds, label: "SECS")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PujaColors.festivalGold.opacity(0.45), lineWidth: 1)
        )
    }

    // MARK: - Login card

    private var loginCard: some View {
        VStack(alignment: .center, spacing: 14) {
            Text("Begin Your Parikrama")
                .font(PujaTypography.display(20, weight: .semibold))
                .foregroundStyle(PujaColors.festivalGold)

            Text("Discover 380+ verified pandals, walking routes, food spots, and squad tracking — fully offline.")
                .font(PujaTypography.rounded(12))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 4)

            // Optional name input
            TextField("Hopper name", text: $name)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                )
                .foregroundStyle(.white)
                .tint(PujaColors.festivalGold)
                .font(PujaTypography.rounded(14))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)

            // Primary action
            Button(action: enterAsGuest) {
                HStack(spacing: 10) {
                    PujaIcon.shankha(size: 22, color: PujaColors.festivalGold)
                    Text(isLoading ? "Entering…" : "Enter as Guest")
                        .font(PujaTypography.rounded(15, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(PujaColors.durgaRed)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(PujaColors.festivalGold.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: PujaColors.durgaRed.opacity(0.55), radius: 12, y: 4)
            }
            .disabled(isLoading)

            // Trust note
            HStack(spacing: 6) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 11))
                Text("Offline First • Zero Friction • Instant Access")
                    .font(PujaTypography.rounded(10.5, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(PujaColors.festivalGold.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 22, y: 10)
    }

    // MARK: - Actions

    private func enterAsGuest() {
        Haptics.light()
        isLoading = true
        let cleanName = name.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Pujo Hopper"
            : name.trimmingCharacters(in: .whitespaces)
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            env.enterApp(as: cleanName)
        }
    }

    private func startCountdown() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            countdown = CountdownTime.toPuja()
        }
    }
}

private struct CountdownCell: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(PujaTypography.mono(18, weight: .bold))
                .foregroundStyle(PujaColors.goldBright)
            Text(label)
                .font(PujaTypography.rounded(8, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(minWidth: 52)
    }
}

#Preview {
    WelcomeView()
        .environment(AppEnvironment())
}
