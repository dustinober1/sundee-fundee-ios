"use client";

import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";
import { enrollInProgram } from "../actions";

export function EnrollButton({ programId }: { programId: string }) {
  const router = useRouter();

  return (
    <Button
      fullWidth
      onClick={() => {
        enrollInProgram(programId).then(() => {
          router.refresh();
        });
        router.push("/programs");
      }}
    >
      Start Program
    </Button>
  );
}
