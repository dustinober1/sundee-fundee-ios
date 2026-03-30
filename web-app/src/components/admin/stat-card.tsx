interface AdminStatCardProps {
  label: string;
  value: string | number;
  trend?: string;
  trendUp?: boolean;
}

export function AdminStatCard({ label, value, trend, trendUp }: AdminStatCardProps) {
  return (
    <div className="bg-card-bg rounded-card p-spacing-lg border border-separator">
      <div className="h-0.5 w-8 bg-gold mb-3 rounded-full" />
      <p className="font-mono text-[10px] tracking-[0.3em] uppercase text-gold mb-1">
        {label}
      </p>
      <p className="font-heading text-2xl text-navy">{value}</p>
      {trend && (
        <p className={`text-xs mt-1 ${trendUp ? "text-green-600" : "text-error"}`}>
          {trend}
        </p>
      )}
    </div>
  );
}
