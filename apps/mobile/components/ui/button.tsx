import React from 'react';
import { Button as PaperButton } from 'react-native-paper';

interface ButtonProps {
  children: React.ReactNode;
  onPress?: () => void;
  mode?: 'text' | 'outlined' | 'contained';
  loading?: boolean;
  disabled?: boolean;
  style?: any;
}

export function Button({
  children,
  mode = 'contained',
  ...props
}: ButtonProps) {
  return (
    <PaperButton mode={mode} {...props}>
      {children}
    </PaperButton>
  );
}
