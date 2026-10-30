import SwiftUI
import Combine
import AuthenticationServices
import LocalAuthentication

// Auth ViewModel
@MainActor
public class AuthViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: UserProfile = .currentUser
    @Published public var authErrorMessage: String? = nil
    @Published public var isAuthenticating: Bool = false
    @Published public var faceIDEnabledForAccount: Bool = true
    
    // Session Persistence Keys
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
        
        // Restore saved session if user previously logged in
        if UserDefaults.standard.bool(forKey: "borrowit_is_authenticated"),
           let data = UserDefaults.standard.data(forKey: "borrowit_saved_user_profile"),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentUser = saved
            self.isAuthenticated = true
        } else {
            self.isAuthenticated = false
        }
    }
    
    // Session Persistence Helpers
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
    
    // Sign In with Face ID (Biometrics)
    public func signInWithFaceID() async -> Bool {
        isAuthenticating = true
        authErrorMessage = nil
        defer { isAuthenticating = false }
        
        let reason = "Sign in to BorrowIt with Face ID"
        let result = await biometricService.authenticate(reason: reason)
        
        switch result {
        case .success(let success):
            if success {
                let user = loadSavedUser() ?? currentUser
                saveSession(user: user, method: "faceid")
                self.isAuthenticated = true
                self.authErrorMessage = nil
                return true
            } else {
                self.authErrorMessage = "Face ID not recognized. Please try again."
                return false
            }
        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == LAErrorDomain && (nsError.code == LAError.userCancel.rawValue || nsError.code == LAError.appCancel.rawValue) {
                // User pressed Cancel on Face ID prompt - stay on login dashboard cleanly
                self.authErrorMessage = nil
                return false
            } else if nsError.domain == LAErrorDomain && nsError.code == LAError.authenticationFailed.rawValue {
                // Face ID did not recognize - stay on login dashboard
                self.authErrorMessage = "Face ID not recognized. Please try again or use your password."
                return false
            } else if nsError.domain == LAErrorDomain && nsError.code == LAError.biometryNotEnrolled.rawValue {
                // Not enrolled in simulator
                self.authErrorMessage = "Face ID is not enrolled. In Simulator menu, choose Features → Face ID → Enrolled."
                return false
            } else {
                self.authErrorMessage = error.localizedDescription
                return false
            }
        }
    }
    
    // Sign In with Apple (AuthenticationServices)
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
                self.authErrorMessage = nil
                
                Task {
                    try? await SupabaseService.shared.updateUserProfile(appleProfile)
                }
            }
            
        case .failure(let error):
            let asError = error as? ASAuthorizationError
            if asError?.code == .canceled {
                // User closed the Apple ID sheet - stay on login dashboard
                self.authErrorMessage = nil
                return
            } else {
                self.authErrorMessage = "Apple Sign In was canceled or could not be completed."
            }
        }
    }
    
    // Sign In with Email and Password
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
    
    // Create Account / Sign Up
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
                    neighborhood: neighborhood.isEmpty ? "Colombo 07" : neighborhood,
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
            self.authErrorMessage = nil
            return success
        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == LAErrorDomain && (nsError.code == LAError.userCancel.rawValue || nsError.code == LAError.appCancel.rawValue) {
                self.authErrorMessage = "Face ID canceled. Tap button to scan."
                return false
            } else if nsError.domain == LAErrorDomain && (nsError.code == -8 /* userInteractionRequired */ || nsError.code == LAError.authenticationFailed.rawValue) {
                // Clear error silently so no red warning appears before user interaction
                self.authErrorMessage = nil
                return false
            }
            self.authErrorMessage = error.localizedDescription
            return false
        }
    }
    
    // Sign Out and Clear Session
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
