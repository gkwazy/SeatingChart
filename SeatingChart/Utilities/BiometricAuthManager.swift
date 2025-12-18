//
//  BiometricAuthManager.swift
//  SeatingChart
//
//  Manages biometric authentication (Face ID/Touch ID) with passcode fallback
//  for secure features like editing past attendance records.
//

import Foundation
import LocalAuthentication

/// Handles biometric and passcode authentication for secure features
@MainActor
final class BiometricAuthManager: ObservableObject {

    static let shared = BiometricAuthManager()

    /// The type of biometric authentication available on the device
    enum BiometricType {
        case faceID
        case touchID
        case none
    }

    /// Result of authentication attempt
    enum AuthResult {
        case success
        case failure(Error)
        case cancelled
    }

    /// Published state for UI binding
    @Published private(set) var isAuthenticated = false
    @Published private(set) var authError: String?

    private init() {}

    /// Returns the type of biometric authentication available on the device
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .faceID // Treat opticID (Vision Pro) like Face ID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    /// Whether any form of device authentication is available (biometric or passcode)
    var canAuthenticate: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    /// Human-readable name for the biometric type
    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "Passcode"
        }
    }

    /// SF Symbol for the biometric type
    var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock.fill"
        }
    }

    /// Authenticates the user with biometrics (Face ID/Touch ID) with passcode fallback
    /// - Parameters:
    ///   - reason: The reason displayed to the user for authentication
    ///   - completion: Callback with the authentication result
    func authenticate(reason: String, completion: @escaping (AuthResult) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        var error: NSError?

        // Use deviceOwnerAuthentication for biometric + passcode fallback
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            authError = error?.localizedDescription ?? "Authentication not available"
            completion(.failure(error ?? NSError(domain: "BiometricAuth", code: -1)))
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, authenticationError in
            Task { @MainActor in
                if success {
                    self?.isAuthenticated = true
                    self?.authError = nil
                    completion(.success)
                } else if let error = authenticationError as? LAError {
                    self?.isAuthenticated = false

                    switch error.code {
                    case .userCancel, .appCancel, .systemCancel:
                        self?.authError = nil
                        completion(.cancelled)
                    default:
                        self?.authError = error.localizedDescription
                        completion(.failure(error))
                    }
                } else if let error = authenticationError {
                    self?.isAuthenticated = false
                    self?.authError = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    /// Async version of authenticate
    /// - Parameter reason: The reason displayed to the user for authentication
    /// - Returns: The authentication result
    func authenticate(reason: String) async -> AuthResult {
        await withCheckedContinuation { continuation in
            authenticate(reason: reason) { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// Resets authentication state (user must re-authenticate)
    func resetAuthentication() {
        isAuthenticated = false
        authError = nil
    }
}
