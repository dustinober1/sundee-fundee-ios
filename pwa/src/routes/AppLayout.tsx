/**
 * AppLayout — authenticated app shell with navigation.
 * Redirects unauthenticated users to /sign-in.
 * Provides responsive navigation: bottom tabs on mobile, sidebar on desktop.
 */
import { Outlet, Navigate, NavLink } from 'react-router';
import { useSession } from '../auth/AuthContext';
import styles from './AppLayout.module.css';

const NAV_ITEMS = [
  { to: '/', label: 'Dashboard', icon: '🏠' },
  { to: '/history', label: 'History', icon: '📖' },
  { to: '/maxes', label: 'Maxes', icon: '💪' },
  { to: '/cycle', label: 'Cycle', icon: '🌙' },
  { to: '/settings', label: 'Settings', icon: '⚙️' },
] as const;

export function AppLayout() {
  const { user, isLoading } = useSession();

  if (isLoading) {
    return (
      <div className={styles.loading}>
        <div className={styles.spinner} />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/sign-in" replace />;
  }

  return (
    <div className={styles.shell}>
      <main className={styles.main}>
        <Outlet />
      </main>
      <nav className={styles.nav}>
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === '/'}
            className={({ isActive }) =>
              `${styles.navItem} ${isActive ? styles.navItemActive : ''}`
            }
          >
            <span className={styles.navIcon}>{item.icon}</span>
            <span className={styles.navLabel}>{item.label}</span>
          </NavLink>
        ))}
      </nav>
    </div>
  );
}
