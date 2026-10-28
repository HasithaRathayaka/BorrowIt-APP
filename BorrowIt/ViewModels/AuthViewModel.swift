import SwiftUI
import Combine

// MARK: - Auth ViewModel
@MainActor
public class AuthViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false // False so new users see Sign In / Sign Up
    @Published public var currentUser: UserProfile = .currentUser
    @Published public var authErrorMessage: String? = nil
    @Published public var isAuthenticating: Bool = false
    @Published public var faceIDEnabledForAccount: Bool = true
    
    private let biometricService: BiometricServiceProtocol
    private let backendService: BackendServiceProtocol
    
    public init(
        biometricService: BiometricServiceProtocol = BiometricAuthService.shared,
        backendService: BackendServiceProtocol = SupabaseService.shared
    ) {
        self.biometricService = biometricService
        self.backendService = backendService
    }
    
    // MARK: - Sign In with Face ID (Biometrics)
    public func signInWithFaceID() async -> Bool {
        isAuthenticating = true
        authErrorMessage = nil
        
        let success = await authenticateWithBiometrics(reason: "Sign in with Face ID to BorrowIt")
        isAuthenticating = false
        if success {
            self.isAuthenticated = true
            return true
        } else {
            if self.authErrorMessage == nil {
                self.authErrorMessage = "Face ID verification was not successful. Please try again or use your password."
            }
            return false
        }
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
                self.currentUser = userProfile
                self.isAuthenticated = true
                return true
            } catch {
                self.authErrorMessage = error.localizedDescription
                return false
            }
        } else {
            // Local fallback simulation when Supabase anon key is dummy
            try? await Task.sleep(nanoseconds: 350_000_000)
            if !currentUser.email.lowercased().contains(trimmedEmail.lowercased()) {
                let nameFromEmail = trimmedEmail.components(separatedBy: "@").first?.capitalized ?? "Neighbor"
                self.currentUser = UserProfile(
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
            }
            self.isAuthenticated = true
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
        
        // Optional Face ID enrollment on registration
        if enableFaceID {
            let bioSuccess = await authenticateWithBiometrics(reason: "Register Face ID for quick login to BorrowIt")
            self.faceIDEnabledForAccount = bioSuccess
        }
        
        // Generate clean initials
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
                self.currentUser = userProfile
                self.isAuthenticated = true
                return true
            } catch {
                self.authErrorMessage = error.localizedDescription
                return false
            }
        } else {
            // Local fallback simulation
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
            
            self.currentUser = newUser
            self.isAuthenticated = true
            return true
        }
    }
    
    public func signInWithApple() async {
        isAuthenticating = true
        try? await Task.sleep(nanoseconds: 400_000_000)
        self.isAuthenticated = true
        self.isAuthenticating = false
    }
    
    public func authenticateWithBiometrics(reason: String = "Unlock BorrowIt") async -> Bool {
        let result = await biometricService.authenticate(reason: reason)
        switch result {
        case .success(let success):
            return success
        case .failure(let error):
            self.authErrorMessage = error.localizedDescription
            return false
        }
    }
    
    public func signOut() {
        Task {
            await SupabaseService.shared.signOut()
        }
        self.isAuthenticated = false
        self.authErrorMessage = nil
    }
    
    // Quick Demo Mode Helper
    public func signInAsAlexMorgan() {
        self.currentUser = UserProfile.currentUser
        self.isAuthenticated = true
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
    }
}
