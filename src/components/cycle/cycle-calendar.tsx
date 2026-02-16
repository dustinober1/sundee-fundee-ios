'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { format, startOfMonth, endOfMonth, startOfWeek, endOfWeek, addMonths, subMonths, isSameMonth, isSameDay, addDays } from 'date-fns';
import { useCycle } from '@/contexts/cycle-context';

interface CycleCalendarProps {
  onDateSelect?: (date: Date) => void;
}

export function CycleCalendar({ onDateSelect }: CycleCalendarProps) {
  const { periodLogs, settings } = useCycle();
  const [currentDate, setCurrentDate] = useState(new Date());

  const monthStart = startOfMonth(currentDate);
  const monthEnd = endOfMonth(currentDate);
  const calendarStart = startOfWeek(monthStart);
  const calendarEnd = endOfWeek(monthEnd);

  // Build array of calendar days
  const calendarDays: Date[] = [];
  let day = calendarStart;
  while (day <= calendarEnd) {
    calendarDays.push(new Date(day));
    day = addDays(day, 1);
  }

  const isPeriodDay = (date: Date): boolean => {
    return periodLogs.some(log => {
      const logStart = new Date(log.startDate);
      const logEnd = log.endDate
        ? new Date(log.endDate)
        : addDays(logStart, (settings?.averagePeriodLength ?? 5) - 1);
      return date >= logStart && date <= logEnd;
    });
  };

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-base">Cycle Calendar</CardTitle>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={() => setCurrentDate(subMonths(currentDate, 1))}>
            <ChevronLeft className="h-4 w-4" />
          </Button>
          <h2 className="font-semibold text-sm min-w-[120px] text-center">
            {format(currentDate, 'MMMM yyyy')}
          </h2>
          <Button variant="outline" size="sm" onClick={() => setCurrentDate(addMonths(currentDate, 1))}>
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-7 gap-1 mb-2">
          {['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((label, i) => (
            <div key={`${label}-${i}`} className="text-center text-xs font-medium text-muted-foreground p-2">
              {label}
            </div>
          ))}
        </div>

        <div className="grid grid-cols-7 gap-1">
          {calendarDays.map((calDay) => {
            const hasPeriod = isPeriodDay(calDay);
            const isToday = isSameDay(calDay, new Date());
            const isCurrentMonth = isSameMonth(calDay, monthStart);

            return (
              <Button
                key={calDay.toISOString()}
                variant={hasPeriod ? 'default' : 'ghost'}
                size="sm"
                className={`w-full h-8 text-xs ${
                  hasPeriod ? 'bg-red-500 hover:bg-red-600 text-white' : ''
                } ${!isCurrentMonth ? 'opacity-30' : ''} ${
                  isToday && !hasPeriod ? 'ring-2 ring-primary' : ''
                }`}
                onClick={() => onDateSelect?.(calDay)}
              >
                {format(calDay, 'd')}
              </Button>
            );
          })}
        </div>

        <div className="mt-4 flex flex-wrap gap-3">
          {[
            { color: 'bg-red-500', label: 'Period' },
            { color: 'bg-green-500', label: 'Follicular' },
            { color: 'bg-pink-500', label: 'Ovulation' },
            { color: 'bg-purple-500', label: 'Luteal' },
          ].map(({ color, label }) => (
            <div key={label} className="flex items-center gap-1.5">
              <div className={`w-3 h-3 ${color} rounded-full`} />
              <span className="text-xs">{label}</span>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
