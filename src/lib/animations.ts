export const TRANSITION_DEFAULTS = {
  duration: 0.3,
  ease: [0.25, 0.1, 0.25, 1], // Cubic bezier for natural feel
};

export const VARIANTS = {
  fadeIn: {
    initial: { opacity: 0, y: 10 },
    animate: { opacity: 1, y: 0 },
    exit: { opacity: 0, y: -10 },
    transition: TRANSITION_DEFAULTS,
  },
  pageTransition: {
    initial: { opacity: 0, y: 20 },
    animate: { opacity: 1, y: 0 },
    exit: { opacity: 0, y: -20 },
    transition: { ...TRANSITION_DEFAULTS, duration: 0.4 },
  },
  scalePress: {
    tap: { scale: 0.96 },
    hover: { scale: 1.02 },
    transition: { duration: 0.1 },
  },
  staggerContainer: {
    animate: {
      transition: {
        staggerChildren: 0.05,
      },
    },
  },
  staggerItem: {
    initial: { opacity: 0, y: 10 },
    animate: { opacity: 1, y: 0 },
    transition: TRANSITION_DEFAULTS,
  },
};
