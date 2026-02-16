'use client';

import React from 'react';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useCycle } from '@/contexts/cycle-context';

interface CycleFilterProps {
  onFilterChange: (filter: string) => void;
}

export function CycleFilter({ onFilterChange }: CycleFilterProps) {
  const { cycleStatus } = useCycle();

  return (
    <div className="flex items-center gap-4 mb-6">
      <div className="flex items-center gap-2">
        <span className="text-sm font-medium">View by:</span>
        <Select defaultValue="all-time" onValueChange={onFilterChange}>
          <SelectTrigger className="w-40">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all-time">All Time</SelectItem>
            <SelectItem value="cycle-phase">By Cycle Phase</SelectItem>
            <SelectItem value="current-cycle">Current Cycle</SelectItem>
            {cycleStatus && (
              <SelectItem value="current-phase">Current Phase</SelectItem>
            )}
          </SelectContent>
        </Select>
      </div>
    </div>
  );
}
