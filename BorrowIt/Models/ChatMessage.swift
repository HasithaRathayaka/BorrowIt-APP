import Foundation

// MARK: - Chat Message Model
public struct ChatMessage: Identifiable, Codable, Hashable {
    public var id: UUID
    public var conversationId: UUID
    public var senderId: UUID
    public var senderName: String
    public var isFromCurrentUser: Bool
    public var content: String
    public var timestamp: Date
    public var isSystemNotification: Bool
    
    public init(
        id: UUID = UUID(),
        conversationId: UUID,
        senderId: UUID,
        senderName: String,
        isFromCurrentUser: Bool,
        content: String,
        timestamp: Date = Date(),
        isSystemNotification: Bool = false
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.isFromCurrentUser = isFromCurrentUser
        self.content = content
        self.timestamp = timestamp
        self.isSystemNotification = isSystemNotification
    }
    
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Conversation Status Badge
public enum ConversationStatus: String, Codable, CaseIterable {
    case pickupToday = "Pickup today"
    case accepted = "Accepted"
    case complete = "Complete"
    case actionNeeded = "Action needed"
    
    public var pillColorHex: String {
        switch self {
        case .pickupToday: return "#10B981" // Emerald
        case .accepted: return "#3B82F6"    // Blue
        case .complete: return "#64748B"    // Slate
        case .actionNeeded: return "#F59E0B" // Amber
        }
    }
    
    public var pillBackgroundHex: String {
        switch self {
        case .pickupToday: return "#D1FAE5"
        case .accepted: return "#DBEAFE"
        case .complete: return "#F1F5F9"
        case .actionNeeded: return "#FEF3C7"
        }
    }
}

// MARK: - Chat Conversation Model
public struct ChatConversation: Identifiable, Codable, Hashable {
    public var id: UUID
    public var participant: LenderProfile
    public var relatedBorrowId: UUID?
    public var relatedItemTitle: String
    public var lastMessage: String
    public var lastMessageTime: Date
    public var unreadCount: Int
    public var status: ConversationStatus
    public var canApproveRequest: Bool
    
    public init(
        id: UUID = UUID(),
        participant: LenderProfile,
        relatedBorrowId: UUID? = nil,
        relatedItemTitle: String,
        lastMessage: String,
        lastMessageTime: Date = Date(),
        unreadCount: Int = 0,
        status: ConversationStatus = .pickupToday,
        canApproveRequest: Bool = false
    ) {
        self.id = id
        self.participant = participant
        self.relatedBorrowId = relatedBorrowId
        self.relatedItemTitle = relatedItemTitle
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
        self.status = status
        self.canApproveRequest = canApproveRequest
    }
    
    public var formattedTime: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(lastMessageTime) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: lastMessageTime)
        } else if calendar.isDateInYesterday(lastMessageTime) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: lastMessageTime)
        }
    }
}

// MARK: - Seed Data for Messages
public extension ChatConversation {
    static let convMaya = ChatConversation(
        id: UUID(uuidString: "e1111111-1111-1111-1111-111111111111")!,
        participant: .maya,
        relatedBorrowId: BorrowTransaction.activeDrillBorrow.id,
        relatedItemTitle: "DeWalt 20V Drill",
        lastMessage: "Batteries are fully charged! Left them in the green case on the front porch.",
        lastMessageTime: Calendar.current.date(byAdding: .minute, value: -12, to: Date())!,
        unreadCount: 1,
        status: .pickupToday,
        canApproveRequest: false
    )
    
    static let convJon = ChatConversation(
        id: UUID(uuidString: "e2222222-2222-2222-2222-222222222222")!,
        participant: .jon,
        relatedBorrowId: BorrowTransaction.pendingTentBorrow.id,
        relatedItemTitle: "2-Person Trail Tent",
        lastMessage: "Hey Alex! Friday afternoon works great for handoff. Have a great hike!",
        lastMessageTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
        unreadCount: 0,
        status: .accepted,
        canApproveRequest: true
    )
    
    static let convAri = ChatConversation(
        id: UUID(uuidString: "e3333333-3333-3333-3333-333333333333")!,
        participant: .ari,
        relatedBorrowId: nil,
        relatedItemTitle: "Bosch Circular Saw",
        lastMessage: "Thanks for bringing it back in great shape! Deposit hold has been cleared.",
        lastMessageTime: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        unreadCount: 0,
        status: .complete,
        canApproveRequest: false
    )
    
    static let convSam = ChatConversation(
        id: UUID(uuidString: "e4444444-4444-4444-4444-444444444444")!,
        participant: .sam,
        relatedBorrowId: nil,
        relatedItemTitle: "Inflatable Kayak",
        lastMessage: "Could you confirm if you need the adult life vest as well?",
        lastMessageTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        unreadCount: 2,
        status: .actionNeeded,
        canApproveRequest: false
    )
    
    static let allSeedConversations: [ChatConversation] = [
        convMaya,
        convJon,
        convAri,
        convSam
    ]
}

// MARK: - Seed Messages for Threads
public extension ChatMessage {
    static let mayaThread: [ChatMessage] = [
        ChatMessage(
            conversationId: ChatConversation.convMaya.id,
            senderId: BorrowTransaction.activeDrillBorrow.borrowerId,
            senderName: "You",
            isFromCurrentUser: true,
            content: "Hi Maya! Requested your DeWalt drill for Saturday afternoon to mount some floating shelves.",
            timestamp: Calendar.current.date(byAdding: .minute, value: -45, to: Date())!
        ),
        ChatMessage(
            conversationId: ChatConversation.convMaya.id,
            senderId: LenderProfile.maya.id,
            senderName: "Maya R.",
            isFromCurrentUser: false,
            content: "Hi! That sounds good. I approved your request. I'll have it ready for pickup around 2 PM.",
            timestamp: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!
        ),
        ChatMessage(
            conversationId: ChatConversation.convMaya.id,
            senderId: BorrowTransaction.activeDrillBorrow.borrowerId,
            senderName: "You",
            isFromCurrentUser: true,
            content: "Awesome, heading over now with my QR handoff pass!",
            timestamp: Calendar.current.date(byAdding: .minute, value: -18, to: Date())!
        ),
        ChatMessage(
            conversationId: ChatConversation.convMaya.id,
            senderId: LenderProfile.maya.id,
            senderName: "Maya R.",
            isFromCurrentUser: false,
            content: "Batteries are fully charged! Left them in the green case on the front porch.",
            timestamp: Calendar.current.date(byAdding: .minute, value: -12, to: Date())!
        )
    ]
    
    static let quickReplies: [String] = [
        "I'm outside for handoff!",
        "On my way with the QR pass",
        "Thanks, returning at 5 PM",
        "Could I extend by 1 more day?"
    ]
}
