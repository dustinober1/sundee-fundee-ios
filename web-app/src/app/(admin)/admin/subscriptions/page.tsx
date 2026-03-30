"use client";

import { useEffect, useState, useMemo } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { AdminStatCard } from "@/components/admin/stat-card";
import { DataTable, Column } from "@/components/admin/data-table";

interface SubscriptionRow {
  uid: string;
  name?: string;
  email?: string;
  tier?: string;
  status?: string;
  currentPeriodEnd?: string;
}

const INPUT_CLASS =
  "bg-card-bg border border-separator rounded-sm px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange/40";

function StatusBadge({ status }: { status?: string }) {
  const color =
    status === "active"
      ? "bg-green-100 text-green-800"
      : status === "canceled"
        ? "bg-red-100 text-red-800"
        : status === "past_due"
          ? "bg-yellow-100 text-yellow-800"
          : "bg-gray-100 text-gray-600";

  return (
    <span className={`inline-block px-2 py-0.5 rounded text-xs font-mono uppercase tracking-wide ${color}`}>
      {status ?? "unknown"}
    </span>
  );
}

const columns: Column<SubscriptionRow>[] = [
  {
    key: "user",
    header: "User",
    render: (row) => (
      <div>
        <p className="text-sm text-navy font-medium">{row.name ?? "—"}</p>
        <p className="text-xs text-text-secondary">{row.email ?? "—"}</p>
      </div>
    ),
  },
  { key: "tier", header: "Tier", sortable: true },
  {
    key: "status",
    header: "Status",
    render: (row) => <StatusBadge status={row.status} />,
    sortable: true,
  },
  {
    key: "currentPeriodEnd",
    header: "Period End",
    render: (row) =>
      row.currentPeriodEnd
        ? new Date(row.currentPeriodEnd).toLocaleDateString()
        : "—",
    sortable: true,
  },
];

export default function SubscriptionsPage() {
  const [data, setData] = useState<SubscriptionRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [tierFilter, setTierFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");

  useEffect(() => {
    fetch("/api/admin/subscriptions")
      .then((r) => r.json())
      .then((d: SubscriptionRow[]) => setData(Array.isArray(d) ? d : []))
      .catch(() => setData([]))
      .finally(() => setLoading(false));
  }, []);

  const filtered = useMemo(() => {
    return data.filter((row) => {
      const tierOk = tierFilter === "all" || row.tier === tierFilter;
      const statusOk = statusFilter === "all" || row.status === statusFilter;
      return tierOk && statusOk;
    });
  }, [data, tierFilter, statusFilter]);

  const plusCount = data.filter((r) => r.tier === "plus").length;
  const premiumCount = data.filter((r) => r.tier === "premium").length;
  const totalPaying = plusCount + premiumCount;

  return (
    <div className="flex flex-col h-screen">
      <AdminHeader title="Subscriptions" />
      <div className="flex-1 overflow-y-auto p-6">
        <div className="grid grid-cols-3 gap-4 mb-6">
          <AdminStatCard label="Total Paying" value={loading ? "…" : totalPaying} />
          <AdminStatCard label="Plus" value={loading ? "…" : plusCount} />
          <AdminStatCard label="Premium" value={loading ? "…" : premiumCount} />
        </div>

        <div className="flex gap-4 mb-4">
          <select
            value={tierFilter}
            onChange={(e) => setTierFilter(e.target.value)}
            className={INPUT_CLASS}
          >
            <option value="all">All Tiers</option>
            <option value="plus">Plus</option>
            <option value="premium">Premium</option>
            <option value="free">Free</option>
          </select>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className={INPUT_CLASS}
          >
            <option value="all">All Statuses</option>
            <option value="active">Active</option>
            <option value="canceled">Canceled</option>
            <option value="past_due">Past Due</option>
          </select>
        </div>

        {loading ? (
          <p className="text-sm text-text-secondary">Loading...</p>
        ) : (
          <div className="bg-card-bg rounded-card border border-separator overflow-hidden">
            <DataTable
              columns={columns}
              data={filtered}
              rowKey={(row) => row.uid}
              searchPlaceholder="Search by name or email..."
              searchFn={(row, q) =>
                (row.name ?? "").toLowerCase().includes(q) ||
                (row.email ?? "").toLowerCase().includes(q)
              }
              emptyMessage="No subscriptions found."
            />
          </div>
        )}
      </div>
    </div>
  );
}
