import React from 'react';
import {
  FlatList,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import ArtDecoButton from '../components/ArtDecoButton';
import ArtDecoCard from '../components/ArtDecoCard';
import { getAllPrograms } from '../data/programs';
import { artDecoTheme } from '../theme/tokens';

export default function ProgramListScreen({
  onSelect,
  onViewProgress,
}: {
  onSelect: (id: string) => void;
  onViewProgress: () => void;
}) {
  const programs = getAllPrograms();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Programs</Text>
      <Text style={styles.subtitle}>Choose a program to start your next cycle.</Text>
      <FlatList
        data={programs}
        keyExtractor={(p) => p.id}
        contentContainerStyle={styles.listContent}
        renderItem={({ item }) => (
          <TouchableOpacity onPress={() => onSelect(item.id)}>
            <ArtDecoCard style={styles.item}>
              <Text style={styles.itemTitle}>{item.name}</Text>
              {item.description ? <Text style={styles.itemDesc}>{item.description}</Text> : null}
            </ArtDecoCard>
          </TouchableOpacity>
        )}
      />
      <ArtDecoButton title="View Progress" variant="secondary" onPress={onViewProgress} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: artDecoTheme.colors.background,
    padding: artDecoTheme.spacing.md,
  },
  title: {
    color: artDecoTheme.colors.accent,
    fontSize: artDecoTheme.typography.title,
    fontWeight: '800',
    marginBottom: artDecoTheme.spacing.xs,
  },
  subtitle: {
    color: artDecoTheme.colors.textSecondary,
    fontSize: artDecoTheme.typography.body,
    marginBottom: artDecoTheme.spacing.sm,
  },
  listContent: {
    paddingBottom: artDecoTheme.spacing.md,
  },
  item: {
    marginBottom: artDecoTheme.spacing.sm,
  },
  itemTitle: {
    color: artDecoTheme.colors.textPrimary,
    fontSize: artDecoTheme.typography.subtitle,
    fontWeight: '700',
    marginBottom: artDecoTheme.spacing.xs,
  },
  itemDesc: {
    color: artDecoTheme.colors.textSecondary,
    fontSize: artDecoTheme.typography.caption,
    lineHeight: 18,
  },
});
