import SwiftUI

// MARK: - Screen 12: Pickup Verified Confirmation
public struct PickupVerifiedView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettingsManager
    public let borrow: BorrowTransaction
    
    public init(borrow: BorrowTransaction) {
        self.borrow = borrow
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // Emerald Checkmark Squircle
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.softMintTint)
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                }
                .shadow(color: Color.brandEmerald.opacity(0.18), radius: 16, y: 6)
                
                // Headline & Subtitle
                VStack(spacing: 8) {
                    Text("Pickup verified!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("You and \(borrow.lenderName) are all set. The borrowing timer and Dynamic Island Live Activity have started.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .lineSpacing(3)
                }
                
                // Item Summary Card with "In your care" Badge
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: borrow.item.category.colorHex).opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: borrow.item.systemImageName)
                                .font(.system(size: 26))
                                .foregroundColor(Color(hex: borrow.item.category.colorHex))
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(borrow.item.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("From \(borrow.lenderName)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // "In your care" Badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.brandEmerald)
                                .frame(width: 6, height: 6)
                            Text("In your care")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color.statusEmeraldText)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.statusEmeraldBg)
                        .clipShape(Capsule())
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("RETURN DEADLINE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("Today by 5:00 PM")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("REFUNDABLE HOLD")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("Rs. \(Int(borrow.depositHoldAmount)) active")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        }
                    }
                }
                .padding(18)
                .squircleCard()
                .padding(.horizontal, 20)
                
                Spacer()
                
                // CTAs
                VStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("View Active Borrows")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .buttonStyle(BrandEmeraldButtonStyle())
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Message \(borrow.lenderName)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .liveAccessibilityScale()
    }
}
