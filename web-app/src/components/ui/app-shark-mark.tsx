const WATER = "#0d4f78";
const WATER_DARK = "#09395c";
const HIGHLIGHT = "#d9f0ff";
const SPLASH = "#2f7eb1";
const BG = "#f7f6f2";

export function AppSharkMark({ size = 512 }: { size?: number }) {
  const stroke = Math.max(6, size * 0.018);
  const finStroke = Math.max(8, size * 0.022);
  const eye = Math.max(4, size * 0.008);

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 512 512"
      width={size}
      height={size}
      aria-hidden="true"
    >
      <rect width="512" height="512" rx="108" fill={BG} />

      <g fill="none" stroke={WATER} strokeLinecap="round" strokeLinejoin="round">
        <ellipse cx="256" cy="334" rx="156" ry="40" strokeWidth={stroke} />
        <ellipse cx="256" cy="348" rx="126" ry="28" strokeWidth={stroke * 0.9} />
        <path d="M146 320c26 16 58 24 110 24s92-8 116-24" strokeWidth={stroke * 0.9} />
        <path d="M166 368c24 8 53 12 90 12 34 0 70-4 95-13" strokeWidth={stroke * 0.85} />
        <path d="M215 306c16 10 30 14 41 14 11 0 25-4 41-14" strokeWidth={stroke * 0.75} />
      </g>

      <g fill={SPLASH}>
        <path d="M170 274c-14 0-24 10-24 23 16 0 28-4 36-13-4-6-7-10-12-10Z" />
        <path d="M191 262c-8 0-13 7-13 16 10 0 17-3 22-10-2-4-4-6-9-6Z" />
        <path d="M346 275c14 0 24 10 24 23-16 0-28-4-36-13 4-6 7-10 12-10Z" />
        <path d="M367 263c8 0 13 7 13 16-10 0-17-3-22-10 2-4 4-6 9-6Z" />
      </g>

      <g>
        <path
          d="M207 306c18-86 72-177 137-212-18 40-31 86-41 133l-26 10c-9 25-12 49-10 69-22 4-41 5-60 0Z"
          fill={WATER}
          stroke={WATER_DARK}
          strokeWidth={finStroke}
          strokeLinejoin="round"
        />
        <path
          d="M230 298c23-88 64-153 125-189-23 44-41 96-55 159"
          fill="none"
          stroke={HIGHLIGHT}
          strokeWidth={stroke * 0.95}
          strokeLinecap="round"
        />
        <path
          d="M248 299c12-54 34-107 71-150"
          fill="none"
          stroke={HIGHLIGHT}
          strokeWidth={stroke * 0.6}
          strokeLinecap="round"
          opacity="0.95"
        />
        <path
          d="M269 241c10-4 19-11 28-21"
          fill="none"
          stroke={WATER_DARK}
          strokeWidth={stroke * 0.45}
          strokeLinecap="round"
        />
        <path
          d="M263 261c9-4 18-10 27-20"
          fill="none"
          stroke={WATER_DARK}
          strokeWidth={stroke * 0.45}
          strokeLinecap="round"
        />
        <circle cx="285" cy="290" r={eye} fill={HIGHLIGHT} />
      </g>
    </svg>
  );
}
