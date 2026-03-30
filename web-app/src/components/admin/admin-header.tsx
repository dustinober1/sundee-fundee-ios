"use client";

import { useAuth } from "@/components/providers/auth-provider";

interface AdminHeaderProps {
  title: string;
}

export function AdminHeader({ title }: AdminHeaderProps) {
  const { user } = useAuth();

  return (
    <header className="h-14 border-b border-separator bg-card-bg flex items-center justify-between px-6">
      <h1 className="font-heading text-lg text-navy">{title}</h1>
      <div className="flex items-center gap-3">
        <span className="text-sm text-text-secondary">
          {user?.email}
        </span>
      </div>
    </header>
  );
}
