import { readJSONFile, writeJSONFile } from "../src/lib/file-io";
import fs from "fs";
import path from "path";
import os from "os";

describe("file-io", () => {
  let tmpFile: string;

  beforeEach(() => {
    tmpFile = path.join(os.tmpdir(), `test-${Date.now()}.json`);
  });

  afterEach(() => {
    if (fs.existsSync(tmpFile)) fs.unlinkSync(tmpFile);
    const bak = tmpFile + ".bak";
    if (fs.existsSync(bak)) fs.unlinkSync(bak);
  });

  test("reads a JSON array file", async () => {
    fs.writeFileSync(tmpFile, JSON.stringify([{ id: "a" }]));
    const data = await readJSONFile(tmpFile);
    expect(data).toEqual([{ id: "a" }]);
  });

  test("writes JSON with pretty-printing", async () => {
    await writeJSONFile(tmpFile, [{ id: "b" }]);
    const raw = fs.readFileSync(tmpFile, "utf-8");
    expect(raw).toContain("  "); // 2-space indent
    expect(JSON.parse(raw)).toEqual([{ id: "b" }]);
  });

  test("creates .bak before writing", async () => {
    fs.writeFileSync(tmpFile, JSON.stringify([{ id: "original" }]));
    await writeJSONFile(tmpFile, [{ id: "updated" }]);
    const bak = fs.readFileSync(tmpFile + ".bak", "utf-8");
    expect(JSON.parse(bak)).toEqual([{ id: "original" }]);
  });

  test("returns fallback for non-existent file", async () => {
    const data = await readJSONFile("/tmp/nonexistent-file.json", []);
    expect(data).toEqual([]);
  });

  test("throws for non-existent file without fallback", async () => {
    await expect(readJSONFile("/tmp/nonexistent-file.json")).rejects.toThrow();
  });
});
