import Foundation

/// Handles Sign in with Apple token exchange and revocation via server-side Cloud Functions.
///
/// The authorization code from Apple expires in ~5 minutes, so it must be exchanged
/// for a refresh token immediately after sign-in. The refresh token is then stored
/// in the keychain and used during account deletion to revoke the SIWA credential.
enum SIWATokenService {

    // MARK: - Configuration

    /// Base URL for Firebase Cloud Functions.
    /// Update this to your deployed function URL after running `firebase deploy --only functions`.
    private static let exchangeURL = URL(string: "https://us-central1-sundee-fundee.cloudfunctions.net/siwaExchangeCode")!
    private static let revokeURL = URL(string: "https://us-central1-sundee-fundee.cloudfunctions.net/siwaRevokeToken")!

    // MARK: - Public

    /// Exchange an authorization code for a refresh token and save it to the keychain.
    /// Call this immediately after a successful Sign in with Apple.
    static func exchangeCodeForRefreshToken(_ authorizationCode: String) async {
        do {
            let body = try JSONEncoder().encode(["authorizationCode": authorizationCode])
            var request = URLRequest(url: exchangeURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("[SIWAToken] Exchange failed: non-200 status")
                return
            }

            let decoded = try JSONDecoder().decode(ExchangeResponse.self, from: data)
            KeychainHelper.saveSIWARefreshToken(decoded.refreshToken)
            // Auth code is no longer needed after successful exchange.
            KeychainHelper.deleteAuthorizationCode()
            print("[SIWAToken] Refresh token saved successfully")
        } catch {
            print("[SIWAToken] Exchange error: \(error.localizedDescription)")
        }
    }

    /// Revoke the stored SIWA refresh token. Call during account deletion.
    /// Returns `true` if revocation succeeded or no token was stored.
    @discardableResult
    static func revokeRefreshToken() async -> Bool {
        guard let refreshToken = KeychainHelper.loadSIWARefreshToken() else {
            print("[SIWAToken] No refresh token to revoke")
            return true
        }

        do {
            let body = try JSONEncoder().encode(["refreshToken": refreshToken])
            var request = URLRequest(url: revokeURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("[SIWAToken] Revocation failed: non-200 status")
                return false
            }

            KeychainHelper.deleteSIWARefreshToken()
            print("[SIWAToken] Token revoked successfully")
            return true
        } catch {
            print("[SIWAToken] Revocation error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Response Types

    private struct ExchangeResponse: Decodable {
        let refreshToken: String
    }
}
