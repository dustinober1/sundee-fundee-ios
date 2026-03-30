"use client";

import { useEffect, useState } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { AdminStatCard } from "@/components/admin/stat-card";

interface Stats {
  totalUsers: number;
  subscriptions: { free: number; plus: number; premium: number };
  aiGenerationsToday: number;
}

export default function AdminDashboard() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/admin/stats")
      .then((r) => r.json())
      .then(setStats)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  return (
    <>
      <AdminHeader title="Dashboard" />
      <main className="flex-1 overflow-y-auto p-6">
        {loading ? (
          <p className="text-text-secondary">Loading...</p>
        ) : stats ? (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
              <AdminStatCard label="Total Users" value={stats.totalUsers} />
              <AdminStatCard
                label="Plus Subscribers"
                value={stats.subscriptions.plus}
              />
              <AdminStatCard
                label="Premium Subscribers"
                value={stats.subscriptions.premium}
              />
              <AdminStatCard
                label="AI Generations Today"
                value={stats.aiGenerationsToday}
              />
            </div>
            <div className="bg-card-bg rounded-card p-spacing-lg border border-separator">
              <p className="font-mono text-[10px] tracking-[0.3em] uppercase text-gold mb-3">
                QUICK ACTIONS
              </p>
              <div className="flex flex-wrap gap-3">
                <a
                  href="/admin/workouts/wods"
                  className="px-4 py-2 bg-orange text-white rounded-button text-sm font-medium hover:bg-orange/90"
                >
                  New WOD
                </a>
                <a
                  href="/admin/workouts/programs"
                  className="px-4 py-2 bg-orange text-white rounded-button text-sm font-medium hover:bg-orange/90"
                >
                  New Program
                </a>
                <a
                  href="/admin/content/blog"
                  className="px-4 py-2 bg-orange text-white rounded-button text-sm font-medium hover:bg-orange/90"
                >
                  New Blog Post
                </a>
                <a
                  href="/admin/users"
                  className="px-4 py-2 bg-card-bg text-navy border border-separator rounded-button text-sm font-medium hover:bg-navy/5"
                >
                  Search Users
                </a>
              </div>
            </div>
          </>
        ) : (
          <p className="text-error">Failed to load stats.</p>
        )}
      </main>
    </>
  );
}
