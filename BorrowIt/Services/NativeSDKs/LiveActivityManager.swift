import Foundation
import ActivityKit
import Combine

// MARK: - ActivityKit Live Activity Manager
@MainActor
public class LiveActivityManager: ObservableObject {
    public static let shared = LiveActivityManager()
    
    @Published public var isLiveActivityActive: Bool = false
    @Published public var previewAttributes = BorrowActivityAttributes()
    @Published public var previewState = BorrowActivityAttributes.ContentState()
    
    private var currentActivity: Any? // Retains Activity<BorrowActivityAttributes> dynamically
    
    public init() {
        // Default initialized with active DeWalt drill preview state
        self.isLiveActivityActive = true
    }
    
    public func startLiveActivity(itemTitle: String, lenderName: String, dueTime: String) {
        let attributes = BorrowActivityAttributes(
            itemTitle: itemTitle,
            lenderName: lenderName,
            borrowId: UUID().uuidString.prefix(6).uppercased(),
            returnDueTime: dueTime
        )
        let state = BorrowActivityAttributes.ContentState(
            statusMessage: "Return to \(lenderName) by \(dueTime)",
            timeRemainingMinutes: 120,
            isOverdue: false,
            progressFraction: 0.65
        )
        
        self.previewAttributes = attributes
        self.previewState = state
        self.isLiveActivityActive = true
        
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            do {
                let activity = try Activity<BorrowActivityAttributes>.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil)
                )
                self.currentActivity = activity
                print("[LiveActivityManager] Started Live Activity: \(activity.id)")
            } catch {
                print("[LiveActivityManager] Could not request system live activity: \(error.localizedDescription)")
            }
        }
    }
    
    public func updateLiveActivity(timeRemainingMinutes: Int, fraction: Double) {
        self.previewState.timeRemainingMinutes = timeRemainingMinutes
        self.previewState.progressFraction = fraction
        
        if let activity = currentActivity as? Activity<BorrowActivityAttributes> {
            Task {
                await activity.update(ActivityContent(state: self.previewState, staleDate: nil))
            }
        }
    }
    
    public func endLiveActivity() {
        self.isLiveActivityActive = false
        if let activity = currentActivity as? Activity<BorrowActivityAttributes> {
            Task {
                await activity.end(ActivityContent(state: self.previewState, staleDate: nil), dismissalPolicy: .immediate)
                self.currentActivity = nil
            }
        }
    }
}
