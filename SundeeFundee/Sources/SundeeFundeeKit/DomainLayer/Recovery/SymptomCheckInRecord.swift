import Foundation

// MARK: - SymptomCheckInRecord

/// A daily symptom check-in record for tracking how the user feels across
/// four dimensions: cramps, fatigue, soreness, and energy (all 0-10).
///
/// Field naming follows CloudKit schema rules: avoids reserved names
/// (createdAt, modifiedAt, startDate, endDate) per CLAUDE.md.
/// `dateCreated` is the record creation timestamp; `symptomDate` is the
/// day the symptoms describe.
public struct SymptomCheckInRecord: Codable, Sendable, Identifiable, Equatable {

    // MARK: - Properties

    public let id: String
    /// The date these symptoms describe (NOT "startDate").
    public let symptomDate: Date
    /// Cramp severity 0-10.
    public let cramps: Int
    /// Fatigue level 0-10.
    public let fatigue: Int
    /// Muscle soreness level 0-10.
    public let soreness: Int
    /// Energy level 0-10.
    public let energy: Int
    /// Optional free-text notes.
    public let notes: String?
    /// Record creation timestamp (NOT "createdAt").
    public let dateCreated: Date

    // MARK: - Initialization

    public init(
        id: String = UUID().uuidString,
        symptomDate: Date,
        cramps: Int,
        fatigue: Int,
        soreness: Int,
        energy: Int,
        notes: String? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.symptomDate = symptomDate
        self.cramps = cramps
        self.fatigue = fatigue
        self.soreness = soreness
        self.energy = energy
        self.notes = notes
        self.dateCreated = dateCreated
    }
}
