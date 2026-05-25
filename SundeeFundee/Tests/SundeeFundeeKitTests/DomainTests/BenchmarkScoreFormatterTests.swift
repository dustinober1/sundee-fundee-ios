import Testing
@testable import SundeeFundeeKit

@Suite("BenchmarkScoreFormatter")
struct BenchmarkScoreFormatterTests {
    @Test("formats elapsed time as minutes and padded seconds")
    func formatsTime() {
        #expect(BenchmarkScoreFormatter.string(for: 185, scoringType: .time) == "3:05")
    }

    @Test("formats rounds and reps using benchmark encoding")
    func formatsRoundsAndReps() {
        #expect(BenchmarkScoreFormatter.string(for: 120007, scoringType: .roundsAndReps) == "12 rounds + 7 reps")
    }

    @Test("formats load in pounds")
    func formatsLoad() {
        #expect(BenchmarkScoreFormatter.string(for: 225, scoringType: .load) == "225 lb")
    }

    @Test("formats reps")
    func formatsReps() {
        #expect(BenchmarkScoreFormatter.string(for: 14, scoringType: .reps) == "14 reps")
    }

    @Test("formats calories")
    func formatsCalories() {
        #expect(BenchmarkScoreFormatter.string(for: 87, scoringType: .calories) == "87 cal")
    }

    @Test("formats distance")
    func formatsDistance() {
        #expect(BenchmarkScoreFormatter.string(for: 2000, scoringType: .distance) == "2000 m")
    }

    @Test("formats raw scoring type strings")
    func formatsRawScoringType() {
        #expect(BenchmarkScoreFormatter.string(for: 185, scoringTypeRaw: "time") == "3:05")
        #expect(BenchmarkScoreFormatter.string(for: 9, scoringTypeRaw: "unknown") == "9")
    }
}

