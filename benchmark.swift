import Foundation

struct ConfettiParticle {
    let x: Double
    let y: Double
    let size: Double
    let rotation: Double
    let color: Int
    let speed: Double
}

func generateMap(count: Int, seed: Int = 0) -> [ConfettiParticle] {
    var state = UInt64(seed == 0 ? 42 : seed)
    func nextRandom() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) & 0x7FFFFFFF) / Double(0x7FFFFFFF)
    }
    return (0..<count).map { _ in
        ConfettiParticle(
            x: nextRandom(),
            y: -nextRandom() * 0.3,
            size: 4 + nextRandom() * 8,
            rotation: nextRandom() * 360,
            color: Int(nextRandom() * 3) % 3,
            speed: 100 + nextRandom() * 200
        )
    }
}

func generateReserve(count: Int, seed: Int = 0) -> [ConfettiParticle] {
    var state = UInt64(seed == 0 ? 42 : seed)
    func nextRandom() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) & 0x7FFFFFFF) / Double(0x7FFFFFFF)
    }
    var result = [ConfettiParticle]()
    result.reserveCapacity(count)
    for _ in 0..<count {
        result.append(
            ConfettiParticle(
                x: nextRandom(),
                y: -nextRandom() * 0.3,
                size: 4 + nextRandom() * 8,
                rotation: nextRandom() * 360,
                color: Int(nextRandom() * 3) % 3,
                speed: 100 + nextRandom() * 200
            )
        )
    }
    return result
}

let start1 = CFAbsoluteTimeGetCurrent()
for _ in 0..<1000 {
    _ = generateMap(count: 10000)
}
let end1 = CFAbsoluteTimeGetCurrent()
print("Map: \(end1 - start1)")

let start2 = CFAbsoluteTimeGetCurrent()
for _ in 0..<1000 {
    _ = generateReserve(count: 10000)
}
let end2 = CFAbsoluteTimeGetCurrent()
print("Reserve: \(end2 - start2)")
