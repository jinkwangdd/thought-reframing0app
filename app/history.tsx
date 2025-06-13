import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, ScrollView, TouchableOpacity, TextInput } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useThoughtStore } from '@/store/thoughtStore';
import { colors } from '@/constants/colors';
import ThoughtCard from '@/components/ThoughtCard';
import EmptyState from '@/components/EmptyState';
import { Search, Filter, X } from 'lucide-react-native';
import { EmotionType } from '@/types/thought';
import { thoughtCategories } from '@/constants/prompts';

export default function HistoryScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ filter?: string }>();
  
  const thoughts = useThoughtStore((state) => state.thoughts);
  const searchThoughts = useThoughtStore((state) => state.searchThoughts);
  
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  const [filter, setFilter] = useState<'all' | 'reframed' | 'unreframed'>(
    params.filter === 'unreframed' ? 'unreframed' : 
    params.filter === 'reframed' ? 'reframed' : 'all'
  );
  const [emotionFilter, setEmotionFilter] = useState<EmotionType | null>(null);
  const [categoryFilter, setCategoryFilter] = useState<string | null>(null);
  const [showFilters, setShowFilters] = useState(false);
  
  useEffect(() => {
    if (params.filter) {
      if (params.filter === 'unreframed') {
        setFilter('unreframed');
      } else if (params.filter === 'reframed') {
        setFilter('reframed');
      }
    }
  }, [params]);
  
  const filteredThoughts = (() => {
    let results = thoughts;
    
    // Apply reframe status filter
    if (filter === 'reframed') {
      results = results.filter(thought => thought.reframe);
    } else if (filter === 'unreframed') {
      results = results.filter(thought => !thought.reframe);
    }
    
    // Apply emotion filter
    if (emotionFilter) {
      results = results.filter(thought => thought.emotion === emotionFilter);
    }
    
    // Apply category filter
    if (categoryFilter) {
      results = results.filter(thought => thought.category === categoryFilter);
    }
    
    // Apply search query
    if (searchQuery.trim()) {
      results = searchThoughts(searchQuery);
      
      // Re-apply filters to search results
      if (filter === 'reframed') {
        results = results.filter(thought => thought.reframe);
      } else if (filter === 'unreframed') {
        results = results.filter(thought => !thought.reframe);
      }
      
      if (emotionFilter) {
        results = results.filter(thought => thought.emotion === emotionFilter);
      }
      
      if (categoryFilter) {
        results = results.filter(thought => thought.category === categoryFilter);
      }
    }
    
    return results;
  })();
  
  const clearFilters = () => {
    setEmotionFilter(null);
    setCategoryFilter(null);
    setFilter('all');
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        {showSearch ? (
          <View style={styles.searchContainer}>
            <TextInput
              style={styles.searchInput}
              placeholder="Search thoughts..."
              placeholderTextColor={colors.textExtraLight}
              value={searchQuery}
              onChangeText={setSearchQuery}
              autoFocus
            />
            <TouchableOpacity 
              onPress={() => {
                setSearchQuery('');
                setShowSearch(false);
              }}
              hitSlop={{ top: 10, right: 10, bottom: 10, left: 10 }}
            >
              <X size={20} color={colors.textLight} />
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.filterContainer}>
            <View style={styles.filterButtons}>
              <TouchableOpacity
                style={[
                  styles.filterButton,
                  filter === 'all' && styles.activeFilter
                ]}
                onPress={() => setFilter('all')}
              >
                <Text
                  style={[
                    styles.filterText,
                    filter === 'all' && styles.activeFilterText
                  ]}
                >
                  All
                </Text>
              </TouchableOpacity>
              
              <TouchableOpacity
                style={[
                  styles.filterButton,
                  filter === 'reframed' && styles.activeFilter
                ]}
                onPress={() => setFilter('reframed')}
              >
                <Text
                  style={[
                    styles.filterText,
                    filter === 'reframed' && styles.activeFilterText
                  ]}
                >
                  Reframed
                </Text>
              </TouchableOpacity>
              
              <TouchableOpacity
                style={[
                  styles.filterButton,
                  filter === 'unreframed' && styles.activeFilter
                ]}
                onPress={() => setFilter('unreframed')}
              >
                <Text
                  style={[
                    styles.filterText,
                    filter === 'unreframed' && styles.activeFilterText
                  ]}
                >
                  Unreframed
                </Text>
              </TouchableOpacity>
            </View>
            
            <View style={styles.headerActions}>
              <TouchableOpacity 
                onPress={() => setShowFilters(!showFilters)}
                style={[
                  styles.iconButton,
                  (emotionFilter || categoryFilter) && styles.activeIconButton
                ]}
                hitSlop={{ top: 10, right: 10, bottom: 10, left: 10 }}
              >
                <Filter size={20} color={(emotionFilter || categoryFilter) ? colors.primary : colors.textLight} />
              </TouchableOpacity>
              
              <TouchableOpacity 
                onPress={() => setShowSearch(true)}
                style={styles.iconButton}
                hitSlop={{ top: 10, right: 10, bottom: 10, left: 10 }}
              >
                <Search size={20} color={colors.textLight} />
              </TouchableOpacity>
            </View>
          </View>
        )}
      </View>
      
      {showFilters && (
        <View style={styles.filtersPanel}>
          <View style={styles.filterSection}>
            <Text style={styles.filterSectionTitle}>Emotions</Text>
            <ScrollView 
              horizontal 
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.emotionsContainer}
            >
              {Object.entries(colors.emotions).map(([emotion, color]) => (
                <TouchableOpacity
                  key={emotion}
                  style={[
                    styles.emotionButton,
                    { borderColor: color },
                    emotionFilter === emotion && { backgroundColor: color }
                  ]}
                  onPress={() => setEmotionFilter(emotionFilter === emotion ? null : emotion as EmotionType)}
                >
                  <Text
                    style={[
                      styles.emotionText,
                      { color: emotionFilter === emotion ? '#FFFFFF' : color }
                    ]}
                  >
                    {emotion.charAt(0).toUpperCase() + emotion.slice(1)}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>
          
          <View style={styles.filterSection}>
            <Text style={styles.filterSectionTitle}>Categories</Text>
            <ScrollView 
              horizontal 
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.categoriesContainer}
            >
              {thoughtCategories.map((category) => (
                <TouchableOpacity
                  key={category}
                  style={[
                    styles.categoryButton,
                    categoryFilter === category && styles.activeCategoryButton
                  ]}
                  onPress={() => setCategoryFilter(categoryFilter === category ? null : category)}
                >
                  <Text
                    style={[
                      styles.categoryText,
                      categoryFilter === category && styles.activeCategoryText
                    ]}
                  >
                    {category}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>
          
          <TouchableOpacity 
            style={styles.clearFiltersButton}
            onPress={clearFilters}
          >
            <Text style={styles.clearFiltersText}>Clear Filters</Text>
          </TouchableOpacity>
        </View>
      )}
      
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.contentContainer}
        showsVerticalScrollIndicator={false}
      >
        {filteredThoughts.length > 0 ? (
          <>
            {(searchQuery || emotionFilter || categoryFilter) && (
              <Text style={styles.resultsText}>
                {filteredThoughts.length} result{filteredThoughts.length !== 1 ? 's' : ''}
              </Text>
            )}
            
            {filteredThoughts.map((thought) => (
              <ThoughtCard key={thought.id} thought={thought} />
            ))}
          </>
        ) : (
          <EmptyState
            title="No thoughts found"
            message={`You don't have any ${filter !== 'all' ? filter + ' ' : ''}thoughts${emotionFilter ? ` with emotion "${emotionFilter}"` : ''}${categoryFilter ? ` in category "${categoryFilter}"` : ''}${searchQuery ? ` matching "${searchQuery}"` : ''}.`}
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
  header: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  filterContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  filterButtons: {
    flexDirection: 'row',
    backgroundColor: colors.border,
    borderRadius: 20,
    padding: 2,
  },
  filterButton: {
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderRadius: 18,
  },
  activeFilter: {
    backgroundColor: colors.card,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 1,
    elevation: 1,
  },
  filterText: {
    fontSize: 14,
    color: colors.textLight,
  },
  activeFilterText: {
    color: colors.primary,
    fontWeight: '500',
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconButton: {
    marginLeft: 16,
  },
  activeIconButton: {
    backgroundColor: colors.primaryLight,
    borderRadius: 20,
    padding: 6,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 16,
    color: colors.text,
    paddingVertical: 4,
    marginRight: 8,
  },
  filtersPanel: {
    backgroundColor: colors.card,
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  filterSection: {
    marginBottom: 16,
  },
  filterSectionTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 8,
  },
  emotionsContainer: {
    paddingVertical: 4,
    gap: 8,
  },
  emotionButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    borderWidth: 1,
    marginRight: 8,
  },
  emotionText: {
    fontSize: 12,
    fontWeight: '500',
  },
  categoriesContainer: {
    paddingVertical: 4,
    gap: 8,
  },
  categoryButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.border,
    marginRight: 8,
    backgroundColor: colors.background,
  },
  activeCategoryButton: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  categoryText: {
    fontSize: 12,
    color: colors.text,
  },
  activeCategoryText: {
    color: '#FFFFFF',
    fontWeight: '500',
  },
  clearFiltersButton: {
    alignSelf: 'center',
    paddingVertical: 8,
    paddingHorizontal: 16,
  },
  clearFiltersText: {
    fontSize: 14,
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
  resultsText: {
    fontSize: 14,
    color: colors.textLight,
    marginBottom: 16,
  },
});