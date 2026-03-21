/**
 * SkeletonCard — shimmer placeholder shown during data loading.
 * Renders `count` animated shimmer divs to approximate content shape.
 */
import styles from './SkeletonCard.module.css';

interface SkeletonCardProps {
  count?: number;  // Number of skeleton cards to render (default: 4)
  height?: number; // Height of each card in px (default: 80)
}

export function SkeletonCard({ count = 4, height = 80 }: SkeletonCardProps) {
  return (
    <>
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={i}
          className={styles.card}
          style={{ height }}
          aria-hidden="true"
        />
      ))}
    </>
  );
}
