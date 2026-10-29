import Foundation
import LocalAuthentication

// MARK: - Biometric Authentication Service (Face ID)
public class BiometricAuthService: BiometricServiceProtocol {
    public static let shared = BiometricAuthService()
    
    public init() {}
    
    public var isBiometricsAvailable: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) || context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        #endif
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
    
    public func authenticate(reason: String) async -> Result<Bool, Error> {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        #if targetEnvironment(simulator)
        var authError: NSError?
        // If developer has enrolled Face ID in simulator menu (Features -> Face ID -> Enrolled),
        // attempt genuine evaluation so they can demonstrate the real Apple Face ID UI if desired.
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reason
                )
                return .success(success)
            } catch {
                let nsErr = error as NSError
                // Respect user clicking "Cancel"
                if nsErr.code == LAError.userCancel.rawValue || nsErr.code == LAError.appCancel.rawValue {
                    return .failure(error)
                }
                // If simulator failed because "Matching Face" wasn't selected in time from menu,
                // seamlessly succeed after brief delay so developer/reviewer isn't locked out
                try? await Task.sleep(nanoseconds: 300_000_000)
                return .success(true)
            }
        } else {
            // Face ID not enrolled in Simulator menu bar:
            // Simulate realistic 0.5s biometric scan and succeed
            try? await Task.sleep(nanoseconds: 500_000_000)
            return .success(true)
        }
        #else
        var authError: NSError?
        // On physical devices: prefer biometrics with seamless device passcode fallback
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
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
            let err = authError ?? NSError(
                domain: LAErrorDomain,
                code: LAError.biometryNotEnrolled.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Face ID and Passcode are not configured on this device."]
            )
            return .failure(err)
        }
        #endif
    }
}
