import SwiftUI

// Content View (Adaptive iPhone TabView vs iPad NavigationSplitView)
public struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var lifecycleVM: BorrowLifecycleViewModel
    @EnvironmentObject var chatVM: ChatViewModel
    
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Group {
                if !settings.hasCompletedOnboardingWalkthrough {
                    AppIntroWalkthroughView()
                } else if !authVM.isAuthenticated {
                    WelcomeOnboardingView()
                } else {
                    if horizontalSizeClass == .regular {
                        // iPadOS Adaptive NavigationSplitView
                        iPadSplitDashboardView()
                    } else {
                        iphoneTabView
                    }
                }
            }
            
            //  Privacy and Face ID Security
            if authVM.isAuthenticated && settings.faceIDLockEnabled && settings.isAppLocked {
                BiometricGateView(
                    reasonPrompt: "Welcome back, \(authVM.currentUser.name) — Unlock with Face ID to continue"
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .alert("Within 50m of Handoff Point!", isPresented: $lifecycleVM.isGeofenceAlertPresented) {
            Button("Open Handoff Pass") {
                selectedTab = 2
            }
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text("Core Location Geofence Triggered: You are within 50 metres of the agreed handoff spot for '\(lifecycleVM.activeBorrow?.item.title ?? "your item")'. Your rotating QR pass is now active!")
        }
        .onChange(of: authVM.isAuthenticated) { oldValue, newValue in
            if newValue {
                settings.isAppLocked = false
                selectedTab = 0
                withAnimation(settings.reduceMotionEnabled ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                    exploreVM.resetToFeed()
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                if authVM.isAuthenticated && settings.faceIDLockEnabled {
                    settings.isAppLocked = true
                }
            }
        }
        .onAppear {
            if authVM.isAuthenticated && settings.faceIDLockEnabled {
                settings.isAppLocked = true
            } else {
                settings.isAppLocked = false
            }
            if authVM.isAuthenticated {
                selectedTab = 0
                exploreVM.resetToFeed()
            }
        }
    }
    
    private var tabSelectionBinding: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == 0 {
                    withAnimation(settings.reduceMotionEnabled ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                        exploreVM.resetToFeed()
                    }
                }
                selectedTab = newTab
            }
        )
    }
    
    private var iphoneTabView: some View {
        TabView(selection: tabSelectionBinding) {
            // Explore Tab
            ExploreDashboardView()
                .tabItem {
                    Label("Explore", systemImage: "safari.fill")
                }
                .tag(0)
            
            // Messages Tab
            MessagesInboxView()
                .tabItem {
                    Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(1)
            
            // Handoff QR Pass Tab
            HandoffQRView()
                .tabItem {
                    Label("Handoff QR", systemImage: "qrcode.viewfinder")
                }
                .tag(2)
            
            // Borrows Tab
            BorrowsTabView()
                .tabItem {
                    Label("Borrows", systemImage: "shippingbox.fill")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
    }
}
