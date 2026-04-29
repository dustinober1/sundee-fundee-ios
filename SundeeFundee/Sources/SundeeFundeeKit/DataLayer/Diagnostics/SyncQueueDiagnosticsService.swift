import Foundation

// MARK: - SyncQueueDiagnosticsService

/// Exposes queue health for Settings so users can see when writes are stuck.
@MainActor
public final class SyncQueueDiagnosticsService: ObservableObject {
    public static let shared = SyncQueueDiagnosticsService()

    @Published public private(set) var pendingCount: Int = 0
    @Published public private(set) var stuckCount: Int = 0
    @Published public private(set) var lastFlushError: String?

    private weak var queue: SyncQueue?
    private var pollTask: Task<Void, Never>?

    private init() {}

    public func attach(_ queue: SyncQueue?) {
        self.queue = queue
        pollTask?.cancel()
        guard queue != nil else {
            pendingCount = 0
            stuckCount = 0
            lastFlushError = nil
            return
        }

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    public func refresh() async {
        guard let queue else {
            pendingCount = 0
            stuckCount = 0
            lastFlushError = nil
            return
        }

        pendingCount = await queue.pendingCount
        stuckCount = await queue.stuckMutations.count
        lastFlushError = await queue.lastFlushError
    }
}
