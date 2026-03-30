"use client";

import { useEffect, useState } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { Button } from "@/components/ui/button";

interface AdminSettings {
  rateLimits: {
    free: number;
    plus: number;
    premium: number;
  };
  featureFlags: Record<string, boolean>;
}

const INPUT_CLASS =
  "w-full bg-card-bg border border-separator rounded-sm px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange/40";

const defaultSettings: AdminSettings = {
  rateLimits: { free: 0, plus: 1, premium: 10 },
  featureFlags: {},
};

export default function RateLimitsPage() {
  const [settings, setSettings] = useState<AdminSettings>(defaultSettings);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState<{ type: "success" | "error"; message: string } | null>(null);
  const [newFlagKey, setNewFlagKey] = useState("");
  const [newFlagValue, setNewFlagValue] = useState(false);

  useEffect(() => {
    fetch("/api/admin/settings")
      .then((r) => r.json())
      .then((data: AdminSettings) => {
        setSettings({
          rateLimits: data.rateLimits ?? defaultSettings.rateLimits,
          featureFlags: data.featureFlags ?? {},
        });
      })
      .catch(() => setSettings(defaultSettings))
      .finally(() => setLoading(false));
  }, []);

  function updateRateLimit(tier: keyof AdminSettings["rateLimits"], value: number) {
    setSettings((prev) => ({
      ...prev,
      rateLimits: { ...prev.rateLimits, [tier]: value },
    }));
  }

  function toggleFlag(key: string) {
    setSettings((prev) => ({
      ...prev,
      featureFlags: { ...prev.featureFlags, [key]: !prev.featureFlags[key] },
    }));
  }

  function addFlag() {
    if (!newFlagKey.trim()) return;
    setSettings((prev) => ({
      ...prev,
      featureFlags: { ...prev.featureFlags, [newFlagKey.trim()]: newFlagValue },
    }));
    setNewFlagKey("");
    setNewFlagValue(false);
  }

  async function handleSave() {
    setSaving(true);
    setFeedback(null);
    try {
      const res = await fetch("/api/admin/settings", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(settings),
      });
      if (res.ok) {
        setFeedback({ type: "success", message: "Settings saved successfully." });
      } else {
        setFeedback({ type: "error", message: "Failed to save settings." });
      }
    } catch {
      setFeedback({ type: "error", message: "Network error. Please try again." });
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <div className="flex flex-col h-screen">
        <AdminHeader title="Rate Limits & Settings" />
        <p className="p-6 text-sm text-text-secondary">Loading...</p>
      </div>
    );
  }

  const flagKeys = Object.keys(settings.featureFlags);

  return (
    <div className="flex flex-col h-screen">
      <AdminHeader title="Rate Limits & Settings" />
      <div className="flex-1 overflow-y-auto p-6 max-w-2xl">
        <section className="bg-card-bg rounded-card border border-separator p-6 mb-6">
          <h2 className="font-heading text-base text-navy mb-4">Daily AI Generation Limits</h2>
          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="font-mono text-[10px] tracking-widest uppercase text-text-secondary block mb-1">
                Free
              </label>
              <input
                type="number"
                min={0}
                value={settings.rateLimits.free}
                onChange={(e) => updateRateLimit("free", parseInt(e.target.value, 10) || 0)}
                className={INPUT_CLASS}
              />
            </div>
            <div>
              <label className="font-mono text-[10px] tracking-widest uppercase text-text-secondary block mb-1">
                Plus
              </label>
              <input
                type="number"
                min={0}
                value={settings.rateLimits.plus}
                onChange={(e) => updateRateLimit("plus", parseInt(e.target.value, 10) || 0)}
                className={INPUT_CLASS}
              />
            </div>
            <div>
              <label className="font-mono text-[10px] tracking-widest uppercase text-text-secondary block mb-1">
                Premium
              </label>
              <input
                type="number"
                min={0}
                value={settings.rateLimits.premium}
                onChange={(e) => updateRateLimit("premium", parseInt(e.target.value, 10) || 0)}
                className={INPUT_CLASS}
              />
            </div>
          </div>
        </section>

        <section className="bg-card-bg rounded-card border border-separator p-6 mb-6">
          <h2 className="font-heading text-base text-navy mb-4">Feature Flags</h2>
          {flagKeys.length > 0 && (
            <table className="w-full text-sm mb-4">
              <thead>
                <tr className="border-b border-separator">
                  <th className="text-left py-2 font-mono text-[10px] tracking-widest uppercase text-text-secondary">
                    Key
                  </th>
                  <th className="text-left py-2 font-mono text-[10px] tracking-widest uppercase text-text-secondary">
                    Enabled
                  </th>
                </tr>
              </thead>
              <tbody>
                {flagKeys.map((key) => (
                  <tr key={key} className="border-b border-separator/50">
                    <td className="py-2 text-navy font-mono text-xs">{key}</td>
                    <td className="py-2">
                      <input
                        type="checkbox"
                        checked={!!settings.featureFlags[key]}
                        onChange={() => toggleFlag(key)}
                        className="accent-orange"
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          <div className="flex gap-3 items-end">
            <div className="flex-1">
              <label className="font-mono text-[10px] tracking-widest uppercase text-text-secondary block mb-1">
                Flag Key
              </label>
              <input
                type="text"
                value={newFlagKey}
                onChange={(e) => setNewFlagKey(e.target.value)}
                placeholder="e.g. enable_new_feature"
                className={INPUT_CLASS}
              />
            </div>
            <div className="flex items-center gap-2 pb-2">
              <input
                type="checkbox"
                checked={newFlagValue}
                onChange={(e) => setNewFlagValue(e.target.checked)}
                className="accent-orange"
              />
              <span className="text-sm text-text-secondary">Enabled</span>
            </div>
            <Button
              variant="secondary"
              onClick={addFlag}
              disabled={!newFlagKey.trim()}
            >
              Add
            </Button>
          </div>
        </section>

        <div className="flex items-center gap-4">
          <Button variant="primary" onClick={handleSave} disabled={saving}>
            {saving ? "Saving..." : "Save Settings"}
          </Button>
          {feedback && (
            <p
              className={`text-sm ${feedback.type === "success" ? "text-green-700" : "text-error"}`}
            >
              {feedback.message}
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
