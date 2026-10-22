import Foundation
import Combine

// MARK: - Supabase Service & Local Seed Fallback
public class SupabaseService: BackendServiceProtocol {
    public static let shared = SupabaseService()
    
    // In-Memory & Local Cache stores
    private var localItems: [BorrowItem]
    private var localBorrows: [BorrowTransaction]
    private var localConversations: [ChatConversation]
    private var localMessages: [UUID: [ChatMessage]] // conversationId -> messages
    private var localProfile: UserProfile
    
    private let session: URLSession
    private let baseURL: URL
    private let apiKey: String
    private let isLiveConfigured: Bool
    
    public init(
        baseURL: URL = AppConfig.supabaseURL,
        apiKey: String = AppConfig.supabaseAnonKey,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
        self.isLiveConfigured = AppConfig.isSupabaseConfigured
        
        // Initialize Cedar Grove Seed Dataset
        self.localItems = BorrowItem.allSeedItems
        self.localBorrows = BorrowTransaction.allSeedTransactions
        self.localConversations = ChatConversation.allSeedConversations
        self.localMessages = [
            ChatConversation.convMaya.id: ChatMessage.mayaThread
        ]
        self.localProfile = UserProfile.currentUser
    }
    
    // MARK: - Items REST / Seed
    public func fetchItems() async throws -> [BorrowItem] {
        if isLiveConfigured {
            guard let url = URL(string: "\(baseURL.absoluteString)/rest/v1/items?select=*") else {
                return localItems
            }
            var request = URLRequest(url: url)
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue(apiKey, forHTTPHeaderField: "apikey")
            
            do {
                let (data, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let decoded = try JSONDecoder().decode([BorrowItem].self, from: data)
                    if !decoded.isEmpty {
                        self.localItems = decoded
                        return decoded
                    }
                }
            } catch {
                print("Supabase live fetch failed, using local seed dataset: \(error)")
            }
        }
        return localItems
    }
    
    public func fetchItem(id: UUID) async throws -> BorrowItem? {
        return localItems.first(where: { $0.id == id })
    }
    
    public func addItem(_ item: BorrowItem) async throws -> BorrowItem {
        localItems.insert(item, at: 0)
        
        if isLiveConfigured {
            guard let url = URL(string: "\(baseURL.absoluteString)/rest/v1/items") else { return item }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue(apiKey, forHTTPHeaderField: "apikey")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(item)
            _ = try? await session.data(for: request)
        }
        
        return item
    }
    
    public func toggleFavorite(itemId: UUID) async throws -> Bool {
        if let idx = localItems.firstIndex(where: { $0.id == itemId }) {
            localItems[idx].isFavorite.toggle()
            return localItems[idx].isFavorite
        }
        return false
    }
    
    // MARK: - Borrows Lifecycle REST / Seed
    public func fetchBorrows() async throws -> [BorrowTransaction] {
        return localBorrows
    }
    
    public func fetchBorrow(id: UUID) async throws -> BorrowTransaction? {
        return localBorrows.first(where: { $0.id == id })
    }
    
    public func createBorrow(_ transaction: BorrowTransaction) async throws -> BorrowTransaction {
        localBorrows.insert(transaction, at: 0)
        
        // Also create or link a conversation with the lender
        let conv = ChatConversation(
            participant: transaction.item.lender,
            relatedBorrowId: transaction.id,
            relatedItemTitle: transaction.item.title,
            lastMessage: "Request sent for \(transaction.item.title) (\(transaction.totalDays) days)",
            lastMessageTime: Date(),
            unreadCount: 0,
            status: .accepted,
            canApproveRequest: true
        )
        localConversations.insert(conv, at: 0)
        
        let initialMsg = ChatMessage(
            conversationId: conv.id,
            senderId: transaction.borrowerId,
            senderName: transaction.borrowerName,
            isFromCurrentUser: true,
            content: "Hi \(transaction.lenderName)! I just submitted a borrow request for your \(transaction.item.title) from \(formattedDate(transaction.startDate)) to \(formattedDate(transaction.endDate)).",
            timestamp: Date()
        )
        localMessages[conv.id] = [initialMsg]
        
        return transaction
    }
    
