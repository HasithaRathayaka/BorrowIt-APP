import SwiftUI

// MARK: - Screen 2: Face ID Security Gate
public struct BiometricGateView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var settings: AppSettingsManager
    public var reasonPrompt: String = "Welcome back — Sign in securely to see what your neighbors are sharing"
    public var onAuthenticated: (() -> Void)? = nil
    public var onCancel: (() -> Void)? = nil
    
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String? = nil
    
    public init(
        reasonPrompt: String = "Welcome back — Sign in securely to see what your neighbors are sharing",
        onAuthenticated: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.reasonPrompt = reasonPrompt
        self.onAuthenticated = onAuthenticated
        self.onCancel = onCancel
    }
    
    public var body: some View {
        ZStack {
            // Blurred background shield
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Bottom Modal Sheet Card
                VStack(spacing: 24) {
                    // Face ID Icon with animated pulse
                    ZStack {
                        Circle()
                            .fill(Color.softMintTint)
                            .frame(width: 84, height: 84)
                        
                        Image(systemName: "faceid")
                            .font(.system(size: 42, weight: .regular))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    }
                    .padding(.top, 12)
                    
                    VStack(spacing: 8) {
                        Text("Face ID for BorrowIt")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(reasonPrompt)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                    }
                    
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
                                }
                                Text("Authenticate with Face ID")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(isProcessing)
                        .accessibilityLabel("Authenticate with Face ID button")
                        
                        Button(action: {
                            onCancel?()
                            settings.unlockApp()
                        }) {
                            Text("Simulator Passcode Bypass")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 6)
                        }
                        
                        Button(action: {
                            settings.unlockApp()
                            authVM.signOut()
                        }) {
                            Text("Log Out / Switch Account")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red.opacity(0.85))
                                .padding(.vertical, 4)
                        }
                    }
                }
                .padding(24)
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: Color.black.opacity(0.15), radius: 24, y: 10)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            // Automatically prompt Face ID on view appearance
            triggerAuthentication()
        }
    }
    
    private func triggerAuthentication() {
        isProcessing = true
        errorMessage = nil
        Task {
            let success = await authVM.authenticateWithBiometrics(reason: reasonPrompt)
            isProcessing = false
            if success {
                settings.unlockApp()
                onAuthenticated?()
            } else {
                errorMessage = "Authentication failed. Tap button or use bypass."
            }
        }
    }
}
