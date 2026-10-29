import SwiftUI

// MARK: - Native Apple Face ID Privacy & Security Shield (Banking App Style)
public struct BiometricGateView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var settings: AppSettingsManager
    public var reasonPrompt: String = "Unlock with Face ID to continue to BorrowIt"
    public var onAuthenticated: (() -> Void)? = nil
    public var onCancel: (() -> Void)? = nil
    
    @State private var isProcessing: Bool = false
    @State private var isSuccess: Bool = false
    @State private var scanLaserOffset: CGFloat = -28
    @State private var errorMessage: String? = nil
    
    public init(
        reasonPrompt: String = "Unlock with Face ID to continue to BorrowIt",
        onAuthenticated: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.reasonPrompt = reasonPrompt
        self.onAuthenticated = onAuthenticated
        self.onCancel = onCancel
    }
    
    public var body: some View {
        ZStack {
            // 1. Full-Screen Frosted Glass Privacy Shield (Completely hides underlying app content)
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            Color(uiColor: .systemBackground)
                .opacity(0.85)
                .ignoresSafeArea()
            
            // 2. Centered Native Security Card
            VStack(spacing: 28) {
                Spacer()
                
                // Animated Biometric Glyph with Scanning Beam
                ZStack {
                    // Pulsing outer biometric aura
                    Circle()
                        .stroke(ThemeColors.emerald(highContrast: settings.highContrastEnabled).opacity(isProcessing ? 0.35 : 0.12), lineWidth: 3)
                        .frame(width: 108, height: 108)
                        .scaleEffect(isProcessing ? 1.08 : 1.0)
                        .animation(isProcessing ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isProcessing)
                    
                    Circle()
                        .fill(Color.softMintTint)
                        .frame(width: 96, height: 96)
                        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 6)
                    
                    if isSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        ZStack {
                            Image(systemName: "faceid")
                                .font(.system(size: 48, weight: .regular))
                                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            
                            // Animated laser scan beam moving across the Face ID glyph
                            if isProcessing {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(
                                        LinearGradient(
                                            colors: [.clear, ThemeColors.emerald(highContrast: settings.highContrastEnabled), .clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 52, height: 3)
                                    .offset(y: scanLaserOffset)
                                    .shadow(color: ThemeColors.emerald(highContrast: settings.highContrastEnabled).opacity(0.8), radius: 4)
                            }
                        }
                    }
                }
                
                // Security Heading & Explanation
                VStack(spacing: 8) {
                    if isSuccess {
                        Text("Face ID Verified")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        
                        Text("Welcome back, \(authVM.currentUser.name)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    } else if isProcessing {
                        Text("Scanning Face...")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Verifying facial biometric data")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    } else {
                        Text("BorrowIt Locked")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Welcome back, \(authVM.currentUser.name)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.85))
                        
                        Text("Face ID is required to access your borrows, QR passes, and messages.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                }
                
                // Error / Status Feedback
                if let error = errorMessage, !isProcessing && !isSuccess {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 13))
                        Text(error)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: {
                        triggerAuthentication()
                    }) {
                        HStack(spacing: 8) {
                            if isSuccess {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                            } else if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "faceid")
                                    .font(.system(size: 18))
                            }
                            Text(isSuccess ? "Verified!" : (isProcessing ? "Scanning Face..." : "Scan Face with Face ID"))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: ThemeColors.emerald(highContrast: settings.highContrastEnabled).opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(isProcessing || isSuccess)
                    .accessibilityLabel("Scan Face with Face ID button")
                    
                    Button(action: {
                        withAnimation(settings.reduceMotionEnabled ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                            settings.unlockApp()
                        }
                        onAuthenticated?()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 12))
                            Text("Simulator Bypass")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.vertical, 6)
                    }
                    
                    Button(action: {
                        withAnimation {
                            settings.unlockApp()
                        }
                        authVM.signOut()
                    }) {
                        Text("Log Out / Switch Account")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red.opacity(0.85))
                            .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
            .frame(maxWidth: 440)
        }
        .onAppear {
            // Automatically start face scan when security shield appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                triggerAuthentication()
            }
        }
    }
    
    private func triggerAuthentication() {
        guard !isProcessing && !isSuccess else { return }
        isProcessing = true
        errorMessage = nil
        scanLaserOffset = -28
        
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
            scanLaserOffset = 28
        }
        
        Task {
            let success = await authVM.authenticateWithBiometrics(reason: reasonPrompt)
            await MainActor.run {
                if success {
                    isProcessing = false
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        isSuccess = true
                    }
                    
                    // Show "Face ID Verified" with green checkmark for 0.45s before unlocking
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        withAnimation(settings.reduceMotionEnabled ? nil : .easeInOut(duration: 0.3)) {
                            settings.unlockApp()
                        }
                        onAuthenticated?()
                    }
                } else {
                    isProcessing = false
                    if let authErr = authVM.authErrorMessage, !authErr.isEmpty {
                        errorMessage = authErr
                    }
                }
            }
        }
    }
}
