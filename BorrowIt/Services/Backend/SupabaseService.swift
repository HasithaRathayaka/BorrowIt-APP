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
    
    // Auth Session State
    public private(set) var currentAccessToken: String? = nil
    public private(set) var currentUserId: UUID? = nil
    
    public init(
        baseURL: URL = AppConfig.supabaseURL,
        apiKey: String = AppConfig.supabaseAnonKey,
        session: URLSession? = nil
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        if let customSession = session {
            self.session = customSession
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15.0
            config.timeoutIntervalForResource = 30.0
            self.session = URLSession(configuration: config)
        }
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
    
    // MARK: - HTTP Helpers
    private func makeRequest(endpoint: String, method: String = "GET", body: Data? = nil) -> URLRequest? {
        guard let url = URL(string: "\(baseURL.absoluteString)\(endpoint)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15.0
        let token = currentAccessToken ?? apiKey
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }
    
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: str) { return date }
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: str) { return date }
            let standard = DateFormatter()
            standard.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let date = standard.date(from: str) { return date }
            return Date()
        }
        return decoder
    }
    
    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    // MARK: - Supabase Cloud Authentication (GoTrue REST)
    
    /// Sign Up new user with Email, Password & Metadata on Supabase Auth
    public func signUp(
        email: String,
        password: String,
        name: String,
        neighborhood: String,
        initials: String
    ) async throws -> UserProfile {
        if !isLiveConfigured {
            // Local fallback simulation if credentials are dummy
            let user = UserProfile(
                id: UUID(),
                name: name,
                email: email,
                initials: initials,
                neighborhood: neighborhood
            )
            self.localProfile = user
            return user
        }
        
        guard let url = URL(string: "\(baseURL.absoluteString)/auth/v1/signup") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "email": email,
            "password": password,
            "data": [
                "name": name,
                "neighborhood": neighborhood,
                "initials": initials
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Read Access Token if auto-confirm is on
                if let token = json["access_token"] as? String {
                    self.currentAccessToken = token
                }
                
                var userId = UUID()
                if let userDict = json["user"] as? [String: Any],
                   let idStr = userDict["id"] as? String,
                   let parsedId = UUID(uuidString: idStr) {
                    userId = parsedId
                } else if let idStr = json["id"] as? String, let parsedId = UUID(uuidString: idStr) {
                    userId = parsedId
                }
                self.currentUserId = userId
                
                let profile = UserProfile(
                    id: userId,
                    name: name,
                    email: email,
                    initials: initials,
                    neighborhood: neighborhood,
                    memberSince: "Neighbor since 2026",
                    isIdVerified: true,
                    trustScore: 95,
                    trustScoreSubtitle: "Verified Member",
                    communityRating: 5.0,
                    reviewCount: 0,
                    totalBorrows: 0,
                    totalLends: 0,
                    wasteAvoidedKg: 0.0,
                    totalMoneySaved: 0.0
                )
                self.localProfile = profile
                
                // Save profile to Supabase public.profiles table
                Task {
                    try? await self.updateUserProfile(profile)
                }
                return profile
            }
        }
        
        // Handle error message from Supabase Auth
        if let errJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let msg = (errJson["msg"] as? String) ?? (errJson["error_description"] as? String) ?? (errJson["message"] as? String) ?? "Sign up failed"
            throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        throw URLError(.cannotParseResponse)
    }
    
    /// Sign In with Email & Password on Supabase Auth
    public func signIn(email: String, password: String) async throws -> UserProfile {
        if !isLiveConfigured {
            // Local fallback simulation if credentials are dummy
            if !localProfile.email.lowercased().contains(email.lowercased()) {
                let name = email.components(separatedBy: "@").first?.capitalized ?? "Neighbor"
                self.localProfile = UserProfile(
                    id: UUID(),
                    name: name,
                    email: email,
                    initials: String(name.prefix(2)).uppercased(),
                    neighborhood: "Colombo, Sri Lanka"
                )
            }
            return localProfile
        }
        
        guard let url = URL(string: "\(baseURL.absoluteString)/auth/v1/token?grant_type=password") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["access_token"] as? String,
               let userDict = json["user"] as? [String: Any] {
                
                self.currentAccessToken = token
                let userIdStr = userDict["id"] as? String ?? ""
                let userId = UUID(uuidString: userIdStr) ?? UUID()
                self.currentUserId = userId
                
                let metadata = userDict["user_metadata"] as? [String: Any]
                let name = (metadata?["name"] as? String) ?? email.components(separatedBy: "@").first?.capitalized ?? "Neighbor"
                let neighborhood = (metadata?["neighborhood"] as? String) ?? "Cedar Grove"
                let initials = (metadata?["initials"] as? String) ?? String(name.prefix(2)).uppercased()
                
                let profile = UserProfile(
                    id: userId,
                    name: name,
                    email: email,
                    initials: initials,
                    neighborhood: neighborhood,
                    memberSince: "Neighbor since 2026",
                    isIdVerified: true,
                    trustScore: 94,
                    trustScoreSubtitle: "Verified Member",
                    communityRating: 5.0
                )
                self.localProfile = profile
                
                // Also fetch cloud profile if available
                if let cloudProfile = try? await self.fetchUserProfile() {
                    self.localProfile = cloudProfile
                    return cloudProfile
                }
                return profile
            }
        }
        
        if let errJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let msg = (errJson["error_description"] as? String) ?? (errJson["msg"] as? String) ?? (errJson["message"] as? String) ?? "Invalid credentials"
            throw NSError(domain: "SupabaseAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        throw URLError(.userAuthenticationRequired)
    }
    
    /// Sign out from Supabase Auth
    public func signOut() async {
        if isLiveConfigured, let token = currentAccessToken {
            if var request = makeRequest(endpoint: "/auth/v1/logout", method: "POST") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                _ = try? await session.data(for: request)
            }
        }
        self.currentAccessToken = nil
        self.currentUserId = nil
    }
    
    // MARK: - Items REST / Seed
    public func fetchItems() async throws -> [BorrowItem] {
        if isLiveConfigured {
            if let request = makeRequest(endpoint: "/rest/v1/items?select=*&order=createdAt.desc") {
                do {
                    let (data, response) = try await session.data(for: request)
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        let decoded = try jsonDecoder.decode([BorrowItem].self, from: data)
                        if !decoded.isEmpty {
                            // Merge cloud items with any local items not yet in cloud
                            var merged = decoded
                            for localItem in self.localItems {
                                if !merged.contains(where: { $0.id == localItem.id }) {
                                    merged.insert(localItem, at: 0)
                                }
                            }
                            self.localItems = merged
                            return merged
                        } else {
                            // Cloud items table is empty: auto-seed Cedar Grove items into Supabase
                            Task {
                                for item in BorrowItem.allSeedItems {
                                    _ = try? await self.addItem(item)
                                }
                            }
                        }
                    }
                } catch {
                    print("Supabase live fetch failed, using local seed dataset: \(error)")
                }
            }
        }
        return localItems
    }
    
    public func fetchItem(id: UUID) async throws -> BorrowItem? {
        if isLiveConfigured {
            if let request = makeRequest(endpoint: "/rest/v1/items?id=eq.\(id.uuidString)&select=*") {
                if let (data, response) = try? await session.data(for: request),
                   let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    if let items = try? jsonDecoder.decode([BorrowItem].self, from: data), let first = items.first {
                        return first
                    }
                }
            }
        }
        return localItems.first(where: { $0.id == id })
    }
    
    public func addItem(_ item: BorrowItem) async throws -> BorrowItem {
        if let idx = localItems.firstIndex(where: { $0.id == item.id }) {
            localItems[idx] = item
        } else {
            localItems.insert(item, at: 0)
        }
        
        if isLiveConfigured {
            do {
                let body = try jsonEncoder.encode(item)
                guard var request = makeRequest(endpoint: "/rest/v1/items", method: "POST", body: body) else {
                    return item
                }
                request.addValue("return=representation", forHTTPHeaderField: "Prefer")
                
                let (data, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        if let decodedList = try? jsonDecoder.decode([BorrowItem].self, from: data), let saved = decodedList.first {
                            if let idx = localItems.firstIndex(where: { $0.id == item.id }) {
                                localItems[idx] = saved
                            }
                            print("Item recorded in Supabase database: \(saved.id)")
                            return saved
                        }
                    } else {
                        let errStr = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
                        print("Supabase addItem error (\(httpResponse.statusCode)): \(errStr)")
                    }
                }
            } catch {
                print("Supabase addItem request failed: \(error)")
            }
        }
        return item
    }
    
    public func deleteItem(id: UUID) async throws {
        localItems.removeAll(where: { $0.id == id })
        if isLiveConfigured {
            if let request = makeRequest(endpoint: "/rest/v1/items?id=eq.\(id.uuidString)", method: "DELETE") {
                _ = try? await session.data(for: request)
            }
        }
    }
    
    public func toggleFavorite(itemId: UUID) async throws -> Bool {
        if let idx = localItems.firstIndex(where: { $0.id == itemId }) {
            localItems[idx].isFavorite.toggle()
            let newVal = localItems[idx].isFavorite
            
            if isLiveConfigured {
                let payload = ["isFavorite": newVal]
                if let body = try? JSONSerialization.data(withJSONObject: payload),
                   let request = makeRequest(endpoint: "/rest/v1/items?id=eq.\(itemId.uuidString)", method: "PATCH", body: body) {
                    _ = try? await session.data(for: request)
                }
            }
            return newVal
        }
        return false
    }
    
    // MARK: - Borrows Lifecycle REST / Seed
    public func fetchBorrows() async throws -> [BorrowTransaction] {
        if isLiveConfigured {
            if let request = makeRequest(endpoint: "/rest/v1/borrows?select=*&order=createdAt.desc") {
                if let (data, response) = try? await session.data(for: request),
                   let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    if let decoded = try? jsonDecoder.decode([BorrowTransaction].self, from: data), !decoded.isEmpty {
                        self.localBorrows = decoded
                        return decoded
                    }
                }
            }
        }
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
        
        if isLiveConfigured {
            if let body = try? jsonEncoder.encode(transaction),
               var request = makeRequest(endpoint: "/rest/v1/borrows", method: "POST", body: body) {
                request.addValue("return=representation", forHTTPHeaderField: "Prefer")
                _ = try? await session.data(for: request)
            }
            _ = try? await sendMessage(initialMsg)
        }
        
        return transaction
    }
    
    public func updateBorrowState(id: UUID, state: BorrowState) async throws -> BorrowTransaction {
        guard let index = localBorrows.firstIndex(where: { $0.id == id }) else {
            throw BorrowStateError.invalidTransition(from: .pending, to: state)
        }
        try localBorrows[index].transition(to: state)
        
        if state == .returned {
            localProfile.totalBorrows += 1
            localProfile.wasteAvoidedKg += 3.5
            localProfile.totalMoneySaved += localBorrows[index].item.dailyRate * Double(localBorrows[index].totalDays)
            let updated = localProfile
            Task {
                try? await self.updateUserProfile(updated)
            }
        }
        
        if isLiveConfigured {
            let payload: [String: Any] = [
                "state": state.rawValue,
                "returnedAt": state == .returned ? ISO8601DateFormatter().string(from: Date()) : NSNull()
            ]
            if let body = try? JSONSerialization.data(withJSONObject: payload),
               let request = makeRequest(endpoint: "/rest/v1/borrows?id=eq.\(id.uuidString)", method: "PATCH", body: body) {
                _ = try? await session.data(for: request)
            }
        }
        
        return localBorrows[index]
    }
    
    public func submitReview(borrowId: UUID, rating: Int, comment: String) async throws {
        if let index = localBorrows.firstIndex(where: { $0.id == borrowId }) {
            localBorrows[index].reviewRating = rating
            localBorrows[index].reviewComment = comment
            
            if isLiveConfigured {
                let payload: [String: Any] = [
                    "reviewRating": rating,
                    "reviewComment": comment
                ]
                if let body = try? JSONSerialization.data(withJSONObject: payload),
                   let request = makeRequest(endpoint: "/rest/v1/borrows?id=eq.\(borrowId.uuidString)", method: "PATCH", body: body) {
                    _ = try? await session.data(for: request)
                }
            }
            
            // If the current user is the lender being reviewed, update their profile rating and review count
            if localBorrows[index].lenderId == localProfile.id {
                let currentCount = localProfile.reviewCount
                let newRating = ((localProfile.communityRating * Double(currentCount)) + Double(rating)) / Double(currentCount + 1)
                localProfile.communityRating = (newRating * 10).rounded() / 10
                localProfile.reviewCount += 1
                let updated = localProfile
                Task {
                    try? await self.updateUserProfile(updated)
                }
            }
        }
    }
    
    public func updateHandoffToken(borrowId: UUID, token: String, expiresAt: Date) async throws {
        if let idx = localBorrows.firstIndex(where: { $0.id == borrowId }) {
            localBorrows[idx].handoffToken = token
            localBorrows[idx].handoffTokenExpiresAt = expiresAt
        }
        
        if isLiveConfigured {
            let payload: [String: Any] = [
                "handoffToken": token,
                "handoffTokenExpiresAt": ISO8601DateFormatter().string(from: expiresAt)
            ]
            if let body = try? JSONSerialization.data(withJSONObject: payload),
               let request = makeRequest(endpoint: "/rest/v1/borrows?id=eq.\(borrowId.uuidString)", method: "PATCH", body: body) {
                _ = try? await session.data(for: request)
            }
        }
    }
    
    // MARK: - Realtime Chat REST / Seed
    public func fetchConversations() async throws -> [ChatConversation] {
        if isLiveConfigured {
            if let request = makeRequest(endpoint: "/rest/v1/conversations?select=*&order=lastMessageTime.desc") {
                if let (data, response) = try? await session.data(for: request),
                   let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    if let decoded = try? jsonDecoder.decode([ChatConversation].self, from: data), !decoded.isEmpty {
                        self.localConversations = decoded
                        return decoded
                    }
                }
            }
        }
        return localConversations
    }
    
    public func fetchMessages(conversationId: UUID) async throws -> [ChatMessage] {
        if isLiveConfigured {
            if let request = makeRequest(endpoint: "/rest/v1/messages?conversationId=eq.\(conversationId.uuidString)&select=*&order=timestamp.asc") {
                if let (data, response) = try? await session.data(for: request),
                   let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    if let decoded = try? jsonDecoder.decode([ChatMessage].self, from: data) {
                        self.localMessages[conversationId] = decoded
                        return decoded
                    }
                }
            }
        }
        return localMessages[conversationId] ?? []
    }
    
    public func sendMessage(_ message: ChatMessage) async throws -> ChatMessage {
        var list = localMessages[message.conversationId] ?? []
        list.append(message)
        localMessages[message.conversationId] = list
        
        if let idx = localConversations.firstIndex(where: { $0.id == message.conversationId }) {
            localConversations[idx].lastMessage = message.content
            localConversations[idx].lastMessageTime = message.timestamp
        }
        
        if isLiveConfigured {
            if let body = try? jsonEncoder.encode(message),
               var request = makeRequest(endpoint: "/rest/v1/messages", method: "POST", body: body) {
                request.addValue("return=representation", forHTTPHeaderField: "Prefer")
                _ = try? await session.data(for: request)
            }
        }
        
        return message
    }
    
    // MARK: - User Profile & Stats
    public func fetchUserProfile() async throws -> UserProfile {
        if isLiveConfigured, let userId = currentUserId {
            if let request = makeRequest(endpoint: "/rest/v1/profiles?id=eq.\(userId.uuidString)&select=*") {
                if let (data, response) = try? await session.data(for: request),
                   let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    if let profiles = try? jsonDecoder.decode([UserProfile].self, from: data), let first = profiles.first {
                        self.localProfile = first
                        return first
                    }
                }
            }
        }
        return localProfile
    }
    
    public func updateUserProfile(_ profile: UserProfile) async throws {
        self.localProfile = profile
        
        if isLiveConfigured {
            do {
                let body = try jsonEncoder.encode(profile)
                guard var request = makeRequest(endpoint: "/rest/v1/profiles", method: "POST", body: body) else {
                    return
                }
                request.addValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
                request.addValue("return=representation", forHTTPHeaderField: "Prefer")
                
                let (data, response) = try await session.data(for: request)
                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 200 || http.statusCode == 201 {
                        if let decodedList = try? jsonDecoder.decode([UserProfile].self, from: data), let saved = decodedList.first {
                            self.localProfile = saved
                            print("User profile synchronized in Supabase database: \(saved.name) (\(saved.id))")
                        }
                    } else {
                        let errStr = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                        print("Supabase updateUserProfile error (\(http.statusCode)): \(errStr)")
                    }
                }
            } catch {
                print("Supabase updateUserProfile failed: \(error)")
            }
        }
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
    public func deleteItem(id: UUID) async throws {
        items.removeAll(where: { $0.id == id })
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
    public func updateHandoffToken(borrowId: UUID, token: String, expiresAt: Date) async throws {
        if let idx = borrows.firstIndex(where: { $0.id == borrowId }) {
            borrows[idx].handoffToken = token
            borrows[idx].handoffTokenExpiresAt = expiresAt
        }
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
