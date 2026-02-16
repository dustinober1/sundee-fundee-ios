'use client';

import { motion } from 'framer-motion';
import { VARIANTS } from '@/lib/animations';
import { ReactNode } from 'react';

export function StaggerList({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <motion.div
      initial="initial"
      animate="animate"
      variants={VARIANTS.staggerContainer}
      className={className}
    >
      {children}
    </motion.div>
  );
}

export function StaggerItem({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <motion.div variants={VARIANTS.staggerItem} className={className}>
      {children}
    </motion.div>
  );
}
