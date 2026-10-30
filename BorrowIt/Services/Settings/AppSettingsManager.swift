import SwiftUI
import Combine

// App Settings and Live Accessibility Manager
@MainActor
public class AppSettingsManager: ObservableObject {
    // 6 Functional Rubric Toggles
    @AppStorage("settings_notifications_enabled") public var notificationsEnabled: Bool = true
    @AppStorage("settings_face_id_lock_enabled") public var faceIDLockEnabled: Bool = true
    @AppStorage("settings_voice_over_assist") public var voiceOverAssistEnabled: Bool = true
    @AppStorage("settings_dynamic_type_scale") public var dynamicTypeScale: Double = 1.0
    @AppStorage("settings_reduce_motion") public var reduceMotionEnabled: Bool = false
    @AppStorage("settings_high_contrast") public var highContrastEnabled: Bool = false
    @AppStorage("has_completed_onboarding_walkthrough") public var hasCompletedOnboardingWalkthrough: Bool = false
    
    // Live UI Security 
    @Published public var isAppLocked: Bool = false
    @Published public var simulateEmptyState: Bool = false
    @Published public var demoBannerMessage: String? = nil
    
    public init() {
        // App starts unlocked or locked if Face ID lock is enabled
        self.isAppLocked = false
    }
    
    public func lockAppWithFaceID() {
        withAnimation(reduceMotionEnabled ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
            self.isAppLocked = true
        }
    }
    
    public func unlockApp() {
        withAnimation(reduceMotionEnabled ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
            self.isAppLocked = false
        }
    }
    
    public func toggleSimulateEmptyState() {
        withAnimation(reduceMotionEnabled ? nil : .easeInOut(duration: 0.25)) {
            self.simulateEmptyState.toggle()
        }
    }
    
    public func showDemoToast(_ message: String) {
        self.demoBannerMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                if self.demoBannerMessage == message {
                    self.demoBannerMessage = nil
                }
            }
        }
    }
    
    public func resetDemoData() {
        self.dynamicTypeScale = 1.0
        self.reduceMotionEnabled = false
        self.highContrastEnabled = false
        self.notificationsEnabled = true
        self.faceIDLockEnabled = true
        self.simulateEmptyState = false
        showDemoToast("Demo data & accessibility toggles restored to defaults.")
    }
}
