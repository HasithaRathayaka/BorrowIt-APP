import SwiftUI

// MARK: - Screen 13: Your Borrows & Live Activity
public struct BorrowsTabView: View {
    @EnvironmentObject var lifecycleVM: BorrowLifecycleViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @EnvironmentObject var liveActivityManager: LiveActivityManager
    
    public init() {}
    
    private var activeCount: Int {
        lifecycleVM.borrows.filter { $0.state != .returned && $0.state != .cancelled }.count
    }
    
    private var completedCount: Int {
        lifecycleVM.borrows.filter { $0.state == .returned }.count
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Subtitle Stats
                            HStack {
                                Text("\(activeCount) active · \(completedCount + 11) completed")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            
                            // 1. Viva Interactive Lifecycle Demonstration Bar
                            vivaLifecycleControlStrip
                                .padding(.horizontal, 20)
                            
                            // 2. Active Borrow Card
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
                }
            }
            .navigationTitle("Your Borrows")
            .sheet(isPresented: $lifecycleVM.isReturnReviewPresented) {
                ReturnReviewView()
            }
        }
        .liveAccessibilityScale()
    }
    
    // MARK: - Viva Lifecycle Controls Strip
    private var vivaLifecycleControlStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "slider.horizontal.below.rectangle")
                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                Text("VIVA DEMO LIFECYCLE CONTROLLER")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                LifecycleStepButton(title: "Approve (Bio)", icon: "faceid") {
                    lifecycleVM.advanceToApproved()
                }
                LifecycleStepButton(title: "50m Arrive", icon: "location.fill") {
                    lifecycleVM.advanceToHandoff()
                }
                LifecycleStepButton(title: "Scan QR", icon: "qrcode.viewfinder") {
                    lifecycleVM.advanceToBorrowed()
                }
                LifecycleStepButton(title: "Return", icon: "arrow.counterclockwise") {
                    lifecycleVM.advanceToReturned()
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

// MARK: - Lifecycle Step Button Helper
struct LifecycleStepButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @EnvironmentObject var settings: AppSettingsManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.softMintTint)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ThemeColors.emerald(highContrast: settings.highContrastEnabled).opacity(0.2), lineWidth: 1)
            )
        }
    }
}
