import Foundation

/// Loads and caches training programs from bundled JSON files and the CloudKit public database.
final class ProgramRepository {
    static let shared = ProgramRepository()

    private var cache: [ProgramV2] = []
    private var publicPrograms: [ProgramV2] = []

    private init() {}

    func loadAll() -> [ProgramV2] {
        let local = loadLocal()
        let publicIds = Set(publicPrograms.map(\.id))
        // Merge: public programs override/supplement local ones (deduplicated by id)
        let merged = local.filter { !publicIds.contains($0.id) } + publicPrograms
        return merged.sorted { $0.name < $1.name }
    }

    /// Fetches admin-pushed programs from CloudKit and merges them into results.
    func loadPublicPrograms() async {
        do {
            let fetched = try await CloudKitProgramService.shared.fetchPublicPrograms()
            await MainActor.run {
                publicPrograms = fetched
            }
        } catch {
            // Silently fall back — CloudKitProgramService returns cached copy if available
        }
    }

    func find(byId id: String) -> ProgramV2? {
        loadAll().first { $0.id == id }
    }

    func filter(byCategory category: String) -> [ProgramV2] {
        loadAll().filter { $0.category == category }
    }

    func categories() -> [String] {
        Array(Set(loadAll().map(\.category))).sorted()
    }

    /// Returns IDs of programs that came from the CloudKit public database.
    func publicProgramIds() -> Set<String> {
        Set(publicPrograms.map(\.id))
    }

    // MARK: - Private

    private func loadLocal() -> [ProgramV2] {
        if !cache.isEmpty { return cache }

        let decoder = JSONDecoder()
        var programs: [ProgramV2] = []

        guard let resourceURL = Bundle.main.resourceURL else { return [] }

        let programsURL = resourceURL.appendingPathComponent("Programs")
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: programsURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return [] }

        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let program = try? decoder.decode(ProgramV2.self, from: data) {
                programs.append(program)
            }
        }

        cache = programs.sorted { $0.name < $1.name }
        return cache
    }
}
