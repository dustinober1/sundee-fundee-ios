import React, { useMemo } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import ArtDecoButton from '../components/ArtDecoButton';
import ArtDecoCard from '../components/ArtDecoCard';
import { getProgramById } from '../data/programs';
import { normalizeProgram } from '../lib/programs';
import { artDecoTheme } from '../theme/tokens';

export default function ProgramDetailScreen({
  programId,
  onStartWorkout,
}: {
  programId: string;
  onStartWorkout: (programId: string) => void;
}) {
  const normalizedProgram = useMemo(() => {
    const program = getProgramById(programId);
    return program ? normalizeProgram(program) : null;
  }, [programId]);

  if (!normalizedProgram) {
    return (
      <View style={styles.emptyState}>
        <Text style={styles.emptyText}>Program not found.</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.title}>{normalizedProgram.name}</Text>
      <Text style={styles.description}>{normalizedProgram.description}</Text>

      <ArtDecoCard style={styles.metaCard}>
        <Text style={styles.metaText}>Duration: {normalizedProgram.durationWeeks} weeks</Text>
        <Text style={styles.metaText}>
          Frequency: {normalizedProgram.sessionsPerWeek} sessions/week
        </Text>
        <Text style={styles.metaText}>Difficulty: {normalizedProgram.difficulty}</Text>
      </ArtDecoCard>

      <Text style={styles.sectionTitle}>Week Preview</Text>
      {normalizedProgram.weeks.slice(0, 2).map(week => (
        <ArtDecoCard key={week.week} style={styles.weekCard}>
          <Text style={styles.weekTitle}>Week {week.week}</Text>
          {week.sessions.map(session => (
            <Text key={session.sessionId} style={styles.weekSession}>
              • {session.sessionName}
            </Text>
          ))}
        </ArtDecoCard>
      ))}

      <ArtDecoButton
        title="Start Workout"
        onPress={() => onStartWorkout(programId)}
      />
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
  description: {
    color: artDecoTheme.colors.textSecondary,
    fontSize: artDecoTheme.typography.body,
    lineHeight: 22,
  },
  metaCard: {
    gap: artDecoTheme.spacing.xs,
  },
  metaText: {
    color: artDecoTheme.colors.textPrimary,
    fontSize: artDecoTheme.typography.body,
  },
  sectionTitle: {
    color: artDecoTheme.colors.textPrimary,
    fontSize: artDecoTheme.typography.subtitle,
    fontWeight: '700',
    marginTop: artDecoTheme.spacing.sm,
  },
  weekCard: {
    gap: artDecoTheme.spacing.xs,
  },
  weekTitle: {
    color: artDecoTheme.colors.accentMuted,
    fontSize: artDecoTheme.typography.body,
    fontWeight: '700',
  },
  weekSession: {
    color: artDecoTheme.colors.textSecondary,
    fontSize: artDecoTheme.typography.caption,
  },
  emptyState: {
    flex: 1,
    backgroundColor: artDecoTheme.colors.background,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyText: {
    color: artDecoTheme.colors.textPrimary,
    fontSize: artDecoTheme.typography.body,
  },
});
