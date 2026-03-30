import { BottomNav } from "@/components/layout/bottom-nav";
import { DiagonalPattern } from "@/components/ui/art-deco";

export default function FeaturesLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="relative min-h-screen pb-20">
      <DiagonalPattern />
      <main className="relative z-10 max-w-xl mx-auto px-5 py-6">
        {children}
      </main>
      <BottomNav />
    </div>
  );
}
