/**
 * Goodbye — shown after account deletion, farewell message.
 */
import { useNavigate } from 'react-router';
import styles from './Goodbye.module.css';

export function Goodbye() {
  const navigate = useNavigate();

  return (
    <div className={styles.container}>
      <div className={styles.content}>
        <h1 className={styles.heading}>Account Deleted</h1>
        <p className={styles.message}>
          Your data has been removed. Thank you for using Sundee Fundee.
        </p>
      </div>
      <button className={styles.doneBtn} onClick={() => navigate('/sign-in')}>Done</button>
    </div>
  );
}
