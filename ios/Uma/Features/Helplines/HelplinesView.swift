// Features/Helplines/HelplinesView.swift — emergency dialer grid

import SwiftUI

struct HelplinesView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    banner

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Direct Helplines")
                            .font(PujaTypography.rounded(15, weight: .heavy))
                            .foregroundStyle(PujaColors.durgaRed)
                        ForEach(env.helplines.helplines, id: \.number) { line in
                            helplineRow(line)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.background)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Festival Medical & Crowd First-Aid")
                            .font(PujaTypography.rounded(15, weight: .heavy))
                            .foregroundStyle(PujaColors.durgaRed)
                        ForEach(env.helplines.safetyGuides) { guide in
                            safetyRow(guide)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.background)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Emergency")
        }
    }

    private var banner: some View {
        HStack(alignment: .top, spacing: 10) {
            PujaIcon.trishulDiya(size: 38, color: PujaColors.durgaRed)
            VStack(alignment: .leading, spacing: 2) {
                Text("Kolkata Emergency Services")
                    .font(PujaTypography.rounded(15, weight: .bold))
                Text("100% offline accessible · toll-free")
                    .font(PujaTypography.rounded(11.5))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(PujaColors.durgaRed.opacity(0.08))
        )
    }

    private func helplineRow(_ line: Helpline) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName(for: line.label))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(PujaColors.durgaRed))
            VStack(alignment: .leading, spacing: 2) {
                Text(line.label)
                    .font(PujaTypography.rounded(14, weight: .semibold))
                Text("Dial \(line.number)")
                    .font(PujaTypography.rounded(11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: { dial(line.number) }) {
                Label("Call", systemImage: "phone.fill")
                    .font(PujaTypography.rounded(12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Capsule().fill(PujaColors.durgaRed))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }

    private func safetyRow(_ guide: SafetyGuide) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "cross.case.fill")
                    .foregroundStyle(PujaColors.crowdMedium)
                Text(guide.title)
                    .font(PujaTypography.rounded(13.5, weight: .bold))
            }
            ForEach(Array(guide.content.enumerated()), id: \.offset) { _, step in
                HStack(alignment: .top, spacing: 8) {
                    Text("•").foregroundStyle(.secondary)
                    Text(step)
                        .font(PujaTypography.rounded(12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func iconName(for label: String) -> String {
        let l = label.lowercased()
        if l.contains("police") { return "shield.fill" }
        if l.contains("fire")   { return "flame.fill" }
        if l.contains("women")  { return "figure.arms.open" }
        if l.contains("ambulance") || l.contains("medical") { return "cross.fill" }
        if l.contains("disaster") { return "exclamationmark.triangle.fill" }
        return "phone.fill"
    }

    private func dial(_ number: String) {
        Haptics.medium()
        if let url = URL(string: "tel://\(number)") {
            UIApplication.shared.open(url)
        }
    }
}
