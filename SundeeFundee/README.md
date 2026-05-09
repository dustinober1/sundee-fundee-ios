# Sundee Fundee - Native Apple App

Cycle-aware strength training, now native on Apple platforms.

## Project Structure

```
SundeeFundee/
├── Sources/SundeeFundeeKit/    # Domain models and calculations
│   ├── Models/                 # Exercise, Workout, etc.
│   ├── Calculations/           # Weight, Plate, Unit converters
│   └── Exports.swift           # Public API surface
├── Tests/SundeeFundeeKitTests/ # Test suite
└── Package.swift               # Swift Package definition
```

## Building

### Prerequisites
- Xcode 16+
- Swift 6.0
- macOS 15+ (Sequoia)

### Build
```bash
swift build
```

### Run Tests
```bash
swift test
```

### Verify Coverage
```bash
./scripts/verify-coverage.sh
```

## Development Status

### Phase 1: Foundation ✅ (CURRENT)
- [x] Swift Package structure
- [x] SundeeFundeeKit shared framework
- [x] Core domain models (Workout, Exercise, Set)
- [x] Calculation modules (Weight, Plate, Unit converters)
- [x] XCTest infrastructure with 100% coverage

### Phase 2: Data Layer (NEXT)
- [ ] CloudKit schema and actors
- [ ] SwiftData models
- [ ] HealthKit client
- [ ] Sign in with Apple

## Tech Stack

- **Language**: Swift 6
- **UI**: SwiftUI
- **Data**: CloudKit for signed-in users, local storage for guests
- **Concurrency**: async/await with Actors
- **Testing**: XCTest
- **Auth**: Sign in with Apple

## License

Copyright © 2026 Sundee Fundee. All rights reserved.
