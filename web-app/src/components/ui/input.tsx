import { InputHTMLAttributes, forwardRef } from "react";

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, className = "", id, ...props }, ref) => {
    const inputId = id ?? label?.toLowerCase().replace(/\s+/g, "-");
    return (
      <div className="flex flex-col gap-spacing-xs">
        {label && (
          <label htmlFor={inputId} className="text-[13px] font-medium text-navy">
            {label}
          </label>
        )}
        <input
          ref={ref}
          id={inputId}
          className={`w-full px-3.5 py-3 bg-card-bg border border-separator rounded-sm text-navy text-[15px] placeholder:text-text-secondary/50 focus:outline-none focus:ring-2 focus:ring-orange/40 focus:border-orange ${error ? "border-error" : ""} ${className}`}
          {...props}
        />
        {error && <p className="text-[13px] text-error">{error}</p>}
      </div>
    );
  }
);
Input.displayName = "Input";
