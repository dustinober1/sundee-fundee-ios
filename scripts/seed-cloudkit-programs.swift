#!/usr/bin/env swift
/// seed-cloudkit-programs.swift
///
/// Seeds workout programs into the CloudKit Public Database.
/// Run from the repo root with your iCloud account signed in:
///
///   chmod +x scripts/seed-cloudkit-programs.swift
///   ./scripts/seed-cloudkit-programs.swift
///
/// Requirements:
///   - macOS 13+, Xcode Command Line Tools
///   - iCloud account with access to the `iCloud.com.sundeefundee.app` container
///   - The CloudKit container must have the `Program` record type configured
///     (use CloudKit Console → Schema → Record Types to create it if needed)
///
/// CloudKit Record Type: Program
///   Fields (all String unless noted):
///     id           String  — unique slug, e.g. "squad-squat-peak-12w"
///     name         String  — display name
///     description  String  — long description
///     durationWeeks  Int64
///     sessionsPerWeek Int64
///     difficulty   String  — beginner / intermediate / advanced
///     category     String  — strength / hypertrophy / powerlifting / etc.
///     phases       Bytes   — JSON-encoded [ProgramPhase]
///     isActive     Int64   — 1 = active, 0 = hidden

import CloudKit
import Foundation

let containerID = "iCloud.com.sundeefundee.app"
let container = CKContainer(identifier: containerID)
let publicDB = container.publicCloudDatabase

// MARK: - Program data to seed

struct SeedProgram {
    let id: String
    let name: String
    let description: String
    let durationWeeks: Int
    let sessionsPerWeek: Int
    let difficulty: String
    let category: String
    let phasesJSON: String
}

let programs: [SeedProgram] = [
    SeedProgram(
        id: "squad-squat-peak-12w",
        name: "12-Week Squad Squat Peak",
        description: "A 12-week periodized squat program designed to peak strength for a 1-rep max attempt. Combines hypertrophy, strength, and peaking blocks with cycle-aware load adjustments.",
        durationWeeks: 12,
        sessionsPerWeek: 3,
        difficulty: "intermediate",
        category: "powerlifting",
        phasesJSON: """
        [
          {
            "name": "Hypertrophy Block",
            "weeks": [1, 2, 3, 4],
            "sessions": [
              {
                "day": 1,
                "name": "Squat A",
                "exercises": [
                  { "name": "Back Squat", "sets": 4, "reps": 8, "percent1RM": 0.70 },
                  { "name": "Romanian Deadlift", "sets": 3, "reps": 10, "percent1RM": 0.60 },
                  { "name": "Leg Press", "sets": 3, "reps": 12, "percent1RM": 0.55 }
                ]
              }
            ]
          },
          {
            "name": "Strength Block",
            "weeks": [5, 6, 7, 8],
            "sessions": [
              {
                "day": 1,
                "name": "Squat A",
                "exercises": [
                  { "name": "Back Squat", "sets": 5, "reps": 5, "percent1RM": 0.80 },
                  { "name": "Romanian Deadlift", "sets": 4, "reps": 6, "percent1RM": 0.70 },
                  { "name": "Bulgarian Split Squat", "sets": 3, "reps": 8, "percent1RM": 0.55 }
                ]
              }
            ]
          },
          {
            "name": "Peaking Block",
            "weeks": [9, 10, 11, 12],
            "sessions": [
              {
                "day": 1,
                "name": "Squat A",
                "exercises": [
                  { "name": "Back Squat", "sets": 3, "reps": 3, "percent1RM": 0.88 },
                  { "name": "Pause Squat", "sets": 3, "reps": 2, "percent1RM": 0.75 },
                  { "name": "Box Squat", "sets": 3, "reps": 3, "percent1RM": 0.70 }
                ]
              }
            ]
          }
        ]
        """
    )
]

// MARK: - Seed logic

func seedProgram(_ program: SeedProgram) async throws {
    let record = CKRecord(recordType: "Program", recordID: CKRecord.ID(recordName: program.id))
    record["id"] = program.id as CKRecordValue
    record["name"] = program.name as CKRecordValue
    record["description"] = program.description as CKRecordValue
    record["durationWeeks"] = program.durationWeeks as CKRecordValue
    record["sessionsPerWeek"] = program.sessionsPerWeek as CKRecordValue
    record["difficulty"] = program.difficulty as CKRecordValue
    record["category"] = program.category as CKRecordValue
    record["isActive"] = 1 as CKRecordValue
    if let data = program.phasesJSON.data(using: .utf8) {
        record["phases"] = data as CKRecordValue
    }
    let saved = try await publicDB.save(record)
    print("✅ Saved: \(saved.recordID.recordName)")
}

// MARK: - Entry point

let sema = DispatchSemaphore(value: 0)

Task {
    do {
        for program in programs {
            print("Seeding '\(program.name)'...")
            try await seedProgram(program)
        }
        print("\nDone. \(programs.count) program(s) seeded.")
    } catch {
        print("❌ Error: \(error)")
    }
    sema.signal()
}

sema.wait()
