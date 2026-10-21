import Foundation
import ActivityKit

// MARK: - ActivityKit Live Activity Attributes
public struct BorrowActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var statusMessage: String
        public var timeRemainingMinutes: Int
        public var isOverdue: Bool
        public var progressFraction: Double // 0.0 to 1.0
        
        public init(
            statusMessage: String = "Return to Maya by 5:00 PM",
            timeRemainingMinutes: Int = 120,
            isOverdue: Bool = false,
            progressFraction: Double = 0.65
        ) {
            self.statusMessage = statusMessage
            self.timeRemainingMinutes = timeRemainingMinutes
            self.isOverdue = isOverdue
            self.progressFraction = progressFraction
        }
    }
    
    public var itemTitle: String
    public var lenderName: String
    public var borrowId: String
    public var returnDueTime: String
    
    public init(
        itemTitle: String = "DeWalt 20V Drill",
        lenderName: String = "Maya R.",
        borrowId: String = "DW20-9842",
        returnDueTime: String = "5:00 PM"
    ) {
        self.itemTitle = itemTitle
        self.lenderName = lenderName
        self.borrowId = borrowId
        self.returnDueTime = returnDueTime
    }
}
