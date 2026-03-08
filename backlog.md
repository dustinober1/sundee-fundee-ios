# Sundee Fundee — Product Backlog

## Epic: Core Foundation & Stability
*Foundational features required for a reliable user experience and App Store launch.*

- [ ] **Plate Calculator Integration**
  - [ ] Add plate calculator accessibility to "Actual Weight" input fields in `WorkoutExecutionView`.
  - [ ] Add "Barbell Weight" selector in user settings (defaulting to 20kg/45lb).
- [ ] **Infrastructure & CI/CD**
  - [ ] Complete Apple Developer Account setup (Team ID, App Record).
  - [ ] Configure Fastlane Match for automated certificate management.
  - [ ] Host Privacy Policy and Support URLs.
  - [ ] Submit for initial TestFlight and App Store review.
- [ ] **Bug Fixes**
  - [ ] Address potential orphaned enrollments in `WorkoutExecutionViewModel`.
  - [ ] Fix any layout issues on smaller iPhone screens (SE/Mini).

## Epic: User Experience & Social
*Features to increase engagement and community growth.*

- [ ] **Public Workout Templates**
  - [ ] Allow users to "Publish" a completed AI workout to a shared repository.
  - [ ] Add a "Community" tab to browse and download popular user-generated workouts.
- [ ] **Subscription Tiers**
  - [ ] Implement "Pro" and "Elite" tiers in `SubscriptionService`.
  - [ ] Add paywalls for advanced AI features.

## Epic: [ELITE] Personalized Coaching & Intelligence
*Premium features justifying a $29.99/mo subscription.*

- [ ] **[Elite] Readiness & Auto-Regulation**
  - [ ] HealthKit integration (HRV, Sleep, Resting HR).
  - [ ] AI-driven intensity adjustments based on recovery metrics.
- [ ] **[Elite] Conversational AI Coach**
  - [ ] Weekly interactive check-ins via Gemini 1.5 Pro.
  - [ ] Voice-enabled coaching conversations.
- [ ] **[Elite] Advanced Form Analysis**
  - [ ] Real-time Bar Path tracking using Apple Vision.
  - [ ] Multimodal AI (Gemini Vision) feedback for technical corrections.
- [ ] **[Elite] Travel Mode & Multi-Gym Profiles**
  - [ ] Saved equipment inventories (Home, Hotel, Commercial).
  - [ ] Instant workout adaptation based on available kit.
- [ ] **[Elite] PR Forecasting & Analytics**
  - [ ] Muscle fatigue heatmaps.
  - [ ] Predictive 1RM trajectory and peaking alerts.
