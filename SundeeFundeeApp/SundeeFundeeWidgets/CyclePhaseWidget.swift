import SundeeFundeeKit
import SwiftUI
import WidgetKit

// MARK: - CyclePhaseEntry

struct CyclePhaseEntry: TimelineEntry {
    let date: Date
    let snapshot: CyclePhaseSnapshot?
}

// MARK: - Provider

struct CyclePhaseProvider: TimelineProvider {
    func placeholder(in context: Context) -> CyclePhaseEntry {
        CyclePhaseEntry(
            date: Date(),
            snapshot: CyclePhaseSnapshot(
                phaseRaw: "follicular",
                cycleDay: 7,
                capturedAt: Date(),
                isSharkWeek: false
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CyclePhaseEntry) -> Void) {
        completion(CyclePhaseEntry(date: Date(), snapshot: SharedSnapshotStore.readCycle()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CyclePhaseEntry>) -> Void) {
        let now = Date()
        let entry = CyclePhaseEntry(date: now, snapshot: SharedSnapshotStore.readCycle())
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

// MARK: - View

struct CyclePhaseWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CyclePhaseEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            accessoryCircular
        default:
            systemSmall
        }
    }

    private var systemSmall: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Cycle")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(phaseTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(phaseColor)
                .lineLimit(2)
            if let day = entry.snapshot?.cycleDay {
                Text("Day \(day)")
                    .font(.footnote)
                    .foregroundStyle(.primary)
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
        .widgetURL(DeepLinkRouter.url(for: .cycle))
    }

    private var accessoryCircular: some View {
        VStack(spacing: 0) {
            Text(shortPhaseLabel)
                .font(.caption2.bold())
            if let day = entry.snapshot?.cycleDay {
                Text("D\(day)")
                    .font(.caption.bold())
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(DeepLinkRouter.url(for: .cycle))
    }

    private var phaseTitle: String {
        if entry.snapshot?.isSharkWeek == true { return "Shark Week" }
        switch entry.snapshot?.phaseRaw {
        case "menstrual": return "Menstrual"
        case "follicular": return "Follicular"
        case "ovulation": return "Ovulation"
        case "luteal": return "Luteal"
        default: return "No data"
        }
    }

    private var shortPhaseLabel: String {
        switch entry.snapshot?.phaseRaw {
        case "menstrual": return "Men"
        case "follicular": return "Fol"
        case "ovulation": return "Ov"
        case "luteal": return "Lut"
        default: return "--"
        }
    }

    private var phaseColor: Color {
        if entry.snapshot?.isSharkWeek == true { return AppTheme.Semantic.error }
        return AppTheme.Accent.gold
    }

    private func freshnessText(capturedAt: Date?) -> String {
        guard let capturedAt else { return "Open app to update" }
        let hours = Calendar.current.dateComponents([.hour], from: capturedAt, to: Date()).hour ?? 0
        if hours >= 24 { return "Open app to refresh" }
        return "Updated \(capturedAt.formatted(.relative(presentation: .numeric)))"
    }
}

// MARK: - Widget

struct CyclePhaseWidget: Widget {
    let kind: String = "CyclePhaseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CyclePhaseProvider()) { entry in
            CyclePhaseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Cycle Phase")
        .description("Today's cycle phase and day count.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}
