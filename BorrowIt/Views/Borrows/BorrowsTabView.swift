import SwiftUI

// MARK: - Screen 13: Your Borrows & My Listed Items Activity Hub
@MainActor
public struct BorrowsTabView: View {
    @EnvironmentObject var lifecycleVM: BorrowLifecycleViewModel
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @EnvironmentObject var liveActivityManager: LiveActivityManager
    
    @State private var selectedSegment: Int = 0 // 0 = Borrowing, 1 = My Listings
    @State private var isAddItemPresented: Bool = false
    @State private var selectedItemForDetail: BorrowItem? = nil
    @State private var itemToEdit: BorrowItem? = nil
    @State private var itemToDelete: BorrowItem? = nil
    @State private var showDeleteAlert: Bool = false
    
    public init() {}
    
    private var activeCount: Int {
        lifecycleVM.borrows.filter { $0.state != .returned && $0.state != .cancelled }.count
    }
    
    private var completedCount: Int {
        lifecycleVM.borrows.filter { $0.state == .returned }.count
    }
    
    private var myListedItems: [BorrowItem] {
        exploreVM.myListedItems(for: authVM.currentUser)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented Activity Selector
                    Picker("Activity Hub", selection: $selectedSegment) {
                        Text("Borrowing (\(activeCount))").tag(0)
                        Text("My Listings (\(myListedItems.count))").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    
                    ScrollView {
                        if selectedSegment == 0 {
                            borrowingView
                        } else {
                            myListingsView
                        }
                    }
                    .refreshable {
                        await exploreVM.fetchItems()
                        await lifecycleVM.loadBorrows()
                    }
                }
            }
            .navigationTitle(selectedSegment == 0 ? "Your Borrows" : "My Listed Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if selectedSegment == 1 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isAddItemPresented = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Item")
                            }
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        }
                    }
                }
            }
            .sheet(isPresented: $lifecycleVM.isReturnReviewPresented) {
                ReturnReviewView()
            }
            .sheet(isPresented: $isAddItemPresented) {
                AddItemView()
            }
            .sheet(item: $itemToEdit) { item in
                AddItemView(editingItem: item)
            }
            .navigationDestination(item: $selectedItemForDetail) { item in
                ItemDetailView(item: item)
            }
            .alert("Remove Listing", isPresented: $showDeleteAlert, presenting: itemToDelete) { item in
                Button("Delete", role: .destructive) {
                    exploreVM.deleteItem(item)
                }
                Button("Cancel", role: .cancel) {}
            } message: { item in
                Text("Are you sure you want to remove '\(item.title)' from your listed items? It will no longer be visible to neighbors.")
            }
        }
        .liveAccessibilityScale()
    }
    
    // MARK: - Borrowing View
    private var borrowingView: some View {
        VStack(spacing: 20) {
            // Subtitle Stats
            HStack {
                Text("\(activeCount) active · \(completedCount + 11) completed")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            
            // Active Borrow Card
            if let active = lifecycleVM.activeBorrow, active.state != .returned {
                activeBorrowCard(active)
                    .padding(.horizontal, 20)
            }
            
            // 3. Pixel-Accurate Live Activity Card (ActivityKit Dynamic Island & Lock Screen Preview)
            liveActivityPreviewCard
                .padding(.horizontal, 20)
            
            // 4. Past Borrows Section
            pastBorrowsSection
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - My Listed Items Dashboard View
    private var myListingsView: some View {
        VStack(spacing: 20) {
            // 1. Lender Overview Hero Card
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            Text("LENDER DASHBOARD")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        Text("Your Neighborhood Inventory")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Button(action: {
                        isAddItemPresented = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("List Item")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        .clipShape(Capsule())
                    }
                }
                
                Divider()
                
                // 3 Metrics Columns
                HStack(spacing: 0) {
                    VStack(spacing: 2) {
                        Text("\(myListedItems.count)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Total Listed")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider().frame(height: 28)
                    
                    VStack(spacing: 2) {
                        Text("\(myListedItems.filter { $0.isAvailable }.count)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        Text("Available Now")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider().frame(height: 28)
                    
                    VStack(spacing: 2) {
                        Text("\(authVM.currentUser.totalLends)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        Text("Total Lends")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .squircleCard()
            .padding(.horizontal, 20)
            .padding(.top, 4)
            
            // 2. Items List or Empty State
            if myListedItems.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.brandEmerald.opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: "shippingbox.and.arrow.backward")
                            .font(.system(size: 32))
                            .foregroundColor(Color.brandEmerald)
                    }
                    
                    VStack(spacing: 6) {
                        Text("No gear listed yet")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Have drills, ladders, camping tents, or kitchen gadgets sitting idle? List them to earn neighbor trust points and help reduce waste.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    Button(action: {
                        isAddItemPresented = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("List Your First Item")
                        }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .squircleCard()
                .padding(.horizontal, 20)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("YOUR LISTINGS (\(myListedItems.count))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    ForEach(myListedItems) { item in
                        myListedItemCard(item)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Individual Listed Item Card
    private func myListedItemCard(_ item: BorrowItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Photo Thumbnail with ItemPhotoView
                ItemPhotoView(item: item, height: 76, cornerRadius: 14)
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        // Category Pill
                        Text(item.category.rawValue)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: item.category.colorHex))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color(hex: item.category.colorHex).opacity(0.12))
                            .clipShape(Capsule())
                        
                        // Core ML Tag Pill
                        HStack(spacing: 3) {
                            Image(systemName: "cpu")
                                .font(.system(size: 9))
                            Text(item.coreMLTag)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 8) {
                        Text(item.isFree ? "Free Community Lend" : "Rs. \(Int(item.dailyRate))/day")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(item.isFree ? ThemeColors.emerald(highContrast: settings.highContrastEnabled) : .primary)
                        
                        Text("·  Rs. \(Int(item.depositHold)) hold")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Bottom Action Strip: Status & Actions
            HStack {
                // Availability Status Indicator
                HStack(spacing: 5) {
                    Circle()
                        .fill(item.isAvailable ? Color.brandEmerald : Color.orange)
                        .frame(width: 7, height: 7)
                    Text(item.isAvailable ? "Available" : "Paused")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(item.isAvailable ? ThemeColors.emerald(highContrast: settings.highContrastEnabled) : .orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((item.isAvailable ? Color.brandEmerald : Color.orange).opacity(0.12))
                .clipShape(Capsule())
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Preview Button
                    Button(action: {
                        selectedItemForDetail = item
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 11))
                            Text("Preview")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.softMintTint)
                        .clipShape(Capsule())
                    }
                    
                    // Edit Button
                    Button(action: {
                        itemToEdit = item
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Edit")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(Capsule())
                    }
                    
                    // Pause / Resume Toggle Button
                    Button(action: {
                        exploreVM.toggleItemAvailability(for: item)
                    }) {
                        Image(systemName: item.isAvailable ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    
                    // Delete Button
                    Button(action: {
                        itemToDelete = item
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 15))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
        }
        .padding(14)
        .squircleCard()
    }
    
    // MARK: - Active Borrow Card
    private func activeBorrowCard(_ borrow: BorrowTransaction) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: borrow.item.category.colorHex).opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: borrow.item.systemImageName)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: borrow.item.category.colorHex))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(borrow.item.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("From \(borrow.lenderName) · ★ \(String(format: "%.1f", borrow.item.rating))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                BorrowStatusPill(state: borrow.state)
            }
            
            // Circular Gauge / Time Remaining Row
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 4)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0.0, to: 0.65)
                        .stroke(ThemeColors.emerald(highContrast: settings.highContrastEnabled), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 44, height: 44)
                    Text("2h")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Return to Maya by 5:00 PM")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("2 hours remaining · $40 deposit hold active")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 4-Segment Progress Bar
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(1...4, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(step <= borrow.state.timelineStepIndex ? ThemeColors.emerald(highContrast: settings.highContrastEnabled) : Color.secondary.opacity(0.18))
                            .frame(height: 6)
                    }
                }
                
                HStack {
                    Text("Requested")
                    Spacer()
                    Text("Accepted")
                    Spacer()
                    Text("Picked up")
                    Spacer()
                    Text("Returned")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            }
            
            // Return Action Button
            Button(action: {
                lifecycleVM.advanceToReturned()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                    Text("Start Return Handoff")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(18)
        .squircleCard()
    }
    
    // MARK: - Pixel-Accurate Live Activity Card
    private var liveActivityPreviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(Color.brandEmerald)
                        .font(.system(size: 13))
                    Text("ACTIVITYKIT · LIVE ACTIVITY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.brandEmerald)
                        .frame(width: 6, height: 6)
                    Text("Active Lock Screen")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.brandEmerald)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.brandEmerald.opacity(0.2))
                .clipShape(Capsule())
            }
            
            // Live Activity Widget Preview Box
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("RETURN TO MAYA BY 5:00 PM")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color.brandEmerald)
                        Text("DeWalt 20V Cordless Drill")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("2h left")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.brandEmerald)
                            .frame(width: geo.size.width * 0.65, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(18)
        .background(Color.darkNavyPass)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 12, y: 5)
    }
    
    // MARK: - Past Borrows History
    private var pastBorrowsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMPLETED BORROWS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
            
            // Sample Returned Item (Camp Chairs)
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "chair.lounge.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Folding Camp Chairs (Pair)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Returned to Jon L. · 5-Star Review Given")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                BorrowStatusPill(state: .returned)
            }
            .padding(14)
            .squircleCard()
        }
    }
}
