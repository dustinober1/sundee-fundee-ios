'use client';

import { motion } from 'framer-motion';
import { VARIANTS } from '@/lib/animations';
import { ReactNode } from 'react';

interface FadeInProps {
  children: ReactNode;
  delay?: number;
  className?: string;
}

export function FadeIn({ children, delay = 0, className }: FadeInProps) {
  return (
    <motion.div
      initial="initial"
      animate="animate"
      variants={VARIANTS.fadeIn}
      transition={{ delay }}
      className={className}
    >
      {children}
    </motion.div>
  );
}
