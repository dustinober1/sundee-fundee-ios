import type { Env, WorkoutRequest, ErrorResponse } from "./types";
import { verifyJwt } from "./auth";
import { checkRateLimit } from "./rate-limit";
import { generateWorkout } from "./ai";

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders() },
  });
}

function errorResponse(error: string, message: string, status: number, extra?: Partial<ErrorResponse>): Response {
  return jsonResponse({ error, message, ...extra }, status);
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    const url = new URL(request.url);

    if (request.method !== "POST" || url.pathname !== "/generate-workout") {
      return errorResponse("not_found", "POST /generate-workout is the only endpoint", 404);
    }

    // 1. Authenticate
    const authHeader = request.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return errorResponse("unauthorized", "Missing Authorization header", 401);
    }

    const token = authHeader.slice(7);
    let jwt;
    try {
      jwt = await verifyJwt(token, env.JWT_SECRET);
    } catch (err) {
      return errorResponse("unauthorized", (err as Error).message, 401);
    }

    // 2. Rate limit
    const rateResult = await checkRateLimit(env.RATE_LIMIT, jwt.sub, jwt.tier);
    if (!rateResult.allowed) {
      return errorResponse("rate_limited", "Daily limit exceeded", 429, {
        remaining: 0,
        resetsAt: rateResult.resetsAt,
      });
    }

    // 3. Parse request body
    let body: WorkoutRequest;
    try {
      body = await request.json() as WorkoutRequest;
    } catch {
      return errorResponse("bad_request", "Invalid JSON body", 400);
    }

    if (!body.prompt || !body.systemInstruction) {
      return errorResponse("bad_request", "Missing prompt or systemInstruction", 400);
    }

    // 4. Generate workout
    try {
      const workout = await generateWorkout(env.AI, jwt.tier, body.prompt, body.systemInstruction);
      return jsonResponse(workout, 200);
    } catch (err) {
      return errorResponse("generation_failed", (err as Error).message, 500);
    }
  },
} satisfies ExportedHandler<Env>;
