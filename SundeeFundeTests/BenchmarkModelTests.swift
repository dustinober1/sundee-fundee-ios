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
            category: "CrossFit WOD",
            workoutDescription: "21-15-9: Thrusters + Pull-ups",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 0
        )
        #expect(def.name == "Fran")
        #expect(def.scoringTypeRaw == BenchmarkScoringType.time.rawValue)
        #expect(def.isPredefined == true)
    }

    @Test func scoringTypeComputedPropertyMatchesInit() {
        let def = BenchmarkDefinition(
            userID: "",
            name: "Fran",
            category: "CrossFit WOD",
            workoutDescription: "21-15-9",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 0
        )
        #expect(def.scoringType == .time)
        #expect(def.scoringTypeRaw == "time")
    }
}
