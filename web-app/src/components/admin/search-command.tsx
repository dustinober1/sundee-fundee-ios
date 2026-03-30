"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";

const COMMANDS = [
  { name: "Dashboard", href: "/admin" },
  { name: "WODs", href: "/admin/workouts/wods" },
  { name: "Programs", href: "/admin/workouts/programs" },
  { name: "Benchmarks", href: "/admin/workouts/benchmarks" },
  { name: "Exercise Catalog", href: "/admin/catalog" },
  { name: "Blog Posts", href: "/admin/content/blog" },
  { name: "Support Articles", href: "/admin/content/support" },
  { name: "Users", href: "/admin/users" },
  { name: "Subscriptions", href: "/admin/subscriptions" },
  { name: "AI Generations", href: "/admin/ai" },
  { name: "AI Prompts", href: "/admin/ai/prompts" },
  { name: "Rate Limits", href: "/admin/ai/rate-limits" },
  { name: "Settings", href: "/admin/settings" },
];

export function SearchCommand() {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const router = useRouter();

  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setOpen((prev) => !prev);
      }
      if (e.key === "Escape") setOpen(false);
    }
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  if (!open) return null;

  const filtered = COMMANDS.filter((cmd) =>
    cmd.name.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[20vh]">
      <div className="absolute inset-0 bg-navy/40" onClick={() => setOpen(false)} />
      <div className="relative bg-card-bg rounded-card shadow-lg w-full max-w-md mx-4">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search pages..."
          className="w-full px-4 py-3 text-sm bg-transparent border-b border-separator focus:outline-none"
          autoFocus
        />
        <div className="max-h-64 overflow-y-auto py-2">
          {filtered.map((cmd) => (
            <button
              key={cmd.href}
              onClick={() => {
                router.push(cmd.href);
                setOpen(false);
                setQuery("");
              }}
              className="w-full text-left px-4 py-2.5 text-sm hover:bg-orange/5 transition-colors"
            >
              {cmd.name}
            </button>
          ))}
          {filtered.length === 0 && (
            <p className="px-4 py-2 text-sm text-text-secondary">No results</p>
          )}
        </div>
      </div>
    </div>
  );
}
