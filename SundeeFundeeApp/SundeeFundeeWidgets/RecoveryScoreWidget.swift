import SundeeFundeeKit
import SwiftUI
import WidgetKit

// MARK: - RecoveryScoreEntry

struct RecoveryScoreEntry: TimelineEntry {
    let date: Date
    let snapshot: RecoverySnapshot?
}

// MARK: - Provider

struct RecoveryScoreProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecoveryScoreEntry {
        RecoveryScoreEntry(
            date: Date(),
            snapshot: RecoverySnapshot(
                total: 78,
                recommendationRaw: "pushDay",
                capturedAt: Date(),
                presentInputCount: 5
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RecoveryScoreEntry) -> Void) {
        let entry = RecoveryScoreEntry(date: Date(), snapshot: SharedSnapshotStore.readRecovery())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecoveryScoreEntry>) -> Void) {
        let now = Date()
        let entry = RecoveryScoreEntry(date: now, snapshot: SharedSnapshotStore.readRecovery())
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

// MARK: - View

struct RecoveryScoreWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RecoveryScoreEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            accessoryCircular
        case .accessoryRectangular:
            accessoryRectangular
        case .systemMedium:
            systemMedium
        default:
            systemSmall
        }
    }

    // MARK: Layouts

    private var systemSmall: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recovery")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(scoreText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(verdictColor)
            Text(verdictText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(for: .widget) { AppTheme.Background.cream }
    }

    private var systemMedium: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recovery")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(scoreText)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(verdictColor)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(verdictText)
                    .font(.headline)
                if let snapshot = entry.snapshot {
                    Text("\(snapshot.presentInputCount)/5 signals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(snapshot.capturedAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(for: .widget) { AppTheme.Background.cream }
    }

    private var accessoryCircular: some View {
        Gauge(value: Double(entry.snapshot?.total ?? 0), in: 0...100) {
            Text("Rec")
        } currentValueLabel: {
            Text(scoreText)
                .font(.caption.bold())
        }
        .gaugeStyle(.accessoryCircular)
        .containerBackground(for: .widget) { Color.clear }
    }

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Recovery \(scoreText)")
                .font(.headline)
            Text(verdictText)
                .font(.caption)
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    // MARK: Helpers

    private var scoreText: String {
        guard let total = entry.snapshot?.total else { return "--" }
        return String(total)
    }

    private var verdictText: String {
        switch entry.snapshot?.recommendationRaw {
        case "pushDay": return "Push day"
        case "moderate": return "Moderate"
        case "restDay": return "Rest day"
        default: return "No data"
        }
    }

    private var verdictColor: Color {
        switch entry.snapshot?.recommendationRaw {
        case "pushDay": return AppTheme.Accent.gold
        case "restDay": return AppTheme.Semantic.error
        default: return AppTheme.Text.primary
        }
    }
}

// MARK: - Widget

struct RecoveryScoreWidget: Widget {
    let kind: String = "RecoveryScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecoveryScoreProvider()) { entry in
            RecoveryScoreWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Recovery Score")
        .description("See today's recovery score — push day or rest day — at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}
