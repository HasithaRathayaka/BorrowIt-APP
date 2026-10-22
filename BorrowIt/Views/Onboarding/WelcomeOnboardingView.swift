import SwiftUI

// MARK: - Screen 1: Welcome, Sign In & Sign Up with Face ID
public struct WelcomeOnboardingView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @EnvironmentObject var exploreVM: ExploreViewModel
    
    // Auth Mode: 0 = Log In, 1 = Sign Up
    @State private var authMode: Int = 0
    
    // Log In Form
    @State private var loginEmail: String = "alex@icloud.com"
    @State private var loginPassword: String = "borrowit2026"
    
    // Sign Up Form
    @State private var signUpName: String = ""
    @State private var signUpEmail: String = ""
    @State private var signUpPassword: String = ""
    @State private var signUpNeighborhood: String = "Colombo 07, Sri Lanka"
    @State private var signUpPhone: String = ""
    @State private var enableFaceID: Bool = true
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 1. App Header & Logo
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.softMintTint)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "hand.raised.square.on.square.fill")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        }
                        .shadow(color: Color.brandEmerald.opacity(0.18), radius: 12, y: 4)
                        .padding(.top, 24)
                        
                        Text("BorrowIt")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Peer-to-Peer Neighborhood Lending")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // 2. Mode Selector: Log In vs Sign Up
                    Picker("Auth Mode", selection: $authMode) {
                        Text("Log In").tag(0)
                        Text("Sign Up").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    
                    // Error Banner if present
                    if let error = authVM.authErrorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 24)
                    }
                    
                    // 3. Tab Content
                    if authMode == 0 {
                        loginSection
                    } else {
                        signUpSection
                    }
                    
                    // Footer
                    Text("By continuing, you agree to BorrowIt Community Safety & Deposit Hold Terms.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                }
            }
        }
        .liveAccessibilityScale()
    }
    
    // MARK: - Log In Section
    private var loginSection: some View {
        VStack(spacing: 16) {
            // Prominent Face ID / Biometric Button
            Button(action: {
                Task {
                    exploreVM.resetToFeed()
                    _ = await authVM.signInWithFaceID()
                }
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.softMintTint)
                            .frame(width: 48, height: 48)
                        Image(systemName: "faceid")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sign in with Face ID")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("One-tap secure biometric login")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ThemeColors.emerald(highContrast: settings.highContrastEnabled).opacity(0.35), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            
            // Divider
            HStack {
                Rectangle().frame(height: 1).foregroundColor(Color.primary.opacity(0.1))
                Text("OR USE EMAIL")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Rectangle().frame(height: 1).foregroundColor(Color.primary.opacity(0.1))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 4)
            
            // Email & Password Fields
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    TextField("Email address", text: $loginEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    SecureField("Password", text: $loginPassword)
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            
            // Log In CTA Button
            Button(action: {
                Task {
                    exploreVM.resetToFeed()
                    _ = await authVM.signInWithEmail(email: loginEmail, password: loginPassword)
                }
            }) {
                HStack(spacing: 8) {
                    if authVM.isAuthenticating {
                        ProgressView().tint(.white)
                    }
                    Text("Log In")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)
            
            // Sign in with Apple Button
            Button(action: {
                Task {
                    exploreVM.resetToFeed()
                    await authVM.signInWithApple()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Sign in with Apple")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(Color(uiColor: .systemBackground))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)
            
            // Quick Demo Sign In
            Button(action: {
                exploreVM.resetToFeed()
                authVM.signInAsAlexMorgan()
            }) {

                Text("Quick Demo: Sign in as Alex Morgan (Cedar Grove)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Sign Up Section (New User Registration)
    private var signUpSection: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Create your account")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Borrow and lend items securely with verified neighbors.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            
            // Form Fields
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    TextField("Full Name (e.g. Kasun Perera)", text: $signUpName)
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    TextField("Email (e.g. kasun@borrowit.lk)", text: $signUpEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    SecureField("Choose a Password", text: $signUpPassword)
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                HStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    TextField("City / Area (e.g. Colombo 07, Sri Lanka)", text: $signUpNeighborhood)
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    TextField("Phone Number (e.g. +94 77 123 4567)", text: $signUpPhone)
                        .keyboardType(.phonePad)
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            
            // Face ID Registration Toggle Card
            HStack(spacing: 12) {
                Image(systemName: "faceid")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Face Recognition (Face ID)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Unlock app and verify pickup handoffs quickly")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $enableFaceID)
                    .labelsHidden()
                    .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 24)
            
            // Create Account CTA Button
            Button(action: {
                Task {
                    exploreVM.resetToFeed()
                    _ = await authVM.signUp(
                        name: signUpName,
                        email: signUpEmail,
                        password: signUpPassword,
                        neighborhood: signUpNeighborhood,
                        phone: signUpPhone,
                        enableFaceID: enableFaceID
                    )
                }
            }) {
                HStack(spacing: 8) {
                    if authVM.isAuthenticating {
                        ProgressView().tint(.white)
                    }
                    Text("Create Account & Sign In")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
    }
}

// MARK: - Feature Bullet Row Helper
struct FeatureBulletRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @EnvironmentObject var settings: AppSettingsManager
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
