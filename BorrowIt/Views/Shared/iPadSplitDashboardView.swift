import SwiftUI

// MARK: - iPadOS Adaptive 2-Column NavigationSplitView
public enum iPadNavigationSection: String, CaseIterable, Identifiable {
    case explore = "Explore"
    case messages = "Messages"
    case handoff = "Handoff Pass"
    case borrows = "Your Borrows"
    case settings = "Settings"
    case profile = "Profile & Stats"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .explore: return "safari.fill"
        case .messages: return "bubble.left.and.bubble.right.fill"
        case .handoff: return "qrcode.viewfinder"
        case .borrows: return "shippingbox.fill"
        case .settings: return "gearshape.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

public struct iPadSplitDashboardView: View {
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var lifecycleVM: BorrowLifecycleViewModel
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var selectedSection: iPadNavigationSection? = .explore
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 1. Sidebar Column: Navigation & Quick Neighborhood Summary
            sidebarColumn
                .navigationTitle("BorrowIt")
        } detail: {
            // 2. Full-Width Detail Area for the Selected Section
            NavigationStack {
                detailContent
            }
        }
        .navigationSplitViewStyle(.balanced)
        .liveAccessibilityScale()
    }
    
    // MARK: - Sidebar Column
    private var sidebarColumn: some View {
        List(selection: $selectedSection) {
            Section("Neighborhood") {
                ForEach([iPadNavigationSection.explore, .messages, .handoff, .borrows]) { sec in
                    NavigationLink(value: sec) {
                        Label(sec.rawValue, systemImage: sec.icon)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                }
            }
            
            Section("Account") {
                ForEach([iPadNavigationSection.profile, .settings]) { sec in
                    NavigationLink(value: sec) {
                        Label(sec.rawValue, systemImage: sec.icon)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                }
            }
            
            Section("Quick Community Stats") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Trust Score")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("94 / 100")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    }
                    HStack {
                        Text("Money Saved")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Rs. 45,000")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    HStack {
                        Text("Waste Avoided")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("42 kg")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.sidebar)
    }
    
    // MARK: - Detail Content for Selected Section
    @ViewBuilder
    private var detailContent: some View {
        switch selectedSection {
        case .explore, .none:
            ExploreDashboardView()
        case .messages:
            MessagesInboxView()
        case .handoff:
            HandoffQRView()
        case .borrows:
            BorrowsTabView()
        case .settings:
            SettingsView()
        case .profile:
            ProfileStatsView(profile: authVM.currentUser)
        }
    }
}
