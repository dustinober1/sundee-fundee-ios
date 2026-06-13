import Foundation

public struct ReleaseNoteItem: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let body: String

    public init(id: String, title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}

public struct ReleaseNotes: Sendable, Equatable {
    public let title: String
    public let items: [ReleaseNoteItem]

    public init(title: String, items: [ReleaseNoteItem]) {
        self.title = title
        self.items = items
    }
}

public enum ReleaseNotesContent {
    public static let current = ReleaseNotes(
        title: "What's New",
        items: [
            ReleaseNoteItem(
                id: "today",
                title: "Clearer daily guidance",
                body: "Today now explains whether to train, modify, or recover with cycle, recovery, and pain context."
            ),
            ReleaseNoteItem(
                id: "gym",
                title: "Better in-gym tools",
                body: "Best Next 20 Min, equipment conversion, warmups, station swaps, technique cues, and rest guidance are easier to find."
            ),
            ReleaseNoteItem(
                id: "trust",
                title: "Privacy and trust",
                body: "Data Trust Center, share privacy controls, sync status, export, and delete-account actions are grouped more clearly."
            ),
            ReleaseNoteItem(
                id: "reflection",
                title: "More progress context",
                body: "Monthly Review, buddy check-ins, cycle-aware progress, symptom trends, and return-to-lifting ramps help explain longer patterns."
            ),
            ReleaseNoteItem(
                id: "support",
                title: "Optional support",
                body: "Support the Developer is now available in Settings as a repeatable $1.99 tip. It is not required for any feature."
            )
        ]
    )
}
