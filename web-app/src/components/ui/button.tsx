import { ButtonHTMLAttributes, forwardRef } from "react";

type Variant = "primary" | "secondary" | "destructive";

const variantStyles: Record<Variant, string> = {
  primary: "bg-orange text-cream hover:opacity-90 active:opacity-80",
  secondary: "bg-card-bg text-navy border border-navy hover:bg-separator/30 active:bg-separator/50",
  destructive: "bg-error/8 text-error hover:bg-error/15 active:bg-error/20",
};

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  fullWidth?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = "primary", fullWidth = false, className = "", children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={`inline-flex items-center justify-center px-spacing-md py-spacing-sm rounded-button font-medium text-[15px] transition-opacity duration-150 disabled:opacity-40 disabled:cursor-not-allowed ${fullWidth ? "w-full" : ""} ${variantStyles[variant]} ${className}`}
        {...props}
      >
        {children}
      </button>
    );
  }
);
Button.displayName = "Button";
