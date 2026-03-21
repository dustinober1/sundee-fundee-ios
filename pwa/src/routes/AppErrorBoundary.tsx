/**
 * AppErrorBoundary — catches uncaught errors within the authenticated AppLayout.
 * Renders a recovery UI with a SPA Link back to Dashboard (uses Link, not anchor,
 * since the shell layout may still be functional).
 */
import { useRouteError, isRouteErrorResponse, Link } from 'react-router';
import styles from './AppErrorBoundary.module.css';

function getErrorMessage(error: unknown): string {
  if (isRouteErrorResponse(error)) {
    return `${error.status} ${error.statusText}`;
  }
  if (error instanceof Error) {
    return error.message;
  }
  return 'An unexpected error occurred.';
}

export function AppErrorBoundary() {
  const error = useRouteError();
  const message = getErrorMessage(error);

  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <h1 className={styles.heading}>Something went wrong</h1>
        <p className={styles.message}>{message}</p>
        <Link to="/" className={styles.link}>
          Back to Dashboard
        </Link>
      </div>
    </div>
  );
}
