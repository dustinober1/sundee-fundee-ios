"use client";

import { Button } from "@/components/ui/button";
import { FormAlert } from "@/components/ui/form-alert";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { enrollInProgram } from "../actions";
import { getErrorMessage } from "@/lib/client-errors";

export function EnrollButton({ programId }: { programId: string }) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  return (
    <div className="space-y-3">
      {error && <FormAlert message={error} />}
      <Button
        fullWidth
        disabled={loading}
        onClick={async () => {
          setError(null);
          setLoading(true);
          try {
            await enrollInProgram(programId);
            router.push("/programs");
            router.refresh();
          } catch (error) {
            setError(getErrorMessage(error));
            setLoading(false);
          }
        }}
      >
        {loading ? "Enrolling..." : "Start Program"}
      </Button>
    </div>
  );
}
