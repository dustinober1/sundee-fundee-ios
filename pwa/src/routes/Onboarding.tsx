/**
 * Onboarding — multi-step wizard (Name, Experience, Goal, Gender, Cycle).
 * Single page with step state, matching the 5-step Expo Router flow.
 * Male users skip the Cycle step.
 */
import { useState } from 'react';
import { useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { OnboardingProvider, useOnboarding } from '../onboarding/OnboardingContext';
import type { ExperienceLevel, PrimaryGoal } from '../repositories/OnboardingProfileRepo';
import type { Gender } from '../domain/types';
import styles from './Onboarding.module.css';

type Step = 'name' | 'experience' | 'goal' | 'gender' | 'cycle';

const STEPS_ALL: Step[] = ['name', 'experience', 'goal', 'gender', 'cycle'];
const STEPS_MALE: Step[] = ['name', 'experience', 'goal', 'gender'];

function OnboardingWizard() {
  const navigate = useNavigate();
  const { user, isGuest } = useSession();
  const {
    draft, setName, setExperienceLevel, setPrimaryGoal, setGender, setCycleOptIn, completeOnboarding,
  } = useOnboarding();

  const [step, setStep] = useState<Step>('name');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const steps = draft.gender === 'male' ? STEPS_MALE : STEPS_ALL;
  const stepIndex = steps.indexOf(step);
  const isLast = stepIndex === steps.length - 1;

  async function handleNext() {
    if (isLast) {
      if (!user) return;
      setIsSubmitting(true);
      try {
        await completeOnboarding(user.uid, isGuest);
        navigate('/');
      } catch {
        setIsSubmitting(false);
      }
    } else {
      setStep(steps[stepIndex + 1]);
    }
  }

  function handleBack() {
    if (stepIndex > 0) setStep(steps[stepIndex - 1]);
  }

  const canProceed = (() => {
    switch (step) {
      case 'name': return draft.name.trim().length > 0;
      case 'experience': return draft.experienceLevel !== null;
      case 'goal': return draft.primaryGoal !== null;
      case 'gender': return draft.gender !== null;
      case 'cycle': return true;
    }
  })();

  return (
    <div className={styles.container}>
      <div className={styles.card}>
        {/* Progress bar */}
        <div className={styles.progress}>
          <div className={styles.progressFill} style={{ width: `${((stepIndex + 1) / steps.length) * 100}%` }} />
        </div>

        <p className={styles.stepLabel}>Step {stepIndex + 1} of {steps.length}</p>

        {/* Step content */}
        {step === 'name' && (
          <div className={styles.stepContent}>
            <h2 className={styles.heading}>What's your name?</h2>
            <input
              className={styles.input}
              type="text"
              placeholder="Your name"
              value={draft.name}
              onChange={(e) => setName(e.target.value)}
              autoFocus
            />
          </div>
        )}

        {step === 'experience' && (
          <div className={styles.stepContent}>
            <h2 className={styles.heading}>Experience level?</h2>
            <div className={styles.options}>
              {(['beginner', 'intermediate', 'advanced'] as ExperienceLevel[]).map((level) => (
                <button
                  key={level}
                  className={`${styles.option} ${draft.experienceLevel === level ? styles.optionActive : ''}`}
                  onClick={() => setExperienceLevel(level)}
                >
                  {level.charAt(0).toUpperCase() + level.slice(1)}
                </button>
              ))}
            </div>
          </div>
        )}

        {step === 'goal' && (
          <div className={styles.stepContent}>
            <h2 className={styles.heading}>Primary goal?</h2>
            <div className={styles.options}>
              {([
                { value: 'strength', label: 'Strength' },
                { value: 'muscle', label: 'Build Muscle' },
                { value: 'endurance', label: 'Endurance' },
                { value: 'weightLoss', label: 'Weight Loss' },
                { value: 'general', label: 'General Fitness' },
              ] as { value: PrimaryGoal; label: string }[]).map(({ value, label }) => (
                <button
                  key={value}
                  className={`${styles.option} ${draft.primaryGoal === value ? styles.optionActive : ''}`}
                  onClick={() => setPrimaryGoal(value)}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
        )}

        {step === 'gender' && (
          <div className={styles.stepContent}>
            <h2 className={styles.heading}>Gender</h2>
            <p className={styles.hint}>Used for cycle-aware training recommendations</p>
            <div className={styles.options}>
              {([
                { value: 'female', label: 'Female' },
                { value: 'male', label: 'Male' },
                { value: 'other', label: 'Prefer Not to Say' },
              ] as { value: Gender; label: string }[]).map(({ value, label }) => (
                <button
                  key={value}
                  className={`${styles.option} ${draft.gender === value ? styles.optionActive : ''}`}
                  onClick={() => setGender(value)}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
        )}

        {step === 'cycle' && (
          <div className={styles.stepContent}>
            <h2 className={styles.heading}>Track your cycle?</h2>
            <p className={styles.hint}>Get training recommendations adapted to your hormonal cycle</p>
            <div className={styles.options}>
              <button
                className={`${styles.option} ${draft.cycleOptIn ? styles.optionActive : ''}`}
                onClick={() => setCycleOptIn(true)}
              >
                Yes, enable cycle tracking
              </button>
              <button
                className={`${styles.option} ${!draft.cycleOptIn ? styles.optionActive : ''}`}
                onClick={() => setCycleOptIn(false)}
              >
                No thanks
              </button>
            </div>
          </div>
        )}

        {/* Navigation buttons */}
        <div className={styles.nav}>
          {stepIndex > 0 && (
            <button className={styles.backBtn} onClick={handleBack}>Back</button>
          )}
          <button
            className={styles.nextBtn}
            onClick={handleNext}
            disabled={!canProceed || isSubmitting}
          >
            {isSubmitting ? 'Saving...' : isLast ? 'Get Started' : 'Next'}
          </button>
        </div>
      </div>
    </div>
  );
}

export function Onboarding() {
  return (
    <OnboardingProvider>
      <OnboardingWizard />
    </OnboardingProvider>
  );
}
