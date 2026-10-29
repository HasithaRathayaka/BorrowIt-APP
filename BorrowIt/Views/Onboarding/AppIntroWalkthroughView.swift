import SwiftUI

// MARK: - Screen 0: App Intro & New User Walkthrough Flow
public struct AppIntroWalkthroughView: View {
    @EnvironmentObject var settings: AppSettingsManager
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var currentPage: Int = 0
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Clean, elevated background matching WanderWise aesthetic
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Top Header (Brand Logo & Skip Button)
                headerView
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                
                // MARK: - 3-Step Walkthrough Carousel
                TabView(selection: $currentPage) {
                    walkthroughPage(
                        index: 0,
                        visualContent: slideOneVisual,
                        title: "Your Neighborhood Gear,\nPerfectely Shared",
                        subtitle: "Borrow drills, camping tents, ladders, and tools from verified neighbors right down your street."
                    )
                    .tag(0)
                    
                    walkthroughPage(
                        index: 1,
                        visualContent: slideTwoVisual,
                        title: "Instant AI Listing &\nTouchless QR Pass",
                        subtitle: "List idle gear in seconds with on-device Core ML vision auto-tagging, and hand off items safely with rotating QR tokens."
                    )
                    .tag(1)
                    
                    walkthroughPage(
                        index: 2,
                        visualContent: slideThreeVisual,
                        title: "Free Community Lending &\nVerified Neighbor Trust",
                        subtitle: "Enjoy 100% free community shares with zero deposit holds, transparent Sri Lankan Rupee rates, and trusted neighbor feedback."
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // MARK: - Bottom Controls (Page Indicator, CTA, Sign In Link)
                bottomControlsView
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            // App Brandmark
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.softMintTint)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "hand.raised.square.on.square.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("BorrowIt")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            // Skip Button
            Button(action: {
                completeWalkthrough()
            }) {
                Text("Skip")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Reusable Page Layout
    private func walkthroughPage<Content: View>(
        index: Int,
        visualContent: Content,
        title: String,
        subtitle: String
    ) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Hero Visual Mockup Area
            visualContent
                .frame(height: 310)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Title & Subtitle Copy
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 10)
        }
    }
    
    // MARK: - Slide 1 Hero Visual: Borrow Tools & Gear Nearby
    private var slideOneVisual: some View {
        ZStack {
            // Ambient Radial Glow
            Circle()
                .fill(Color.brandEmerald.opacity(0.10))
                .frame(width: 260, height: 260)
                .blur(radius: 20)
            
            // Angled Background Card (Little Giant Ladder)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Hand Tools")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.12))
                        .clipShape(Capsule())
                    Spacer()
                    Text("FREE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.brandEmerald)
                }
                Text("Little Giant 17ft Ladder")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Rs. 0 · No deposit hold")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .frame(width: 240)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 5)
            .offset(x: 35, y: -70)
            .rotationEffect(.degrees(6))
            
            // Foreground Prominent Card (DeWalt Drill)
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.statusAmberBg)
                            .frame(width: 60, height: 60)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#F59E0B"))
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("DeWalt 20V Max Drill")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 6) {
                            Text("Power Tools")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#F59E0B"))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(Color(hex: "#F59E0B").opacity(0.12))
                                .clipShape(Capsule())
                            
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.orange)
                                Text("4.9 (42)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Rs. 1,500/day · Rs. 5,000 hold")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    }
                }
            }
            .padding(16)
            .frame(width: 290)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 16, y: 8)
            .offset(x: -15, y: 20)
            
            // Floating Pill Badge: 120m away
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.brandEmerald)
                    .frame(width: 8, height: 8)
                Text("120m away · Available Now")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(uiColor: .systemBackground))
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.10), radius: 8, y: 4)
            .offset(x: 40, y: -10)
            
            // Floating Pill Badge: Zero Waste
            HStack(spacing: 5) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.brandEmerald)
                Text("Zero Waste · Community Share")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(uiColor: .systemBackground))
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
            .offset(x: -45, y: 95)
        }
    }
    
    // MARK: - Slide 2 Hero Visual: Core ML AI & Rotating QR Code Pass
    private var slideTwoVisual: some View {
        ZStack {
            // Ambient Radial Glow
            Circle()
                .fill(Color.blue.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 20)
            
            // Background Card: Core ML Camera Auto-Tagging
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 11))
                        Text("CORE ML VISION SCAN")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundColor(Color.brandEmerald)
                    Spacer()
                    Text("LIVE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
                
                // Target Bounding Box Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .foregroundColor(Color.brandEmerald.opacity(0.6))
                        .frame(height: 70)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "cpu.fill")
                            .foregroundColor(Color.brandEmerald)
                            .font(.system(size: 14))
                        Text("96% Confidence: Power Tools")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.softMintTint)
                    .clipShape(Capsule())
                }
            }
            .padding(14)
            .frame(width: 260)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 5)
            .offset(x: -30, y: -65)
            .rotationEffect(.degrees(-4))
            
            // Foreground Prominent Card: Rotating Handoff Pass
            HStack(spacing: 14) {
                // QR Mockup Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.darkNavyPass)
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "qrcode")
                        .font(.system(size: 42))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.brandEmerald)
                            .frame(width: 6, height: 6)
                        Text("ROTATING PASS")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    }
                    
                    Text("Secure QR Handoff")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        Text("⏱ 04:58")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text("· Face ID Verified")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .frame(width: 290)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 16, y: 8)
            .offset(x: 10, y: 25)
            
            // Floating Pill: 50m Geofence
            HStack(spacing: 5) {
                Image(systemName: "location.north.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 11))
                Text("50m Geofence Handoff Spot")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(uiColor: .systemBackground))
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
            .offset(x: -30, y: 95)
        }
    }
    
    // MARK: - Slide 3 Hero Visual: Community Trust & Free Lending
    private var slideThreeVisual: some View {
        ZStack {
            // Ambient Radial Glow
            Circle()
                .fill(Color.brandEmerald.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 20)
            
            // Background Card: Maya R. Verified Lender
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#10B981"))
                        .frame(width: 44, height: 44)
                    Text("MR")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Maya R.")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            .font(.system(size: 12))
                    }
                    Text("Colombo 07 · 38 Lends")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("5.0")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
            }
            .padding(14)
            .frame(width: 270)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 5)
            .offset(x: -15, y: -65)
            .rotationEffect(.degrees(-3))
            
            // Foreground Prominent Card: Free Community Lending & No Deposit
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.statusEmeraldBg)
                            .frame(width: 38, height: 38)
                        Image(systemName: "gift.fill")
                            .font(.system(size: 18))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Community Share Pool")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Sri Lankan Rupees · Transparent")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Rental")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("FREE (Rs. 0)")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Deposit Hold")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("No Hold Required")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(16)
            .frame(width: 290)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 16, y: 8)
            .offset(x: 10, y: 25)
            
            // Floating Pill: 100% Return Guarantee
            HStack(spacing: 5) {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    .font(.system(size: 11))
                Text("100% Return Protection & Trust")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(uiColor: .systemBackground))
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
            .offset(x: -20, y: 95)
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControlsView: some View {
        VStack(spacing: 18) {
            // Animated Dot / Capsule Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Capsule()
                        .fill(currentPage == index ? ThemeColors.emerald(highContrast: settings.highContrastEnabled) : Color.secondary.opacity(0.25))
                        .frame(width: currentPage == index ? 24 : 7, height: 7)
                        .animation(settings.reduceMotionEnabled ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.top, 4)
            
            // Primary Action Button (Continue / Get Started)
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                if currentPage < 2 {
                    withAnimation(settings.reduceMotionEnabled ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                        currentPage += 1
                    }
                } else {
                    completeWalkthrough()
                }
            }) {
                HStack(spacing: 8) {
                    Text(currentPage == 2 ? "Get Started" : "Continue")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    
                    Image(systemName: currentPage == 2 ? "sparkles" : "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color.brandEmerald, Color(hex: "#059669")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.brandEmerald.opacity(0.35), radius: 10, y: 4)
            }
            
            // Secondary Sign In Link
            Button(action: {
                completeWalkthrough()
            }) {
                Text("Already have an account? ")
                    .foregroundColor(.secondary)
                    + Text("Sign In")
                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    .bold()
            }
            .font(.system(size: 14))
        }
    }
    
    // MARK: - Navigation Action
    private func completeWalkthrough() {
        withAnimation(settings.reduceMotionEnabled ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
            settings.hasCompletedOnboardingWalkthrough = true
        }
    }
}
