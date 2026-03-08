'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

export default function NavHeader() {
  const pathname = usePathname();

  const links = [
    { href: '/', label: 'Calendar' },
    { href: '/admin', label: 'Admin' },
  ];

  return (
    <header className="bg-navy text-cream">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <Link href="/" className="flex items-center gap-3">
            <span className="text-gold text-lg">&#9670;</span>
            <span className="text-2xl font-bold tracking-wide" style={{ fontFamily: 'Georgia, serif' }}>
              Sundee Fundee
            </span>
            <span className="text-orange text-sm font-medium tracking-widest uppercase">
              WOD Dashboard
            </span>
          </Link>
          <nav className="flex items-center gap-1">
            {links.map((link) => {
              const isActive = link.href === '/'
                ? pathname === '/'
                : pathname.startsWith(link.href);
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                    isActive
                      ? 'bg-orange text-cream'
                      : 'text-cream/70 hover:text-cream hover:bg-navy-light'
                  }`}
                >
                  {link.label}
                </Link>
              );
            })}
          </nav>
        </div>
      </div>
      {/* Art Deco gold-orange gradient border */}
      <div
        className="h-1"
        style={{
          background: 'linear-gradient(90deg, #D9B34A 0%, #F2731A 50%, #D9B34A 100%)',
        }}
      />
    </header>
  );
}
