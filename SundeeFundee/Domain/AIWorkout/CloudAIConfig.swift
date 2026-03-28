import Foundation
import CryptoKit

enum CloudAIConfig {

    static let workerURL = "https://ai-coach.sundeefundee.workers.dev/generate-workout"

    // Shared secret matching the Cloudflare Worker's JWT_SECRET.
    // Rotatable via `wrangler secret put JWT_SECRET` if compromised.
    private static let jwtSecret = "sundee-fundee-ai-coach-shared-secret-v1"

    struct JwtPayload: Codable {
        let sub: String
        let tier: String
        let iat: Int
    }

    static func createJwt(userID: String, tier: SubscriptionTier) async throws -> String {
        let tierString: String = switch tier {
        case .plus: "plus"
        case .premium: "premium"
        case .free: "free"
        }

        let payload = JwtPayload(
            sub: userID,
            tier: tierString,
            iat: Int(Date().timeIntervalSince1970)
        )

        let header = #"{"alg":"HS256","typ":"JWT"}"#
        let headerB64 = base64UrlEncode(Data(header.utf8))
        let payloadData = try JSONEncoder().encode(payload)
        let payloadB64 = base64UrlEncode(payloadData)

        let signingInput = "\(headerB64).\(payloadB64)"
        let key = SymmetricKey(data: Data(jwtSecret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(signingInput.utf8), using: key)
        let signatureB64 = base64UrlEncode(Data(signature))

        return "\(headerB64).\(payloadB64).\(signatureB64)"
    }

    // MARK: - Base64URL Helpers (internal for testing)

    static func base64UrlEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func base64UrlDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: base64)
    }

    static func decodePayload(_ token: String) throws -> JwtPayload {
        let parts = token.split(separator: ".")
        guard parts.count == 3, let data = base64UrlDecode(String(parts[1])) else {
            throw AIWorkoutServiceError.decodingFailed
        }
        return try JSONDecoder().decode(JwtPayload.self, from: data)
    }
}
