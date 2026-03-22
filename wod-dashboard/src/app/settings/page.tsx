"use client";

import { useState } from "react";

// ─── Types ────────────────────────────────────────────────────────────────────

type TestStatus = "idle" | "loading" | "success" | "error";

// ─── Sub-components ───────────────────────────────────────────────────────────

function Card({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="border border-navy/15 rounded bg-white shadow-sm">
      <div className="px-5 py-3 border-b border-navy/10 bg-navy/[0.03]">
        <h2 className="text-sm font-semibold tracking-widest uppercase text-navy/60">
          {title}
        </h2>
      </div>
      <div className="px-5 py-4 space-y-3">{children}</div>
    </div>
  );
}

function ConfigRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-start gap-4">
      <span className="w-52 shrink-0 text-sm font-medium text-navy/50">
        {label}
      </span>
      <span className="text-sm font-mono text-navy break-all">{value}</span>
    </div>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function SettingsPage() {
  const [testStatus, setTestStatus] = useState<TestStatus>("idle");
  const [testMessage, setTestMessage] = useState<string>("");

  // NEXT_PUBLIC_ vars are accessible client-side
  const cloudkitContainer =
    process.env.NEXT_PUBLIC_CLOUDKIT_CONTAINER ?? "(not set)";
  const cloudkitEnv = process.env.NEXT_PUBLIC_CLOUDKIT_ENV ?? "(not set)";
  const cloudkitToken = process.env.NEXT_PUBLIC_CLOUDKIT_API_TOKEN;
  const maskedToken = cloudkitToken
    ? cloudkitToken.slice(0, 6) + "••••••••" + cloudkitToken.slice(-4)
    : "(not set)";

  async function handleTestWorker() {
    setTestStatus("loading");
    setTestMessage("");
    try {
      const res = await fetch("/api/generate/wod", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          date: "2000-01-01",
          focusArea: "test",
          difficulty: "beginner",
          exerciseCount: 1,
          equipment: "none",
          notes: "connectivity-check",
        }),
      });

      if (res.ok) {
        setTestStatus("success");
        setTestMessage("Worker is reachable and returned a valid response.");
      } else {
        const body = await res.json().catch(() => ({}));
        setTestStatus("error");
        setTestMessage(
          `HTTP ${res.status}: ${body?.error ?? res.statusText}`
        );
      }
    } catch (e) {
      setTestStatus("error");
      setTestMessage(String(e));
    }
  }

  return (
    <div className="max-w-2xl space-y-6">
      <h1 className="text-2xl font-bold tracking-tight text-navy">Settings</h1>

      {/* Configuration */}
      <Card title="Configuration">
        <ConfigRow label="Cloudflare Worker URL" value="(server-only env var — tested via API route below)" />
        <ConfigRow label="CloudKit Container" value={cloudkitContainer} />
        <ConfigRow label="CloudKit Environment" value={cloudkitEnv} />
        <ConfigRow label="CloudKit API Token" value={maskedToken} />
        <p className="text-xs text-navy/40 pt-1">
          These values are read from environment variables at build time and
          cannot be changed at runtime.
        </p>
      </Card>

      {/* Connection Test */}
      <Card title="Connection Test">
        <p className="text-sm text-navy/60">
          Sends a minimal POST to{" "}
          <code className="text-xs bg-navy/5 px-1 py-0.5 rounded font-mono">
            /api/generate/wod
          </code>{" "}
          to verify the Cloudflare Worker is reachable from the server.
        </p>

        <div className="flex items-center gap-3 pt-1">
          <button
            onClick={handleTestWorker}
            disabled={testStatus === "loading"}
            className="px-4 py-2 rounded border border-orange text-sm font-semibold text-white bg-orange hover:bg-orange/90 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {testStatus === "loading" ? "Testing…" : "Test Worker Connection"}
          </button>

          {testStatus === "success" && (
            <span className="flex items-center gap-1.5 text-sm font-medium text-green-700">
              <span className="w-2 h-2 rounded-full bg-green-500 inline-block" />
              Connected
            </span>
          )}

          {testStatus === "error" && (
            <span className="flex items-center gap-1.5 text-sm font-medium text-red-700">
              <span className="w-2 h-2 rounded-full bg-red-500 inline-block" />
              Failed
            </span>
          )}
        </div>

        {testMessage && (
          <p
            className={`text-xs mt-1 font-mono px-3 py-2 rounded ${
              testStatus === "success"
                ? "bg-green-50 text-green-800 border border-green-200"
                : "bg-red-50 text-red-800 border border-red-200"
            }`}
          >
            {testMessage}
          </p>
        )}
      </Card>

      {/* CloudKit Auth Status */}
      <Card title="CloudKit Auth Status">
        <p className="text-sm text-navy/60 italic">
          CloudKit authentication will be configured in a future update.
        </p>
      </Card>
    </div>
  );
}
