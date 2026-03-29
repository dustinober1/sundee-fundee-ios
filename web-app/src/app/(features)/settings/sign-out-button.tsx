"use client";

import { signOut } from "firebase/auth";
import { firebaseAuth } from "@/lib/firebase";
import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";

export function SignOutButton() {
  const router = useRouter();

  async function handleSignOut() {
    await signOut(firebaseAuth);
    await fetch("/api/auth/session", { method: "DELETE" });
    router.push("/sign-in");
  }

  return (
    <Button variant="secondary" onClick={handleSignOut}>
      Sign Out
    </Button>
  );
}
