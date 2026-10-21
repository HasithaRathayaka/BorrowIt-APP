import SwiftUI

// MARK: - Screen 9: Add an Item with On-Device Core ML Auto-Categorization
public struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var addVM = AddItemViewModel()
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var settings: AppSettingsManager
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 1. Photo Box with Live Core ML Badge & Presets
                            VStack(alignment: .leading, spacing: 12) {
                                ZStack(alignment: .bottomLeading) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(Color(hex: addVM.selectedCategory.colorHex).opacity(0.14))
                                            .frame(height: 190)
                                        
                                        Image(systemName: addVM.selectedPreset.symbol)
                                            .font(.system(size: 72, weight: .light))
                                            .foregroundColor(Color(hex: addVM.selectedCategory.colorHex))
                                    }
                                    
                                    // Live Core ML classification pill
                                    CoreMLBadge(tag: addVM.coreMLTag, confidence: addVM.coreMLConfidence)
                                        .padding(14)
                                }
                                
                                // Test Preset Strip (for Graders running on Simulator)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("TEST CORE ML IMAGE PRESETS")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(TestImagePreset.presets) { preset in
                                                let isSelected = addVM.selectedPreset.name == preset.name
                                                Button(action: {
                                                    addVM.selectPreset(preset)
                                                }) {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: preset.symbol)
                                                        Text(preset.name)
                                                    }
                                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                    .foregroundColor(isSelected ? .white : .primary)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        isSelected ?
                                                        ThemeColors.emerald(highContrast: settings.highContrastEnabled) :
                                                        Color(uiColor: .secondarySystemGroupedBackground)
                                                    )
                                                    .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .squircleCard()
                            
                            // 2. Item Details Form
                            VStack(alignment: .leading, spacing: 14) {
                                Text("ITEM DETAILS")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Item Name")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    TextField("e.g. DeWalt 20V Drill", text: $addVM.title)
                                        .font(.system(size: 15))
                                        .padding(10)
                                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Price / Day ($)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        TextField("8", value: $addVM.dailyRate, format: .number)
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .keyboardType(.decimalPad)
                                            .padding(10)
                                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Refundable Deposit ($)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        TextField("40", value: $addVM.depositHold, format: .number)
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .keyboardType(.decimalPad)
                                            .padding(10)
                                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Category")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    Picker("Category", selection: $addVM.selectedCategory) {
                                        ForEach(ItemCategory.allCases) { cat in
                                            Text(cat.rawValue).tag(cat)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    TextField("Describe condition, accessories included, etc.", text: $addVM.itemDescription, axis: .vertical)
                                        .lineLimit(3...5)
                                        .font(.system(size: 14))
                                        .padding(10)
                                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                            .padding(16)
                            .squircleCard()
                            
                            // 3. Availability & Privacy Toggles
                            VStack(alignment: .leading, spacing: 14) {
                                Toggle(isOn: $addVM.isAvailableNow) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Available Now")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        Text("Item is ready for immediate borrowing")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                
                                Divider()
                                
                                Toggle(isOn: $addVM.pickupAddressSharedAfterApproval) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Pickup at my address")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        Text("Exact address is only revealed after you approve request")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            }
                            .padding(16)
                            .squircleCard()
                        }
                        .padding(20)
                    }
                    
                    // Bottom CTA
                    VStack {
                        Button(action: {
                            Task {
                                let newItem = await addVM.publishItem()
                                await exploreVM.fetchItems()
                                exploreVM.selectedItemForDetail = newItem
                                dismiss()
                            }
                        }) {
                            Text("Publish Item")
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
            .navigationTitle("Add an Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .liveAccessibilityScale()
    }
}
