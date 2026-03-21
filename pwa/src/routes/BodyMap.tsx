/**
 * Body Map — tap body region to create an injury with phase and notes.
 */
import { useState } from 'react';
import { useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getInjuryRepo, type InjuryProfileRecord } from '../repositories/InjuryRepo';
import type { BodyLocation, RecoveryPhase } from '../domain/types';
import styles from './BodyMap.module.css';

const BODY_REGIONS: { id: BodyLocation; label: string; x: number; y: number }[] = [
  { id: 'head', label: 'Head', x: 50, y: 5 },
  { id: 'neck', label: 'Neck', x: 50, y: 12 },
  { id: 'leftShoulder', label: 'L Shoulder', x: 30, y: 18 },
  { id: 'rightShoulder', label: 'R Shoulder', x: 70, y: 18 },
  { id: 'chest', label: 'Chest', x: 50, y: 24 },
  { id: 'upperBack', label: 'Upper Back', x: 50, y: 30 },
  { id: 'leftElbow', label: 'L Elbow', x: 20, y: 35 },
  { id: 'rightElbow', label: 'R Elbow', x: 80, y: 35 },
  { id: 'lowerBack', label: 'Lower Back', x: 50, y: 40 },
  { id: 'leftWrist', label: 'L Wrist', x: 15, y: 48 },
  { id: 'rightWrist', label: 'R Wrist', x: 85, y: 48 },
  { id: 'leftHip', label: 'L Hip', x: 38, y: 50 },
  { id: 'rightHip', label: 'R Hip', x: 62, y: 50 },
  { id: 'leftKnee', label: 'L Knee', x: 38, y: 68 },
  { id: 'rightKnee', label: 'R Knee', x: 62, y: 68 },
  { id: 'leftAnkle', label: 'L Ankle', x: 38, y: 85 },
  { id: 'rightAnkle', label: 'R Ankle', x: 62, y: 85 },
];

const PHASE_OPTIONS: { value: RecoveryPhase; label: string; desc: string }[] = [
  { value: 'acute', label: 'Acute', desc: 'Recently injured, significant pain' },
  { value: 'rehab', label: 'Rehab', desc: 'Recovering, doing rehab exercises' },
  { value: 'lightLoad', label: 'Light Load', desc: 'Can train with modifications' },
  { value: 'returnToPlay', label: 'Return to Play', desc: 'Nearly recovered, easing back in' },
];

function locationLabel(loc: string): string {
  return loc.replace(/([A-Z])/g, ' $1').replace(/^./, (c) => c.toUpperCase()).trim();
}

export function BodyMap() {
  const navigate = useNavigate();
  const { user, isGuest } = useSession();
  const [selected, setSelected] = useState<BodyLocation | null>(null);
  const [phase, setPhase] = useState<RecoveryPhase>('acute');
  const [notes, setNotes] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  async function handleSave() {
    if (!user || !selected) return;
    setIsSaving(true);
    const record: InjuryProfileRecord = {
      id: crypto.randomUUID(),
      uid: user.uid,
      bodyLocation: selected,
      recoveryPhase: phase,
      injuryDate: new Date().toISOString(),
      notes: notes.trim() || undefined,
    };
    await getInjuryRepo(isGuest).saveInjury(user.uid, record);
    navigate('/injuries');
  }

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <button className={styles.cancel} onClick={() => navigate('/injuries')}>Cancel</button>
        <h1 className={styles.title}>Where's the injury?</h1>
      </div>

      <p className={styles.hint}>Tap a body region below</p>

      {/* Body map grid */}
      <div className={styles.bodyMap}>
        {BODY_REGIONS.map((r) => (
          <button
            key={r.id}
            className={`${styles.region} ${selected === r.id ? styles.regionActive : ''}`}
            style={{ left: `${r.x}%`, top: `${r.y}%` }}
            onClick={() => setSelected(r.id)}
          >
            {r.label}
          </button>
        ))}
      </div>

      {/* Modal form when region selected */}
      {selected && (
        <div className={styles.form}>
          <h2 className={styles.formTitle}>{locationLabel(selected)} Injury</h2>

          <label className={styles.label}>Recovery Phase</label>
          <div className={styles.phaseOptions}>
            {PHASE_OPTIONS.map((opt) => (
              <button
                key={opt.value}
                className={`${styles.phaseChip} ${phase === opt.value ? styles.phaseChipActive : ''}`}
                onClick={() => setPhase(opt.value)}
              >
                <span className={styles.phaseLabel}>{opt.label}</span>
                <span className={styles.phaseDesc}>{opt.desc}</span>
              </button>
            ))}
          </div>

          <label className={styles.label}>Notes</label>
          <textarea
            className={styles.textarea}
            placeholder="Optional notes about the injury..."
            value={notes}
            onChange={(e) => setNotes(e.target.value.slice(0, 200))}
            rows={3}
            maxLength={200}
          />
          <span className={styles.charCount}>{notes.length}/200</span>

          <button className={styles.saveBtn} onClick={handleSave} disabled={isSaving}>
            {isSaving ? 'Saving...' : 'Save Injury'}
          </button>
        </div>
      )}
    </div>
  );
}
