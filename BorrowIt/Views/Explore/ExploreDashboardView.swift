import SwiftUI
import MapKit

// MARK: - Screens 3 & 4: Explore Dashboard (Feed & Map Toggle)
public struct ExploreDashboardView: View {
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @ObservedObject private var locationService = LocationGeofenceService.shared
    
    // Map position centered on Colombo 07 (Cinnamon Gardens)
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: AppConfig.cedarGroveCenter.clCoordinate,
            latitudinalMeters: 1400,
            longitudinalMeters: 1400
        )
    )
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top App Header
                    exploreHeaderView
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 12)
                    
                    // Search Bar & Filter Button
                    searchAndFilterBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    
                    // Category Filter Chips
                    categoryChipsScrollView
                        .padding(.bottom, 12)
                    
                    // Body: Empty State OR Feed List OR Map View
                    if settings.simulateEmptyState || exploreVM.filteredItems.isEmpty {
                        EmptyExploreStateView()
                    } else if exploreVM.isFeedMode {
                        feedListView
                    } else {
                        mapModeView
                    }
                }
            }
            .sheet(isPresented: $exploreVM.isFilterSheetPresented) {
                FilterSheetView()
            }
            .sheet(isPresented: $exploreVM.isAddItemPresented) {
                AddItemView()
            }
            .navigationDestination(item: $exploreVM.selectedItemForDetail) { item in
                ItemDetailView(item: item)
            }
            .onAppear {
                locationService.requestPermissions()
            }
        }
        .liveAccessibilityScale()
    }
    
    // MARK: - Header
    private var exploreHeaderView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Nearby to borrow")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    Text("Colombo 07 · within \(Int(exploreVM.searchRadiusMeters))m")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Mode Toggle (Feed vs Map)
            HStack(spacing: 6) {
                Button(action: {
                    withAnimation(settings.reduceMotionEnabled ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                        exploreVM.isFeedMode.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: exploreVM.isFeedMode ? "map.fill" : "list.bullet")
                            .font(.system(size: 14, weight: .semibold))
                        Text(exploreVM.isFeedMode ? "Map" : "Feed")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.softMintTint)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(ThemeColors.emerald(highContrast: settings.highContrastEnabled).opacity(0.3), lineWidth: 1)
                    )
                }
                .accessibilityLabel("Switch to \(exploreVM.isFeedMode ? "Map" : "Feed") view")
                
                // + Add Item Button
                Button(action: {
                    exploreVM.isAddItemPresented = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        .clipShape(Circle())
                        .shadow(color: Color.brandEmerald.opacity(0.3), radius: 6, y: 2)
                }
                .accessibilityLabel("Add an item to lend")
            }
        }
    }
    
    // MARK: - Search & Filter Bar
    private var searchAndFilterBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField("Tools, camping gear, more...", text: $exploreVM.searchQuery)
                    .font(.system(size: 15))
                
                if !exploreVM.searchQuery.isEmpty {
                    Button(action: { exploreVM.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            
            // Filter Button
            Button(action: {
                exploreVM.isFilterSheetPresented = true
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                    
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(exploreVM.selectedFilterCategories.isEmpty && !exploreVM.filterWeekendOnly ? .primary : ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    
                    if !exploreVM.selectedFilterCategories.isEmpty || exploreVM.filterWeekendOnly {
                        Circle()
                            .fill(Color.brandEmerald)
                            .frame(width: 8, height: 8)
                            .offset(x: 10, y: -10)
                    }
                }
            }
            .accessibilityLabel("Open Search Filters")
        }
    }
    
    // MARK: - Category Filter Chips
    private var categoryChipsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All nearby" chip
                CategoryChip(
                    title: "All nearby",
                    icon: "sparkles",
                    isSelected: exploreVM.selectedCategory == nil && !exploreVM.filterFreeOnly
                ) {
                    exploreVM.selectedCategory = nil
                    exploreVM.filterFreeOnly = false
                }
                
                // "Free to Borrow" chip
                CategoryChip(
                    title: "Free Items",
                    icon: "gift.fill",
                    isSelected: exploreVM.filterFreeOnly
                ) {
                    exploreVM.filterFreeOnly.toggle()
                }
                
                // Specific categories
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
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Screen 4: Feed Mode List
    private var feedListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(exploreVM.filteredItems) { item in
                    ItemFeedCard(item: item) {
                        exploreVM.selectedItemForDetail = item
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .refreshable {
            await exploreVM.fetchItems()
        }
    }
    
    // MARK: - Screen 3: Map Mode View
    private var mapModeView: some View {
        let currentCenter = locationService.userCoordinate?.clCoordinate ?? AppConfig.cedarGroveCenter.clCoordinate
        
        return ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                // Translucent 500m Walkable Neighborhood Circle
                MapCircle(center: currentCenter, radius: exploreVM.searchRadiusMeters)
                    .foregroundStyle(Color.brandEmerald.opacity(0.12))
                    .stroke(Color.brandEmerald.opacity(0.6), lineWidth: 2)
                
                // User Location Dot
                Annotation("You", coordinate: currentCenter) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.25))
                            .frame(width: 28, height: 28)
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 14, height: 14)
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Item Pins (Custom Distance Pills)
                ForEach(exploreVM.filteredItems) { item in
                    Annotation(item.title, coordinate: item.coordinate.clCoordinate) {
                        MapItemPillPin(
                            item: item,
                            isSelected: exploreVM.selectedItemForMapPreview?.id == item.id
                        ) {
                            withAnimation(settings.reduceMotionEnabled ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                                exploreVM.selectedItemForMapPreview = item
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            
            // Bottom Floating Item Preview Card
            if let selected = exploreVM.selectedItemForMapPreview {
                FloatingMapItemCard(item: selected) {
                    exploreVM.selectedItemForDetail = selected
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Category Chip Component
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var settings: AppSettingsManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                ThemeColors.emerald(highContrast: settings.highContrastEnabled) :
                Color(uiColor: .secondarySystemGroupedBackground)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .accessibilityLabel("\(title) category filter, \(isSelected ? "selected" : "unselected")")
    }
}

// MARK: - Feed Card Component (Screen 4)
struct ItemFeedCard: View {
    let item: BorrowItem
    let onTap: () -> Void
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var settings: AppSettingsManager
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Visual Hero Box with Real Item Photo
                ItemPhotoView(item: item, height: 160, cornerRadius: 16)
                
                // Item Info Row
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(item.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if item.isFree {
                            HStack(spacing: 4) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 11))
                                Text("FREE")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(Color.brandEmerald)
                            .clipShape(Capsule())
                        } else {
                            Text(item.formattedRate)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        }
                    }
                    
                    HStack(spacing: 8) {
                        // Distance
                        HStack(spacing: 3) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 12))
                            Text(item.formattedDistance)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        // Rating
                        RatingStarRow(rating: item.rating)
                        
                        Spacer()
                        
                        // Available Today Pill
                        if item.isAvailable {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.brandEmerald)
                                    .frame(width: 5, height: 5)
                                Text("Available today")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color.statusEmeraldText)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.statusEmeraldBg)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
            .padding(12)
            .squircleCard()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.formattedRate), \(item.formattedDistance), rated \(String(format: "%.1f", item.rating)) stars")
    }
}

