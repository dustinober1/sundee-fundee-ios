'use client';

import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from '@/components/ui/sheet';
import { Plus } from 'lucide-react';
import { useCycle } from '@/contexts/cycle-context';

interface SymptomLoggerProps {
  date?: Date;
  trigger?: React.ReactNode;
}

export function SymptomLogger({ date = new Date(), trigger }: SymptomLoggerProps) {
  const { availableSymptoms, settings, logSymptom, addCustomSymptom } = useCycle();
  const [isOpen, setIsOpen] = useState(false);
  const [selectedSymptom, setSelectedSymptom] = useState('');
  const [severity, setSeverity] = useState(3);
  const [notes, setNotes] = useState('');
  const [customSymptomName, setCustomSymptomName] = useState('');
  const [customSymptomCategory, setCustomSymptomCategory] = useState<'physical' | 'emotional' | 'energy'>('physical');
  const [showCustomForm, setShowCustomForm] = useState(false);

  const enabledSymptoms = availableSymptoms.filter(symptom =>
    settings?.enabledSymptomIds.includes(symptom.id) || !symptom.userId
  );

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedSymptom) {
      await logSymptom(date, selectedSymptom, severity, notes);
      resetForm();
      setIsOpen(false);
    }
  };

  const handleAddCustomSymptom = async () => {
    if (customSymptomName.trim()) {
      await addCustomSymptom(customSymptomName, customSymptomCategory);
      setCustomSymptomName('');
      setShowCustomForm(false);
    }
  };

  const resetForm = () => {
    setSelectedSymptom('');
    setSeverity(3);
    setNotes('');
  };

  const severityColors = ['text-green-500', 'text-lime-500', 'text-yellow-500', 'text-orange-500', 'text-red-500'];

  return (
    <Sheet open={isOpen} onOpenChange={setIsOpen}>
      <SheetTrigger asChild>
        {trigger || (
          <Button size="sm" variant="outline">
            <Plus className="h-4 w-4 mr-1" />
            Add Symptom
          </Button>
        )}
      </SheetTrigger>
      <SheetContent>
        <SheetHeader>
          <SheetTitle>Log Symptom</SheetTitle>
          <SheetDescription>
            Track how you&apos;re feeling on {date.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
          </SheetDescription>
        </SheetHeader>

        <form onSubmit={handleSubmit} className="space-y-6 pt-4">
          <div className="space-y-4">
            <div>
              <Label htmlFor="symptom">Select Symptom</Label>
              <Select value={selectedSymptom} onValueChange={setSelectedSymptom}>
                <SelectTrigger id="symptom">
                  <SelectValue placeholder="Choose a symptom" />
                </SelectTrigger>
                <SelectContent>
                  {enabledSymptoms.map(symptom => (
                    <SelectItem key={symptom.id} value={symptom.id}>
                      <span className="capitalize">{symptom.category}</span> · {symptom.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {!showCustomForm ? (
              <Button type="button" variant="outline" size="sm" onClick={() => setShowCustomForm(true)}>
                <Plus className="h-4 w-4 mr-1" />
                Add Custom Symptom
              </Button>
            ) : (
              <div className="space-y-3 p-3 border rounded-md">
                <h4 className="font-medium text-sm">Add Custom Symptom</h4>
                <div>
                  <Label htmlFor="custom-name">Name</Label>
                  <Input
                    id="custom-name"
                    value={customSymptomName}
                    onChange={e => setCustomSymptomName(e.target.value)}
                    placeholder="Headache, fatigue, etc."
                  />
                </div>
                <div>
                  <Label htmlFor="custom-category">Category</Label>
                  <Select value={customSymptomCategory} onValueChange={(v) => setCustomSymptomCategory(v as 'physical' | 'emotional' | 'energy')}>
                    <SelectTrigger id="custom-category"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="physical">Physical</SelectItem>
                      <SelectItem value="emotional">Emotional</SelectItem>
                      <SelectItem value="energy">Energy</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="flex gap-2">
                  <Button type="button" size="sm" onClick={handleAddCustomSymptom} disabled={!customSymptomName.trim()}>
                    Add
                  </Button>
                  <Button type="button" variant="outline" size="sm" onClick={() => { setShowCustomForm(false); setCustomSymptomName(''); }}>
                    Cancel
                  </Button>
                </div>
              </div>
            )}
          </div>

          <div>
            <Label>Severity (1-5)</Label>
            <div className="flex items-center gap-2 mt-2">
              {[1, 2, 3, 4, 5].map(level => (
                <Button
                  key={level}
                  type="button"
                  variant={severity === level ? 'default' : 'outline'}
                  size="sm"
                  className={`w-10 h-10 ${severityColors[level - 1]}`}
                  onClick={() => setSeverity(level)}
                >
                  {level}
                </Button>
              ))}
            </div>
            <p className="text-xs text-muted-foreground mt-1">1 = Mild, 5 = Severe</p>
          </div>

          <div>
            <Label htmlFor="notes">Additional Notes</Label>
            <Textarea
              id="notes"
              value={notes}
              onChange={e => setNotes(e.target.value)}
              placeholder="Any additional details..."
              rows={3}
            />
          </div>

          <Button type="submit" className="w-full" disabled={!selectedSymptom}>
            Log Symptom
          </Button>
        </form>
      </SheetContent>
    </Sheet>
  );
}
