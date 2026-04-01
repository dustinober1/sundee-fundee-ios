import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { adminAuth } from "@/lib/firebase-admin";

// Stay slightly under Firebase's 2-week hard limit to avoid boundary validation failures.
const SESSION_EXPIRY_MS = 13 * 24 * 60 * 60 * 1000; // 13 days

export async function POST(request: Request) {
  const { idToken } = (await request.json()) as { idToken: string };

  try {
    await adminAuth.verifyIdToken(idToken);

    const sessionCookie = await adminAuth.createSessionCookie(idToken, {
      expiresIn: SESSION_EXPIRY_MS,
    });

    const cookieStore = await cookies();
    cookieStore.set("__session", sessionCookie, {
      maxAge: SESSION_EXPIRY_MS / 1000,
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      path: "/",
      sameSite: "lax",
    });

    return NextResponse.json({ success: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown auth error";
    const isConfigError =
      message.includes("Firebase Admin credentials are missing") ||
      message.includes("credential") ||
      message.includes("Could not load the default credentials");

    const isInvalidTokenError =
      message.includes("verifyIdToken") ||
      message.includes("ID token") ||
      message.includes("incorrect \"aud\"") ||
      message.includes("issuer") ||
      message.includes("expired");

    console.error("[auth/session] Failed to create session cookie", {
      message,
      isConfigError,
      isInvalidTokenError,
    });

    if (isConfigError) {
      return NextResponse.json(
        {
          error:
            process.env.NODE_ENV === "production"
              ? "Authentication server configuration is incomplete."
              : message,
        },
        { status: 500 },
      );
    }

    return NextResponse.json(
      {
        error:
          process.env.NODE_ENV === "production"
            ? "Invalid token"
            : message,
      },
      { status: 401 },
    );
  }
}

export async function DELETE() {
  const cookieStore = await cookies();
  cookieStore.delete("__session");
  return NextResponse.json({ success: true });
}
