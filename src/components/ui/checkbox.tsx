'use client';

import * as React from 'react';

import { cn } from '@/lib/utils';

interface CheckboxProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'type' | 'onChange'> {
  onCheckedChange?: (checked: boolean) => void;
}

const Checkbox = React.forwardRef<HTMLInputElement, CheckboxProps>(
  ({ className, checked, onCheckedChange, ...props }, ref) => {
    return (
      <input
        ref={ref}
        type="checkbox"
        data-slot="checkbox"
        checked={checked}
        onChange={event => onCheckedChange?.(event.target.checked)}
        className={cn(
          'border-input text-primary focus-visible:border-ring focus-visible:ring-ring/50 h-4 w-4 rounded border shadow-xs focus-visible:ring-[3px]',
          className
        )}
        {...props}
      />
    );
  }
);

Checkbox.displayName = 'Checkbox';

export { Checkbox };
