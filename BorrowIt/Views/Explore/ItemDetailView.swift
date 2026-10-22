import SwiftUI

// MARK: - Screen 6: Item Detail View
public struct ItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var settings: AppSettingsManager
    public let item: BorrowItem
    
    @State private var isSchedulePresented: Bool = false
    
    public init(item: BorrowItem) {
        self.item = item
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 1. Hero Image Box
                        ZStack(alignment: .bottomLeading) {
                            ItemPhotoView(item: item, height: 250, cornerRadius: 24)
                            
                            // Bottom-left Core ML Badge
                            CoreMLBadge(tag: item.coreMLTag, confidence: item.coreMLConfidence)
                                .padding(16)
                        }
                        
                        // 2. Title, Rate, Distance, Rating
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top) {
                                Text(item.title)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(item.formattedRate)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            }
                            
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 13))
                                    Text(item.formattedDistance)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.secondary)
                                
                                Text("•")
                                    .foregroundColor(.secondary)
                                
                                RatingStarRow(rating: item.rating)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.brandEmerald)
                                        .frame(width: 6, height: 6)
                                    Text("Available today")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.statusEmeraldText)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.statusEmeraldBg)
                                .clipShape(Capsule())
                            }
                        }
                        
                        // 3. Lender Profile Card
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color(hex: item.lender.avatarColorHex))
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Text(item.lender.initials)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(item.lender.name)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                }
                                
                                Text("Neighbor since \(item.lender.joinedYear) · \(item.lender.totalLends) lends")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            RatingStarRow(rating: item.lender.rating)
                        }
                        .padding(16)
                        .squircleCard()
                        
                        // 4. Two Side-by-Side Spec Cards
                        HStack(spacing: 12) {
                            // Borrowing Term Card
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.blue)
                                Text("1–3 days")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Borrowing term")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .squircleCard()
                            
                            // Deposit Hold Card
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                Text("Rs. \(Int(item.depositHold)) hold")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Released on return")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .squircleCard()
                        }
                        
                        // 5. Full Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About this item")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(item.description)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .squircleCard()
                        
                        // 6. Pickup Address Privacy Notice
                        HStack(spacing: 10) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            Text("Exact pickup address is unlocked after lender approval and biometric verification.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 16)
                    }
                    .padding(20)
                }
                
                // Bottom CTA
                VStack {
                    Button(action: {
                        isSchedulePresented = true
                    }) {
                        HStack {
                            Text("Request to Borrow")
                            Spacer()
                            Text("Rs. \(Int(item.dailyRate))/day")
                                .opacity(0.85)
                        }
                    }
                    .buttonStyle(BrandEmeraldButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    // Native ShareLink
                    ShareLink(
                        item: "Borrow '\(item.title)' from \(item.lender.name) on BorrowIt!",
                        subject: Text("BorrowIt: \(item.title)"),
                        message: Text("Check out this \(item.title) nearby in Cedar Grove for Rs. \(Int(item.dailyRate))/day on BorrowIt.")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    // Favorite Toggle
                    Button(action: {
                        exploreVM.toggleFavorite(for: item)
                    }) {
                        Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(item.isFavorite ? .red : .primary)
                    }
                }
            }
        }
        .sheet(isPresented: $isSchedulePresented) {
            ScheduleBorrowView(item: item)
        }
        .liveAccessibilityScale()
    }
}
