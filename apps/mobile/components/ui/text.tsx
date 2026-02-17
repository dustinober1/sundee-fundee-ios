import React from 'react';
import { Text as PaperText } from 'react-native-paper';
import { Typography } from '@/constants';

interface TextProps {
  children: React.ReactNode;
  variant?: keyof typeof Typography;
  style?: any;
}

export function Text({ children, variant = 'body', style }: TextProps) {
  return (
    <PaperText style={[Typography[variant], style]}>
      {children}
    </PaperText>
  );
}
