import SwiftUI

// MARK: - Screen 8: Request Sent & State Tracker
public struct RequestSentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettingsManager
    public let transaction: BorrowTransaction
    
    @State private var navigateToChat: Bool = false
    
    public init(transaction: BorrowTransaction) {
        self.transaction = transaction
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Mint Circle with Paper Plane Icon
                        ZStack {
                            Circle()
                                .fill(Color.softMintTint)
                                .frame(width: 90, height: 90)
                            
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 40))
                                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        }
                        .padding(.top, 20)
                        
                        // Header & Subtitle
                        VStack(spacing: 8) {
                            Text("Request sent")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("\(transaction.lenderName) usually replies within 20 minutes. We'll notify you as soon as she responds.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                        }
                        
                        // Item Summary Card with Pending Amber Pill
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(hex: transaction.item.category.colorHex).opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: transaction.item.systemImageName)
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: transaction.item.category.colorHex))
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(transaction.item.title)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("From \(transaction.lenderName) · Rs. \(Int(transaction.dailyRate))/day")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                BorrowStatusPill(state: transaction.state)
                            }
                        }
                        .padding(16)
                        .squircleCard()
                        .padding(.horizontal, 20)
                        
                        // 4-Step Vertical Timeline
                        VStack(alignment: .leading, spacing: 16) {
                            Text("BORROW LIFECYCLE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 0) {
                                TimelineStepRow(
                                    stepNumber: 1,
                                    title: "1. Requested",
                                    subtitle: "Dates submitted & refundable hold pre-authorized",
                                    isCompleted: true,
                                    isCurrent: true,
                                    isLast: false
                                )
                                TimelineStepRow(
                                    stepNumber: 2,
                                    title: "2. Accepted",
                                    subtitle: "Lender approves behind Face ID & unlocks pickup spot",
                                    isCompleted: false,
                                    isCurrent: false,
                                    isLast: false
                                )
                                TimelineStepRow(
                                    stepNumber: 3,
                                    title: "3. Picked up",
                                    subtitle: "Within 50m geofence: Vision scans rotating QR pass",
                                    isCompleted: false,
                                    isCurrent: false,
                                    isLast: false
                                )
                                TimelineStepRow(
                                    stepNumber: 4,
                                    title: "4. Returned",
                                    subtitle: "Return verified, hold released & 5-star review",
                                    isCompleted: false,
                                    isCurrent: false,
                                    isLast: true
                                )
                            }
                        }
                        .padding(18)
                        .squircleCard()
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24)
                }
                
                // Bottom CTAs
                VStack(spacing: 12) {
                    NavigationLink(destination: ChatThreadView(conversation: ChatConversation.convMaya)) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Message \(transaction.lenderName)")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Back to Explore")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .liveAccessibilityScale()
    }
}

// MARK: - Timeline Step Row Helper
struct TimelineStepRow: View {
    let stepNumber: Int
    let title: String
    let subtitle: String
    let isCompleted: Bool
    let isCurrent: Bool
    let isLast: Bool
    @EnvironmentObject var settings: AppSettingsManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(
                        isCompleted ?
                        ThemeColors.emerald(highContrast: settings.highContrastEnabled) :
                        Color.secondary.opacity(0.2)
                    )
                    .frame(width: 24, height: 24)
                    .overlay(
                        Group {
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(stepNumber)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? ThemeColors.emerald(highContrast: settings.highContrastEnabled) : Color.secondary.opacity(0.15))
                        .frame(width: 2, height: 36)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrent || isCompleted ? .primary : .secondary)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.bottom, isLast ? 0 : 16)
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
