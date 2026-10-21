import SwiftUI

// MARK: - Screen 10 (Detail): Real-Time Chat Thread View
public struct ChatThreadView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var settings: AppSettingsManager
    public let conversation: ChatConversation
    
    @State private var inputText: String = ""
    
    public init(conversation: ChatConversation) {
        self.conversation = conversation
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Context Bar
                topContextBar
                
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatVM.messages) { msg in
                                ChatBubbleRow(message: msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: chatVM.messages.count) { _ in
                        if let last = chatVM.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Quick Replies Strip
                quickRepliesStrip
                
                // Bottom Input Bar
                bottomInputBar
            }
        }
        .navigationTitle(conversation.participant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Circle()
                    .fill(Color(hex: conversation.participant.avatarColorHex))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(conversation.participant.initials)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .onAppear {
            Task {
                await chatVM.selectConversation(conversation)
            }
        }
        .liveAccessibilityScale()
    }
    
    // MARK: - Top Context Bar with Status & Face ID Approval
    private var topContextBar: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.relatedItemTitle)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Cedar Grove · Handoff spot: 148 Cedar Grove Lane")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(conversation.status.rawValue)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: conversation.status.pillColorHex))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: conversation.status.pillBackgroundHex))
                    .clipShape(Capsule())
            }
            
            // Inline Face ID Lender Approval Button
            if conversation.canApproveRequest {
                Button(action: {
                    Task {
                        _ = await chatVM.approveRequestInline()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "faceid")
                        Text("Approve Request (Face ID Gate)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.primary.opacity(0.06)),
            alignment: .bottom
        )
    }
    
    // MARK: - Quick Replies Strip
    private var quickRepliesStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChatMessage.quickReplies, id: \.self) { reply in
                    Button(action: {
                        Task {
                            await chatVM.sendQuickReply(reply)
                        }
                    }) {
                        Text(reply)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Bottom Input Bar
    private var bottomInputBar: some View {
        HStack(spacing: 10) {
            TextField("Message \(conversation.participant.name)...", text: $chatVM.messageText)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            
            Button(action: {
                Task {
                    await chatVM.sendMessage()
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(
                        chatVM.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                        Color.secondary.opacity(0.4) :
                        ThemeColors.emerald(highContrast: settings.highContrastEnabled)
                    )
            }
            .disabled(chatVM.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - Chat Bubble Row Component
struct ChatBubbleRow: View {
    let message: ChatMessage
    @EnvironmentObject var settings: AppSettingsManager
    
    var body: some View {
        if message.isSystemNotification {
            // System Notification Pill
            HStack {
                Spacer()
                Text(message.content)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
                Spacer()
            }
            .padding(.vertical, 4)
        } else {
            HStack(alignment: .bottom, spacing: 8) {
                if message.isFromCurrentUser {
                    Spacer(minLength: 40)
                }
                
                VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            message.isFromCurrentUser ?
                            ThemeColors.emerald(highContrast: settings.highContrastEnabled) :
                            Color(uiColor: .secondarySystemGroupedBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    
                    Text(message.formattedTime)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
                
                if !message.isFromCurrentUser {
                    Spacer(minLength: 40)
                }
            }
        }
    }
}
