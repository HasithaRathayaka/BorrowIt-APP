import Foundation
import LocalAuthentication

// MARK: - Biometric Authentication Service (Face ID)
public class BiometricAuthService: BiometricServiceProtocol {
    public static let shared = BiometricAuthService()
    
    public init() {}
    
    public var isBiometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) || context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
    
    public var biometricTypeString: String {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .none: return "Face ID"
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            @unknown default: return "Face ID"
            }
        }
        return "Face ID"
    }
    
    /// Native Apple LocalAuthentication evaluation (Standard Apple Face ID with Passcode fallback)
    public func authenticate(reason: String) async -> Result<Bool, Error> {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        var authError: NSError?
        // Primary policy: Face ID first with native Passcode fallback
        let policy: LAPolicy = .deviceOwnerAuthentication
        
        if context.canEvaluatePolicy(policy, error: &authError) {
            do {
                let success = try await context.evaluatePolicy(
                    policy,
                    localizedReason: reason
                )
                return .success(success)
            } catch {
                return .failure(error)
            }
        } else {
            let err = authError ?? NSError(
                domain: LAErrorDomain,
                code: LAError.biometryNotEnrolled.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Face ID is not enrolled. In Simulator top menu bar, select Features → Face ID → Enrolled."]
            )
            return .failure(err)
        }
    }
}
