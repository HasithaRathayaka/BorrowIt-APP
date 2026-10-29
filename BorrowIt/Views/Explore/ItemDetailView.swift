import SwiftUI

// MARK: - Screen 6: Item Detail View
public struct ItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @EnvironmentObject var chatVM: ChatViewModel
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
                        ItemPhotoView(item: item, height: 250, cornerRadius: 24)
                        
                        // 2. Title, Rate, Distance, Rating
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Text(item.title)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                                if item.isFree {
                                    HStack(spacing: 4) {
                                        Image(systemName: "gift.fill")
                                            .font(.system(size: 12))
                                        Text("FREE")
                                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.brandEmerald)
                                    .clipShape(Capsule())
                                    .fixedSize()
                                    .layoutPriority(1)
                                } else {
                                    Text(item.formattedRate)
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                        .lineLimit(1)
                                        .layoutPriority(1)
                                }
                            }
                            
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 13))
                                    Text(item.formattedDistance)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .fixedSize()
                                
                                Text("•")
                                    .foregroundColor(.secondary)
                                
                                RatingStarRow(rating: item.rating)
                                
                                Spacer(minLength: 4)
                            }
                        }
                        
                        // 3. Tappable Lender Profile Card -> Direct Message with Owner
                        NavigationLink(destination: ChatThreadView(conversation: chatVM.getOrCreateConversation(with: item.lender, itemTitle: item.title))) {
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
                                    HStack(spacing: 4) {
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
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "bubble.left.fill")
                                            .font(.system(size: 10))
                                        Text("Tap to message \(item.lender.name)")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                    .padding(.top, 1)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    RatingStarRow(rating: item.lender.rating)
                                    
                                    HStack(spacing: 3) {
                                        Text("Chat")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(14)
                            .squircleCard()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Message lender \(item.lender.name)")
                        
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
                                Text(item.isFree || item.depositHold <= 0 ? "No hold" : "Rs. \(Int(item.depositHold)) hold")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text(item.isFree || item.depositHold <= 0 ? "Free Community Lend" : "Released on return")
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
                
                // Bottom CTAs: Quick Message Shortcut + Request to Borrow
                HStack(spacing: 12) {
                    NavigationLink(destination: ChatThreadView(conversation: chatVM.getOrCreateConversation(with: item.lender, itemTitle: item.title))) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            .frame(width: 52, height: 52)
                            .background(Color.softMintTint)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(ThemeColors.emerald(highContrast: settings.highContrastEnabled).opacity(0.3), lineWidth: 1.5)
                            )
                    }
                    .accessibilityLabel("Message \(item.lender.name)")
                    
                    Button(action: {
                        isSchedulePresented = true
                    }) {
                        HStack {
                            Text("Request to Borrow")
                            Spacer()
                            Text(item.isFree ? "Free to Borrow" : item.formattedRate)
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
                        message: Text("Check out this \(item.title) nearby in Colombo 07 for Rs. \(Int(item.dailyRate))/day on BorrowIt.")
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
