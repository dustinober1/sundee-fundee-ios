import Testing
import Foundation
import SwiftData
@testable import SundeeFundee

@Suite("BenchmarkDefinition Model")
struct BenchmarkDefinitionTests {

    @Test func scoringTypeRoundTrips() {
        for type in BenchmarkScoringType.allCases {
            #expect(BenchmarkScoringType(rawValue: type.rawValue) == type)
        }
    }

    @Test func definitionInit() {
        let def = BenchmarkDefinition(
            userID: "",
            name: "Fran",
            category: "Classic WODs",
            workoutDescription: "21-15-9: Thrusters + Pull-ups",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 0
        )
        #expect(def.name == "Fran")
        #expect(def.scoringTypeRaw == BenchmarkScoringType.time.rawValue)
        #expect(def.isPredefined == true)
    }

    @Test func roundsAndRepsScoringTypeRoundTrips() {
        let def = BenchmarkDefinition(
            userID: "",
            name: "AMRAP",
            category: "Classic WODs",
            workoutDescription: "",
            scoringType: .roundsAndReps,
            isPredefined: false,
            sortOrder: 0
        )
        #expect(def.scoringType == .roundsAndReps)
        #expect(def.scoringTypeRaw == "roundsAndReps")
    }

    @Test func scoringTypeComputedPropertyMatchesInit() {
        let def = BenchmarkDefinition(
            userID: "",
            name: "Fran",
            category: "Classic WODs",
            workoutDescription: "21-15-9",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 0
        )
        #expect(def.scoringType == .time)
        #expect(def.scoringTypeRaw == "time")
    }
}

@Suite("BenchmarkCatalog")
struct BenchmarkCatalogTests {

    @Test func catalogIsNotEmpty() {
        #expect(!BenchmarkCatalog.predefined.isEmpty)
    }

    @Test func allEntriesHaveUniqueNames() {
        let names = BenchmarkCatalog.predefined.map(\.name)
        #expect(names.count == Set(names).count)
    }

    @Test func allScoringTypesAreValid() {
        for entry in BenchmarkCatalog.predefined {
            #expect(BenchmarkScoringType(rawValue: entry.scoringTypeRaw) != nil)
        }
    }

    @Test func categoriesGroupedCorrectly() {
        let grouped = BenchmarkCatalog.groupedByCategory
        #expect(!grouped.isEmpty)
        for group in grouped {
            #expect(!group.entries.isEmpty)
        }
    }

    @Test func franIsPresent() {
        let fran = BenchmarkCatalog.predefined.first { $0.name == "Fran" }
        #expect(fran != nil)
        #expect(fran?.scoringTypeRaw == BenchmarkScoringType.time.rawValue)
    }

    @Test func predefinedEntriesHaveEmptyUserID() {
        for entry in BenchmarkCatalog.predefined {
            #expect(entry.userID == "")
            #expect(entry.isPredefined == true)
        }
    }

    @Test func sortOrderIsMonotonicallyIncreasing() {
        let orders = BenchmarkCatalog.predefined.map(\.sortOrder)
        for i in 1..<orders.count {
            #expect(orders[i] > orders[i - 1])
        }
    }
}
