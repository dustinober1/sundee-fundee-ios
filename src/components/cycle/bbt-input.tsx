'use client';

import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Thermometer } from 'lucide-react';
import { useCycle } from '@/contexts/cycle-context';

interface BBTInputProps {
  date?: Date;
  trigger?: React.ReactNode;
}

export function BBTInput({ date = new Date(), trigger }: BBTInputProps) {
  const { logBBT } = useCycle();
  const [isOpen, setIsOpen] = useState(false);
  const [temperature, setTemperature] = useState('');
  const [time, setTime] = useState(new Date().toTimeString().substring(0, 5));
  const [notes, setNotes] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (temperature && time) {
      const tempValue = parseFloat(temperature);
      if (!isNaN(tempValue)) {
        await logBBT(date, tempValue, time, notes);
        resetForm();
        setIsOpen(false);
      }
    }
  };

  const resetForm = () => {
    setTemperature('');
    setTime(new Date().toTimeString().substring(0, 5));
    setNotes('');
  };

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        {trigger || (
          <Button size="sm" variant="outline">
            <Thermometer className="h-4 w-4 mr-1" />
            BBT
          </Button>
        )}
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Log Basal Body Temperature</DialogTitle>
          <DialogDescription>
            Record your temperature for {date.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4 pt-4">
          <div className="space-y-2">
            <Label htmlFor="temperature">Temperature (°F)</Label>
            <div className="flex items-center gap-2">
              <Input
                id="temperature"
                type="number"
                value={temperature}
                onChange={e => setTemperature(e.target.value)}
                placeholder="96.0"
                step="0.1"
                min="95.0"
                max="100.0"
                className="w-32"
              />
              <span className="text-sm text-muted-foreground">°F</span>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="time">Time Taken</Label>
            <Input
              id="time"
              type="time"
              value={time}
              onChange={e => setTime(e.target.value)}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="notes">Notes</Label>
            <Textarea
              id="notes"
              value={notes}
              onChange={e => setNotes(e.target.value)}
              placeholder="How was your sleep? Any factors that might affect temperature?"
              rows={2}
            />
          </div>

          <div className="flex gap-2 pt-2">
            <Button type="submit" disabled={!temperature || !time}>
              Log Temperature
            </Button>
            <Button type="button" variant="outline" onClick={resetForm}>
              Reset
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
