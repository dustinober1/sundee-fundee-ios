'use client';

import { motion } from 'framer-motion';
import { VARIANTS } from '@/lib/animations';
import { Button, ButtonProps } from '@/components/ui/button';
import { forwardRef } from 'react';

export const ScaleButton = forwardRef<HTMLButtonElement, ButtonProps>(
  (props, ref) => {
    return (
      <motion.div
        whileTap="tap"
        whileHover="hover"
        variants={VARIANTS.scalePress}
        className="inline-block" // Ensure wrapper doesn't break layout
      >
        <Button ref={ref} {...props} />
      </motion.div>
    );
  }
);
ScaleButton.displayName = 'ScaleButton';
