import Foundation

/// Loads and caches training programs from bundled JSON files.
final class ProgramRepository {
    static let shared = ProgramRepository()

    private var cache: [ProgramV2] = []

    private init() {}

    func loadAll() -> [ProgramV2] {
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

    func find(byId id: String) -> ProgramV2? {
        loadAll().first { $0.id == id }
    }

    func filter(byCategory category: String) -> [ProgramV2] {
        loadAll().filter { $0.category == category }
    }

    func categories() -> [String] {
        Array(Set(loadAll().map(\.category))).sorted()
    }
}
