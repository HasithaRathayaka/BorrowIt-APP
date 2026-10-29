import Foundation

// MARK: - Borrow State Machine
public enum BorrowState: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case handoff = "handoff"
    case borrowed = "borrowed"
    case returned = "returned"
    case cancelled = "cancelled"
    
    public var displayTitle: String {
        switch self {
        case .pending: return "Pending Approval"
        case .approved: return "Approved"
        case .handoff: return "Ready for Handoff"
        case .borrowed: return "In Your Care"
        case .returned: return "Returned & Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    public var shortBadge: String {
        switch self {
        case .pending: return "PENDING"
        case .approved: return "ACCEPTED"
        case .handoff: return "HANDOFF"
        case .borrowed: return "ACTIVE"
        case .returned: return "RETURNED"
        case .cancelled: return "CANCELLED"
        }
    }
    
    public var timelineStepIndex: Int {
        switch self {
        case .pending: return 1
        case .approved: return 2
        case .handoff: return 2
        case .borrowed: return 3
        case .returned: return 4
        case .cancelled: return 0
        }
    }
    
    public var pillColorHex: String {
        switch self {
        case .pending: return "#F59E0B"  // Amber
        case .approved: return "#3B82F6" // Royal Blue
        case .handoff: return "#10B981"  // Emerald
        case .borrowed: return "#10B981" // Emerald
        case .returned: return "#64748B" // Slate
        case .cancelled: return "#EF4444" // Red
        }
    }
    
    public var pillBackgroundHex: String {
        switch self {
        case .pending: return "#FEF3C7"
        case .approved: return "#DBEAFE"
        case .handoff: return "#D1FAE5"
        case .borrowed: return "#D1FAE5"
        case .returned: return "#F1F5F9"
        case .cancelled: return "#FEE2E2"
        }
    }
}

// MARK: - State Machine Errors
public enum BorrowStateError: LocalizedError, Equatable {
    case invalidTransition(from: BorrowState, to: BorrowState)
    case tokenExpired
    case invalidTokenSignature
    case depositHoldRequired
    case geofenceNotEntered
    
    public var errorDescription: String? {
        switch self {
        case .invalidTransition(let from, let to):
            return "Cannot transition borrow lifecycle from '\(from.rawValue)' to '\(to.rawValue)'."
        case .tokenExpired:
            return "The rotating handoff QR token has expired. Please refresh your pass."
        case .invalidTokenSignature:
            return "QR Code cryptographic signature verification failed."
        case .depositHoldRequired:
            return "A refundable deposit hold is required to advance this borrow."
        case .geofenceNotEntered:
            return "Must be within 50m of the lender's handoff coordinates to open handoff."
        }
    }
}

// MARK: - Borrow Transaction Model
public struct BorrowTransaction: Identifiable, Codable, Hashable {
    public var id: UUID
    public var item: BorrowItem
    public var borrowerId: UUID
    public var borrowerName: String
    public var lenderId: UUID
    public var lenderName: String
    public var startDate: Date
    public var endDate: Date
    public var totalDays: Int
    public var dailyRate: Double
    public var totalRentalCost: Double
    public var depositHoldAmount: Double
    public var state: BorrowState
    public var handoffToken: String
    public var handoffTokenExpiresAt: Date
    public var calendarEventAdded: Bool
    public var pickedUpAt: Date?
    public var returnedAt: Date?
    public var reviewRating: Int?
    public var reviewComment: String?
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        item: BorrowItem,
        borrowerId: UUID = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
        borrowerName: String = "You",
        lenderId: UUID? = nil,
        lenderName: String? = nil,
        startDate: Date = Date(),
        endDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
        state: BorrowState = .pending,
        handoffToken: String = UUID().uuidString.prefix(8).uppercased(),
        handoffTokenExpiresAt: Date = Date().addingTimeInterval(300),
        calendarEventAdded: Bool = true,
        pickedUpAt: Date? = nil,
        returnedAt: Date? = nil,
        reviewRating: Int? = nil,
        reviewComment: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.item = item
        self.borrowerId = borrowerId
        self.borrowerName = borrowerName
        self.lenderId = lenderId ?? item.lender.id
        self.lenderName = lenderName ?? item.lender.name
        self.startDate = startDate
        self.endDate = endDate
        
        let days = max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
        self.totalDays = days
        self.dailyRate = item.dailyRate
        self.totalRentalCost = Double(days) * item.dailyRate
        self.depositHoldAmount = item.isFree ? 0.0 : item.depositHold
        self.state = state
        self.handoffToken = handoffToken
        self.handoffTokenExpiresAt = handoffTokenExpiresAt
        self.calendarEventAdded = calendarEventAdded
        self.pickedUpAt = pickedUpAt
        self.returnedAt = returnedAt
        self.reviewRating = reviewRating
        self.reviewComment = reviewComment
        self.createdAt = createdAt
    }
    
    // MARK: - State Validation & Transition
    public static func canTransition(from current: BorrowState, to target: BorrowState) -> Bool {
        switch current {
        case .pending:
            return target == .approved || target == .cancelled
        case .approved:
            return target == .handoff || target == .cancelled
        case .handoff:
            return target == .borrowed || target == .approved || target == .cancelled
        case .borrowed:
            return target == .returned
        case .returned:
            return false
        case .cancelled:
            return false
        }
    }
    
    public mutating func transition(to newState: BorrowState) throws {
        guard Self.canTransition(from: self.state, to: newState) else {
            throw BorrowStateError.invalidTransition(from: self.state, to: newState)
        }
        self.state = newState
        if newState == .borrowed {
            self.pickedUpAt = Date()
        } else if newState == .returned {
            self.returnedAt = Date()
        }
    }
    
    // Static calculation helper
    public static func calculateCost(days: Int, rate: Double, deposit: Double) -> (rentalCost: Double, depositHold: Double, grandTotal: Double) {
        let rental = Double(max(1, days)) * rate
        let total = rental + deposit
        return (rentalCost: rental, depositHold: deposit, grandTotal: total)
    }
    
    public var isTokenExpired: Bool {
        Date() > handoffTokenExpiresAt
    }
}

// MARK: - Seeded Sample Transactions
public extension BorrowTransaction {
    static let activeDrillBorrow = BorrowTransaction(
        id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
        item: .dewaltDrill,
        borrowerId: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
        borrowerName: "You",
        startDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
        endDate: Calendar.current.date(byAdding: .hour, value: 4, to: Date())!,
        state: .handoff,
        handoffToken: "DW20-9842"
    )
    
    static let pendingTentBorrow = BorrowTransaction(
        id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
        item: .trailTent,
        borrowerId: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
        borrowerName: "You",
        startDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
        state: .pending
    )
    
    static let returnedChairsBorrow = BorrowTransaction(
        id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
        item: .campChairs,
        borrowerId: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
        borrowerName: "You",
        startDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        state: .returned,
        pickedUpAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        returnedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        reviewRating: 5,
        reviewComment: "Dilshan was super responsive and the chairs were spotless. Saved us Rs. 5,000 from buying new ones for our weekend trip!"
    )
    
    static let allSeedTransactions: [BorrowTransaction] = [
        activeDrillBorrow,
        pendingTentBorrow,
        returnedChairsBorrow
    ]
}
