import * as React from 'react';

import { cn } from '@/lib/utils';

interface ProgressProps extends React.ComponentProps<'div'> {
  value: number;
}

function Progress({ className, value, ...props }: ProgressProps) {
  const clampedValue = Math.max(0, Math.min(100, value));

  return (
    <div
      data-slot="progress-track"
      className={cn('bg-primary/20 h-2 w-full overflow-hidden rounded-full', className)}
      {...props}
    >
      <div
        role="progressbar"
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={clampedValue}
        data-slot="progress-indicator"
        className="bg-primary h-full rounded-full transition-all"
        style={{ width: `${clampedValue}%` }}
      />
    </div>
  );
}

export { Progress };
