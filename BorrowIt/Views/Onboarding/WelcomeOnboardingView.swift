import SwiftUI
import AuthenticationServices

// MARK: - Screen 1: Welcome, Sign In & Sign Up with Face ID
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
        .sheet(isPresented: $authVM.showFaceIDEnrollmentGuidance) {
            faceIDEnrollmentSheet
        }
        .sheet(isPresented: $authVM.showAppleSignInSandboxPrompt) {
            appleSandboxSheet
        }
    }
    
    // MARK: - Log In Section
    private var loginSection: some View {
        VStack(spacing: 16) {
            // Prominent Face ID / Biometric Button with Remembered Account support
            let remembered = authVM.loadSavedUser()
            Button(action: {
                Task {
                    let success = await authVM.signInWithFaceID()
                    if success {
                        exploreVM.resetToFeed()
                    }
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
                        if let user = remembered {
                            Text("Sign in as \(user.name)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("One-tap biometric unlock · \(user.neighborhood)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Sign in with Face ID")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("One-tap secure biometric login")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
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
            
            // Official Native Apple Sign In Button (AuthenticationServices)
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
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 24)
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
    
    // MARK: - Face ID Simulator / Enrollment Guidance Sheet
    private var faceIDEnrollmentSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.softMintTint)
                        .frame(width: 80, height: 80)
                    Image(systemName: "faceid")
                        .font(.system(size: 42))
                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                }
                .padding(.top, 20)
                
                VStack(spacing: 8) {
                    Text("Face ID Biometric Login")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                    let targetUser = authVM.loadSavedUser() ?? authVM.currentUser
                    Text("Ready to authenticate as **\(targetUser.name)**")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("SIMULATOR TESTING GUIDE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            Text("1.")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            Text("In the Mac menu bar at the top, select **Features → Face ID → Enrolled**.")
                                .font(.system(size: 13))
                        }
                        HStack(alignment: .top, spacing: 10) {
                            Text("2.")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            Text("Tap **Sign in with Face ID** again to see Apple's native Face ID popup.")
                                .font(.system(size: 13))
                        }
                        HStack(alignment: .top, spacing: 10) {
                            Text("3.")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            Text("Trigger **Features → Face ID → Matching Face** to simulate a real face match.")
                                .font(.system(size: 13))
                        }
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        authVM.continueWithBiometricSandboxProfile()
                        exploreVM.resetToFeed()
                    }) {
                        Text("Simulate Face ID Pass (One-Tap)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    Button("Cancel") {
                        authVM.showFaceIDEnrollmentGuidance = false
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Face ID Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Apple Sign In Simulator Sandbox Sheet
    private var appleSandboxSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 80, height: 80)
                    Image(systemName: "applelogo")
                        .font(.system(size: 38))
                        .foregroundColor(.primary)
                }
                .padding(.top, 20)
                
                VStack(spacing: 8) {
                    Text("Sign in with Apple")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("On real devices, iOS presents the native Apple ID popup. On Xcode Simulator without an active iCloud account, continue with your verified profile below:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FULL NAME")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        TextField("Name", text: $authVM.pendingAppleName)
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EMAIL (SHARE OR HIDE)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        TextField("Email", text: $authVM.pendingAppleEmail)
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        authVM.continueWithAppleSandboxProfile(
                            name: authVM.pendingAppleName,
                            email: authVM.pendingAppleEmail
                        )
                        exploreVM.resetToFeed()
                    }) {
                        Text("Continue as Apple Verified Neighbor")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(uiColor: .systemBackground))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    Button("Cancel") {
                        authVM.showAppleSignInSandboxPrompt = false
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Apple ID Verification")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
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
