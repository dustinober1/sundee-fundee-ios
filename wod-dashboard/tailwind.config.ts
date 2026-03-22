import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        cream: "#F4F0DF",
        navy: "#0D1A40",
        orange: "#F2731A",
      },
    },
  },
  plugins: [],
};

export default config;
