"use client";

import { useEffect, useState } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { ConfirmDialog } from "@/components/admin/confirm-dialog";
import { Button } from "@/components/ui/button";

interface AdminUser {
  uid: string;
  email?: string;
  role?: string;
  addedAt?: string;
}

const INPUT_CLASS =
  "w-full bg-card-bg border border-separator rounded-sm px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange/40";

const EXPORT_COLLECTIONS = [
  { key: "wods", label: "WODs" },
  { key: "programs", label: "Programs" },
  { key: "benchmarkDefinitions", label: "Benchmark Definitions" },
  { key: "exerciseCatalog", label: "Exercise Catalog" },
  { key: "blogPosts", label: "Blog Posts" },
  { key: "supportArticles", label: "Support Articles" },
  { key: "aiPrompts", label: "AI Prompts" },
];

export default function SettingsPage() {
  const [admins, setAdmins] = useState<AdminUser[]>([]);
  const [adminsLoading, setAdminsLoading] = useState(true);
  const [newUid, setNewUid] = useState("");
  const [newEmail, setNewEmail] = useState("");
  const [addError, setAddError] = useState<string | null>(null);
  const [adding, setAdding] = useState(false);
  const [confirmDeleteUid, setConfirmDeleteUid] = useState<string | null>(null);
  const [importStatus, setImportStatus] = useState<Record<string, string>>({});

  async function loadAdmins() {
    setAdminsLoading(true);
    try {
      const res = await fetch("/api/admin/settings/admins");
      const data: AdminUser[] = await res.json();
      setAdmins(Array.isArray(data) ? data : []);
    } catch {
      setAdmins([]);
    } finally {
      setAdminsLoading(false);
    }
  }

  useEffect(() => {
    loadAdmins();
  }, []);

  async function handleAddAdmin() {
    setAddError(null);
    if (!newUid.trim()) {
      setAddError("UID is required.");
      return;
    }
    setAdding(true);
    try {
      const res = await fetch("/api/admin/settings/admins", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ uid: newUid.trim(), email: newEmail.trim() }),
      });
      if (res.ok) {
        setNewUid("");
        setNewEmail("");
        await loadAdmins();
      } else {
        const data = await res.json();
        setAddError(data.error ?? "Failed to add admin.");
      }
    } catch {
      setAddError("Network error.");
    } finally {
      setAdding(false);
    }
  }

  async function handleRemoveAdmin(uid: string) {
    try {
      const res = await fetch("/api/admin/settings/admins", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ uid }),
      });
      if (!res.ok) {
        const data = await res.json();
        setAddError(data.error ?? "Failed to remove admin.");
        return;
      }
    } catch {
      setAddError("Network error.");
      return;
    } finally {
      setConfirmDeleteUid(null);
    }
    await loadAdmins();
  }

  function handleExport(collection: string) {
    window.open(`/api/admin/export/${collection}`, "_blank");
  }

  async function handleImport(collection: string, file: File) {
    setImportStatus((prev) => ({ ...prev, [collection]: "Importing..." }));
    try {
      const text = await file.text();
      const json = JSON.parse(text);
      const res = await fetch(`/api/admin/import/${collection}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(json),
      });
      if (res.ok) {
        setImportStatus((prev) => ({ ...prev, [collection]: "Import successful." }));
      } else {
        const data = await res.json();
        setImportStatus((prev) => ({
          ...prev,
          [collection]: data.error ?? "Import failed.",
        }));
      }
    } catch {
      setImportStatus((prev) => ({ ...prev, [collection]: "Invalid JSON or network error." }));
    }
  }

  const adminToDelete = admins.find((a) => a.uid === confirmDeleteUid);

  return (
    <div className="flex flex-col h-screen">
      <AdminHeader title="Settings" />
      <div className="flex-1 overflow-y-auto p-6 max-w-3xl space-y-8">
        {/* Admin Allowlist */}
        <section className="bg-card-bg rounded-card border border-separator p-6">
          <h2 className="font-heading text-base text-navy mb-4">Admin Allowlist</h2>

          {adminsLoading ? (
            <p className="text-sm text-text-secondary">Loading...</p>
          ) : admins.length > 0 ? (
            <table className="w-full text-sm mb-6">
              <thead>
                <tr className="border-b border-separator">
                  <th className="text-left py-2 font-mono text-[10px] tracking-widest uppercase text-text-secondary">
                    Email
                  </th>
                  <th className="text-left py-2 font-mono text-[10px] tracking-widest uppercase text-text-secondary">
                    Role
                  </th>
                  <th className="text-left py-2 font-mono text-[10px] tracking-widest uppercase text-text-secondary">
                    Added
                  </th>
                  <th className="py-2" />
                </tr>
              </thead>
              <tbody>
                {admins.map((admin) => (
                  <tr key={admin.uid} className="border-b border-separator/50">
                    <td className="py-2 text-navy">{admin.email ?? admin.uid}</td>
                    <td className="py-2 text-text-secondary">{admin.role ?? "admin"}</td>
                    <td className="py-2 text-text-secondary text-xs">
                      {admin.addedAt ? new Date(admin.addedAt).toLocaleDateString() : "—"}
                    </td>
                    <td className="py-2 text-right">
                      <button
                        onClick={() => setConfirmDeleteUid(admin.uid)}
                        className="text-xs text-error hover:underline"
                      >
                        Remove
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <p className="text-sm text-text-secondary mb-4">No admins configured.</p>
          )}

          <h3 className="font-mono text-[10px] tracking-widest uppercase text-text-secondary mb-3">
            Add Admin
          </h3>
          <div className="flex gap-3 items-end">
            <div className="flex-1">
              <label className="font-mono text-[10px] tracking-widest uppercase text-text-secondary block mb-1">
                UID
              </label>
              <input
                type="text"
                value={newUid}
                onChange={(e) => setNewUid(e.target.value)}
                placeholder="Firebase UID"
                className={INPUT_CLASS}
              />
            </div>
            <div className="flex-1">
              <label className="font-mono text-[10px] tracking-widest uppercase text-text-secondary block mb-1">
                Email
              </label>
              <input
                type="email"
                value={newEmail}
                onChange={(e) => setNewEmail(e.target.value)}
                placeholder="admin@example.com"
                className={INPUT_CLASS}
              />
            </div>
            <Button
              variant="primary"
              onClick={handleAddAdmin}
              disabled={!newUid.trim() || adding}
            >
              {adding ? "Adding..." : "Add"}
            </Button>
          </div>
          {addError && <p className="text-xs text-error mt-2">{addError}</p>}
        </section>

        {/* Data Tools */}
        <section className="bg-card-bg rounded-card border border-separator p-6">
          <h2 className="font-heading text-base text-navy mb-4">Data Tools</h2>
          <div className="space-y-3">
            {EXPORT_COLLECTIONS.map(({ key, label }) => (
              <div
                key={key}
                className="flex items-center justify-between py-2 border-b border-separator/50"
              >
                <span className="text-sm text-navy font-medium">{label}</span>
                <div className="flex items-center gap-3">
                  {importStatus[key] && (
                    <span
                      className={`text-xs ${
                        importStatus[key].includes("successful")
                          ? "text-green-700"
                          : "text-text-secondary"
                      }`}
                    >
                      {importStatus[key]}
                    </span>
                  )}
                  <Button variant="secondary" onClick={() => handleExport(key)}>
                    Export
                  </Button>
                  <label className="cursor-pointer">
                    <span className="inline-flex items-center justify-center px-3 py-1.5 rounded-sm border border-separator text-xs font-medium text-text-secondary bg-card-bg hover:bg-orange/5 transition-colors">
                      Import
                    </span>
                    <input
                      type="file"
                      accept=".json"
                      className="hidden"
                      onChange={(e) => {
                        const file = e.target.files?.[0];
                        if (file) handleImport(key, file);
                        e.target.value = "";
                      }}
                    />
                  </label>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>

      <ConfirmDialog
        open={!!confirmDeleteUid}
        title="Remove Admin"
        message={`Remove ${adminToDelete?.email ?? confirmDeleteUid} from the admin allowlist?`}
        confirmLabel="Remove"
        onConfirm={() => confirmDeleteUid && handleRemoveAdmin(confirmDeleteUid)}
        onCancel={() => setConfirmDeleteUid(null)}
      />
    </div>
  );
}
