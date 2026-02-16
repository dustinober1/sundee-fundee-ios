'use client';

import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import type { ExperienceLevel, PrimaryGoal } from '@/types';
import { useUser } from '@/contexts/user-context';
import { useRouter } from 'next/navigation';
import { createUser } from '@/lib/db';

interface OnboardingData {
  name: string;
  experienceLevel: ExperienceLevel;
  primaryGoal: PrimaryGoal;
}

export function OnboardingWizard() {
  const [step, setStep] = useState(1);
  const [data, setData] = useState<OnboardingData>({
    name: '',
    experienceLevel: 'beginner',
    primaryGoal: 'strength'
  });
  const { refresh } = useUser();
  const router = useRouter();

  async function handleNext() {
    if (step < 3) {
      setStep(step + 1);
    } else {
      // Complete onboarding - create user
      await createUser({
        name: data.name,
        experienceLevel: data.experienceLevel,
        primaryGoal: data.primaryGoal
      });
      await refresh();
      router.push('/dashboard');
    }
  }

  function canProceed() {
    switch (step) {
      case 1: return data.name.trim().length > 0;
      case 2: return data.experienceLevel !== undefined;
      case 3: return data.primaryGoal !== undefined;
      default: return false;
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>
            {step === 1 && 'Welcome to Strength'}
            {step === 2 && 'Training Experience'}
            {step === 3 && 'Your Goals'}
          </CardTitle>
          <CardDescription>
            Step {step} of 3
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {step === 1 && (
            <div className="space-y-2">
              <Label htmlFor="name">What&apos;s your name?</Label>
              <Input
                id="name"
                value={data.name}
                onChange={(e) => setData({ ...data, name: e.target.value })}
                placeholder="Enter your name"
              />
            </div>
          )}

          {step === 2 && (
            <div className="space-y-2">
              <Label>Training experience</Label>
              <RadioGroup
                value={data.experienceLevel}
                onValueChange={(value) => setData({ ...data, experienceLevel: value as ExperienceLevel })}
              >
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="beginner" id="beginner" />
                  <Label htmlFor="beginner">0-1 years (Beginner)</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="intermediate" id="intermediate" />
                  <Label htmlFor="intermediate">1-3 years (Intermediate)</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="advanced" id="advanced" />
                  <Label htmlFor="advanced">3+ years (Advanced)</Label>
                </div>
              </RadioGroup>
            </div>
          )}

          {step === 3 && (
            <div className="space-y-2">
              <Label>Primary goal</Label>
              <Select
                value={data.primaryGoal}
                onValueChange={(value) => setData({ ...data, primaryGoal: value as PrimaryGoal })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="strength">Build Strength</SelectItem>
                  <SelectItem value="hypertrophy">Muscle Growth</SelectItem>
                  <SelectItem value="explosiveness">Power & Speed</SelectItem>
                </SelectContent>
              </Select>
            </div>
          )}

          <div className="flex justify-between pt-4">
            <Button
              variant="outline"
              onClick={() => setStep(step - 1)}
              disabled={step === 1}
            >
              Back
            </Button>
            <Button onClick={handleNext} disabled={!canProceed()}>
              {step === 3 ? 'Start Training' : 'Next'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
