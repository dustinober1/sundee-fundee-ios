/**
 * AuthButton — Reusable full-width auth button with spinner and inline error state.
 *
 * Per locked design decisions:
 * - Tapped button shows inline spinner during loading
 * - All sibling buttons are disabled while any auth operation is in progress (parent passes disabled prop)
 * - Error messages appear inline below the button (NOT in a modal)
 *
 * Variants:
 * - primary: NAVY background + CREAM text (main CTAs)
 * - secondary: CREAM background + NAVY text + NAVY border (secondary actions)
 * - text: transparent background + NAVY text (de-emphasized actions like "Continue as Guest")
 */

import React from 'react';
import {
  ActivityIndicator,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import * as colors from '@/src/theme/colors';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface AuthButtonProps {
  title: string;
  onPress: () => void;
  isLoading: boolean;
  error: string | null;
  icon?: React.ReactNode;
  variant: 'primary' | 'secondary' | 'text';
  disabled?: boolean;
}

// ─── AuthButton ───────────────────────────────────────────────────────────────

export function AuthButton({
  title,
  onPress,
  isLoading,
  error,
  icon,
  variant,
  disabled = false,
}: AuthButtonProps): React.JSX.Element {
  const isDisabled = disabled || isLoading;

  // Determine button container style based on variant
  const buttonStyle = [
    styles.button,
    variant === 'primary' && styles.buttonPrimary,
    variant === 'secondary' && styles.buttonSecondary,
    variant === 'text' && styles.buttonText,
    isDisabled && variant !== 'text' && styles.buttonDisabled,
  ];

  // Determine text style based on variant
  const textStyle = [
    styles.buttonLabel,
    variant === 'primary' && styles.labelPrimary,
    variant === 'secondary' && styles.labelSecondary,
    variant === 'text' && styles.labelText,
    isDisabled && styles.labelDisabled,
  ];

  return (
    <View style={styles.container}>
      <TouchableOpacity
        style={buttonStyle}
        onPress={onPress}
        disabled={isDisabled}
        activeOpacity={0.7}
        accessibilityRole="button"
        accessibilityLabel={title}
        accessibilityState={{ busy: isLoading, disabled: isDisabled }}
      >
        {isLoading ? (
          <ActivityIndicator
            color={variant === 'primary' ? colors.CREAM : colors.NAVY}
            size="small"
            testID="auth-button-spinner"
          />
        ) : (
          <View style={styles.buttonContent}>
            {icon != null && <View style={styles.iconContainer}>{icon}</View>}
            <Text style={textStyle}>{title}</Text>
          </View>
        )}
      </TouchableOpacity>

      {error != null && error.length > 0 && (
        <Text style={styles.errorText} testID="auth-button-error">
          {error}
        </Text>
      )}
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    width: '100%',
    marginBottom: 4,
  },
  button: {
    width: '100%',
    height: 52,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 16,
  },
  buttonPrimary: {
    backgroundColor: colors.NAVY,
  },
  buttonSecondary: {
    backgroundColor: colors.CREAM,
    borderWidth: 1.5,
    borderColor: colors.NAVY,
  },
  buttonText: {
    backgroundColor: 'transparent',
  },
  buttonDisabled: {
    opacity: 0.5,
  },
  buttonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconContainer: {
    marginRight: 8,
  },
  buttonLabel: {
    fontSize: 16,
    fontWeight: '600',
    letterSpacing: 0.5,
  },
  labelPrimary: {
    color: colors.CREAM,
  },
  labelSecondary: {
    color: colors.NAVY,
  },
  labelText: {
    color: colors.NAVY,
    textDecorationLine: 'underline',
    fontWeight: '400',
  },
  labelDisabled: {
    opacity: 0.7,
  },
  errorText: {
    marginTop: 4,
    fontSize: 13,
    color: colors.RED,
    textAlign: 'center',
  },
});
