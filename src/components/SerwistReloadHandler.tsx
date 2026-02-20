"use client";

import { useEffect } from "react";
import { usePathname } from "next/navigation";

const PENDING_RELOAD_KEY = "serwist_pending_reload";

/**
 * Handles service worker `controllerchange` events with workout protection.
 *
 * When the SW updates and takes control, a normal reload would interrupt an
 * active workout. Instead, we defer the reload until the user navigates away
 * from a /workout* route, persisting the pending flag in sessionStorage so it
 * survives any nested navigation within the workout flow.
 */
export function SerwistReloadHandler() {
  const pathname = usePathname();

  // On every navigation, check if a reload is pending and we're now safe to fire it.
  useEffect(() => {
    if (
      sessionStorage.getItem(PENDING_RELOAD_KEY) === "true" &&
      !pathname.startsWith("/workout")
    ) {
      sessionStorage.removeItem(PENDING_RELOAD_KEY);
      window.location.reload();
    }
  }, [pathname]);

  // Register the controllerchange listener once on mount.
  useEffect(() => {
    if (typeof window === "undefined" || !("serviceWorker" in navigator)) {
      return;
    }

    const handleControllerChange = () => {
      if (pathname.startsWith("/workout")) {
        // Defer reload — user is mid-workout.
        sessionStorage.setItem(PENDING_RELOAD_KEY, "true");
      } else {
        window.location.reload();
      }
    };

    navigator.serviceWorker.addEventListener(
      "controllerchange",
      handleControllerChange
    );

    return () => {
      navigator.serviceWorker.removeEventListener(
        "controllerchange",
        handleControllerChange
      );
    };
    // pathname intentionally omitted: we capture it via closure at registration
    // time and update via the navigation effect above.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return null;
}
