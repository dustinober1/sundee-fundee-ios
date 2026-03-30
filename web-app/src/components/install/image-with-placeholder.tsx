"use client";

import Image from "next/image";
import { useState } from "react";

export function ImageWithPlaceholder({ src, alt }: { src: string; alt: string }) {
  const [failed, setFailed] = useState(false);

  return (
    <div className="relative aspect-[9/19] sm:aspect-[9/16] max-h-[400px] bg-navy/5 flex items-center justify-center">
      {/* Placeholder shown while image doesn't exist */}
      <div className="absolute inset-0 flex flex-col items-center justify-center text-text-secondary p-4 text-center">
        <svg
          viewBox="0 0 48 48"
          className="w-12 h-12 text-gold/40 mb-3"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.5"
        >
          <rect x="8" y="8" width="32" height="32" rx="4" />
          <circle cx="18" cy="20" r="4" fill="currentColor" opacity="0.2" />
          <path d="M12 32 L20 24 L26 28 L36 18" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
        <p className="font-mono text-[10px] tracking-[0.15em] uppercase text-gold/60">Screenshot Coming Soon</p>
        <p className="text-[11px] mt-1 opacity-70">{src.split("/").pop()}</p>
      </div>
      {/* Actual image (will show when file exists) */}
      {!failed && (
        <Image
          src={src}
          alt={alt}
          fill
          className="object-contain relative z-10"
          onError={() => setFailed(true)}
        />
      )}
    </div>
  );
}
