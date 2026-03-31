import { defaultCache } from "@serwist/next/worker";
import type { PrecacheEntry, SerwistGlobalConfig } from "serwist";
import { NetworkOnly, Serwist } from "serwist";

declare global {
  interface WorkerGlobalScope extends SerwistGlobalConfig {
    __SW_MANIFEST: (PrecacheEntry | string)[] | undefined;
  }
}

declare const self: ServiceWorkerGlobalScope;

const authBypassCache = [
  {
    matcher: ({ sameOrigin, url: { pathname } }: { sameOrigin: boolean; url: URL }) =>
      sameOrigin &&
      (
        pathname === "/sign-in" ||
        pathname === "/sign-up" ||
        pathname.startsWith("/api/auth/") ||
        pathname.startsWith("/__/auth/")
      ),
    handler: new NetworkOnly(),
  },
];

const serwist = new Serwist({
  precacheEntries: self.__SW_MANIFEST,
  skipWaiting: true,
  clientsClaim: true,
  navigationPreload: true,
  runtimeCaching: [...authBypassCache, ...defaultCache],
});

serwist.addEventListeners();
