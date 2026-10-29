import SwiftUI
import Combine
import AuthenticationServices
import LocalAuthentication

// MARK: - Auth ViewModel
@MainActor
public class AuthViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: UserProfile = .currentUser
    @Published public var authErrorMessage: String? = nil
    @Published public var isAuthenticating: Bool = false
    @Published public var faceIDEnabledForAccount: Bool = true
    
    // Interactive Guidance & Simulator Modals
    @Published public var showFaceIDEnrollmentGuidance: Bool = false
    @Published public var showAppleSignInSandboxPrompt: Bool = false
    @Published public var pendingAppleName: String = "Hasitha Rathnayaka"
    @Published public var pendingAppleEmail: String = "hasithar02@gmail.com"
    
    // MARK: - Session Persistence Keys
    private let userDefaultsProfileKey = "borrowit_saved_user_profile"
    private let authStateKey = "borrowit_is_authenticated"
    private let authMethodKey = "borrowit_auth_method"
    
    private let biometricService: BiometricServiceProtocol
    private let backendService: BackendServiceProtocol
    
    public init(
        biometricService: BiometricServiceProtocol = BiometricAuthService.shared,
        backendService: BackendServiceProtocol = SupabaseService.shared
    ) {
        self.biometricService = biometricService
        self.backendService = backendService
        
        // Restore saved session if previously authenticated
        if UserDefaults.standard.bool(forKey: "borrowit_is_authenticated"),
           let data = UserDefaults.standard.data(forKey: "borrowit_saved_user_profile"),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentUser = saved
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Session Persistence Helpers
    public var hasSavedSession: Bool {
        return UserDefaults.standard.bool(forKey: authStateKey) && UserDefaults.standard.data(forKey: userDefaultsProfileKey) != nil
    }
    
    public func loadSavedUser() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsProfileKey),
              let user = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        return user
    }
    
    public func saveSession(user: UserProfile, method: String) {
        self.currentUser = user
        self.isAuthenticated = true
        self.authErrorMessage = nil
        UserDefaults.standard.set(true, forKey: authStateKey)
        UserDefaults.standard.set(method, forKey: authMethodKey)
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsProfileKey)
        }
    }
    
    // MARK: - Sign In with Face ID (Biometrics)
    public func signInWithFaceID() async -> Bool {
        isAuthenticating = true
        authErrorMessage = nil
        defer { isAuthenticating = false }
        
        let targetName = loadSavedUser()?.name ?? currentUser.name
        let reason = "Sign in to BorrowIt as \(targetName)"
        let result = await biometricService.authenticate(reason: reason)
        
        switch result {
        case .success(let success):
            if success {
                let user = loadSavedUser() ?? currentUser
                saveSession(user: user, method: "faceid")
                return true
            } else {
                self.authErrorMessage = "Face ID verification failed. Please try again or use your email and password."
                return false
            }
        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == LAErrorDomain && (nsError.code == LAError.userCancel.rawValue || nsError.code == LAError.appCancel.rawValue) {
                // User explicitly pressed Cancel - silent dismiss without error banner
                return false
            } else if nsError.domain == LAErrorDomain && nsError.code == LAError.biometryNotEnrolled.rawValue {
                // Face ID not enrolled in this simulator/device
                self.showFaceIDEnrollmentGuidance = true
                return false
            } else {
                self.authErrorMessage = error.localizedDescription
                return false
            }
        }
    }
    
    public func continueWithBiometricSandboxProfile() {
        let user = loadSavedUser() ?? currentUser
        saveSession(user: user, method: "faceid")
        self.showFaceIDEnrollmentGuidance = false
    }
    
    // MARK: - Sign In with Apple (AuthenticationServices)
    public func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        isAuthenticating = true
        authErrorMessage = nil
        defer { isAuthenticating = false }
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                
                // 1. Resolve User Full Name
                var fullNameString = ""
                if let fullName = appleIDCredential.fullName {
                    let given = fullName.givenName ?? ""
                    let family = fullName.familyName ?? ""
                    fullNameString = "\(given) \(family)".trimmingCharacters(in: .whitespaces)
                }
                
                if !fullNameString.isEmpty {
                    UserDefaults.standard.set(fullNameString, forKey: "apple_user_name_\(userIdentifier)")
                } else if let savedName = UserDefaults.standard.string(forKey: "apple_user_name_\(userIdentifier)") {
                    fullNameString = savedName
                } else {
                    fullNameString = "Apple Neighbor"
                }
                
                // 2. Resolve User Email
                var emailString = appleIDCredential.email ?? ""
                if !emailString.isEmpty {
                    UserDefaults.standard.set(emailString, forKey: "apple_user_email_\(userIdentifier)")
                } else if let savedEmail = UserDefaults.standard.string(forKey: "apple_user_email_\(userIdentifier)") {
                    emailString = savedEmail
                } else {
                    emailString = "apple.user@borrowit.app"
                }
                
                // 3. Compute Initials
                let parts = fullNameString.split(separator: " ")
                let initials: String
                if parts.count >= 2 {
                    initials = "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
                } else if let first = parts.first {
                    initials = String(first.prefix(2)).uppercased()
                } else {
                    initials = "AP"
                }
                
                // 4. Create Personalized User Profile
                let appleProfile = UserProfile(
                    id: UUID(),
                    name: fullNameString,
                    email: emailString,
                    initials: initials,
                    neighborhood: "Colombo, Sri Lanka",
                    memberSince: "Apple ID Verified · 2026",
                    isIdVerified: true,
                    trustScore: 98,
                    trustScoreSubtitle: "Apple Verified · Top Neighbor",
                    communityRating: 5.0,
                    reviewCount: 1,
                    totalBorrows: 0,
                    totalLends: 0,
                    wasteAvoidedKg: 0.0,
                    totalMoneySaved: 0.0
                )
                
                saveSession(user: appleProfile, method: "apple")
                
                Task {
                    try? await SupabaseService.shared.updateUserProfile(appleProfile)
                }
            }
            
        case .failure(let error):
            let asError = error as? ASAuthorizationError
            if asError?.code == .canceled {
                // User closed the Apple ID sheet
                return
            } else {
                // Simulator without iCloud configured - present sandbox option
                self.showAppleSignInSandboxPrompt = true
            }
        }
    }
    
    public func continueWithAppleSandboxProfile(name: String = "Hasitha Rathnayaka", email: String = "hasithar02@gmail.com") {
        let parts = name.split(separator: " ")
        let initials: String
        if parts.count >= 2 {
            initials = "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        } else {
            initials = String(name.prefix(2)).uppercased()
        }
        
        let profile = UserProfile(
            id: UUID(),
            name: name,
            email: email,
            initials: initials,
            neighborhood: "Colombo, Sri Lanka",
            memberSince: "Apple Verified · 2026",
            isIdVerified: true,
            trustScore: 99,
            trustScoreSubtitle: "Apple Verified · Top Neighbor",
            communityRating: 5.0,
            reviewCount: 3
        )
        saveSession(user: profile, method: "apple")
        showAppleSignInSandboxPrompt = false
    }
    
    // MARK: - Sign In with Email & Password
    public func signInWithEmail(email: String, password: String = "password") async -> Bool {
        isAuthenticating = true
        authErrorMessage = nil
        defer { isAuthenticating = false }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else {
            authErrorMessage = "Please enter your email address."
            return false
        }
        guard password.count >= 4 else {
            authErrorMessage = "Password must be at least 4 characters."
            return false
        }
        
        if AppConfig.isSupabaseConfigured {
            do {
                let userProfile = try await SupabaseService.shared.signIn(email: trimmedEmail, password: password)
                saveSession(user: userProfile, method: "email")
                return true
            } catch {
                self.authErrorMessage = error.localizedDescription
                return false
            }
        } else {
            // Local fallback simulation when Supabase anon key is dummy
            try? await Task.sleep(nanoseconds: 350_000_000)
            let nameFromEmail = trimmedEmail.components(separatedBy: "@").first?.capitalized ?? "Neighbor"
            let profile = UserProfile(
                id: UUID(),
                name: nameFromEmail,
                email: trimmedEmail,
                initials: String(nameFromEmail.prefix(2)).uppercased(),
                neighborhood: "Colombo, Sri Lanka",
                memberSince: "Neighbor since 2026",
                isIdVerified: true,
                trustScore: 92,
                trustScoreSubtitle: "Verified Member",
                communityRating: 5.0,
                reviewCount: 1,
                totalBorrows: 0,
                totalLends: 0,
                wasteAvoidedKg: 0.0,
                totalMoneySaved: 0.0,
                monthlySavings: [
                    MonthlySaving(month: "Current", amountSaved: 0.0, isCurrentMonth: true)
                ]
            )
            saveSession(user: profile, method: "email")
            return true
        }
    }
    
    // MARK: - Create Account / Sign Up
    public func signUp(
        name: String,
        email: String,
        password: String,
        neighborhood: String,
        phone: String,
        enableFaceID: Bool
    ) async -> Bool {
        isAuthenticating = true
        authErrorMessage = nil
        defer { isAuthenticating = false }
        
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedName.isEmpty else {
            authErrorMessage = "Please enter your full name."
            return false
        }
        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
            authErrorMessage = "Please enter a valid email address."
            return false
        }
        guard password.count >= 4 else {
            authErrorMessage = "Password must be at least 4 characters."
            return false
        }
        
        if enableFaceID {
            let bioSuccess = await authenticateWithBiometrics(reason: "Register Face ID for quick login to BorrowIt")
            self.faceIDEnabledForAccount = bioSuccess
        }
        
        let parts = trimmedName.split(separator: " ")
        let initials: String
        if parts.count >= 2 {
            initials = "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        } else if let first = parts.first {
            initials = String(first.prefix(2)).uppercased()
        } else {
            initials = "U"
        }
        
        if AppConfig.isSupabaseConfigured {
            do {
                let userProfile = try await SupabaseService.shared.signUp(
                    email: trimmedEmail,
                    password: password,
                    name: trimmedName,
                    neighborhood: neighborhood.isEmpty ? "Cedar Grove" : neighborhood,
                    initials: initials
                )
                saveSession(user: userProfile, method: "email")
                return true
            } catch {
                self.authErrorMessage = error.localizedDescription
                return false
            }
        } else {
            try? await Task.sleep(nanoseconds: 350_000_000)
            let newUser = UserProfile(
                id: UUID(),
                name: trimmedName,
                email: trimmedEmail.lowercased(),
                initials: initials,
                neighborhood: neighborhood.isEmpty ? "Colombo, Sri Lanka" : neighborhood,
                memberSince: "Neighbor since 2026",
                isIdVerified: true,
                trustScore: 95,
                trustScoreSubtitle: "New neighbor · ID verified",
                communityRating: 5.0,
                reviewCount: 0,
                totalBorrows: 0,
                totalLends: 0,
                wasteAvoidedKg: 0.0,
                totalMoneySaved: 0.0,
                monthlySavings: [
                    MonthlySaving(month: "Current", amountSaved: 0.0, isCurrentMonth: true)
                ]
            )
            saveSession(user: newUser, method: "email")
            return true
        }
    }
    
    public func authenticateWithBiometrics(reason: String = "Unlock BorrowIt") async -> Bool {
        let result = await biometricService.authenticate(reason: reason)
        switch result {
        case .success(let success):
            return success
        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == LAErrorDomain && (nsError.code == LAError.userCancel.rawValue || nsError.code == LAError.appCancel.rawValue) {
                return false
            }
            self.authErrorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Sign Out & Clear Session
    public func signOut() {
        Task {
            await SupabaseService.shared.signOut()
        }
        UserDefaults.standard.removeObject(forKey: authStateKey)
        UserDefaults.standard.removeObject(forKey: authMethodKey)
        self.isAuthenticated = false
        self.authErrorMessage = nil
        self.currentUser = UserProfile.currentUser
    }
    
    // Quick Demo Mode Helper
    public func signInAsAlexMorgan() {
        saveSession(user: UserProfile.currentUser, method: "demo")
    }
    
    // Refresh User Profile from Supabase Cloud
    public func refreshUserProfile() async {
        if let fresh = try? await backendService.fetchUserProfile() {
            self.currentUser = fresh
            if let encoded = try? JSONEncoder().encode(fresh) {
                UserDefaults.standard.set(encoded, forKey: userDefaultsProfileKey)
            }
        }
    }
    
    // Update Profile Photo
    public func updateProfilePhoto(data: Data) {
        var updated = currentUser
        updated.avatarImageData = data
        let filename = "avatar_\(currentUser.id.uuidString).jpg"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        try? data.write(to: fileURL)
        updated.avatarImageURL = fileURL.absoluteString
        self.currentUser = updated
        if let encoded = try? JSONEncoder().encode(updated) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsProfileKey)
        }
        
        Task {
            try? await backendService.updateUserProfile(updated)
        }
    }
}
