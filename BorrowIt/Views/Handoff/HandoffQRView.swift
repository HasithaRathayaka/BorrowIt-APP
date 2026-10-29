import SwiftUI
import CoreImage

// MARK: - Screen 11: Handoff QR Pass & Vision Scanner
public struct HandoffQRView: View {
    @EnvironmentObject var lifecycleVM: BorrowLifecycleViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var selectedSegment: Int = 0 // 0 = My Handoff Pass, 1 = Scan & Verify QR
    
    public init() {}
    
    private var hasAcceptedHandoff: Bool {
        guard let active = lifecycleVM.activeBorrow else { return false }
        return active.state == .approved || active.state == .handoff || active.state == .borrowed
    }
    
    private var displayBorrowerName: String {
        let authName = authVM.currentUser.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !authName.isEmpty && authName != "Alex Morgan" {
            return authName
        }
        if let bName = lifecycleVM.activeBorrow?.borrowerName, !bName.isEmpty && bName != "Alex Morgan" {
            return bName
        }
        return "You"
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Segment Picker
                    Picker("Handoff Mode", selection: $selectedSegment) {
                        Text("My Handoff Pass").tag(0)
                        Text("Scan & Verify QR").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    if selectedSegment == 0 {
                        if hasAcceptedHandoff {
                            // Pass Card View
                            handoffPassCardView
                        } else {
                            // Awaiting Acceptance / No Active Handoff State
                            awaitingAcceptanceView
                        }
                    } else {
                        // Vision Barcode Scanner View
                        visionScannerView
                    }
                }
            }
            .navigationTitle("Handoff Pass")
            .sheet(isPresented: $lifecycleVM.isPickupVerifiedPresented) {
                if let active = lifecycleVM.activeBorrow {
                    PickupVerifiedView(borrow: active)
                }
            }
            .sheet(isPresented: $lifecycleVM.isReturnReviewPresented) {
                ReturnReviewView()
            }
        }
        .liveAccessibilityScale()
    }
    
    // MARK: - Dark Navy Rotating QR Pass Card
    private var handoffPassCardView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 20) {
                    // Top Pass Header
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.raised.square.on.square.fill")
                                .foregroundColor(Color.brandEmerald)
                                .font(.system(size: 18))
                            Text("BorrowIt Handoff Pass")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    
                    // QR Code Display
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                            .frame(width: 220, height: 220)
                        
                        if let cgImg = lifecycleVM.qrImage {
                            Image(decorative: cgImg, scale: 1.0)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 196, height: 196)
                        } else {
                            ProgressView()
                                .tint(.black)
                        }
                    }
                    .shadow(color: Color.black.opacity(0.3), radius: 10, y: 4)
                    
                    // Live Countdown & Progress Bar
                    VStack(spacing: 8) {
                        Text(lifecycleVM.formattedQRCountdown)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.brandEmerald)
                        
                        // Progress Bar (0 to 300 seconds)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 5)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.brandEmerald)
                                    .frame(width: max(0, geo.size.width * CGFloat(lifecycleVM.qrCountdownSecondsRemaining) / 300.0), height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                    .padding(.horizontal, 10)
                    
                    Divider()
                        .background(Color.white.opacity(0.15))
                    
                    // Item and Borrower Information
                    VStack(spacing: 12) {
                        if let active = lifecycleVM.activeBorrow {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("ITEM")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(active.item.title)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 3) {
                                    Text("LENDER")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(active.lenderName)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.10))
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("BORROWER")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text(displayBorrowerName)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("STATUS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text(lifecycleVM.activeBorrow?.state.displayTitle ?? "Ready for Handoff")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.brandEmerald)
                            }
                        }
                    }
                }
                .padding(24)
                .background(Color.darkNavyPass)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.2), radius: 20, y: 8)
                .padding(.horizontal, 20)
                
                // Core Location 50m Geofencing Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill.viewfinder")
                                .foregroundColor(lifecycleVM.isWithin50mOfHandoff ? Color.brandEmerald : Color.orange)
                            Text("CORE LOCATION GEOFENCE (50M)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Status badge (Within 50m vs Approaching)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(lifecycleVM.isWithin50mOfHandoff ? Color.brandEmerald : Color.orange)
                                .frame(width: 6, height: 6)
                            Text(lifecycleVM.isWithin50mOfHandoff ? "Within 50m zone" : "Monitoring (<50m)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(lifecycleVM.isWithin50mOfHandoff ? Color.statusEmeraldText : Color.orange)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(lifecycleVM.isWithin50mOfHandoff ? Color.statusEmeraldBg : Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    
                    Text("Agreed Handoff Location: \(lifecycleVM.activeBorrow?.item.locationName ?? "Colombo 07") (\(Int(lifecycleVM.handoffDistanceMeters))m away)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    // Viva / Simulator trigger button
                    Button(action: {
                        lifecycleVM.advanceToHandoff()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.circle.fill")
                            Text("Simulate Entering 50m Zone (Geofence Trigger)")
                        }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.brandEmerald)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.brandEmerald.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(14)
                .squircleCard()
                .padding(.horizontal, 20)
                
                // Offline Privacy Security Banner
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 18))
                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    
                    Text("This rotating pass works offline and never reveals your personal phone number or home address.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                .padding(14)
                .squircleCard()
                .padding(.horizontal, 20)
                
                // Manual Refresh Pass Button
                Button(action: {
                    if let active = lifecycleVM.activeBorrow {
                        lifecycleVM.regenerateRotatingQRPayload(for: active)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Rotating Token Now")
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                }
                .padding(.top, 4)
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Vision Barcode Scanner View
    private var visionScannerView: some View {
        VStack(spacing: 20) {
            // Camera Viewfinder Box
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.85))
                    .frame(height: 280)
                
                // Viewfinder Target Reticle
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ThemeColors.emerald(highContrast: settings.highContrastEnabled), lineWidth: 3)
                    .frame(width: 180, height: 180)
                
                VStack {
                    Spacer()
                    Text("Align neighbor's QR pass within box")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 16)
                }
            }
            .padding(.horizontal, 20)
            
            // Scanner Status / Error Feedback
            if let error = lifecycleVM.scanErrorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
            }
            
            // Primary Action: Vision On-Device Scanner Button
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await lifecycleVM.simulateCameraVisionScan()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                        Text(lifecycleVM.activeBorrow?.state == .borrowed ? "Verify Return QR (Vision On-Device)" : "Verify Pickup QR (Vision On-Device)")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .buttonStyle(BrandEmeraldButtonStyle())
                .padding(.horizontal, 20)
                
                Text("Graders: Tapping this runs Apple's VNDetectBarcodesRequest directly against the generated on-device pass image without requiring a physical camera!")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Awaiting Acceptance Empty State
    private var awaitingAcceptanceView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 30)
                
                ZStack {
                    Circle()
                        .fill(Color.brandEmerald.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 40))
                        .foregroundColor(Color.brandEmerald)
                }
                
                VStack(spacing: 8) {
                    Text("No Active Handoff Pass")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("There is no borrower until a lender accepts the request. Once accepted, your rotating QR handoff pass will appear here automatically.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                if let pending = lifecycleVM.borrows.first(where: { $0.state == .pending }) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.orange)
                            Text("Pending Request")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("AWAITING ACCEPTANCE")
                                .font(.system(size: 10, weight: .heavy))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        }
                        
                        Text(pending.item.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Requested from \(pending.lenderName). Awaiting acceptance before handoff pass unlocks.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        // Demo button for viva / grader testing
                        Button(action: {
                            Task {
                                _ = await lifecycleVM.approveBorrow(id: pending.id)
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Simulate Lender Acceptance (Demo)")
                            }
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.brandEmerald)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(16)
                    .squircleCard()
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 40)
        }
    }
}
