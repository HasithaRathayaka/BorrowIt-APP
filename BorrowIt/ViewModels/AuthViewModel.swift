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
        try? await Task.sleep(nanoseconds: 350_000_000)
        isAuthenticating = false
        
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            authErrorMessage = "Please enter your email address."
            return false
        }
        guard password.count >= 4 else {
            authErrorMessage = "Password must be at least 4 characters."
            return false
        }
        
        // If email matches current user, keep profile; otherwise create profile for this email
        if !currentUser.email.lowercased().contains(email.lowercased()) {
            let nameFromEmail = email.components(separatedBy: "@").first?.capitalized ?? "Neighbor"
            self.currentUser = UserProfile(
                id: UUID(),
                name: nameFromEmail,
                email: email,
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
        
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            authErrorMessage = "Please enter your full name."
            isAuthenticating = false
            return false
        }
        guard email.contains("@") && email.contains(".") else {
            authErrorMessage = "Please enter a valid email address."
            isAuthenticating = false
            return false
        }
        guard password.count >= 4 else {
            authErrorMessage = "Password must be at least 4 characters."
            isAuthenticating = false
            return false
        }
        
        // Optional Face ID enrollment on registration
        if enableFaceID {
            let bioSuccess = await authenticateWithBiometrics(reason: "Register Face ID for quick login to BorrowIt")
            self.faceIDEnabledForAccount = bioSuccess
        }
        
        try? await Task.sleep(nanoseconds: 350_000_000)
        
        // Generate clean initials
        let parts = name.split(separator: " ")
        let initials: String
        if parts.count >= 2 {
            initials = "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        } else if let first = parts.first {
            initials = String(first.prefix(2)).uppercased()
        } else {
            initials = "U"
        }
        
        let newUser = UserProfile(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces).lowercased(),
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
        self.isAuthenticating = false
        return true
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
