interface FormAlertProps {
  message: string;
}

export function FormAlert({ message }: FormAlertProps) {
  return (
    <div
      role="alert"
      aria-live="polite"
      className="rounded-sm border border-warm-rose/30 bg-warm-rose/10 px-3 py-2 text-[13px] text-warm-rose"
    >
      {message}
    </div>
  );
}
