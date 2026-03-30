"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { getErrorMessage } from "@/lib/client-errors";

interface DeleteRecordButtonProps {
  action: (recordId: string) => Promise<unknown>;
  recordId: string;
  noun: string;
  className?: string;
}

export function DeleteRecordButton({
  action,
  recordId,
  noun,
  className = "",
}: DeleteRecordButtonProps) {
  const router = useRouter();
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleDelete() {
    if (!window.confirm(`Delete this ${noun.toLowerCase()}? This cannot be undone.`)) {
      return;
    }

    setError(null);
    setDeleting(true);

    try {
      await action(recordId);
      router.refresh();
    } catch (error) {
      setError(getErrorMessage(error));
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className={`flex flex-col items-end gap-1 ${className}`}>
      <button
        type="button"
        onClick={handleDelete}
        disabled={deleting}
        className="text-[11px] font-mono uppercase tracking-wider text-error hover:opacity-80 disabled:opacity-40"
      >
        {deleting ? "Deleting..." : "Delete"}
      </button>
      {error && <p className="max-w-40 text-right text-[11px] text-error">{error}</p>}
    </div>
  );
}
