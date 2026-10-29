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
            ZStack(alignment: .top) {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if exploreVM.isFeedMode {
                    // Feed Mode Layout
                    VStack(spacing: 0) {
                        exploreHeaderView
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            .padding(.bottom, 12)
                        
                        searchAndFilterBar
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                        
                        categoryChipsScrollView
                            .padding(.bottom, 12)
                        
                        if settings.simulateEmptyState || exploreVM.filteredItems.isEmpty {
                            EmptyExploreStateView()
                        } else {
                            feedListView
                        }
                    }
                } else {
                    // Map Mode: Immersive Edge-to-Edge Map with Glassmorphic Floating Top Bar
                    ZStack(alignment: .top) {
                        mapModeView
                            .ignoresSafeArea(edges: .top)
                        
                        // Floating Glassmorphic Top Controls
                        VStack(spacing: 8) {
                            exploreHeaderView
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            searchAndFilterBar
                                .padding(.horizontal, 20)
                            
                            categoryChipsScrollView
                                .padding(.bottom, 8)
                        }
                        .background(
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .ignoresSafeArea(edges: .top)
                                .shadow(color: Color.black.opacity(0.12), radius: 10, y: 5)
                        )
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
    // Neighborhood Center: Defaults to Colombo 07, or tracks user GPS if within 25km of Colombo
    private var neighborhoodCenter: CLLocationCoordinate2D {
        if let userCoord = locationService.userCoordinate {
            let userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
            let colomboLoc = CLLocation(latitude: AppConfig.cedarGroveCenter.latitude, longitude: AppConfig.cedarGroveCenter.longitude)
            if userLoc.distance(from: colomboLoc) < 25_000 {
                return userCoord.clCoordinate
            }
        }
        return AppConfig.cedarGroveCenter.clCoordinate
    }
    
    // Calculates a 64-point circle perimeter for high-visibility boundary line rendering
    private func circleCoordinates(center: CLLocationCoordinate2D, radius: Double, points: Int = 64) -> [CLLocationCoordinate2D] {
        let earthRadius = 6378137.0
        let dLat = radius / earthRadius
        let dLon = dLat / cos(center.latitude * .pi / 180.0)
        
        var coords: [CLLocationCoordinate2D] = []
        for i in 0...points {
            let angle = Double(i) * (2.0 * .pi / Double(points))
            let lat = center.latitude + (dLat * sin(angle)) * (180.0 / .pi)
            let lon = center.longitude + (dLon * cos(angle)) * (180.0 / .pi)
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return coords
    }
    
    private var mapModeView: some View {
        let center = neighborhoodCenter
        let perimeterCoords = circleCoordinates(center: center, radius: exploreVM.searchRadiusMeters)
        
        return ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                // 1. Translucent Walkable Neighborhood Zone Fill
                MapCircle(center: center, radius: exploreVM.searchRadiusMeters)
                    .foregroundStyle(Color.brandEmerald.opacity(0.18))
                    .mapOverlayLevel(level: .aboveRoads)
                
                // 2. High-Visibility Boundary Perimeter Ring
                MapPolyline(coordinates: perimeterCoords)
                    .stroke(Color.brandEmerald, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 5]))
                    .mapOverlayLevel(level: .aboveRoads)
                
                // 3. Perimeter Badge Annotation (at top of circle)
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: center.latitude + (exploreVM.searchRadiusMeters / 110574.0), longitude: center.longitude)) {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(Int(exploreVM.searchRadiusMeters))m Zone")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.brandEmerald)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.25), radius: 4, y: 2)
                }
                
                // 4. User Location Beacon Dot
                Annotation("", coordinate: center) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.25))
                            .frame(width: 32, height: 32)
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                            .shadow(color: Color.blue.opacity(0.4), radius: 5)
                    }
                }
                
                // 5. Item Pins (Empty annotation title to prevent MapKit raw text clutter!)
                ForEach(exploreVM.filteredItems) { item in
                    Annotation("", coordinate: item.coordinate.clCoordinate) {
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
            
            // Floating Recenter & Radius Controls on Map (right side)
            VStack(spacing: 12) {
                // Radius toggle button (500m <-> 1000m)
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        if exploreVM.searchRadiusMeters <= 500 {
                            exploreVM.searchRadiusMeters = 1000
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: center,
                                    latitudinalMeters: 2600,
                                    longitudinalMeters: 2600
                                )
                            )
                        } else {
                            exploreVM.searchRadiusMeters = 500
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: center,
                                    latitudinalMeters: 1400,
                                    longitudinalMeters: 1400
                                )
                            )
                        }
                    }
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "circle.circle")
                            .font(.system(size: 15, weight: .bold))
                        Text("\(Int(exploreVM.searchRadiusMeters))m")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.18), radius: 6, y: 3)
                    .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                }
                .accessibilityLabel("Toggle search radius")
                
                // Recenter Camera on Colombo 07
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: center,
                                latitudinalMeters: exploreVM.searchRadiusMeters * 2.8,
                                longitudinalMeters: exploreVM.searchRadiusMeters * 2.8
                            )
                        )
                    }
                }) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.18), radius: 6, y: 3)
                        .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                }
                .accessibilityLabel("Recenter map on neighborhood")
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 16)
            .padding(.bottom, exploreVM.selectedItemForMapPreview != nil ? 148 : 24)
            
            // Bottom Floating Item Preview Card
            if let selected = exploreVM.selectedItemForMapPreview {
                FloatingMapItemCard(
                    item: selected,
                    onDetailsTap: { exploreVM.selectedItemForDetail = selected },
                    onDismiss: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            exploreVM.selectedItemForMapPreview = nil
                        }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
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
            HStack(spacing: 5) {
                Image(systemName: item.systemImageName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? .white : Color(hex: item.category.colorHex))
                
                Text(item.isFree ? "FREE" : "Rs.\(Int(item.dailyRate))")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                
                Text("· \(Int(item.distanceMeters))m")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
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
            .shadow(color: Color.black.opacity(isSelected ? 0.25 : 0.14), radius: isSelected ? 8 : 5, y: isSelected ? 4 : 2)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.white : Color.primary.opacity(0.12), lineWidth: isSelected ? 1.5 : 1)
            )
            .scaleEffect(isSelected && !settings.reduceMotionEnabled ? 1.1 : 1.0)
        }
        .accessibilityLabel("\(item.title), \(item.formattedRate), \(Int(item.distanceMeters)) meters away")
    }
}

// MARK: - Floating Map Item Preview Card
struct FloatingMapItemCard: View {
    let item: BorrowItem
    let onDetailsTap: () -> Void
    var onDismiss: (() -> Void)? = nil
    @EnvironmentObject var settings: AppSettingsManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Mini Photo Box
            ItemPhotoView(item: item, height: 68, cornerRadius: 14)
                .frame(width: 68, height: 68)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if item.isFree {
                        HStack(spacing: 3) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 10))
                            Text("FREE")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.brandEmerald)
                        .clipShape(Capsule())
                    } else {
                        Text(item.formattedRate)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    }
                    
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    HStack(spacing: 3) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 10))
                        Text(item.formattedDistance)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
                
                RatingStarRow(rating: item.rating)
            }
            .layoutPriority(1)
            
            Spacer(minLength: 4)
            
            VStack(alignment: .trailing, spacing: 6) {
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss card")
                }
                
                Button(action: onDetailsTap) {
                    HStack(spacing: 4) {
                        Text("View")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    .clipShape(Capsule())
                }
                .fixedSize()
            }
        }
        .padding(12)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 16, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
