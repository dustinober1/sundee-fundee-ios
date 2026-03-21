/**
 * NotFound — branded 404 page shown for any unrecognised URL.
 */
import { Link } from 'react-router';
import styles from './NotFound.module.css';

export function NotFound() {
  return (
    <div className={styles.container}>
      <div className={styles.inner}>
        <h1 className={styles.code}>404</h1>
        <p className={styles.message}>This page doesn't exist.</p>
        <Link to="/" className={styles.link}>
          Back to App
        </Link>
      </div>
    </div>
  );
}
