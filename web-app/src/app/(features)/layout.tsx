import { BottomNav } from "@/components/layout/bottom-nav";

export default function FeaturesLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen pb-16">
      <main className="max-w-xl mx-auto px-spacing-lg py-spacing-lg">
        {children}
      </main>
      <BottomNav />
    </div>
  );
}
