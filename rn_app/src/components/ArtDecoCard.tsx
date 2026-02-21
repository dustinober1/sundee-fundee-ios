import React from 'react';
import { View, StyleSheet, type ViewProps } from 'react-native';
import { artDecoTheme } from '../theme/tokens';

type Props = ViewProps;

export default function ArtDecoCard({ style, ...rest }: Props) {
  return <View style={[styles.card, style]} {...rest} />;
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: artDecoTheme.colors.surface,
    borderColor: artDecoTheme.colors.border,
    borderWidth: 1,
    borderRadius: artDecoTheme.radius.md,
    padding: artDecoTheme.spacing.md,
  },
});
