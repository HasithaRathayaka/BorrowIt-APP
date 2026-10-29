import SwiftUI
import Combine

// MARK: - Real-Time Chat & Messages ViewModel
@MainActor
public class ChatViewModel: ObservableObject {
    @Published public var conversations: [ChatConversation] = []
    @Published public var selectedConversation: ChatConversation? = nil
    @Published public var messages: [ChatMessage] = []
    @Published public var messageText: String = ""
    @Published public var isApproving: Bool = false
    @Published public var approvalSuccessToast: String? = nil
    
    private let backendService: BackendServiceProtocol
    private let biometricService: BiometricServiceProtocol
    
    public init(
        backendService: BackendServiceProtocol = SupabaseService.shared,
        biometricService: BiometricServiceProtocol = BiometricAuthService.shared
    ) {
        self.backendService = backendService
        self.biometricService = biometricService
        Task {
            await loadConversations()
        }
    }
    
    public func loadConversations() async {
        do {
            self.conversations = try await backendService.fetchConversations()
            if selectedConversation == nil {
                selectedConversation = conversations.first
                if let first = selectedConversation {
                    await loadMessages(for: first)
                }
            }
        } catch {
            print("Failed to load conversations: \(error)")
        }
    }
    
    public func selectConversation(_ conv: ChatConversation) async {
        self.selectedConversation = conv
        await loadMessages(for: conv)
    }
    
    public func loadMessages(for conv: ChatConversation) async {
        do {
            self.messages = try await backendService.fetchMessages(conversationId: conv.id)
            if self.messages.isEmpty {
                if conv.id == ChatConversation.convMaya.id {
                    self.messages = ChatMessage.mayaThread
                } else {
                    // Seed initial inquiry greeting from lender
                    self.messages = [
                        ChatMessage(
                            conversationId: conv.id,
                            senderId: conv.participant.id,
                            senderName: conv.participant.name,
                            isFromCurrentUser: false,
                            content: "Hi neighbor! Thanks for checking out '\(conv.relatedItemTitle)'. Feel free to ask any questions about pickup or availability!",
                            timestamp: Date().addingTimeInterval(-120)
                        )
                    ]
                }
            }
        } catch {
            print("Failed to load messages: \(error)")
        }
    }
    
    public func getOrCreateConversation(with lender: LenderProfile, itemTitle: String) -> ChatConversation {
        if let existing = conversations.first(where: { $0.participant.id == lender.id && $0.relatedItemTitle == itemTitle }) {
            return existing
        }
        if let existingLender = conversations.first(where: { $0.participant.id == lender.id || $0.participant.name == lender.name }) {
            var updated = existingLender
            updated.relatedItemTitle = itemTitle
            if let idx = conversations.firstIndex(where: { $0.id == existingLender.id }) {
                conversations[idx] = updated
            }
            return updated
        }
        let newConv = ChatConversation(
            id: UUID(),
            participant: lender,
            relatedBorrowId: nil,
            relatedItemTitle: itemTitle,
            lastMessage: "Inquiry about \(itemTitle)",
            lastMessageTime: Date(),
            unreadCount: 0,
            status: .pending,
            canApproveRequest: false
        )
        conversations.insert(newConv, at: 0)
        return newConv
    }
    
    public func sendMessage() async {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let conv = selectedConversation else { return }
        
        let newMsg = ChatMessage(
            conversationId: conv.id,
            senderId: UserProfile.currentUser.id,
            senderName: UserProfile.currentUser.name,
            isFromCurrentUser: true,
            content: trimmed,
            timestamp: Date()
        )
        
        self.messages.append(newMsg)
        self.messageText = ""
        
        _ = try? await backendService.sendMessage(newMsg)
    }
    
    public func sendQuickReply(_ reply: String) async {
        self.messageText = reply
        await sendMessage()
    }
    
    // MARK: - Inline Face ID Approval by Lender
    public func approveRequestInline() async -> Bool {
        guard let conv = selectedConversation else { return false }
        isApproving = true
        let result = await biometricService.authenticate(reason: "Approve borrow request for \(conv.relatedItemTitle)")
        isApproving = false
        
        switch result {
        case .success:
            if let idx = conversations.firstIndex(where: { $0.id == conv.id }) {
                conversations[idx].canApproveRequest = false
                conversations[idx].status = .accepted
                selectedConversation?.canApproveRequest = false
                selectedConversation?.status = .accepted
            }
            
            // Post system approval message
            let systemMsg = ChatMessage(
                conversationId: conv.id,
                senderId: LenderProfile.maya.id,
                senderName: conv.participant.name,
                isFromCurrentUser: false,
                content: "✅ Request Approved! The pickup address is 148 Cedar Grove Lane.",
                timestamp: Date(),
                isSystemNotification: true
            )
            messages.append(systemMsg)
            _ = try? await backendService.sendMessage(systemMsg)
            
            self.approvalSuccessToast = "Request approved via Face ID!"
            return true
        case .failure:
            return false
        }
    }
}
