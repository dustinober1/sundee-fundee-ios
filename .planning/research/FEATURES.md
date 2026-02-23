# Features Research

## Table Stakes
- User authentication (anonymous/email) with persistent state
- Cycle logging: record periods, display current phase
- Program enrollment: join a training plan and track progress
- Dashboard showing current cycle and program week
- Data sync via Firestore, offline support

## Differentiators
- Cycle-aware program generator adjusting loads by phase
- Custom 12-week plan for men and adaptive plan for women
- Menstrual phase cues (sharkweek logo)

## Anti-features
- Social networking or sharing
- Real-time coaching AI

**Notes:** Existing code already implements most table stakes and some differentiators. Future work focuses on fine-tuning program adaptation and UI.
