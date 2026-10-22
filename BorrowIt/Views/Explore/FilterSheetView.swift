import SwiftUI

// MARK: - Screen 5: Search Filters Sheet
public struct FilterSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var settings: AppSettingsManager
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 1. Search Radius Card
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("SEARCH RADIUS")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(exploreVM.searchRadiusMeters < 1000 ? "\(Int(exploreVM.searchRadiusMeters))m" : String(format: "%.1f km", exploreVM.searchRadiusMeters / 1000.0))
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.softMintTint)
                                        .clipShape(Capsule())
                                }
                                
                                Slider(value: $exploreVM.searchRadiusMeters, in: 100...2000, step: 50)
                                    .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                
                                HStack {
                                    Text("100m")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("500m (Walkable)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("2 km")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Keep it walkable. We'll only show items in your immediate neighborhood.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(18)
                            .squircleCard()
                            
                            // 2. Categories Multi-Select Grid
                            VStack(alignment: .leading, spacing: 14) {
                                Text("CATEGORIES")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(ItemCategory.allCases) { category in
                                        let isSelected = exploreVM.selectedFilterCategories.contains(category)
                                        Button(action: {
                                            if isSelected {
                                                exploreVM.selectedFilterCategories.remove(category)
                                            } else {
                                                exploreVM.selectedFilterCategories.insert(category)
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: category.sfSymbol)
                                                    .font(.system(size: 14, weight: .semibold))
                                                Text(category.rawValue)
                                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                Spacer()
                                                if isSelected {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 12, weight: .bold))
                                                }
                                            }
                                            .foregroundColor(isSelected ? .white : .primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 12)
                                            .background(
                                                isSelected ?
                                                ThemeColors.emerald(highContrast: settings.highContrastEnabled) :
                                                Color(uiColor: .tertiarySystemGroupedBackground)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        }
                                        .accessibilityLabel("\(category.rawValue), \(isSelected ? "selected" : "not selected")")
                                    }
                                }
                            }
                            .padding(18)
                            .squircleCard()
                            
                            // 3. Availability & Community Sharing Toggles
                            VStack(alignment: .leading, spacing: 14) {
                                Toggle(isOn: $exploreVM.filterWeekendOnly) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Available This Weekend")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Text("Fri, Oct 2 – Sun, Oct 4")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                
                                Divider()
                                
                                Toggle(isOn: $exploreVM.filterFreeOnly) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "gift.fill")
                                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                            .font(.system(size: 16))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Free to Borrow Only")
                                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                .foregroundColor(.primary)
                                            Text("Items neighbors are sharing at Rs. 0/day")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            }
                            .padding(18)
                            .squircleCard()
                        }
                        .padding(20)
                    }
                    
                    // Bottom CTA Button
                    VStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Show \(exploreVM.filteredCount) nearby items")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .buttonStyle(BrandEmeraldButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        exploreVM.resetFilters()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                }
            }
        }
        .liveAccessibilityScale()
    }
}
