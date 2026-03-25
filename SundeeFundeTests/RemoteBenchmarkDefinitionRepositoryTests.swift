import Testing
import Foundation
@testable import SundeeFundee

@Suite("BundledBenchmarkDefinitionRepository")
struct BundledBenchmarkDefinitionRepositoryTests {

    @Test func fetchesFromBundledJSON() async throws {
        let repo = BundledBenchmarkDefinitionRepository()
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(!defs.isEmpty)
        #expect(defs.allSatisfy { $0.category == "Sundee Fundee" })
        #expect(defs.allSatisfy { $0.isPredefined == true })
        #expect(defs.allSatisfy { $0.userID == "" })
    }

    @Test func returnsEmptyForMissingBundle() async throws {
        let repo = BundledBenchmarkDefinitionRepository(bundle: .main, resourceName: "nonexistent")
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(defs.isEmpty)
    }

    @Test func cachesResults() async throws {
        let repo = BundledBenchmarkDefinitionRepository()
        let first = try await repo.fetchBenchmarkDefinitions()
        let second = try await repo.fetchBenchmarkDefinitions()
        #expect(first.count == second.count)
    }
}
