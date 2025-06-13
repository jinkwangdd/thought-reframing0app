import React, { useState } from 'react';
import { StyleSheet, Text, View, ScrollView, TouchableOpacity, TextInput } from 'react-native';
import { useThoughtStore } from '@/store/thoughtStore';
import { colors } from '@/constants/colors';
import ThoughtCard from '@/components/ThoughtCard';
import EmptyState from '@/components/EmptyState';
import { Search, BookOpen, Star, Filter, X } from 'lucide-react-native';
import { journalPrompts } from '@/constants/prompts';
import { useTranslation } from '@/hooks/useTranslation';

export default function JournalScreen() {
  const thoughts = useThoughtStore((state) => state.thoughts);
  const searchThoughts = useThoughtStore((state) => state.searchThoughts);
  const getFavoriteThoughts = useThoughtStore((state) => state.getFavoriteThoughts);
  const { t } = useTranslation();
  
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  const [filter, setFilter] = useState<'all' | 'favorites'>('all');
  const [randomPrompt, setRandomPrompt] = useState(getRandomPrompt());
  
  function getRandomPrompt() {
    return journalPrompts[Math.floor(Math.random() * journalPrompts.length)];
  }
  
  const refreshPrompt = () => {
    setRandomPrompt(getRandomPrompt());
  };
  
  const filteredThoughts = (() => {
    if (searchQuery.trim()) {
      return searchThoughts(searchQuery);
    }
    
    if (filter === 'favorites') {
      return getFavoriteThoughts();
    }
    
    return thoughts;
  })();

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        {showSearch ? (
          <View style={styles.searchContainer}>
            <TextInput
              style={styles.searchInput}
              placeholder={t('searchThoughts')}
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
                <BookOpen size={16} color={filter === 'all' ? colors.primary : colors.textLight} />
                <Text
                  style={[
                    styles.filterText,
                    filter === 'all' && styles.activeFilterText
                  ]}
                >
                  {t('all')}
                </Text>
              </TouchableOpacity>
              
              <TouchableOpacity
                style={[
                  styles.filterButton,
                  filter === 'favorites' && styles.activeFilter
                ]}
                onPress={() => setFilter('favorites')}
              >
                <Star size={16} color={filter === 'favorites' ? colors.primary : colors.textLight} />
                <Text
                  style={[
                    styles.filterText,
                    filter === 'favorites' && styles.activeFilterText
                  ]}
                >
                  {t('favorites')}
                </Text>
              </TouchableOpacity>
            </View>
            
            <TouchableOpacity 
              onPress={() => setShowSearch(true)}
              hitSlop={{ top: 10, right: 10, bottom: 10, left: 10 }}
            >
              <Search size={20} color={colors.textLight} />
            </TouchableOpacity>
          </View>
        )}
      </View>
      
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.contentContainer}
        showsVerticalScrollIndicator={false}
      >
        <TouchableOpacity 
          style={styles.promptCard}
          onPress={refreshPrompt}
          activeOpacity={0.8}
        >
          <Text style={styles.promptTitle}>{t('journalPrompt')}</Text>
          <Text style={styles.promptText}>{randomPrompt}</Text>
          <Text style={styles.promptRefresh}>{t('tapToRefresh')}</Text>
        </TouchableOpacity>
        
        {filteredThoughts.length > 0 ? (
          <>
            {searchQuery && (
              <Text style={styles.resultsText}>
                {filteredThoughts.length} {t('result')}{filteredThoughts.length !== 1 ? 's' : ''}
              </Text>
            )}
            
            {filteredThoughts.map((thought) => (
              <ThoughtCard key={thought.id} thought={thought} />
            ))}
          </>
        ) : (
          <EmptyState
            title={searchQuery ? t('noMatchingThoughts') : t('journalEmpty')}
            message={searchQuery 
              ? t('tryDifferentSearchTerm')
              : t('journalEmptyMessage')
            }
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
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
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
    marginLeft: 6,
  },
  activeFilterText: {
    color: colors.primary,
    fontWeight: '500',
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
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    padding: 16,
    paddingBottom: 32,
  },
  promptCard: {
    backgroundColor: colors.primary,
    borderRadius: 16,
    padding: 16,
    marginBottom: 24,
    shadowColor: colors.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 4,
  },
  promptTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: 8,
  },
  promptText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 12,
    lineHeight: 24,
  },
  promptRefresh: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
    textAlign: 'right',
    fontStyle: 'italic',
  },
  resultsText: {
    fontSize: 14,
    color: colors.textLight,
    marginBottom: 16,
  },
});