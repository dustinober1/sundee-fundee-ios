import SundeeFundeeKit
import SwiftUI
import WidgetKit

// MARK: - ReadinessEntry

struct ReadinessEntry: TimelineEntry {
    let date: Date
    let snapshot: DailyReadinessSnapshot?
}

// MARK: - Provider

struct ReadinessProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReadinessEntry {
        ReadinessEntry(
            date: Date(),
            snapshot: DailyReadinessSnapshot(
                stateRaw: "maintain",
                totalScore: 68,
                confidenceRaw: "medium",
                modelVersion: "readiness-v1",
                assessmentDate: Date(),
                capturedAt: Date()
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadinessEntry) -> Void) {
        completion(ReadinessEntry(date: Date(), snapshot: SharedSnapshotStore.readReadiness()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadinessEntry>) -> Void) {
        let now = Date()
        let entry = ReadinessEntry(date: now, snapshot: SharedSnapshotStore.readReadiness())
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

// MARK: - View

struct ReadinessWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ReadinessEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            accessoryCircular
        case .accessoryRectangular:
            accessoryRectangular
        default:
            systemSmall
        }
    }

    private var systemSmall: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Readiness")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let snapshot = entry.snapshot, !isStale(snapshot) {
                Text("\(snapshot.totalScore)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.recoveryColor(for: snapshot.totalScore))
                Text(stateTitle(snapshot.stateRaw))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
            } else {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(entry.snapshot == nil ? "No data yet" : "Stale")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text(freshnessText(capturedAt: entry.snapshot?.capturedAt))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(for: .widget) { AppTheme.Background.cream }
        .widgetURL(DeepLinkRouter.url(for: .readinessDetail))
    }

    private var accessoryCircular: some View {
        VStack(spacing: 0) {
            Text("RDY")
                .font(.caption2.bold())
            if let snapshot = entry.snapshot, !isStale(snapshot) {
                Text("\(snapshot.totalScore)")
                    .font(.caption.bold())
            } else {
                Text("--")
                    .font(.caption.bold())
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(DeepLinkRouter.url(for: .readinessDetail))
    }

    private var accessoryRectangular: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Readiness")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let snapshot = entry.snapshot, !isStale(snapshot) {
                    Text(stateTitle(snapshot.stateRaw))
                        .font(.headline)
                        .lineLimit(1)
                } else {
                    Text(entry.snapshot == nil ? "No data yet" : "Open app to refresh")
                        .font(.subheadline)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 4)
            if let snapshot = entry.snapshot, !isStale(snapshot) {
                Text("\(snapshot.totalScore)")
                    .font(.title2.bold())
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(DeepLinkRouter.url(for: .readinessDetail))
    }

    // MARK: - Helpers

    private func isStale(_ snapshot: DailyReadinessSnapshot) -> Bool {
        let hours = Calendar.current.dateComponents([.hour], from: snapshot.capturedAt, to: Date()).hour ?? 0
        return hours >= 24
    }

    private func stateTitle(_ stateRaw: String) -> String {
        switch stateRaw {
        case "ready": return "Ready"
        case "maintain": return "Maintain"
        case "recover": return "Recover"
        case "rest": return "Rest"
        default: return "--"
        }
    }

    private func freshnessText(capturedAt: Date?) -> String {
        guard let capturedAt else { return "Open app to update" }
        let hours = Calendar.current.dateComponents([.hour], from: capturedAt, to: Date()).hour ?? 0
        if hours >= 24 { return "Open app to refresh" }
        return "Updated \(capturedAt.formatted(.relative(presentation: .numeric)))"
    }
}

// MARK: - Widget

struct ReadinessWidget: Widget {
    let kind: String = "ReadinessWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadinessProvider()) { entry in
            ReadinessWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Readiness")
        .description("Today's readiness score and state.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}
