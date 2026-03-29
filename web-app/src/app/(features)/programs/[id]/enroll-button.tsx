"use client";

import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { enrollInProgram } from "../actions";

export function EnrollButton({ programId }: { programId: string }) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  return (
    <Button
      fullWidth
      disabled={loading}
      onClick={async () => {
        setLoading(true);
        try {
          await enrollInProgram(programId);
          router.push("/programs");
          router.refresh();
        } catch {
          setLoading(false);
        }
      }}
    >
      {loading ? "Enrolling..." : "Start Program"}
    </Button>
  );
}
