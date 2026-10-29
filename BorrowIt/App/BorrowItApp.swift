import SwiftUI

// MARK: - App Entry Point
@main
struct BorrowItApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    // Core Shared State
    @StateObject private var settingsManager = AppSettingsManager()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var exploreViewModel = ExploreViewModel()
    @StateObject private var lifecycleViewModel = BorrowLifecycleViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(settingsManager)
                .environmentObject(authViewModel)
                .environmentObject(exploreViewModel)
                .environmentObject(lifecycleViewModel)
                .environmentObject(chatViewModel)
                .environmentObject(liveActivityManager)
                .onAppear {
                    // Request notification authorization on launch
                    Task {
                        _ = await NotificationService.shared.requestAuthorization()
                    }
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                // If user is actively logged in and Face ID Lock is enabled, lock app when sent to background
                if authViewModel.isAuthenticated && settingsManager.faceIDLockEnabled {
                    settingsManager.isAppLocked = true
                }
            }
        }
    }
}
