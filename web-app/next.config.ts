import type { NextConfig } from "next";
import withSerwistInit from "@serwist/next";

const withSerwist = withSerwistInit({
  swSrc: "src/app/sw.ts",
  swDest: "public/sw.js",
  // Disable in development — serwist uses webpack which conflicts with Next 16 Turbopack in dev mode
  disable: process.env.NODE_ENV !== "production",
});

const nextConfig: NextConfig = {
  // Required to avoid "webpack config with no turbopack config" error in Next 16
  turbopack: {},
};

export default withSerwist(nextConfig);
