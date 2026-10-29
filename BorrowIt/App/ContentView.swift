import SwiftUI

// MARK: - Root Content View (Adaptive iPhone TabView vs iPad NavigationSplitView)
public struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var lifecycleVM: BorrowLifecycleViewModel
    @EnvironmentObject var chatVM: ChatViewModel
    
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
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
                    // iPhone 5-Tab TabView
                    iphoneTabView
                }
            }
        }
        .fullScreenCover(isPresented: $settings.isAppLocked) {
            BiometricGateView(
                reasonPrompt: "Welcome back — Sign in securely to see what your neighbors are sharing"
            )
        }
        .onChange(of: authVM.isAuthenticated) { oldValue, newValue in
            if newValue {
                // Once logged in, guarantee landing directly on Explore Dashboard in Feed mode
                selectedTab = 0
                withAnimation(settings.reduceMotionEnabled ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                    exploreVM.resetToFeed()
                }
            }
        }
        .onAppear {
            if authVM.isAuthenticated {
                selectedTab = 0
                exploreVM.resetToFeed()
            }
        }
    }
    
    // MARK: - iPhone 5-Tab Navigation Architecture
    // Intercepts tab taps: whenever the user taps the Explore tab button below (tag 0),
    // even if already on Explore or currently in Map mode, directly resets to Feed mode.
    private var tabSelectionBinding: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == 0 {
                    // Pressed the Explore button below -> directly return to Feed
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
            // 1. Explore Tab
            ExploreDashboardView()
                .tabItem {
                    Label("Explore", systemImage: "safari.fill")
                }
                .tag(0)
            
            // 2. Messages Tab
            MessagesInboxView()
                .tabItem {
                    Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(1)
            
            // 3. Handoff QR Pass Tab
            HandoffQRView()
                .tabItem {
                    Label("Handoff QR", systemImage: "qrcode.viewfinder")
                }
                .tag(2)
            
            // 4. Borrows Tab
            BorrowsTabView()
                .tabItem {
                    Label("Borrows", systemImage: "shippingbox.fill")
                }
                .tag(3)
            
            // 5. Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
    }
}
