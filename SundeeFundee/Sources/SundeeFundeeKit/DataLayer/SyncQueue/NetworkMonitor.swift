import Foundation

#if canImport(Network)
import Network
#endif

/// Monitors network connectivity changes using NWPathMonitor.
///
/// On iOS, uses NWPathMonitor from the Network framework to detect
/// when connectivity becomes available. On platforms where Network
/// is unavailable, always reports as connected (no offline support).
///
/// Connectivity changes are published via an AsyncStream that consumers
/// can subscribe to for triggering actions like queue flush.
public actor NetworkMonitor: Sendable {

    // MARK: - Properties

    /// Whether the device currently has network connectivity.
    public private(set) var isConnected: Bool = true

    /// Async stream of connectivity state changes.
    /// Consumers subscribe to receive updates when connectivity changes.
    public let connectivityChanges: AsyncStream<Bool>

    private let continuation: AsyncStream<Bool>.Continuation

    #if canImport(Network)
    private var monitor: NWPathMonitor?
    #endif

    // MARK: - Initialization

    public init() {
        let (stream, continuation) = AsyncStream<Bool>.makeStream()
        self.connectivityChanges = stream
        self.continuation = continuation

        #if canImport(Network)
        Task { [weak self] in
            await self?.startMonitoring()
        }
        #endif
    }

    deinit {
        #if canImport(Network)
        monitor?.cancel()
        #endif
        continuation.finish()
    }

    // MARK: - Testing Support

    /// Manually set connectivity state for testing.
    /// In production, this is driven by NWPathMonitor.
    public func setConnectedForTesting(_ connected: Bool) {
        let changed = isConnected != connected
        isConnected = connected
        if changed {
            continuation.yield(connected)
        }
    }

    #if canImport(Network)
    private func startMonitoring() {
        let monitor = NWPathMonitor()
        self.monitor = monitor

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { [weak self] in
                await self?.handlePathUpdate(path.status)
            }
        }

        monitor.start(queue: DispatchQueue(label: "com.sundeefundee.network-monitor", qos: .utility))
    }

    private func handlePathUpdate(_ status: NWPath.Status) {
        let connected = status == .satisfied
        let changed = isConnected != connected
        isConnected = connected
        if changed {
            continuation.yield(connected)
        }
    }
    #endif
}

