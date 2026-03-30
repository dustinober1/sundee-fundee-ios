"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV_GROUPS = [
  {
    label: "OVERVIEW",
    items: [{ name: "Dashboard", href: "/admin" }],
  },
  {
    label: "TRAINING",
    items: [
      { name: "WODs", href: "/admin/workouts/wods" },
      { name: "Programs", href: "/admin/workouts/programs" },
      { name: "Benchmarks", href: "/admin/workouts/benchmarks" },
      { name: "Exercise Catalog", href: "/admin/catalog" },
    ],
  },
  {
    label: "CONTENT",
    items: [
      { name: "Blog Posts", href: "/admin/content/blog" },
      { name: "Support Articles", href: "/admin/content/support" },
    ],
  },
  {
    label: "USERS",
    items: [
      { name: "User Management", href: "/admin/users" },
      { name: "Subscriptions", href: "/admin/subscriptions" },
    ],
  },
  {
    label: "AI",
    items: [
      { name: "Generated Workouts", href: "/admin/ai" },
      { name: "Prompts", href: "/admin/ai/prompts" },
      { name: "Rate Limits", href: "/admin/ai/rate-limits" },
    ],
  },
  {
    label: "SYSTEM",
    items: [{ name: "Settings", href: "/admin/settings" }],
  },
] as const;

export function AdminSidebar() {
  const pathname = usePathname();

  function isActive(href: string) {
    if (href === "/admin") return pathname === "/admin";
    return pathname.startsWith(href);
  }

  return (
    <aside className="w-60 shrink-0 bg-navy text-cream min-h-screen flex flex-col">
      <div className="px-5 py-6">
        <Link href="/admin" className="font-heading text-xl text-orange">
          Sundee Fundee
        </Link>
        <p className="font-mono text-[10px] tracking-[0.3em] uppercase text-gold mt-1">
          ADMIN
        </p>
      </div>
      <nav className="flex-1 px-3 pb-6 overflow-y-auto">
        {NAV_GROUPS.map((group) => (
          <div key={group.label} className="mb-5">
            <p className="font-mono text-[10px] tracking-[0.3em] uppercase text-gold px-2 mb-2">
              {group.label}
            </p>
            {group.items.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={`block px-3 py-2 rounded-button text-sm font-medium transition-colors ${
                  isActive(item.href)
                    ? "bg-orange text-white"
                    : "text-cream/70 hover:text-orange hover:bg-white/5"
                }`}
              >
                {item.name}
              </Link>
            ))}
          </div>
        ))}
      </nav>
    </aside>
  );
}
