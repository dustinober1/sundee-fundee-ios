import Testing
import Foundation
@testable import SundeeFundeeKit

struct RemoteContentClientTests {

    @Test("Falls back to bundled when fetch fails")
    func testFallbackOnFetchFailure() async throws {
        let client = RemoteContentClient(
            baseURL: "http://localhost:1", // Will fail
            token: "test-token",
            cacheDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("test-content-\(UUID().uuidString)")
        )
        let benchmarks = try await client.fetchBenchmarks()
        #expect(!benchmarks.isEmpty)
        #expect(benchmarks.allSatisfy { $0.source == .bundled })
    }

    @Test("Returns cached content on second call")
    func testCaching() async throws {
        let cacheDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-cache-\(UUID().uuidString)")
        let client = RemoteContentClient(
            baseURL: "http://localhost:1",
            token: "test-token",
            cacheDirectory: cacheDir
        )
        let first = try await client.fetchBenchmarks()
        #expect(!first.isEmpty)
        let second = try await client.fetchBenchmarks()
        #expect(!second.isEmpty)
        try? FileManager.default.removeItem(at: cacheDir)
    }

    @Test("Remote content overlays bundled by ID")
    func testRemoteOverlay() async throws {
        let bundled = BundledContentProvider.benchmarks
        let remote = ContentBenchmark(
            id: bundled[0].id,
            name: "Updated Name",
            category: bundled[0].category,
            workoutDescription: "Updated",
            scoringType: "time",
            sortOrder: 0,
            source: .remote
        )
        let merged = RemoteContentClient.merge(bundled: bundled, remote: [remote])
        #expect(merged.count == bundled.count)
        #expect(merged.first { $0.id == bundled[0].id }?.name == "Updated Name")
        #expect(merged.first { $0.id == bundled[0].id }?.source == .remote)
    }

    @Test("Remote content adds new items alongside bundled")
    func testRemoteAddsNewItems() async throws {
        let bundled = BundledContentProvider.benchmarks
        let new = ContentBenchmark(
            id: "remote-new-1",
            name: "Brand New",
            category: "General Fitness",
            workoutDescription: "New benchmark",
            scoringType: "reps",
            sortOrder: 99,
            source: .remote
        )
        let merged = RemoteContentClient.merge(bundled: bundled, remote: [new])
        #expect(merged.count == bundled.count + 1)
        #expect(merged.contains { $0.id == "remote-new-1" })
    }
}
