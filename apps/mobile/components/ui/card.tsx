import React from 'react';
import { Card as PaperCard } from 'react-native-paper';

interface CardProps {
  children: React.ReactNode;
  style?: any;
}

export function Card({ children, style }: CardProps) {
  return (
    <PaperCard style={[{ padding: 16, borderRadius: 8 }, style]}>
      {children}
    </PaperCard>
  );
}
