import type { JwtPayload } from "./types";

const MAX_AGE_SECONDS = 300; // 5 minutes

export async function verifyJwt(token: string, secret: string): Promise<JwtPayload> {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Malformed token");

  const [headerB64, payloadB64, signatureB64] = parts;

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );

  const data = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
  const signature = base64UrlDecode(signatureB64);

  const valid = await crypto.subtle.verify("HMAC", key, signature, data);
  if (!valid) throw new Error("Invalid signature");

  const payload = JSON.parse(new TextDecoder().decode(base64UrlDecode(payloadB64)));

  if (!payload.sub) throw new Error("Missing sub");
  if (!payload.tier || (payload.tier !== "plus" && payload.tier !== "premium")) {
    throw new Error("Invalid tier");
  }

  const now = Math.floor(Date.now() / 1000);
  if (now - payload.iat > MAX_AGE_SECONDS) throw new Error("Token expired");

  return { sub: payload.sub, tier: payload.tier, iat: payload.iat };
}

export async function createJwt(payload: Record<string, unknown>, secret: string): Promise<string> {
  const header = { alg: "HS256", typ: "JWT" };
  const headerB64 = base64UrlEncode(JSON.stringify(header));
  const payloadB64 = base64UrlEncode(JSON.stringify(payload));

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const data = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
  const signature = await crypto.subtle.sign("HMAC", key, data);

  return `${headerB64}.${payloadB64}.${base64UrlEncode(signature)}`;
}

function base64UrlEncode(input: string | ArrayBuffer): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : new Uint8Array(input);
  const binString = Array.from(bytes, (b) => String.fromCodePoint(b)).join("");
  return btoa(binString).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlDecode(input: string): Uint8Array {
  const padded = input.replace(/-/g, "+").replace(/_/g, "/");
  const binString = atob(padded);
  return Uint8Array.from(binString, (c) => c.codePointAt(0)!);
}
