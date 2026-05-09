# Sundee Fundee

Cycle-aware strength training for iPhone.

## What It Does

Sundee Fundee adapts strength training recommendations to menstrual cycle phases, energy, pain, and recovery context. Built natively for iOS with Apple Sign-In, CloudKit sync, and full local guest mode.

## Architecture

```
SundeeFundee/          Swift Package (SundeeFundeeKit)
├── DomainLayer/       Pure business logic (zero dependencies)
├── DataLayer/         Protocol-based persistence (CloudKit, Local, Mock)
├── UI/                SwiftUI views + view models
├── Auth/              Apple Sign-In + Keychain
└── Models/            Shared Codable models

SundeeFundeeApp/       Xcode project (app entry point)
```

## Getting Started

### Prerequisites

- Xcode 16.0+
- Swift 6.0+
- iOS 18.0+ deployment target

### Setup

1. Open `SundeeFundeeApp/SundeeFundee.xcodeproj` in Xcode
2. Select the SundeeFundee scheme
3. Choose an iOS Simulator or connected device
4. Build and run (Cmd+R)

### Running Tests

```bash
cd SundeeFundee
swift test
```

## Key Features

- **Cycle-Aware Training** — Workouts adapt to menstrual cycle phase (menstrual, follicular, ovulation, luteal)
- **1RM Tracking** — Track and progress your one-rep maxes across lifts
- **Benchmark Workouts** — AMRAP benchmarks with readiness scoring
- **Program Enrollment** — Follow structured training programs
- **Coach Plan** — Cycle-aware workout plans built from local training rules
- **Guest Mode** — Full local functionality without CloudKit
- **Art Deco Theme** — Cream, navy, and orange design language

## Product Model

All features are free and unlocked. Signed-in users sync with CloudKit; guest users store data locally.

## Tech Stack

| Component | Technology |
|:---|:---|
| **UI** | SwiftUI, Swift 6 (strict concurrency) |
| **Persistence** | CloudKit (signed-in), Local storage (guest) |
| **Auth** | Apple Sign-In, Keychain session |
| **Health Data** | HealthKit |
| **Package Manager** | Swift Package Manager |
| **Project Generation** | XcodeGen (`project.yml`) |

## License

Proprietary. All rights reserved.
