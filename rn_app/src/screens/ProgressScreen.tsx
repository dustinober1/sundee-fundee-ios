import React, { useEffect, useMemo, useState } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import ArtDecoCard from '../components/ArtDecoCard';
import { getEstimatedOneRmHistory, getWeeklyVolume } from '../lib/db';
import { artDecoTheme } from '../theme/tokens';

export default function ProgressScreen() {
  const [weeklyVolume, setWeeklyVolume] = useState<Array<{ weekKey: string; totalVolume: number }>>([]);
  const [oneRmHistory, setOneRmHistory] = useState<Array<{ date: string; value: number }>>([]);

  useEffect(() => {
    const loadProgress = async () => {
      const [volume, oneRm] = await Promise.all([
        getWeeklyVolume(8),
        getEstimatedOneRmHistory('back-squat'),
      ]);
      setWeeklyVolume(volume);
      setOneRmHistory(oneRm.slice(-8));
    };

    void loadProgress();
  }, []);

  const maxVolume = useMemo(() => {
    const values = weeklyVolume.map(item => item.totalVolume);
    return values.length > 0 ? Math.max(...values) : 1;
  }, [weeklyVolume]);

  const maxOneRm = useMemo(() => {
    const values = oneRmHistory.map(item => item.value);
    return values.length > 0 ? Math.max(...values) : 1;
  }, [oneRmHistory]);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.title}>Progress</Text>

      <ArtDecoCard style={styles.card}>
        <Text style={styles.cardTitle}>Weekly Volume</Text>
        {weeklyVolume.length === 0 ? (
          <Text style={styles.emptyText}>No workout volume recorded yet.</Text>
        ) : (
          weeklyVolume.map(point => (
            <View key={point.weekKey} style={styles.metricRow}>
              <Text style={styles.metricLabel}>{point.weekKey}</Text>
              <View style={styles.barTrack}>
                <View
                  style={[
                    styles.barFill,
                    { width: `${Math.max(8, (point.totalVolume / maxVolume) * 100)}%` },
                  ]}
                />
              </View>
              <Text style={styles.metricValue}>{Math.round(point.totalVolume)}</Text>
            </View>
          ))
        )}
      </ArtDecoCard>

      <ArtDecoCard style={styles.card}>
        <Text style={styles.cardTitle}>Estimated 1RM (Back Squat)</Text>
        {oneRmHistory.length === 0 ? (
          <Text style={styles.emptyText}>No set history available yet.</Text>
        ) : (
          oneRmHistory.map(point => (
            <View key={`${point.date}-${point.value}`} style={styles.metricRow}>
              <Text style={styles.metricLabel}>{point.date.slice(0, 10)}</Text>
              <View style={styles.barTrack}>
                <View
                  style={[
                    styles.secondaryBarFill,
                    { width: `${Math.max(8, (point.value / maxOneRm) * 100)}%` },
                  ]}
                />
              </View>
              <Text style={styles.metricValue}>{Math.round(point.value)}</Text>
            </View>
          ))
        )}
      </ArtDecoCard>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: artDecoTheme.colors.background,
  },
  content: {
    padding: artDecoTheme.spacing.md,
    gap: artDecoTheme.spacing.sm,
  },
  title: {
    color: artDecoTheme.colors.accent,
    fontSize: artDecoTheme.typography.title,
    fontWeight: '800',
  },
  card: {
    gap: artDecoTheme.spacing.sm,
  },
  cardTitle: {
    color: artDecoTheme.colors.textPrimary,
    fontSize: artDecoTheme.typography.subtitle,
    fontWeight: '700',
  },
  metricRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: artDecoTheme.spacing.xs,
  },
  metricLabel: {
    color: artDecoTheme.colors.textSecondary,
    width: 72,
    fontSize: artDecoTheme.typography.caption,
  },
  metricValue: {
    color: artDecoTheme.colors.textPrimary,
    width: 56,
    textAlign: 'right',
    fontSize: artDecoTheme.typography.caption,
  },
  barTrack: {
    flex: 1,
    height: 10,
    backgroundColor: artDecoTheme.colors.surfaceMuted,
    borderRadius: artDecoTheme.radius.sm,
    overflow: 'hidden',
  },
  barFill: {
    height: '100%',
    backgroundColor: artDecoTheme.colors.accent,
  },
  secondaryBarFill: {
    height: '100%',
    backgroundColor: artDecoTheme.colors.success,
  },
  emptyText: {
    color: artDecoTheme.colors.textSecondary,
    fontSize: artDecoTheme.typography.body,
  },
});
