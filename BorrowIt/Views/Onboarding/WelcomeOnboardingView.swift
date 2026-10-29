import SwiftUI
import AuthenticationServices

// MARK: - Screen 1: Welcome, Sign In & Sign Up
public struct WelcomeOnboardingView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @EnvironmentObject var exploreVM: ExploreViewModel
    
    // Auth Mode: 0 = Log In, 1 = Sign Up
    @State private var authMode: Int = 0
    
    // Log In Form
    @State private var loginEmail: String = ""
    @State private var loginPassword: String = ""
    
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
            // 1. Dynamic Ambient Background with Soft Emerald Glow
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.brandEmerald.opacity(colorScheme == .dark ? 0.22 : 0.15),
                                Color.brandEmerald.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.6
                        )
                    )
                    .frame(width: geo.size.width * 1.2, height: geo.size.width * 1.2)
                    .offset(x: -geo.size.width * 0.1, y: -geo.size.width * 0.45)
                    .blur(radius: 40)
            }
            .ignoresSafeArea()
            
            // 2. Main Scrollable Content
            ScrollView {
                VStack(spacing: 22) {
                    // Hero Brand Presentation
                    heroBrandHeader
                        .padding(.top, 28)
                    
                    // Mode Selector: Log In vs Sign Up
                    authModeSelector
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
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    // Active Form Section
                    if authMode == 0 {
                        loginSection
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    } else {
                        signUpSection
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                    
                    // Trust & Community Badges
                    trustBadgesStrip
                        .padding(.top, 4)
                    
                    // Terms Footer
                    Text("By continuing, you agree to BorrowIt Community Safety & Deposit Hold Terms.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 28)
                }
            }
        }
        .liveAccessibilityScale()
    }
    
    // MARK: - Hero Brand Header
    private var heroBrandHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                // Ambient Shadow Glow
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 78, height: 78)
                    .blur(radius: 14)
                    .opacity(0.35)
                    .offset(y: 4)
                
                // Icon Squircle Container
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(uiColor: .systemBackground),
                                Color(uiColor: .secondarySystemBackground)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 78, height: 78)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.brandEmerald.opacity(0.35),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 10, y: 5)
                
                // Foreground Brand Glyph
                Image(systemName: "hand.raised.square.on.square.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 4) {
                Text("BorrowIt")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        .frame(width: 6, height: 6)
                    Text("Peer-to-Peer Neighborhood Lending")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Custom Sliding Mode Selector
    private var authModeSelector: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    authMode = 0
                }
            }) {
                Text("Log In")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(authMode == 0 ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        authMode == 0 ?
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .systemBackground))
                            .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                        : nil
                    )
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    authMode = 1
                }
            }) {
                Text("Sign Up")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(authMode == 1 ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        authMode == 1 ?
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .systemBackground))
                            .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                        : nil
                    )
            }
        }
        .padding(4)
        .background(Color(uiColor: .tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - Log In Section
    private var loginSection: some View {
        VStack(spacing: 16) {
            // Email & Password Inputs
            VStack(spacing: 12) {
                // Email Field
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 15))
                        .foregroundColor(loginEmail.isEmpty ? .secondary : ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        .frame(width: 22)
                    
                    TextField("Email address", text: $loginEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .font(.system(size: 15))
                    
                    if !loginEmail.isEmpty {
                        Button(action: { loginEmail = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary.opacity(0.6))
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(15)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(loginEmail.isEmpty ? Color.primary.opacity(0.06) : ThemeColors.emerald(highContrast: settings.highContrastEnabled).opacity(0.4), lineWidth: 1)
                )
                
                // Password Field
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 15))
                        .foregroundColor(loginPassword.isEmpty ? .secondary : ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        .frame(width: 22)
                    
                    SecureField("Password", text: $loginPassword)
                        .font(.system(size: 15))
                    
                    if !loginPassword.isEmpty {
                        Button(action: { loginPassword = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary.opacity(0.6))
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(15)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(loginPassword.isEmpty ? Color.primary.opacity(0.06) : ThemeColors.emerald(highContrast: settings.highContrastEnabled).opacity(0.4), lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
            
            // Log In Primary Action CTA
            Button(action: {
                Task {
                    exploreVM.resetToFeed()
                    _ = await authVM.signInWithEmail(email: loginEmail, password: loginPassword)
                }
            }) {
                HStack(spacing: 8) {
                    if authVM.isAuthenticating {
                        ProgressView().tint(.white)
                    } else {
                        Text("Log In")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.brandEmerald.opacity(0.35), radius: 10, y: 5)
            }
            .padding(.horizontal, 24)
            
            // Divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)
                Text("OR CONTINUE WITH")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 4)
            
            // Official Native Apple Sign In Button
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    Task {
                        await authVM.handleAppleSignInResult(result)
                        if authVM.isAuthenticated {
                            exploreVM.resetToFeed()
                        }
                    }
                }
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 24)
            
            // Quick Demo Auto-fill Helper for Reviewers
            Button(action: {
                loginEmail = "alex.morgan@borrowit.lk"
                loginPassword = "password123"
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                    Text("Auto-fill Demo Neighbor (Alex M.)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.softMintTint)
                .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Sign Up Section
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
            
            // Registration Form Fields
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    TextField("Full Name (e.g. Kasun Perera)", text: $signUpName)
                        .font(.system(size: 15))
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.06), lineWidth: 1))
                
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    TextField("Email (e.g. kasun@borrowit.lk)", text: $signUpEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .font(.system(size: 15))
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.06), lineWidth: 1))
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    SecureField("Choose a Password", text: $signUpPassword)
                        .font(.system(size: 15))
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.06), lineWidth: 1))
                
                HStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    TextField("City / Area (e.g. Colombo 07, Sri Lanka)", text: $signUpNeighborhood)
                        .font(.system(size: 15))
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.06), lineWidth: 1))
                
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    TextField("Phone Number (e.g. +94 77 123 4567)", text: $signUpPhone)
                        .keyboardType(.phonePad)
                        .font(.system(size: 15))
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.06), lineWidth: 1))
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
                    } else {
                        Text("Create Account & Sign In")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.brandEmerald.opacity(0.35), radius: 10, y: 5)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
    }
    
    // MARK: - Trust Badges Strip
    private var trustBadgesStrip: some View {
        HStack(spacing: 16) {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                Text("ID Verified")
            }
            
            Text("·")
                .foregroundColor(.secondary.opacity(0.4))
            
            HStack(spacing: 5) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.blue)
                Text("Deposit Escrow")
            }
            
            Text("·")
                .foregroundColor(.secondary.opacity(0.4))
            
            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.orange)
                Text("Neighborhood")
            }
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundColor(.secondary)
    }
}
