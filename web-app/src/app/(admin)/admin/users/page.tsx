"use client";

import { useEffect, useState } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { DataTable, Column } from "@/components/admin/data-table";
import { DetailPanel } from "@/components/admin/detail-panel";
import { EmptyState } from "@/components/admin/empty-state";

interface UserRow {
  uid: string;
  name?: string;
  email?: string;
  tier?: string;
  experienceLevel?: string;
}

interface OneRepMax {
  id?: string;
  exercise?: string;
  value?: number;
  weight?: number;
  date?: string;
}

interface UserDetail extends UserRow {
  gender?: string;
  primaryGoal?: string;
  weightUnit?: string;
  cycleTrackingEnabled?: boolean;
  subscription?: {
    tier?: string;
    status?: string;
    stripeCustomerId?: string;
  } | null;
  completedWorkoutCount?: number;
  benchmarkResultCount?: number;
  oneRepMaxes?: OneRepMax[];
}

const columns: Column<UserRow>[] = [
  { key: "name", header: "Name", sortable: true },
  { key: "email", header: "Email", sortable: true },
  { key: "tier", header: "Tier", sortable: true },
  { key: "experienceLevel", header: "Experience Level", sortable: true },
];

function LabelValue({ label, value }: { label: string; value?: string | number | boolean | null }) {
  return (
    <div className="flex flex-col gap-0.5 mb-3">
      <span className="font-mono text-[10px] tracking-widest uppercase text-text-secondary">{label}</span>
      <span className="text-sm text-navy">{value != null ? String(value) : "—"}</span>
    </div>
  );
}

function SectionTitle({ children }: { children: React.ReactNode }) {
  return (
    <h3 className="font-heading text-base text-navy mb-3 mt-5 first:mt-0 border-b border-separator pb-1">{children}</h3>
  );
}

export default function UsersPage() {
  const [users, setUsers] = useState<UserRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUid, setSelectedUid] = useState<string | null>(null);
  const [detail, setDetail] = useState<UserDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);

  useEffect(() => {
    fetch("/api/admin/users")
      .then((r) => r.json())
      .then((data: UserRow[]) => setUsers(Array.isArray(data) ? data : []))
      .catch(() => setUsers([]))
      .finally(() => setLoading(false));
  }, []);

  async function handleRowClick(row: UserRow) {
    setSelectedUid(row.uid);
    setDetailLoading(true);
    try {
      const res = await fetch(`/api/admin/users/${row.uid}`);
      const data: UserDetail = await res.json();
      setDetail(data);
    } catch {
      setDetail(null);
    } finally {
      setDetailLoading(false);
    }
  }

  return (
    <div className="flex flex-col h-screen">
      <AdminHeader title="Users" />
      <div className="flex flex-1 overflow-hidden">
        <div className={`flex flex-col overflow-hidden ${selectedUid ? "w-1/2" : "flex-1"}`}>
          {loading ? (
            <p className="p-6 text-sm text-text-secondary">Loading...</p>
          ) : users.length === 0 ? (
            <EmptyState title="No users found." description="No users have been registered yet." />
          ) : (
            <DataTable
              columns={columns}
              data={users}
              rowKey={(row) => row.uid}
              onRowClick={handleRowClick}
              selectedKey={selectedUid}
              searchPlaceholder="Search by name or email..."
              searchFn={(row, q) =>
                (row.name ?? "").toLowerCase().includes(q) ||
                (row.email ?? "").toLowerCase().includes(q)
              }
            />
          )}
        </div>

        {selectedUid && (
          <div className="w-1/2 overflow-hidden">
            <DetailPanel
              title={detail?.name ?? detail?.email ?? "User Detail"}
              onClose={() => {
                setSelectedUid(null);
                setDetail(null);
              }}
            >
              {detailLoading ? (
                <p className="text-sm text-text-secondary">Loading...</p>
              ) : detail ? (
                <div>
                  <SectionTitle>Profile</SectionTitle>
                  <LabelValue label="Name" value={detail.name} />
                  <LabelValue label="Email" value={detail.email} />
                  <LabelValue label="Gender" value={detail.gender} />
                  <LabelValue label="Experience Level" value={detail.experienceLevel} />
                  <LabelValue label="Primary Goal" value={detail.primaryGoal} />
                  <LabelValue label="Weight Unit" value={detail.weightUnit} />
                  <LabelValue label="Cycle Tracking" value={detail.cycleTrackingEnabled != null ? String(detail.cycleTrackingEnabled) : undefined} />

                  <SectionTitle>Subscription</SectionTitle>
                  <LabelValue label="Tier" value={detail.subscription?.tier} />
                  <LabelValue label="Status" value={detail.subscription?.status} />
                  {detail.subscription?.stripeCustomerId && (
                    <div className="flex flex-col gap-0.5 mb-3">
                      <span className="font-mono text-[10px] tracking-widest uppercase text-text-secondary">Stripe Customer</span>
                      <a
                        href={`https://dashboard.stripe.com/customers/${detail.subscription.stripeCustomerId}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-sm text-orange hover:underline"
                      >
                        {detail.subscription.stripeCustomerId}
                      </a>
                    </div>
                  )}

                  <SectionTitle>Activity</SectionTitle>
                  <LabelValue label="Completed Workouts" value={detail.completedWorkoutCount} />
                  <LabelValue label="Benchmark Results" value={detail.benchmarkResultCount} />
                  <LabelValue label="1RM Records" value={detail.oneRepMaxes?.length ?? 0} />

                  {detail.oneRepMaxes && detail.oneRepMaxes.length > 0 && (
                    <>
                      <SectionTitle>1RM Records</SectionTitle>
                      <table className="w-full text-xs">
                        <thead>
                          <tr className="border-b border-separator">
                            <th className="text-left py-1.5 font-mono uppercase tracking-wider text-text-secondary">Exercise</th>
                            <th className="text-left py-1.5 font-mono uppercase tracking-wider text-text-secondary">Weight</th>
                            <th className="text-left py-1.5 font-mono uppercase tracking-wider text-text-secondary">Date</th>
                          </tr>
                        </thead>
                        <tbody>
                          {detail.oneRepMaxes.map((orm, i) => (
                            <tr key={orm.id ?? i} className="border-b border-separator/50">
                              <td className="py-1.5 text-navy">{orm.exercise ?? "—"}</td>
                              <td className="py-1.5 text-navy">{orm.value ?? orm.weight ?? "—"}</td>
                              <td className="py-1.5 text-text-secondary">{orm.date ?? "—"}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </>
                  )}
                </div>
              ) : (
                <p className="text-sm text-text-secondary">Failed to load user detail.</p>
              )}
            </DetailPanel>
          </div>
        )}
      </div>
    </div>
  );
}
