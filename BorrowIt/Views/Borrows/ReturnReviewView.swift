import SwiftUI

// MARK: - Screen 14: Return Complete & 5-Star Neighbor Review
public struct ReturnReviewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lifecycleVM: BorrowLifecycleViewModel
    @EnvironmentObject var settings: AppSettingsManager
    
    @State private var rating: Int = 5
    @State private var commentText: String = "Maya was great! The drill was fully charged and clean. Saved our weekend shelf project."
    @State private var isSubmitted: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Return Checkmark Badge
                ZStack {
                    Circle()
                        .fill(Color.softMintTint)
                        .frame(width: 88, height: 88)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 46))
                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                }
                .shadow(color: Color.brandEmerald.opacity(0.18), radius: 14, y: 5)
                
                // Headline & Subtitle
                VStack(spacing: 8) {
                    Text("Return complete!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if let active = lifecycleVM.activeBorrow, active.depositHoldAmount > 0 {
                        Text("\(active.lenderName) verified '\(active.item.title)' is back in great shape. Your Rs. \(Int(active.depositHoldAmount)) refundable deposit hold has been released.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .lineSpacing(3)
                    } else if let active = lifecycleVM.activeBorrow {
                        Text("\(active.lenderName) verified '\(active.item.title)' is back in great shape. Thank you for participating in community sharing!")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .lineSpacing(3)
                    } else {
                        Text("Your item is back in great shape. Thank you for borrowing responsibly!")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .lineSpacing(3)
                    }
                }
                
                // 5-Star Interactive Rating Card
                VStack(spacing: 16) {
                    Text("How was \(lifecycleVM.activeBorrow?.lenderName ?? "your lender")?")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    // Star selector
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                rating = star
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.orange)
                            }
                            .accessibilityLabel("\(star) stars")
                        }
                    }
                    
                    // Comment TextField
                    TextField("Add a quick thank-you note or review...", text: $commentText, axis: .vertical)
                        .lineLimit(3...4)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(20)
                .squircleCard()
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Bottom CTAs
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            lifecycleVM.reviewRating = rating
                            lifecycleVM.reviewComment = commentText
                            await lifecycleVM.submitReview()
                            dismiss()
                        }
                    }) {
                        Text("Submit \(rating)-Star Review")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .buttonStyle(BrandEmeraldButtonStyle())
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Not now")
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
