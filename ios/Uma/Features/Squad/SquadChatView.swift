// Features/Squad/SquadChatView.swift — text-only chat (v1)

import SwiftUI

struct SquadChatView: View {
    @Environment(AppEnvironment.self) private var env
    let squadId: String
    let squadName: String

    @State private var input: String = ""
    @State private var showingPhotoFilter: Bool = false
    @FocusState private var focused: Bool

    @State private var draft: [ChatMessage] = []

    var body: some View {
        VStack(spacing: 0) {
            messageList
            inputBar
        }
        .navigationTitle(squadName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingPhotoFilter.toggle() }) {
                    Image(systemName: showingPhotoFilter ? "photo.fill" : "photo")
                }
            }
        }
        .onAppear { refresh() }
        .onChange(of: env.chat.messages(for: squadId).count) { _, _ in refresh() }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(draft) { msg in
                        MessageBubble(message: msg, isMe: env.userState.currentUserName == msg.senderName)
                            .id(msg.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: draft.count) { _, _ in
                if let last = draft.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message…", text: $input, axis: .vertical)
                .focused($focused)
                .lineLimit(1...4)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle().fill(input.trimmingCharacters(in: .whitespaces).isEmpty
                                      ? PujaColors.durgaRed.opacity(0.4)
                                      : PujaColors.durgaRed)
                    )
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        env.chat.send(
            squadId: squadId,
            senderId: env.userState.currentUserName,
            senderName: env.userState.currentUserName,
            text: text)
        input = ""
        refresh()
    }

    private func refresh() {
        draft = env.chat.messages(for: squadId)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let isMe: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isMe { Spacer(minLength: 40) }
            else {
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(message.senderInitials)
                            .font(PujaTypography.rounded(10, weight: .heavy))
                            .foregroundStyle(.white)
                    )
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                if !isMe {
                    Text(message.senderName)
                        .font(PujaTypography.rounded(10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Text(message.text ?? "")
                    .font(PujaTypography.rounded(14))
                    .foregroundStyle(isMe ? .white : .primary)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isMe ? PujaColors.durgaRed : Color.primary.opacity(0.08))
                    )
                Text(formattedTime(message.timestamp))
                    .font(PujaTypography.rounded(9))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            if !isMe { Spacer(minLength: 40) }
        }
    }

    private func formattedTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }
}