// MARK: - Map Pin Pill Component (Screen 3)
struct MapItemPillPin: View {
    let item: BorrowItem
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var settings: AppSettingsManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: item.systemImageName)
                    .font(.system(size: 11, weight: .bold))
                Text("\(item.category.rawValue.prefix(5)) \(Int(item.distanceMeters))m")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isSelected ?
                ThemeColors.emerald(highContrast: settings.highContrastEnabled) :
                Color(uiColor: .systemBackground)
            )
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.18), radius: 6, y: 3)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.white : Color.primary.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
            )
            .scaleEffect(isSelected && !settings.reduceMotionEnabled ? 1.08 : 1.0)
        }
        .accessibilityLabel("\(item.title) pin at \(Int(item.distanceMeters)) meters")
    }
}

// MARK: - Floating Map Item Preview Card
struct FloatingMapItemCard: View {
    let item: BorrowItem
    let onDetailsTap: () -> Void
    @EnvironmentObject var settings: AppSettingsManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Mini Photo Box
            ItemPhotoView(item: item, height: 64, cornerRadius: 14)
                .frame(width: 64, height: 64)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if item.isFree {
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 10))
                            Text("FREE")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.brandEmerald)
                        .clipShape(Capsule())
                        .fixedSize()
                    } else {
                        Text(item.formattedRate)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            .lineLimit(1)
                            .fixedSize()
                    }
                    
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                    
                    HStack(spacing: 3) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 10))
                        Text(item.formattedDistance)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .fixedSize()
                }
                
                RatingStarRow(rating: item.rating)
            }
            .layoutPriority(1)
            
            Spacer(minLength: 6)
            
            Button(action: onDetailsTap) {
                Text("View")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    .clipShape(Capsule())
            }
            .fixedSize()
        }
        .padding(12)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 14, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
