#!/usr/bin/env swift
/// seed-cloudkit-wods.swift
///
/// Seeds Workout of the Day entries into the CloudKit Public Database.
/// Run from the repo root with your iCloud account signed in:
///
///   chmod +x scripts/seed-cloudkit-wods.swift
///   ./scripts/seed-cloudkit-wods.swift
///
/// Requirements:
///   - macOS 13+, Xcode Command Line Tools
///   - iCloud account with access to the `iCloud.com.sundeefundee.app` container
///   - The CloudKit container must have the `WOD` record type configured
///     (use CloudKit Console -> Schema -> Record Types to create it if needed)
///
/// CloudKit Record Type: WOD
///   Fields:
///     id              String  — unique slug, e.g. "wod-2026-03-01"
///     date            String  — "2026-03-01" (yyyy-MM-dd)
///     title           String  — display name
///     description     String  — coach notes
///     exercisesJSON   String  — JSON-encoded [ProgramExercise]

import CloudKit
import Foundation

let containerID = "iCloud.com.sundeefundee.app"
let container = CKContainer(identifier: containerID)
let publicDB = container.publicCloudDatabase

// MARK: - Load WODs from bundled JSON

func loadWODsFromJSON() throws -> [[String: Any]] {
    let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
    let jsonURL = scriptDir
        .deletingLastPathComponent()
        .appendingPathComponent("SundeeFundee/Resources/WODs/wods.json")

    let data = try Data(contentsOf: jsonURL)
    guard let wods = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
        throw NSError(domain: "SeedWODs", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
    }
    return wods
}

// MARK: - Seed logic

func seedWOD(_ wod: [String: Any]) async throws {
    guard let id = wod["id"] as? String,
          let date = wod["date"] as? String,
          let title = wod["title"] as? String,
          let description = wod["description"] as? String,
          let exercises = wod["exercises"] else {
        print("Skipping invalid WOD entry")
        return
    }

    let exercisesData = try JSONSerialization.data(withJSONObject: exercises)
    let exercisesJSON = String(data: exercisesData, encoding: .utf8) ?? "[]"

    let record = CKRecord(recordType: "WOD", recordID: CKRecord.ID(recordName: id))
    record["id"] = id as CKRecordValue
    record["date"] = date as CKRecordValue
    record["title"] = title as CKRecordValue
    record["description"] = description as CKRecordValue
    record["exercisesJSON"] = exercisesJSON as CKRecordValue

    let saved = try await publicDB.save(record)
    print("Saved: \(saved.recordID.recordName)")
}

// MARK: - Entry point

let sema = DispatchSemaphore(value: 0)

Task {
    do {
        let wods = try loadWODsFromJSON()
        for wod in wods {
            let title = wod["title"] as? String ?? "unknown"
            print("Seeding '\(title)'...")
            try await seedWOD(wod)
        }
        print("\nDone. \(wods.count) WOD(s) seeded.")
    } catch {
        print("Error: \(error)")
    }
    sema.signal()
}

sema.wait()
