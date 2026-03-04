import Foundation
import AuthenticationServices
import Security

/// Persists the current Apple user ID in the Keychain so it survives app reinstalls.
enum KeychainHelper {
    private static let service = "com.sundeefundee.app"
    private static let appleUserIDKey = "appleUserID"

    static func saveAppleUserID(_ userID: String) {
        let data = Data(userID.utf8)

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: appleUserIDKey,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Explicitly define kSecAttrAccessible to avoid falling back to insecure OS defaults.
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: appleUserIDKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func loadAppleUserID() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: appleUserIDKey,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let id = String(data: data, encoding: .utf8)
        else { return nil }
        return id
    }

    static func deleteAppleUserID() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: appleUserIDKey,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
