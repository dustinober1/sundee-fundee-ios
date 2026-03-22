"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV_LINKS = [
  { href: "/wods", label: "WODs" },
  { href: "/programs", label: "Programs" },
  { href: "/catalog", label: "Exercise Catalog" },
  { href: "/settings", label: "Settings" },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <nav className="w-60 bg-navy text-cream p-4 flex flex-col gap-2">
      <h1 className="text-xl font-bold mb-6 text-orange">Sundee Fundee</h1>
      {NAV_LINKS.map(({ href, label }) => {
        const isActive = pathname === href;
        return (
          <Link
            key={href}
            href={href}
            className={`px-3 py-2 rounded transition-colors ${
              isActive
                ? "bg-orange text-white"
                : "hover:text-orange"
            }`}
          >
            {label}
          </Link>
        );
      })}
    </nav>
  );
}
