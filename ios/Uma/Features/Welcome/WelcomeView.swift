// Features/Welcome/WelcomeView.swift — animated onboarding + countdown to Maha Shasthi 2026

import SwiftUI

struct WelcomeView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    .font(PujaTypography.festival(52))
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

                Text("The festival, held close")
                    .font(PujaTypography.rounded(12, weight: .medium))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(PujaColors.goldSoft.opacity(0.84))
                    .opacity(headerOpacity)

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
            if reduceMotion {
                headerOpacity = 1
                headerOffset = 0
                countdownOpacity = 1
                cardOpacity = 1
                cardOffset = 0
            } else {
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
        }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            GeometryReader { geometry in
                Image("PujaWelcome")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .overlay(Color.black.opacity(0.52))
            }
            .ignoresSafeArea()

            Image("FestivalEyes")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 66)
                .opacity(0.72)
                .accessibilityHidden(true)

            LinearGradient(
                colors: [PujaColors.crimsonVelvet.opacity(0.34), .clear,
                         PujaColors.bgDark.opacity(0.40), PujaColors.bgDark.opacity(0.96)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
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
        .liquidBackground(.ultraThin, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

            Text("Explore \(env.pandals.totalCount) pandals, photo galleries, walking routes, station planning and squad tracking. Your festival directory works offline.")
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
        .liquidBackground(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
            // Snappy greeting transition <= 200ms (reduced from legacy delays)
            try? await Task.sleep(nanoseconds: 200_000_000)
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
