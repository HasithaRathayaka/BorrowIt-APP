import Foundation
import CoreGraphics
import CoreLocation

// MARK: - Backend Service Protocol (Live Supabase & Offline Seed Mock)
public protocol BackendServiceProtocol {
    func fetchItems() async throws -> [BorrowItem]
    func fetchItem(id: UUID) async throws -> BorrowItem?
    func addItem(_ item: BorrowItem) async throws -> BorrowItem
    func updateItem(_ item: BorrowItem) async throws -> BorrowItem
    func deleteItem(id: UUID) async throws
    func toggleFavorite(itemId: UUID) async throws -> Bool
    
    func fetchBorrows() async throws -> [BorrowTransaction]
    func fetchBorrow(id: UUID) async throws -> BorrowTransaction?
    func createBorrow(_ transaction: BorrowTransaction) async throws -> BorrowTransaction
    func updateBorrowState(id: UUID, state: BorrowState) async throws -> BorrowTransaction
    func updateHandoffToken(borrowId: UUID, token: String, expiresAt: Date) async throws
    func submitReview(borrowId: UUID, rating: Int, comment: String) async throws
    
    func fetchConversations() async throws -> [ChatConversation]
    func fetchMessages(conversationId: UUID) async throws -> [ChatMessage]
    func sendMessage(_ message: ChatMessage) async throws -> ChatMessage
    
    func fetchUserProfile() async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws
}

// MARK: - Biometric Service Protocol (LocalAuthentication)
public protocol BiometricServiceProtocol {
    var isBiometricsAvailable: Bool { get }
    var biometricTypeString: String { get }
    func authenticate(reason: String) async -> Result<Bool, Error>
}

// MARK: - Vision / Core ML Image Classifier Protocol
public protocol ClassifierProtocol {
    func classify(image: CGImage) async throws -> (category: ItemCategory, confidence: Double, rawLabel: String)
    func mapLabelToCategory(_ label: String) -> ItemCategory
}

// MARK: - QR Code Service Protocol
public protocol QRServiceProtocol {
    func generateQRCodeImage(from payload: QRPayload) -> CGImage?
    func decodeQRCode(from image: CGImage) async throws -> QRPayload
    func verifyPayload(_ payload: QRPayload) -> Bool
}

// MARK: - User Notifications Protocol
public protocol NotificationServiceProtocol {
    func requestAuthorization() async -> Bool
    func scheduleLocalAlert(title: String, body: String, timeInterval: TimeInterval)
    func notifyBorrowRequested(itemTitle: String, lenderName: String)
    func notifyLenderApproved(itemTitle: String, lenderName: String)
    func notifyGeofenceEntered(itemTitle: String, lenderName: String)
    func notifyDueReminder(itemTitle: String, hoursRemaining: Int)
}

// MARK: - Geofence Service Protocol
public protocol GeofenceServiceProtocol {
    var isAuthorized: Bool { get }
    var currentCoordinate: Coordinate? { get }
    func checkDistanceTo(coordinate: Coordinate) -> Double
    func startMonitoringGeofence(target: Coordinate, radiusMeters: Double, onArrival: @escaping () -> Void)
    func simulateGeofenceArrival()
}

// MARK: - EventKit Calendar Protocol
public protocol CalendarServiceProtocol {
    func requestAccess() async -> Bool
    func addBorrowEvents(itemTitle: String, lenderName: String, startDate: Date, endDate: Date) async -> Bool
}

public extension BackendServiceProtocol {
    func deleteItem(id: UUID) async throws {}
}

