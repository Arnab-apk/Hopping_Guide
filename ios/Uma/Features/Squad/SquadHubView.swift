// Features/Squad/SquadHubView.swift — 4-card group layout

import SwiftUI

struct SquadHubView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false
    @State private var joinCode: String = ""
    @State private var newSquadName: String = "My Squad"
    @State private var navigateToChat = false
    @State private var navigateToDetail: SquadMember?

    var body: some View {
        NavigationStack {
            ScrollView {
                if !env.squad.hasActiveSquad {
                    emptyState
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                } else {
                    content
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }
            }
            .navigationTitle("Squads")
            .navigationDestination(isPresented: $navigateToChat) {
                SquadChatView(squadId: env.squad.currentCode ?? "",
                              squadName: env.squad.currentName ?? "")
            }
            .sheet(isPresented: $showCreateSheet) {
                createSheet
            }
            .sheet(isPresented: $showJoinSheet) {
                joinSheet
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Hop Together, Stay Together", systemImage: "person.3.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(PujaColors.festivalGold)
        } description: {
            Text("Create a squad to share live locations, ping each other, and stay within reach during pandal hopping.")
                .multilineTextAlignment(.center)
        } actions: {
            VStack(spacing: 10) {
                Button(action: { showCreateSheet = true }) {
                    Label("Create New Squad", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(PujaColors.durgaRed)
                        )
                        .foregroundStyle(.white)
                        .font(PujaTypography.rounded(15, weight: .bold))
                }
                .buttonStyle(.plain)
                Button(action: { showJoinSheet = true }) {
                    Label("Join with Squad Code", systemImage: "person.2.badge.gearshape")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                        .foregroundStyle(.primary)
                        .font(PujaTypography.rounded(15, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Active squad

    private var content: some View {
        VStack(spacing: 14) {
            identityCard
            settingsCard
            membersCard
            chatCard
            Button(action: { env.squad.leaveSquad() }) {
                Label("Leave Squad", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(PujaTypography.rounded(13, weight: .semibold))
                    .foregroundStyle(PujaColors.crowdHigh)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(env.squad.currentName ?? "")
                        .font(PujaTypography.rounded(18, weight: .bold))
                    Text("\(env.squad.members.count) members")
                        .font(PujaTypography.rounded(12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                PujaIcon.shankha(size: 30, color: PujaColors.festivalGold)
            }
            HStack {
                Text("Code: \(env.squad.currentCode ?? "")")
                    .font(PujaTypography.mono(13, weight: .bold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(PujaColors.crimsonVelvet))
                    .foregroundStyle(PujaColors.goldBright)
                Spacer()
                Button(action: copyInvite) {
                    Label("Invite", systemImage: "square.and.arrow.up")
                        .font(PujaTypography.rounded(12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Capsule().fill(PujaColors.durgaRed))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("Squad Settings", icon: "gearshape.fill")
            HStack {
                PujaIcon.kalash(size: 26, color: PujaColors.festivalGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meet-up Point").font(PujaTypography.rounded(13, weight: .semibold))
                    Text(env.squad.meetupPointName ?? "Not set")
                        .font(PujaTypography.rounded(11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            Divider()
            Toggle(isOn: Binding(
                get: { env.squad.shareLocation },
                set: { _ in env.squad.toggleLocationSharing() })) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(PujaColors.durgaRed)
                    Text("Live GPS Share").font(PujaTypography.rounded(13, weight: .semibold))
                }
            }
            Divider()
            HStack {
                PujaIcon.trishulEyes(size: 26, color: PujaColors.festivalGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Separation Alert")
                        .font(PujaTypography.rounded(13, weight: .semibold))
                    Text("\(Int(env.squad.separationAlertMeters)) m")
                        .font(PujaTypography.rounded(11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    ForEach([100, 250, 500, 1000], id: \.self) { m in
                        Button("\(m) m") { env.squad.setSeparationAlert(meters: Double(m)) }
                    }
                } label: {
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }

    private var membersCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                cardTitle("Members", icon: "person.3.fill")
                Spacer()
                Button(action: { env.selectedTab = .map }) {
                    Label("View on Map", systemImage: "map")
                        .font(PujaTypography.rounded(11, weight: .semibold))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(PujaColors.durgaRed.opacity(0.15)))
                        .foregroundStyle(PujaColors.durgaRed)
                }
                .buttonStyle(.plain)
            }
            ForEach(env.squad.members) { member in
                MemberRow(member: member)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }

    private var chatCard: some View {
        Button(action: { navigateToChat = true }) {
            HStack(spacing: 14) {
                ZStack {
                    LinearGradient(colors: [PujaColors.durgaRed, PujaColors.crimsonVelvet],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Squad Chat").font(PujaTypography.rounded(15, weight: .bold))
                    Text("Live · \(env.chat.messages(for: env.squad.currentCode ?? "").count) messages")
                        .font(PujaTypography.rounded(11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func cardTitle(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(PujaTypography.rounded(13, weight: .heavy))
            .foregroundStyle(PujaColors.durgaRed)
    }

    private func copyInvite() {
        UIPasteboard.general.string = "Join my Uma squad: \(env.squad.currentCode ?? "")"
        Haptics.notifySuccess()
    }

    private var createSheet: some View {
        NavigationStack {
            Form {
                TextField("Squad name", text: $newSquadName)
                    .textInputAutocapitalization(.words)
            }
            .navigationTitle("Create Squad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showCreateSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        let host = SquadMember(
                            id: "user", name: env.userState.currentUserName,
                            latitude: AppConfig.defaultLat, longitude: AppConfig.defaultLng,
                            isHost: true, isUser: true)
                        env.squad.createSquad(name: newSquadName, host: host)
                        showCreateSheet = false
                    }
                    .fontWeight(.bold)
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var joinSheet: some View {
        NavigationStack {
            Form {
                TextField("Squad code (e.g. PUJA1234)", text: $joinCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }
            .navigationTitle("Join Squad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showJoinSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Join") {
                        env.squad.joinSquad(code: joinCode.uppercased())
                        showJoinSheet = false
                    }
                    .fontWeight(.bold)
                    .disabled(joinCode.isEmpty)
                }
            }
            .presentationDetents([.medium])
        }
    }
}

private struct MemberRow: View {
    let member: SquadMember
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color(hex: UInt32(member.avatarColorHex & 0xFFFFFF)))
                    .frame(width: 40, height: 40)
                Text(member.initials)
                    .font(PujaTypography.rounded(13, weight: .heavy))
                    .foregroundStyle(.white)
                Circle()
                    .fill(member.markerState == .fresh ? Color.green :
                          member.markerState == .stale ? Color.yellow :
                          member.markerState == .offline ? Color.gray : Color.red)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(.background, lineWidth: 2))
                    .offset(x: 2, y: 2)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(PujaTypography.rounded(13, weight: .semibold))
                    if member.isHost {
                        Text("HOST")
                            .font(PujaTypography.rounded(9, weight: .heavy))
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Capsule().fill(Color.yellow.opacity(0.25)))
                            .foregroundStyle(.yellow)
                    }
                }
                Text("\(member.lastSeenText) · \(member.batteryLevel)%")
                    .font(PujaTypography.rounded(11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: { callMember() }) {
                Image(systemName: "phone.fill")
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Circle().fill(Color.green))
            }
            .buttonStyle(.plain)
            .disabled(member.phoneNumber == nil)
            .opacity(member.phoneNumber == nil ? 0.4 : 1)
        }
    }

    private func callMember() {
        guard let number = member.phoneNumber,
              let url = URL(string: "tel://\(number)") else { return }
        UIApplication.shared.open(url)
    }
}
