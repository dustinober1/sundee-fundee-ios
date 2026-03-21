/**
 * RootErrorBoundary — catches uncaught errors at the root router level.
 * Renders a full-page recovery UI with a hard-reload link to "/".
 */
import { useRouteError, isRouteErrorResponse } from 'react-router';
import styles from './RootErrorBoundary.module.css';

function getErrorMessage(error: unknown): string {
  if (isRouteErrorResponse(error)) {
    return `${error.status} ${error.statusText}`;
  }
  if (error instanceof Error) {
    return error.message;
  }
  return 'An unexpected error occurred.';
}

export function RootErrorBoundary() {
  const error = useRouteError();
  const message = getErrorMessage(error);

  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <h1 className={styles.heading}>Something went wrong</h1>
        <p className={styles.message}>{message}</p>
        <a href="/" className={styles.link}>
          Reload App
        </a>
      </div>
    </div>
  );
}