    public func updateBorrowState(id: UUID, state: BorrowState) async throws -> BorrowTransaction {
        guard let index = localBorrows.firstIndex(where: { $0.id == id }) else {
            throw BorrowStateError.invalidTransition(from: .pending, to: state)
        }
        try localBorrows[index].transition(to: state)
        
        // If approved or returned, update user stats
        if state == .returned {
            localProfile.totalBorrows += 1
            localProfile.wasteAvoidedKg += 3.5
            localProfile.totalMoneySaved += localBorrows[index].item.dailyRate * Double(localBorrows[index].totalDays)
        }
        
        return localBorrows[index]
    }
    
    public func submitReview(borrowId: UUID, rating: Int, comment: String) async throws {
        if let index = localBorrows.firstIndex(where: { $0.id == borrowId }) {
            localBorrows[index].reviewRating = rating
            localBorrows[index].reviewComment = comment
        }
    }
    
    // MARK: - Realtime Chat REST / Seed
    public func fetchConversations() async throws -> [ChatConversation] {
        return localConversations
    }
    
    public func fetchMessages(conversationId: UUID) async throws -> [ChatMessage] {
        return localMessages[conversationId] ?? []
    }
    
    public func sendMessage(_ message: ChatMessage) async throws -> ChatMessage {
        var list = localMessages[message.conversationId] ?? []
        list.append(message)
        localMessages[message.conversationId] = list
        
        // Update conversation preview
        if let idx = localConversations.firstIndex(where: { $0.id == message.conversationId }) {
            localConversations[idx].lastMessage = message.content
            localConversations[idx].lastMessageTime = message.timestamp
        }
        
        return message
    }
    
    // MARK: - User Profile & Stats
    public func fetchUserProfile() async throws -> UserProfile {
        return localProfile
    }
    
    public func updateUserProfile(_ profile: UserProfile) async throws {
        self.localProfile = profile
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

// MARK: - MockBackendService for Swift Testing Suite
public class MockBackendService: BackendServiceProtocol {
    public var items: [BorrowItem]
    public var borrows: [BorrowTransaction]
    public var conversations: [ChatConversation]
    public var messages: [UUID: [ChatMessage]]
    public var profile: UserProfile
    
    public init(
        items: [BorrowItem] = BorrowItem.allSeedItems,
        borrows: [BorrowTransaction] = BorrowTransaction.allSeedTransactions,
        conversations: [ChatConversation] = ChatConversation.allSeedConversations,
        profile: UserProfile = UserProfile.currentUser
    ) {
        self.items = items
        self.borrows = borrows
        self.conversations = conversations
        self.messages = [:]
        self.profile = profile
    }
    
    public func fetchItems() async throws -> [BorrowItem] { items }
    public func fetchItem(id: UUID) async throws -> BorrowItem? { items.first(where: { $0.id == id }) }
    public func addItem(_ item: BorrowItem) async throws -> BorrowItem {
        items.append(item)
        return item
    }
    public func toggleFavorite(itemId: UUID) async throws -> Bool {
        if let idx = items.firstIndex(where: { $0.id == itemId }) {
            items[idx].isFavorite.toggle()
            return items[idx].isFavorite
        }
        return false
    }
    public func fetchBorrows() async throws -> [BorrowTransaction] { borrows }
    public func fetchBorrow(id: UUID) async throws -> BorrowTransaction? { borrows.first(where: { $0.id == id }) }
    public func createBorrow(_ transaction: BorrowTransaction) async throws -> BorrowTransaction {
        borrows.append(transaction)
        return transaction
    }
    public func updateBorrowState(id: UUID, state: BorrowState) async throws -> BorrowTransaction {
        guard let idx = borrows.firstIndex(where: { $0.id == id }) else {
            throw BorrowStateError.invalidTransition(from: .pending, to: state)
        }
        try borrows[idx].transition(to: state)
        return borrows[idx]
    }
    public func submitReview(borrowId: UUID, rating: Int, comment: String) async throws {
        if let idx = borrows.firstIndex(where: { $0.id == borrowId }) {
            borrows[idx].reviewRating = rating
            borrows[idx].reviewComment = comment
        }
    }
    public func fetchConversations() async throws -> [ChatConversation] { conversations }
    public func fetchMessages(conversationId: UUID) async throws -> [ChatMessage] { messages[conversationId] ?? [] }
    public func sendMessage(_ message: ChatMessage) async throws -> ChatMessage {
        var current = messages[message.conversationId] ?? []
        current.append(message)
        messages[message.conversationId] = current
        return message
    }
    public func fetchUserProfile() async throws -> UserProfile { profile }
    public func updateUserProfile(_ profile: UserProfile) async throws { self.profile = profile }
}
