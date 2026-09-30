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
                stateRaw: "ready",
                totalScore: 84,
                confidenceRaw: "high",
                modelVersion: "1.0",
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
        case .accessoryInline:
            accessoryInline
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
                Text(stateTitle)
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
        Gauge(value: Double(entry.snapshot?.totalScore ?? 0), in: 0...100) {
            Image(systemName: "bolt.heart.fill")
        } currentValueLabel: {
            Text(entry.snapshot.map { "\($0.totalScore)" } ?? "--")
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(stateColor)
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(DeepLinkRouter.url(for: .readinessDetail))
    }

    private var accessoryInline: some View {
        ViewThatFits {
            Label("Readiness: \(scoreString) • \(stateTitle)", systemImage: "bolt.heart.fill")
            Label("\(scoreString) • \(stateTitle)", systemImage: "bolt.heart.fill")
            Text("RDY \(scoreString)")
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(DeepLinkRouter.url(for: .readinessDetail))
    }

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "bolt.heart.fill")
                    .foregroundStyle(stateColor)
                Text("READINESS")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(scoreString)
                    .font(.headline.bold())
                    .foregroundStyle(stateColor)
            }
            Text(stateTitle)
                .font(.subheadline.bold())
            Text(guidanceSummary)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(DeepLinkRouter.url(for: .readinessDetail))
    }

    // MARK: - Helpers

    private var scoreString: String {
        entry.snapshot.map { "\($0.totalScore)" } ?? "--"
    }

    private var stateTitle: String {
        switch entry.snapshot?.stateRaw {
        case "ready", "primed": return "Primed"
        case "maintain", "steady": return "Steady"
        case "recover", "recovering": return "Recovering"
        case "rest": return "Rest"
        default: return "Check In"
        }
    }

    private var stateColor: Color {
        guard let snapshot = entry.snapshot else { return .secondary }
        return AppTheme.recoveryColor(for: snapshot.totalScore)
    }

    private var guidanceSummary: String {
        switch entry.snapshot?.stateRaw {
        case "ready", "primed": return "Full capacity for high intensity"
        case "maintain", "steady": return "Solid capacity for baseline load"
        case "recover", "recovering": return "Active recovery or rest advised"
        case "rest": return "Full rest advised today"
        default: return "Open app to assess readiness"
        }
    }

    private func isStale(_ snapshot: DailyReadinessSnapshot) -> Bool {
        let hours = Calendar.current.dateComponents([.hour], from: snapshot.capturedAt, to: Date()).hour ?? 0
        return hours >= 24
    }

    private func freshnessText(capturedAt: Date?) -> String {
        guard let capturedAt else { return "Open app to assess" }
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
        .configurationDisplayName("Daily Readiness")
        .description("Daily recovery score and training readiness.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}
