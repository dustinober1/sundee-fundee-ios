import { getCloudflareContext } from "@opennextjs/cloudflare";

export async function getBindings(): Promise<CloudflareEnv> {
  const { env } = await getCloudflareContext();
  return env as CloudflareEnv;
}
