import { redirect } from 'next/navigation';

export default function HomePage() {
  // TODO: Check if user exists, redirect to dashboard or onboarding
  redirect('/onboarding');
}
