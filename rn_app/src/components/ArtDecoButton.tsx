import React from 'react';
import {
  Pressable,
  StyleSheet,
  Text,
  type PressableProps,
} from 'react-native';
import { artDecoTheme } from '../theme/tokens';

interface ArtDecoButtonProps extends Omit<PressableProps, 'style'> {
  title: string;
  variant?: 'primary' | 'secondary';
}

export default function ArtDecoButton({
  title,
  variant = 'primary',
  disabled,
  ...rest
}: ArtDecoButtonProps) {
  return (
    <Pressable
      {...rest}
      disabled={disabled}
      style={({ pressed }) => [
        styles.base,
        variant === 'primary' ? styles.primary : styles.secondary,
        pressed && !disabled ? styles.pressed : null,
        disabled ? styles.disabled : null,
      ]}
    >
      <Text
        style={[
          styles.label,
          variant === 'primary' ? styles.primaryLabel : styles.secondaryLabel,
        ]}
      >
        {title}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    alignItems: 'center',
    borderRadius: artDecoTheme.radius.sm,
    paddingHorizontal: artDecoTheme.spacing.md,
    paddingVertical: artDecoTheme.spacing.sm,
  },
  primary: {
    backgroundColor: artDecoTheme.colors.accent,
  },
  secondary: {
    backgroundColor: artDecoTheme.colors.surfaceMuted,
    borderColor: artDecoTheme.colors.border,
    borderWidth: 1,
  },
  pressed: {
    opacity: 0.85,
  },
  disabled: {
    opacity: 0.5,
  },
  label: {
    fontSize: artDecoTheme.typography.body,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  primaryLabel: {
    color: '#151515',
  },
  secondaryLabel: {
    color: artDecoTheme.colors.textPrimary,
  },
});
