import { BottomNav } from "@/components/layout/bottom-nav";

export default function FeaturesLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen pb-16">
      <main className="max-w-lg mx-auto px-spacing-md py-spacing-md">
        {children}
      </main>
      <BottomNav />
    </div>
  );
}
