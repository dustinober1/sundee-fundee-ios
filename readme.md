# Sundee Fundee

Cycle-aware strength training for iPhone.

## What It Does

Sundee Fundee adapts strength training recommendations to menstrual cycle phases — optimizing intensity, volume, and recovery based on where you are in your cycle. Built natively for iOS with Apple Sign-In, CloudKit sync, and StoreKit 2 subscriptions.

## Architecture

```
SundeeFundee/          Swift Package (SundeeFundeeKit)
├── DomainLayer/       Pure business logic (zero dependencies)
├── DataLayer/         Protocol-based persistence (CloudKit, Local, Mock)
├── UI/                SwiftUI views + view models
├── Auth/              Apple Sign-In + Keychain
└── Subscription/      StoreKit 2

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
- **AI Workout Generation** — AI-powered workout suggestions (Premium)
- **Guest Mode** — Full local functionality without CloudKit
- **Art Deco Theme** — Cream, navy, and orange design language

## Subscription Tiers

| Tier | Features |
|------|----------|
| **Free** | 5 lifts, 1 injury, 30-day history, limited AI |
| **Sundee Plus** | Unlimited lifts/injuries/history, daily AI, custom benchmarks |
| **Sundee Premium** | Full access, 10 AI/day, rehab sessions, AI coach, plateau detection |

## Tech Stack

| Component | Technology |
|:---|:---|
| **UI** | SwiftUI, Swift 6 (strict concurrency) |
| **Persistence** | CloudKit (signed-in), Local storage (guest) |
| **Auth** | Apple Sign-In, Keychain session |
| **Subscriptions** | StoreKit 2 |
| **Health Data** | HealthKit |
| **Package Manager** | Swift Package Manager |
| **Project Generation** | XcodeGen (`project.yml`) |

## License

Proprietary. All rights reserved.
