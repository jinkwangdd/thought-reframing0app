import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { colors } from '@/constants/colors';
import { thoughtCategories } from '@/constants/prompts';
import { useTranslation } from '@/hooks/useTranslation';

interface CategorySelectorProps {
  selectedCategory: string | undefined;
  onSelect: (category: string) => void;
}

export default function CategorySelector({ selectedCategory, onSelect }: CategorySelectorProps) {
  const { t } = useTranslation();
  
  // Map category keys to translation keys
  const categoryTranslationMap: Record<string, keyof TranslationKey> = {
    "Work & Career": 'workAndCareer',
    "Relationships": 'relationships',
    "Health & Wellness": 'healthAndWellness',
    "Self-Image": 'selfImage',
    "Future & Goals": 'futureAndGoals',
    "Past Regrets": 'pastRegrets',
    "Daily Stressors": 'dailyStressors',
    "Social Situations": 'socialSituations'
  };

  return (
    <View style={styles.container}>
      <Text style={styles.label}>{t('categorizeThought')}</Text>
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
              selectedCategory === category && styles.selectedCategory,
            ]}
            onPress={() => onSelect(category)}
            activeOpacity={0.7}
          >
            <Text
              style={[
                styles.categoryText,
                selectedCategory === category && styles.selectedCategoryText,
              ]}
            >
              {categoryTranslationMap[category] ? t(categoryTranslationMap[category]) : category}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginVertical: 16,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 12,
  },
  categoriesContainer: {
    paddingVertical: 8,
    gap: 8,
  },
  categoryButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: colors.border,
    marginRight: 8,
    backgroundColor: colors.background,
  },
  selectedCategory: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  categoryText: {
    fontSize: 14,
    color: colors.text,
  },
  selectedCategoryText: {
    color: '#FFFFFF',
    fontWeight: '500',
  },
});