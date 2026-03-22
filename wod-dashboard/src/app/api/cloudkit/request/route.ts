import { NextRequest, NextResponse } from "next/server";
import crypto from "crypto";

function signRequest(body: string, subpath: string): {
  keyID: string;
  date: string;
  signature: string;
} {
  const keyID = process.env.CLOUDKIT_SERVER_KEY_ID ?? "";
  const privateKeyPem = (process.env.CLOUDKIT_SERVER_PRIVATE_KEY ?? "").replace(
    /\\n/g,
    "\n"
  );

  const date = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");

  // CloudKit server-to-server signature: date:bodyHash:subpath
  const bodyHash = crypto
    .createHash("sha256")
    .update(body || "")
    .digest("base64");
  const message = `${date}:${bodyHash}:${subpath}`;

  const signature = crypto
    .sign("sha256", Buffer.from(message), crypto.createPrivateKey(privateKeyPem))
    .toString("base64");

  return { keyID, date, signature };
}

export async function POST(req: NextRequest) {
  try {
    const { ckMethod, path, body } = await req.json();

    const containerId = process.env.NEXT_PUBLIC_CLOUDKIT_CONTAINER ?? "";
    const env = process.env.CLOUDKIT_SERVER_ENV ?? "development";

    const subpath = `/database/1/${containerId}/${env}/public/${path}`;
    const url = `https://api.apple-cloudkit.com${subpath}`;

    const bodyStr = body ? JSON.stringify(body) : "";
    const { keyID, date, signature } = signRequest(bodyStr, subpath);

    const res = await fetch(url, {
      method: ckMethod || "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Apple-CloudKit-Request-KeyID": keyID,
        "X-Apple-CloudKit-Request-ISO8601Date": date,
        "X-Apple-CloudKit-Request-SignatureV1": signature,
      },
      body: bodyStr || undefined,
    });

    const data = await res.json();
    return NextResponse.json(data);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
