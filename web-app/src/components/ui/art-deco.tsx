export function ArtDecoRule({ className = "" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 400 24"
      fill="none"
      className={`w-full max-w-xs mx-auto ${className}`}
      aria-hidden="true"
    >
      <line x1="0" y1="12" x2="160" y2="12" stroke="currentColor" strokeWidth="1" />
      <polygon points="200,2 210,12 200,22 190,12" fill="currentColor" />
      <line x1="240" y1="12" x2="400" y2="12" stroke="currentColor" strokeWidth="1" />
    </svg>
  );
}

export function ArtDecoRuleSmall({ className = "" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 200 12"
      fill="none"
      className={`w-full max-w-[8rem] ${className}`}
      aria-hidden="true"
    >
      <line x1="0" y1="6" x2="80" y2="6" stroke="currentColor" strokeWidth="1" />
      <polygon points="100,1 105,6 100,11 95,6" fill="currentColor" />
      <line x1="120" y1="6" x2="200" y2="6" stroke="currentColor" strokeWidth="1" />
    </svg>
  );
}

export function SectionLabel({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return (
    <p className={`text-gold font-mono text-[10px] tracking-[0.3em] uppercase ${className}`}>
      {children}
    </p>
  );
}

export function PageHeader({
  label,
  title,
  subtitle,
  action,
}: {
  label: string;
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="flex items-start justify-between">
      <div>
        <SectionLabel className="mb-1">{label}</SectionLabel>
        <h1 className="!text-3xl tracking-tight">{title}</h1>
        {subtitle && <p className="text-text-secondary mt-1">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

export function SectionHeader({
  label,
  title,
}: {
  label: string;
  title: string;
}) {
  return (
    <div>
      <SectionLabel className="mb-0.5">{label}</SectionLabel>
      <h2>{title}</h2>
    </div>
  );
}

export function DiagonalPattern() {
  return (
    <div
      className="fixed inset-0 pointer-events-none opacity-[0.03] z-0"
      aria-hidden="true"
      style={{
        backgroundImage: `repeating-linear-gradient(
          45deg,
          transparent,
          transparent 40px,
          #0d1a40 40px,
          #0d1a40 41px
        )`,
      }}
    />
  );
}

export function StatCard({
  value,
  label,
}: {
  value: string | number;
  label: string;
}) {
  return (
    <div className="relative bg-card-bg rounded-card p-4 text-center shadow-sm border border-separator/50 overflow-hidden">
      <div className="absolute top-0 left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-gold/40 to-transparent" />
      <p className="text-2xl font-bold text-orange">{value}</p>
      <p className="text-[11px] text-text-secondary font-mono tracking-wider uppercase mt-1">{label}</p>
    </div>
  );
}
