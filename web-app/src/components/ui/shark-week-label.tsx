export function SharkIcon({ className = "" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
      className={className}
      fill="currentColor"
    >
      <path d="M2.5 13.2c3.1-3.3 6.8-5 10.6-4.9l2.7-3.2.9 3.9c1.5.4 2.9 1.1 4.3 2.2-1.4 1.1-2.8 1.8-4.3 2.2l-.9 3.9-2.7-3.2c-1.3.1-2.6 0-3.8-.3L5.8 16l.8-2.6c-1.4-.5-2.8-1.4-4.1-2.8Z" />
      <circle cx="15.7" cy="10.3" r="1" fill="white" />
      <circle cx="15.7" cy="10.3" r="0.45" fill="currentColor" />
    </svg>
  );
}

export function SharkWeekLabel({
  className = "",
  iconClassName = "",
}: {
  className?: string;
  iconClassName?: string;
}) {
  return (
    <span className={`inline-flex items-center gap-1 ${className}`}>
      <SharkIcon className={iconClassName || "w-4 h-4"} />
      <span>Shark Week</span>
    </span>
  );
}
