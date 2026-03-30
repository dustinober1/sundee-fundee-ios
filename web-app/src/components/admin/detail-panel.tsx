"use client";

interface DetailPanelProps {
  title: string;
  onClose?: () => void;
  actions?: React.ReactNode;
  children: React.ReactNode;
}

export function DetailPanel({ title, onClose, actions, children }: DetailPanelProps) {
  return (
    <div className="flex flex-col h-full border-l border-separator bg-card-bg">
      <div className="flex items-center justify-between px-5 py-4 border-b border-separator">
        <h2 className="font-heading text-lg text-navy">{title}</h2>
        <div className="flex items-center gap-2">
          {actions}
          {onClose && (
            <button
              onClick={onClose}
              className="text-text-secondary hover:text-navy text-lg leading-none"
              aria-label="Close"
            >
              ×
            </button>
          )}
        </div>
      </div>
      <div className="flex-1 overflow-y-auto p-5">{children}</div>
    </div>
  );
}
