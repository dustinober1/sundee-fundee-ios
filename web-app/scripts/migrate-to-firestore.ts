#!/usr/bin/env npx ts-node
import * as fs from "fs";
import * as path from "path";
import matter from "gray-matter";
import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

// ── Firebase Admin init ──────────────────────────────────────────────────────
// Requires env vars: FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY
if (getApps().length === 0) {
  initializeApp({
    credential: cert({
      projectId: process.env.FIREBASE_PROJECT_ID!,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL!,
      privateKey: process.env.FIREBASE_PRIVATE_KEY!.replace(/\\n/g, "\n"),
    }),
  });
}
const db = getFirestore();

// ── Helper: batch write ──────────────────────────────────────────────────────
async function batchWrite(
  collection: string,
  docs: { id: string; data: Record<string, unknown> }[]
) {
  const batchSize = 500;
  for (let i = 0; i < docs.length; i += batchSize) {
    const batch = db.batch();
    for (const { id, data } of docs.slice(i, i + batchSize)) {
      batch.set(db.collection(collection).doc(id), data);
    }
    await batch.commit();
    console.log(
      `  Wrote ${Math.min(i + batchSize, docs.length)} / ${docs.length} to ${collection}`
    );
  }
}

// ── Simple MDX → HTML converter (no external dep) ───────────────────────────
function mdxToHtml(mdx: string): string {
  // Strip MDX/JSX component tags
  let html = mdx.replace(/<[A-Z][^>]*>[\s\S]*?<\/[A-Z][^>]*>/g, "");
  // Self-closing MDX tags
  html = html.replace(/<[A-Z][^/]*\/>/g, "");
  // Headers
  html = html.replace(/^## (.+)$/gm, "<h2>$1</h2>");
  html = html.replace(/^### (.+)$/gm, "<h3>$1</h3>");
  html = html.replace(/^# (.+)$/gm, "<h1>$1</h1>");
  // Bold
  html = html.replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>");
  // List items
  html = html.replace(/^- (.+)$/gm, "<li>$1</li>");
  // Wrap consecutive <li> in <ul>
  html = html.replace(/(<li>.*<\/li>\n?)+/gs, (match) => `<ul>${match}</ul>`);
  // Paragraphs (non-empty lines not already block elements)
  html = html.replace(/^(?!<[hul]|$)(.+)$/gm, "<p>$1</p>");
  // Clean up extra blank lines
  html = html.replace(/\n{3,}/g, "\n\n").trim();
  return html;
}

async function main() {
  const ROOT = path.join(__dirname, "../..");

  // 1. WODs
  console.log("Migrating WODs...");
  const wods = JSON.parse(
    fs.readFileSync(path.join(ROOT, "wod-dashboard/data/wods.json"), "utf-8")
  ) as Record<string, unknown>[];
  await batchWrite(
    "wods",
    wods.map((w) => ({ id: w.id as string, data: w }))
  );

  // 2. Programs
  console.log("Migrating Programs...");
  const programs = JSON.parse(
    fs.readFileSync(path.join(ROOT, "wod-dashboard/data/programs.json"), "utf-8")
  ) as Record<string, unknown>[];
  await batchWrite(
    "programs",
    programs.map((p) => ({ id: p.id as string, data: p }))
  );

  // 3. Benchmark Definitions
  console.log("Migrating Benchmarks...");
  const benchmarks = JSON.parse(
    fs.readFileSync(path.join(ROOT, "wod-dashboard/data/benchmarks.json"), "utf-8")
  ) as Record<string, unknown>[];
  await batchWrite(
    "benchmarkDefinitions",
    benchmarks.map((b) => ({ id: b.id as string, data: b }))
  );

  // 4. Exercise Catalog — read from TS source, extract entries
  console.log("Migrating Exercise Catalog...");
  const catalogSrc = fs.readFileSync(
    path.join(ROOT, "web-app/src/lib/domain/exercise-catalog.ts"),
    "utf-8"
  );
  // Parse entries from source: lines like { id: "Back Squat", category: "Squat" }
  const entryRegex = /\{\s*id:\s*"([^"]+)",\s*category:\s*"([^"]+)"\s*\}/g;
  const entries: { id: string; name: string; category: string }[] = [];
  let match;
  while ((match = entryRegex.exec(catalogSrc)) !== null) {
    const name = match[1];
    const category = match[2];
    const id = name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "");
    entries.push({ id, name, category });
  }
  await batchWrite(
    "exerciseCatalog",
    entries.map((e) => ({ id: e.id, data: { name: e.name, category: e.category } }))
  );

  // 5. Blog Posts (all .mdx files in content/blog)
  console.log("Migrating Blog Posts...");
  const blogDir = path.join(ROOT, "content/blog");
  if (fs.existsSync(blogDir)) {
    const mdxFiles = fs.readdirSync(blogDir).filter((f) => f.endsWith(".mdx"));
    const blogDocs: { id: string; data: Record<string, unknown> }[] = [];
    for (const file of mdxFiles) {
      const slug = file.replace(/\.mdx$/, "");
      const raw = fs.readFileSync(path.join(blogDir, file), "utf-8");
      const { data: fm, content } = matter(raw);
      blogDocs.push({
        id: slug,
        data: {
          slug,
          title: fm.title ?? slug,
          description: fm.description ?? "",
          date: fm.date ?? "",
          author: fm.author ?? "",
          tags: fm.tags ?? [],
          image: fm.image ?? null,
          content: mdxToHtml(content),
          status: "published",
          updatedAt: new Date().toISOString(),
        },
      });
    }
    await batchWrite("blogPosts", blogDocs);
  }

  console.log("Migration complete.");
  process.exit(0);
}

main().catch((err) => {
  console.error("Migration failed:", err);
  process.exit(1);
});
