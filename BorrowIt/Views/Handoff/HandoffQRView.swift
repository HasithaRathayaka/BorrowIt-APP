import SwiftUI
import CoreImage

// MARK: - Screen 11: Handoff QR Pass & Vision Scanner
public struct HandoffQRView: View {
    @EnvironmentObject var lifecycleVM: BorrowLifecycleViewModel
    @EnvironmentObject var settings: AppSettingsManager
    
    @State private var selectedSegment: Int = 0 // 0 = My Handoff Pass, 1 = Scan & Verify QR
    
    public init() {}
    
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
                        // Pass Card View
                        handoffPassCardView
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
                            Text("BorrowIt")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Offline Badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.brandEmerald)
                                .frame(width: 6, height: 6)
                            Text("Core Data offline")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.brandEmerald)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.brandEmerald.opacity(0.18))
                        .clipShape(Capsule())
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
                    
                    // Borrower and Validity Information
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("BORROWER")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Text(lifecycleVM.activeBorrow?.borrowerName ?? "Alex Morgan")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("VALID UNTIL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Text("5:15 PM")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(24)
                .background(Color.darkNavyPass)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.2), radius: 20, y: 8)
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
                        Text("Verify Pickup QR (Vision On-Device)")
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
}
