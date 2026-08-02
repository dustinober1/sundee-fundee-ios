import Foundation
#if os(iOS)
import UIKit
#endif

/// Debug helper to reset onboarding and feature tour state for testing
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct OnboardingResetHelper {
    
    /// Call this to reset all onboarding and tour flags (for testing only!)
    static func resetForTesting() {
        // Clear onboarding completion
        _ = KeychainHelper.delete(key: "onboarding_complete")
        
        // Clear feature tour completion
        _ = KeychainHelper.delete(key: "feature_tour_complete")
        
        // Clear user authentication (forces re-login)
        _ = KeychainHelper.delete(key: KeychainHelper.userIDKey)
        _ = KeychainHelper.delete(key: KeychainHelper.userEmailKey)
        _ = KeychainHelper.delete(key: KeychainHelper.userNameKey)
        
        print("✅ Onboarding state reset for testing")
    }
    
    /// Reset only the feature tour (to re-watch it)
    static func resetFeatureTour() {
        _ = KeychainHelper.delete(key: "feature_tour_complete")
        print("✅ Feature tour reset - it will show again after onboarding")
    }
    
    /// Reset only onboarding (will show onboarding + tour)
    static func resetOnboarding() {
        _ = KeychainHelper.delete(key: "onboarding_complete")
        _ = KeychainHelper.delete(key: "feature_tour_complete")
        print("✅ Onboarding reset - will show onboarding flow again")
    }
}

#if DEBUG
extension OnboardingResetHelper {
    /// Add a shake gesture to reset (iOS only, for testing)
    #if os(iOS)
    static func setupShakeToReset() {
        // You can call this from App.swift to enable shake-to-reset during development
        NotificationCenter.default.addObserver(
            forName: UIDevice.deviceDidShakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            resetForTesting()
        }
    }
    #endif
}

// Extension to detect shake gesture
#if os(iOS) && DEBUG
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}
#endif
#endif
