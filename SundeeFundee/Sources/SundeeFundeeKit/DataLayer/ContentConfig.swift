import Foundation

/// Configuration for remote content client
public struct ContentConfig: Sendable {
    /// Teenybase API base URL
    public static var baseURL: String {
        return "http://localhost:8787"
    }

    /// Admin auth token for Teenybase API
    public static var adminToken: String {
        return "password_for_accessing_the_backend_as_admin"
    }

    /// Directory for caching content JSON files
    public static var cacheDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ContentCache")
    }
}
