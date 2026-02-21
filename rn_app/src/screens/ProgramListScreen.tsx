import React from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, Button } from 'react-native';
import { getAllPrograms } from '../data/programs';

export default function ProgramListScreen({ onBack, onSelect }: { onBack: () => void; onSelect: (id: string) => void; }) {
  const programs = getAllPrograms();

  return (
    <View style={styles.container}>
      <Button title="Back" onPress={onBack} />
      <Text style={styles.title}>Programs</Text>
      <FlatList
        data={programs}
        keyExtractor={(p) => p.id}
        renderItem={({ item }) => (
          <TouchableOpacity style={styles.item} onPress={() => onSelect(item.id)}>
            <Text style={styles.itemTitle}>{item.name}</Text>
            {item.description ? <Text style={styles.itemDesc}>{item.description}</Text> : null}
          </TouchableOpacity>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16 },
  title: { fontSize: 20, fontWeight: '700', marginVertical: 8 },
  item: { padding: 12, borderBottomWidth: 1, borderColor: '#eee' },
  itemTitle: { fontSize: 16, fontWeight: '600' },
  itemDesc: { fontSize: 12, color: '#666' }
});
