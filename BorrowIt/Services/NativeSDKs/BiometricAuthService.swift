import Foundation
import LocalAuthentication

// MARK: - Biometric Authentication Service (Face ID / Touch ID)
public class BiometricAuthService: BiometricServiceProtocol {
    public static let shared = BiometricAuthService()
    
    public init() {}
    
    public var isBiometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    public var biometricTypeString: String {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .none: return "None"
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            @unknown default: return "Biometrics"
            }
        }
        return "Face ID" // Default display for HIG & Simulator
    }
    
    public func authenticate(reason: String) async -> Result<Bool, Error> {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        var authError: NSError?
        // 1. Evaluate genuine biometrics (Face ID / Touch ID)
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reason
                )
                return .success(success)
            } catch {
                return .failure(error)
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
            // 2. Passcode fallback if biometrics not enrolled
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: reason
                )
                return .success(success)
            } catch {
                return .failure(error)
            }
        } else {
            // 3. Neither biometrics nor passcode enrolled
            let err = authError ?? NSError(
                domain: LAErrorDomain,
                code: LAError.biometryNotEnrolled.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Face ID is not enrolled. Enable in Simulator menu: Features > Face ID > Enrolled."]
            )
            return .failure(err)
        }
    }
}
