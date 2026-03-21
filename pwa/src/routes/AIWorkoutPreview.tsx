/**
 * AI Workout Preview — shows generated workout before starting.
 * Currently a placeholder for the generation pipeline (Cloud Function / offline).
 */
import { useNavigate } from 'react-router';
import styles from './AIWorkoutConfig.module.css';

export function AIWorkoutPreview() {
  const navigate = useNavigate();

  // Read config from sessionStorage
  const raw = sessionStorage.getItem('@sundee/ai-config');
  const config = raw ? JSON.parse(raw) : null;

  if (!config) {
    return (
      <div className={styles.container}>
        <p>No workout configuration found.</p>
        <button className={styles.generateBtn} onClick={() => navigate('/ai-workout/config')}>Go Back</button>
      </div>
    );
  }

  return (
    <div className={styles.container}>
      <button className={styles.back} onClick={() => navigate('/ai-workout/config')}>&larr; Back to Config</button>
      <h1 className={styles.title}>Workout Preview</h1>
      <p className={styles.subtitle}>
        {config.time} min {config.focus.replace(/_/g, ' ')} workout — {config.equipment.replace(/_/g, ' ')}
      </p>

      <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)', marginBottom: 'var(--space-lg)' }}>
        <p style={{ color: 'var(--text-muted)', fontSize: 'var(--font-body-small)' }}>
          AI workout generation will call the Cloud Function to create a personalized workout based on your settings, cycle phase, injuries, and recent training history.
        </p>
      </div>

      <button className={styles.generateBtn} onClick={() => navigate('/workout-session')}>
        Start Workout
      </button>
    </div>
  );
}
