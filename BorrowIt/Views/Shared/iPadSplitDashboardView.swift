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
        .onChange(of: selectedSection) { oldValue, newValue in
            if newValue == .explore {
                withAnimation(settings.reduceMotionEnabled ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                    exploreVM.resetToFeed()
                }
            }
        }
        .sheet(isPresented: $exploreVM.isAddItemPresented) {
            AddItemView()
        }
        .onAppear {
            if selectedItem == nil {
                selectedItem = exploreVM.filteredItems.first ?? BorrowItem.dewaltDrill
            }
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
                // Explore Header with Add Button
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Colombo 07")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("\(exploreVM.filteredCount) items within 500m")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        exploreVM.isAddItemPresented = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)
                
                // Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    TextField("Search Colombo items...", text: $exploreVM.searchQuery)
                        .font(.system(size: 14))
                        .textFieldStyle(.plain)
                    if !exploreVM.searchQuery.isEmpty {
                        Button(action: { exploreVM.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                // Horizontal Category Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(
                            title: "All",
                            icon: "sparkles",
                            isSelected: exploreVM.selectedCategory == nil && !exploreVM.filterFreeOnly
                        ) {
                            exploreVM.selectedCategory = nil
                            exploreVM.filterFreeOnly = false
                        }
                        
                        CategoryChip(
                            title: "Free Items",
                            icon: "gift.fill",
                            isSelected: exploreVM.filterFreeOnly
                        ) {
                            exploreVM.filterFreeOnly.toggle()
                            if exploreVM.filterFreeOnly {
                                exploreVM.selectedCategory = nil
                            }
                        }
                        
                        ForEach(ItemCategory.allCases) { cat in
                            CategoryChip(
                                title: cat.rawValue,
                                icon: cat.sfSymbol,
                                isSelected: exploreVM.selectedCategory == cat
                            ) {
                                if exploreVM.selectedCategory == cat {
                                    exploreVM.selectedCategory = nil
                                } else {
                                    exploreVM.selectedCategory = cat
                                    exploreVM.filterFreeOnly = false
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                
                Divider()
                
                // Item Feed Selection List
                List(exploreVM.filteredItems, selection: $selectedItem) { item in
                    HStack(spacing: 12) {
                        ItemPhotoView(item: item, height: 48, cornerRadius: 10)
                            .frame(width: 48, height: 48)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .lineLimit(1)
                            
                            HStack(spacing: 6) {
                                if item.isFree {
                                    Text("FREE")
                                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.brandEmerald)
                                        .clipShape(Capsule())
                                } else {
                                    Text(item.formattedRate)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                }
                                
                                Text("•")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 3) {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 10))
                                    Text(item.formattedDistance)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 3)
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
                        
                        ChatThreadView(conversation: chatVM.getOrCreateConversation(with: item.lender, itemTitle: item.title))
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
