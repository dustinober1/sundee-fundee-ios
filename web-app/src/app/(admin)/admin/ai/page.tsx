"use client";

import { useEffect, useState } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { DataTable, Column } from "@/components/admin/data-table";
import { DetailPanel } from "@/components/admin/detail-panel";
import { EmptyState } from "@/components/admin/empty-state";

interface GenerationRow {
  id: string;
  uid?: string;
  email?: string;
  createdAt?: string;
  exercises?: unknown[];
  [key: string]: unknown;
}

const columns: Column<GenerationRow>[] = [
  { key: "email", header: "User", sortable: true },
  {
    key: "createdAt",
    header: "Date",
    render: (row) =>
      row.createdAt ? new Date(row.createdAt).toLocaleString() : "—",
    sortable: true,
  },
  {
    key: "exerciseCount",
    header: "Exercise Count",
    render: (row) =>
      String(Array.isArray(row.exercises) ? row.exercises.length : 0),
  },
];

export default function AIGenerationsPage() {
  const [data, setData] = useState<GenerationRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<GenerationRow | null>(null);

  useEffect(() => {
    fetch("/api/admin/ai/generations")
      .then((r) => r.json())
      .then((d: GenerationRow[]) => setData(Array.isArray(d) ? d : []))
      .catch(() => setData([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="flex flex-col h-screen">
      <AdminHeader title="Generated Workouts" />
      <div className="flex flex-1 overflow-hidden">
        <div className={`flex flex-col overflow-hidden ${selected ? "w-1/2" : "flex-1"}`}>
          {loading ? (
            <p className="p-6 text-sm text-text-secondary">Loading...</p>
          ) : data.length === 0 ? (
            <EmptyState title="No generated workouts found." description="No AI-generated workout records exist yet." />
          ) : (
            <DataTable
              columns={columns}
              data={data}
              rowKey={(row) => row.id}
              onRowClick={(row) => setSelected(row)}
              selectedKey={selected?.id ?? null}
              searchPlaceholder="Search by email..."
              searchFn={(row, q) => (row.email ?? "").toLowerCase().includes(q)}
            />
          )}
        </div>

        {selected && (
          <div className="w-1/2 overflow-hidden">
            <DetailPanel
              title={selected.email ?? "Generation Detail"}
              onClose={() => setSelected(null)}
            >
              <pre className="text-xs font-mono overflow-auto whitespace-pre-wrap break-all text-navy">
                {JSON.stringify(selected, null, 2)}
              </pre>
            </DetailPanel>
          </div>
        )}
      </div>
    </div>
  );
}
