import React, { useState } from 'react';
import { StyleSheet, Text, View, ScrollView, TouchableOpacity } from 'react-native';
import { useThoughtStore } from '@/store/thoughtStore';
import { colors } from '@/constants/colors';
import ThoughtCard from '@/components/ThoughtCard';
import EmptyState from '@/components/EmptyState';
import { EmotionType } from '@/types/thought';

export default function HistoryScreen() {
  const thoughts = useThoughtStore((state) => state.thoughts);
  const [filter, setFilter] = useState<'all' | 'reframed' | 'unreframed'>('all');
  
  const filteredThoughts = thoughts.filter((thought) => {
    if (filter === 'reframed') return thought.reframe;
    if (filter === 'unreframed') return !thought.reframe;
    return true;
  });

  return (
    <View style={styles.container}>
      <View style={styles.filterContainer}>
        <TouchableOpacity
          style={[styles.filterButton, filter === 'all' && styles.activeFilter]}
          onPress={() => setFilter('all')}
        >
          <Text
            style={[styles.filterText, filter === 'all' && styles.activeFilterText]}
          >
            All
          </Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={[styles.filterButton, filter === 'reframed' && styles.activeFilter]}
          onPress={() => setFilter('reframed')}
        >
          <Text
            style={[styles.filterText, filter === 'reframed' && styles.activeFilterText]}
          >
            Reframed
          </Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={[styles.filterButton, filter === 'unreframed' && styles.activeFilter]}
          onPress={() => setFilter('unreframed')}
        >
          <Text
            style={[styles.filterText, filter === 'unreframed' && styles.activeFilterText]}
          >
            Unreframed
          </Text>
        </TouchableOpacity>
      </View>
      
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.contentContainer}
        showsVerticalScrollIndicator={false}
      >
        {filteredThoughts.length > 0 ? (
          filteredThoughts.map((thought) => (
            <ThoughtCard key={thought.id} thought={thought} />
          ))
        ) : (
          <EmptyState
            title="No thoughts found"
            message={`You don't have any ${filter !== 'all' ? filter + ' ' : ''}thoughts yet.`}
          />
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  filterContainer: {
    flexDirection: 'row',
    padding: 16,
    paddingBottom: 8,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  filterButton: {
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderRadius: 20,
    marginRight: 8,
  },
  activeFilter: {
    backgroundColor: colors.primaryLight,
  },
  filterText: {
    fontSize: 14,
    color: colors.textLight,
  },
  activeFilterText: {
    color: colors.primary,
    fontWeight: '500',
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    padding: 16,
    paddingBottom: 32,
  },
});