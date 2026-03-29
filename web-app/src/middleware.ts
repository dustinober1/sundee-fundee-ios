export { auth as middleware } from "@/lib/auth";

export const config = {
  matcher: [
    "/dashboard/:path*",
    "/workouts/:path*",
    "/programs/:path*",
    "/maxes/:path*",
    "/benchmarks/:path*",
    "/cycle/:path*",
    "/settings/:path*",
  ],
};
