import Foundation
import WidgetKit

// MARK: - SharedSnapshotProvider

/// Generic `TimelineProvider` for snapshot-backed widgets.
///
/// The cycle-phase, readiness, and next-workout widgets differ only in
/// their entry type, placeholder payload, and which `SharedSnapshotStore`
/// reader feeds the timeline. This provider keeps that plumbing in one
/// place; each widget passes two closures into `StaticConfiguration` and
/// drops its hand-rolled provider struct.
///
/// Timeline behavior matches the per-widget providers it replaces: a
/// single entry for "now", refreshed one hour later (with the fixed
/// interval as the fallback when calendar math fails).
public struct SharedSnapshotProvider<Entry: TimelineEntry>: TimelineProvider {
    /// Sample data for placeholder rendering (widget gallery, previews).
    private let makePlaceholder: @Sendable () -> Entry
    /// Builds the real entry; receives the timeline's anchor date.
    private let makeEntry: @Sendable (Date) -> Entry
    private let refreshInterval: TimeInterval

    public init(
        refreshInterval: TimeInterval = 3600,
        makePlaceholder: @escaping @Sendable () -> Entry,
        makeEntry: @escaping @Sendable (Date) -> Entry
    ) {
        self.refreshInterval = refreshInterval
        self.makePlaceholder = makePlaceholder
        self.makeEntry = makeEntry
    }

    public func placeholder(in context: Context) -> Entry {
        makePlaceholder()
    }

    public func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(makeEntry(Date()))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let now = Date()
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: now)
            ?? now.addingTimeInterval(refreshInterval)
        completion(Timeline(entries: [makeEntry(now)], policy: .after(refresh)))
    }
}
