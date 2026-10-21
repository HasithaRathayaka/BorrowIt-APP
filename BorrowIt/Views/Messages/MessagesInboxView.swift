import SwiftUI

// MARK: - Screen 10: Messages Inbox
public struct MessagesInboxView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var settings: AppSettingsManager
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatVM.conversations) { conv in
                                NavigationLink(destination: ChatThreadView(conversation: conv)) {
                                    ConversationRow(conversation: conv)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Messages")
            .refreshable {
                await chatVM.loadConversations()
            }
        }
        .liveAccessibilityScale()
    }
}

// MARK: - Conversation Row Component
struct ConversationRow: View {
    let conversation: ChatConversation
    @EnvironmentObject var settings: AppSettingsManager
    
    var body: some View {
        HStack(spacing: 14) {
            // Lender Avatar with Unread Dot
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color(hex: conversation.participant.avatarColorHex))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(conversation.participant.initials)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
                
                if conversation.unreadCount > 0 {
                    Circle()
                        .fill(Color.brandEmerald)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.participant.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(conversation.formattedTime)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(conversation.relatedItemTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Status Badge
                    Text(conversation.status.rawValue)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: conversation.status.pillColorHex))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: conversation.status.pillBackgroundHex))
                        .clipShape(Capsule())
                }
                
                Text(conversation.lastMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .squircleCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(conversation.participant.name), item \(conversation.relatedItemTitle), status \(conversation.status.rawValue), last message: \(conversation.lastMessage)")
    }
}
