import SundeeFundeeKit
import SwiftUI
import WidgetKit

// MARK: - NextWorkoutEntry

struct NextWorkoutEntry: TimelineEntry {
    let date: Date
    let snapshot: NextWorkoutSnapshot?
}

// MARK: - Provider

struct NextWorkoutProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextWorkoutEntry {
        NextWorkoutEntry(
            date: Date(),
            snapshot: NextWorkoutSnapshot(
                workoutName: "Full Body Strength",
                recommendationRaw: "train",
                guidanceDetail: "Primed for high capacity lifting",
                scheduledDate: Date(),
                capturedAt: Date()
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextWorkoutEntry) -> Void) {
        completion(NextWorkoutEntry(date: Date(), snapshot: SharedSnapshotStore.readNextWorkout()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextWorkoutEntry>) -> Void) {
        let now = Date()
        let entry = NextWorkoutEntry(date: now, snapshot: SharedSnapshotStore.readNextWorkout())
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

// MARK: - View

struct NextWorkoutWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextWorkoutEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            accessoryCircular
        case .accessoryInline:
            accessoryInline
        case .accessoryRectangular:
            accessoryRectangular
        #if os(watchOS)
        case .accessoryCorner:
            accessoryCorner
        #endif
        default:
            #if os(watchOS)
            accessoryCircular
            #else
            systemSmall
            #endif
        }
    }

    private var systemSmall: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Next Workout", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(badgeTitle)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badgeColor.opacity(0.15))
                    .foregroundStyle(badgeColor)
                    .clipShape(Capsule())
            }

            Text(workoutTitle)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Text.primary)
                .lineLimit(2)

            Text(guidanceText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer()

            HStack {
                Image(systemName: "play.circle.fill")
                    .foregroundStyle(AppTheme.Accent.orange)
                Text("Start")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.Accent.orange)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(for: .widget) { AppTheme.Background.cream }
        .widgetURL(DeepLinkRouter.url(for: .workout))
    }

    private var accessoryCircular: some View {
        VStack(spacing: 1) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.caption2)
                .foregroundStyle(badgeColor)
            Text(badgeShort)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(DeepLinkRouter.url(for: .workout))
    }

    private var accessoryInline: some View {
        ViewThatFits {
            Label("\(workoutTitle) • \(badgeTitle)", systemImage: "figure.strengthtraining.traditional")
            Text("\(workoutTitle) • \(badgeShort)")
            Text(workoutTitle)
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(DeepLinkRouter.url(for: .workout))
    }

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(badgeColor)
                Text("NEXT WORKOUT")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(badgeTitle)
                    .font(.caption2.bold())
                    .foregroundStyle(badgeColor)
            }

            Text(workoutTitle)
                .font(.headline.bold())
                .lineLimit(1)

            Text(guidanceText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(DeepLinkRouter.url(for: .workout))
    }

    #if os(watchOS)
    private var accessoryCorner: some View {
        Text(badgeShort)
            .font(.headline.bold())
            .widgetLabel {
                Text(workoutTitle)
            }
            .containerBackground(for: .widget) { Color.clear }
            .widgetURL(DeepLinkRouter.url(for: .workout))
    }
    #endif

    // MARK: - Computed Properties

    private var workoutTitle: String {
        entry.snapshot?.workoutName ?? "Next Session"
    }

    private var guidanceText: String {
        entry.snapshot?.guidanceDetail ?? "Open app to view training plan"
    }

    private var badgeTitle: String {
        switch entry.snapshot?.recommendationRaw {
        case "train": return "TRAIN"
        case "modify": return "MODIFY"
        case "recover": return "RECOVER"
        default: return "READY"
        }
    }

    private var badgeShort: String {
        switch entry.snapshot?.recommendationRaw {
        case "train": return "TRN"
        case "modify": return "MOD"
        case "recover": return "REC"
        default: return "RDY"
        }
    }

    private var badgeColor: Color {
        switch entry.snapshot?.recommendationRaw {
        case "train": return AppTheme.Recovery.green
        case "modify": return AppTheme.Accent.gold
        case "recover": return AppTheme.Accent.orange
        default: return AppTheme.Accent.gold
        }
    }
}

// MARK: - Widget

struct NextWorkoutWidget: Widget {
    let kind: String = "NextWorkoutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextWorkoutProvider()) { entry in
            NextWorkoutWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Workout")
        .description("Upcoming workout and daily training guidance.")
        #if os(watchOS)
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryRectangular, .accessoryCorner])
        #else
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline, .accessoryRectangular])
        #endif
    }
}
