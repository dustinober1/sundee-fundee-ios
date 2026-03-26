import * as functions from "firebase-functions";
import * as crypto from "crypto";

const APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token";
const APPLE_REVOKE_URL = "https://appleid.apple.com/auth/revoke";

interface SiwaConfig {
  teamId: string;
  clientId: string;
  keyId: string;
  privateKey: string; // PEM-encoded P256 private key
}

function loadConfig(): SiwaConfig {
  const config = functions.config();
  return {
    teamId: config.siwa?.team_id ?? process.env.SIWA_TEAM_ID ?? "",
    clientId: config.siwa?.client_id ?? process.env.SIWA_CLIENT_ID ?? "",
    keyId: config.siwa?.key_id ?? process.env.SIWA_KEY_ID ?? "",
    privateKey: (config.siwa?.private_key ?? process.env.SIWA_PRIVATE_KEY ?? "")
      .replace(/\\n/g, "\n"),
  };
}

function generateClientSecret(config: SiwaConfig): string {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "ES256", kid: config.keyId };
  const payload = {
    iss: config.teamId,
    iat: now,
    exp: now + 15777000, // ~6 months
    aud: "https://appleid.apple.com",
    sub: config.clientId,
  };

  const encodedHeader = base64url(JSON.stringify(header));
  const encodedPayload = base64url(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;

  const sign = crypto.createSign("SHA256");
  sign.update(signingInput);
  const derSignature = sign.sign(config.privateKey);

  // Convert DER signature to raw r||s format for ES256
  const rawSignature = derToRaw(derSignature);
  const encodedSignature = base64url(rawSignature);

  return `${signingInput}.${encodedSignature}`;
}

function base64url(input: string | Buffer): string {
  const buf = typeof input === "string" ? Buffer.from(input, "utf8") : input;
  return buf.toString("base64url");
}

function derToRaw(derSig: Buffer): Buffer {
  // DER: 0x30 [total-len] 0x02 [r-len] [r] 0x02 [s-len] [s]
  let offset = 2; // skip 0x30 and total length
  if (derSig[1] & 0x80) offset += (derSig[1] & 0x7f);

  // r
  offset += 1; // skip 0x02
  const rLen = derSig[offset++];
  const rStart = offset;
  offset += rLen;

  // s
  offset += 1; // skip 0x02
  const sLen = derSig[offset++];
  const sStart = offset;

  const raw = Buffer.alloc(64);
  const r = derSig.subarray(rStart, rStart + rLen);
  const s = derSig.subarray(sStart, sStart + sLen);

  // Pad/trim to 32 bytes each
  r.copy(raw, 32 - r.length > 0 ? 32 - r.length : 0, r.length > 32 ? r.length - 32 : 0);
  s.copy(raw, 64 - s.length > 0 ? 64 - s.length : 0, s.length > 32 ? s.length - 32 : 0);

  return raw;
}

// Exchange an authorization code for a refresh token.
export const siwaExchangeCode = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({error: "Method not allowed"});
    return;
  }

  const {authorizationCode} = req.body;
  if (!authorizationCode) {
    res.status(400).json({error: "authorizationCode is required"});
    return;
  }

  const config = loadConfig();
  if (!config.privateKey || !config.keyId) {
    res.status(500).json({error: "SIWA configuration not set"});
    return;
  }

  const clientSecret = generateClientSecret(config);

  const params = new URLSearchParams({
    client_id: config.clientId,
    client_secret: clientSecret,
    code: authorizationCode,
    grant_type: "authorization_code",
  });

  const response = await fetch(APPLE_TOKEN_URL, {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: params.toString(),
  });

  if (!response.ok) {
    const text = await response.text();
    console.error("Apple token exchange failed:", response.status, text);
    res.status(502).json({error: "Token exchange failed"});
    return;
  }

  const data = await response.json() as { refresh_token?: string };
  if (!data.refresh_token) {
    res.status(502).json({error: "No refresh token returned"});
    return;
  }

  res.json({refreshToken: data.refresh_token});
});

// Revoke a refresh token (called during account deletion).
export const siwaRevokeToken = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({error: "Method not allowed"});
    return;
  }

  const {refreshToken} = req.body;
  if (!refreshToken) {
    res.status(400).json({error: "refreshToken is required"});
    return;
  }

  const config = loadConfig();
  if (!config.privateKey || !config.keyId) {
    res.status(500).json({error: "SIWA configuration not set"});
    return;
  }

  const clientSecret = generateClientSecret(config);

  const params = new URLSearchParams({
    client_id: config.clientId,
    client_secret: clientSecret,
    token: refreshToken,
    token_type_hint: "refresh_token",
  });

  const response = await fetch(APPLE_REVOKE_URL, {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: params.toString(),
  });

  if (!response.ok) {
    const text = await response.text();
    console.error("Apple token revocation failed:", response.status, text);
    res.status(502).json({error: "Token revocation failed"});
    return;
  }

  res.json({success: true});
});
