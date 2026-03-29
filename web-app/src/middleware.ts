import { NextResponse, type NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const sessionCookie = request.cookies.get("__session")?.value;

  if (!sessionCookie) {
    const signInUrl = new URL("/sign-in", request.url);
    return NextResponse.redirect(signInUrl);
  }

  return NextResponse.next();
}

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
