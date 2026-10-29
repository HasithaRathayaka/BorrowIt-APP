import SwiftUI

// MARK: - Native Apple Face ID Privacy & Security Shield (Banking App Style)
public struct BiometricGateView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var settings: AppSettingsManager
    public var reasonPrompt: String = "Unlock with Face ID to continue to BorrowIt"
    public var onAuthenticated: (() -> Void)? = nil
    public var onCancel: (() -> Void)? = nil
    
    @State private var isProcessing: Bool = false
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
                
                // Animated Biometric Glyph
                ZStack {
                    Circle()
                        .fill(Color.softMintTint)
                        .frame(width: 96, height: 96)
                        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 6)
                    
                    Image(systemName: "faceid")
                        .font(.system(size: 48, weight: .regular))
                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                }
                
                // Security Heading & Explanation
                VStack(spacing: 8) {
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
                
                // Error / Status Feedback
                if let error = errorMessage {
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
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "faceid")
                                    .font(.system(size: 18))
                            }
                            Text(isProcessing ? "Authenticating..." : "Unlock with Face ID")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: ThemeColors.emerald(highContrast: settings.highContrastEnabled).opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(isProcessing)
                    .accessibilityLabel("Unlock with Face ID button")
                    
                    Button(action: {
                        withAnimation(settings.reduceMotionEnabled ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                            settings.unlockApp()
                        }
                        onAuthenticated?()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 12))
                            Text("Use Passcode / Simulator Bypass")
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
            // Automatically prompt native Face ID when security shield appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                triggerAuthentication()
            }
        }
    }
    
    private func triggerAuthentication() {
        guard !isProcessing else { return }
        isProcessing = true
        errorMessage = nil
        Task {
            let success = await authVM.authenticateWithBiometrics(reason: reasonPrompt)
            await MainActor.run {
                isProcessing = false
                if success {
                    withAnimation(settings.reduceMotionEnabled ? nil : .easeInOut(duration: 0.3)) {
                        settings.unlockApp()
                    }
                    onAuthenticated?()
                } else {
                    if let authErr = authVM.authErrorMessage, !authErr.isEmpty {
                        errorMessage = authErr
                    } else {
                        errorMessage = "Authentication failed. Tap button or use Simulator menu."
                    }
                }
            }
        }
    }
}
