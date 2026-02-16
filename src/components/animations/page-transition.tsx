'use client';

import { motion } from 'framer-motion';
import { VARIANTS } from '@/lib/animations';
import { ReactNode } from 'react';

interface PageTransitionProps {
  children: ReactNode;
  className?: string;
}

export function PageTransition({ children, className }: PageTransitionProps) {
  return (
    <motion.div
      initial="initial"
      animate="animate"
      exit="exit"
      variants={VARIANTS.pageTransition}
      className={className}
    >
      {children}
    </motion.div>
  );
}
