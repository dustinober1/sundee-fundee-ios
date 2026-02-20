# Sundee-Fundee - Workout Tracking App

Mobile-first web app for tracking workout programs, logging exercises, and monitoring progress.

## Features

- 6 built-in workout programs (back squat, front squat, bench press, deadlift, box jump, burpees)
- 8-week training cycles with percentage-based intensity
- Comprehensive onboarding flow
- Progress tracking with charts
- Plateau detection and recommendations
- Offline-first with IndexedDB storage
- Optional Supabase sync for cross-device backup

## Tech Stack

- Next.js 15 with App Router
- React 19
- TypeScript
- Tailwind CSS + shadcn/ui
- Dexie.js (IndexedDB)
- Supabase (auth + sync, optional)
- Recharts (progress charts)

## Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run unit tests
npm run test:run

# Run E2E tests
npm run test:e2e

# Build for production
npm run build
```

## Deployment

Deploy to Vercel:

1. Connect repository to Vercel
2. Add environment variables (Supabase URL and anon key)
3. Deploy

## Environment Variables

```env
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
```

## Project Structure

```
src/
  app/              # Next.js App Router pages
  components/       # React components (ui, layout, features)
  contexts/         # React contexts (User, Exercise)
  data/             # Static program data (JSON)
  lib/              # Utilities, database, calculations
  types/            # TypeScript type definitions
tests/
  unit/             # Vitest unit tests
  e2e/              # Playwright E2E tests
```

## License

MIT
