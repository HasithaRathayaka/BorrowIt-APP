import Foundation
import AppIntents

// MARK: - Interactive Widget AppIntent for Return Handoff
public struct InitiateReturnHandoffIntent: AppIntent {
    public static var title: LocalizedStringResource = "Initiate Return Handoff"
    public static var description = IntentDescription("Marks active borrowed item ready for return and activates return QR pass.")
    
    @Parameter(title: "Borrow ID")
    public var borrowId: String?
    
    public init() {
        self.borrowId = "DW20-9842"
    }
    
    public init(borrowId: String) {
        self.borrowId = borrowId
    }
    
    public func perform() async throws -> some IntentResult {
        // Update AppGroup shared defaults
        if let userDefaults = UserDefaults(suiteName: AppConfig.appGroupIdentifier) {
            userDefaults.set("return_initiated", forKey: "widget_action_status")
            userDefaults.set(Date(), forKey: "widget_return_timestamp")
        }
        
        print("[InitiateReturnHandoffIntent] Widget interactive return button triggered.")
        return .result()
    }
}
