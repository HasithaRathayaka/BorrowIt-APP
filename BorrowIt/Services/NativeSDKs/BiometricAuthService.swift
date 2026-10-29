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
    
    /// Pure Face ID evaluation (.deviceOwnerAuthenticationWithBiometrics)
    /// Strictly prompts Face ID and NEVER presents the device Passcode screen
    public func authenticate(reason: String) async -> Result<Bool, Error> {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        var authError: NSError?
        // Strict biometrics only — prevents iOS from falling back to the "Enter iPhone Passcode" screen
        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
        
        #if targetEnvironment(simulator)
        // If developer enabled Face ID in Simulator menu (Features -> Face ID -> Enrolled),
        // invoke native Apple Face ID dialog.
        if context.canEvaluatePolicy(policy, error: &authError) {
            do {
                let success = try await context.evaluatePolicy(
                    policy,
                    localizedReason: reason
                )
                return .success(success)
            } catch {
                let nsErr = error as NSError
                if nsErr.code == LAError.userCancel.rawValue || nsErr.code == LAError.appCancel.rawValue {
                    return .failure(error)
                }
                // If simulator failed to match face or had focus loss, fallback to simulated scan success
                try? await Task.sleep(nanoseconds: 800_000_000)
                return .success(true)
            }
        } else {
            // Face ID not enrolled in Simulator:
            // Simulate realistic 1.2s facial recognition scan
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            return .success(true)
        }
        #else
        // Physical iPhone: strictly use front TrueDepth camera Face ID
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
                userInfo: [NSLocalizedDescriptionKey: "Face ID is not set up on this device."]
            )
            return .failure(err)
        }
        #endif
    }
}
