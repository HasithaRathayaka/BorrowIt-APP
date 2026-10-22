import SwiftUI
import MapKit

// MARK: - iPadOS Adaptive 3-Column NavigationSplitView
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
    @State private var selectedItem: BorrowItem? = BorrowItem.dewaltDrill
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            // 1. Sidebar Column: Navigation & Quick Neighborhood Summary
            sidebarColumn
                .navigationTitle("BorrowIt")
        } content: {
            // 2. Content Column: Side-by-Side Map & Filtered Feed
            contentColumn
        } detail: {
            // 3. Detail Column: Inspector Layout (Item Details + Live Chat & Handoff Card)
            detailColumn
        }
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
    
    // MARK: - Content Column
    @ViewBuilder
    private var contentColumn: some View {
        switch selectedSection {
        case .explore, .none:
            VStack(spacing: 0) {
                // Mini Explore Filter Header
                HStack {
                    Text("Cedar Grove Items")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Spacer()
                    Button(action: {
                        exploreVM.isAddItemPresented = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Item Feed Selection List
                List(exploreVM.filteredItems, selection: $selectedItem) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.systemImageName)
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: item.category.colorHex))
                            .frame(width: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                            Text("\(item.formattedRate) · \(item.formattedDistance)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
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
    
    // MARK: - Detail Column (Inspector Layout)
    @ViewBuilder
    private var detailColumn: some View {
        if let item = selectedItem {
            ScrollView {
                VStack(spacing: 20) {
                    ItemDetailView(item: item)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Embedded Chat Inspector for selected item's lender
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CHAT WITH LENDER (\(item.lender.name))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                        
                        ChatThreadView(conversation: ChatConversation.convMaya)
                            .frame(height: 380)
                            .squircleCard()
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 24)
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "square.dashed")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Select an item to view details & handoff inspector")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}
