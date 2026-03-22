import fs from "fs/promises";
import { existsSync } from "fs";

let writeLock: Promise<void> = Promise.resolve();

export async function readJSONFile<T = unknown[]>(filePath: string, fallback?: T): Promise<T> {
  try {
    const content = await fs.readFile(filePath, "utf-8");
    return JSON.parse(content);
  } catch {
    if (fallback !== undefined) return fallback;
    throw new Error(`Failed to read ${filePath}`);
  }
}

export async function writeJSONFile<T>(filePath: string, data: T): Promise<void> {
  writeLock = writeLock.then(async () => {
    if (existsSync(filePath)) {
      const existing = await fs.readFile(filePath, "utf-8");
      await fs.writeFile(filePath + ".bak", existing, "utf-8");
    }
    const json = JSON.stringify(data, null, 2) + "\n";
    await fs.writeFile(filePath, json, "utf-8");
  });
  return writeLock;
}
