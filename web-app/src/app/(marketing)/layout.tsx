import { DiagonalPattern } from "@/components/ui/art-deco";

export default function MarketingLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="relative min-h-screen">
      <DiagonalPattern />
      <div className="relative z-10 pt-12 pb-20 px-6">{children}</div>
    </div>
  );
}
