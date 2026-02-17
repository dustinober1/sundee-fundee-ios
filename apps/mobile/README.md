# Strength - React Native Workout Tracker

Mobile-first workout tracking app for iOS and Android.

## Tech Stack

- React Native via Expo SDK 51+
- Expo Router for navigation
- React Native Paper for UI components
- NativeWind for Tailwind CSS styling
- AsyncStorage for local persistence
- TypeScript for type safety

## Development

### Prerequisites

- Node.js 18+
- macOS with Xcode 15+ (iOS development)
- CocoaPods installed

### Setup

```bash
# Install dependencies
npm install

# Start development server
npm start

# Run on iOS Simulator
npm run ios

# Run on Android Emulator
npm run android
```

### Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Generate coverage report
npm run test:coverage
```

### Build

```bash
# Install EAS CLI
npm install -g eas-cli

# Build for iOS (development)
eas build --platform ios --profile development

# Build for TestFlight
eas build --platform ios --profile preview

# Build for App Store
eas build --platform ios --profile production
```

## Project Status

This is the Foundation phase (Phase 1) of the React Native migration.

### Completed
- ✅ Project setup with Expo and TypeScript
- ✅ Navigation configured with Expo Router
- ✅ Basic UI component wrappers
- ✅ AsyncStorage database layer
- ✅ React Context providers
- ✅ Business logic (calculations)
- ✅ Jest testing configuration
- ✅ Design token constants

### In Progress
- 🔄 Phase 2: Data Layer & Contexts completion
- 🔄 Phase 3: Onboarding & Core Flows

### Roadmap
See [docs/plans/2026-02-16-react-native-ios-app-design.md](../docs/plans/2026-02-16-react-native-ios-app-design.md) for complete roadmap.

## License

MIT
