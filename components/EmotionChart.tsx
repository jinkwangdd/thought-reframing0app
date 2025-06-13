import React, { useMemo } from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import { colors } from '@/constants/colors';
import { useThoughtStore } from '@/store/thoughtStore';
import { EmotionType } from '@/types/thought';
import { useTranslation } from '@/hooks/useTranslation';

const { width } = Dimensions.get('window');
const BAR_WIDTH = (width - 64) / 5; // Adjust based on screen width and padding

export default function EmotionChart() {
  const emotionStats = useThoughtStore((state) => state.getEmotionStats());
  const { t } = useTranslation();
  
  // Use useMemo to prevent recalculations on every render
  const topEmotions = useMemo(() => {
    return Object.entries(emotionStats)
      .filter(([_, count]) => count > 0)
      .sort(([_, countA], [__, countB]) => countB - countA)
      .slice(0, 5);
  }, [emotionStats]);
  
  // Find the maximum count for scaling
  const maxCount = useMemo(() => {
    if (topEmotions.length === 0) return 1; // Prevent division by zero
    return Math.max(...topEmotions.map(([_, count]) => count));
  }, [topEmotions]);
  
  // If no emotions recorded yet
  if (topEmotions.length === 0) {
    return (
      <View style={styles.container}>
        <Text style={styles.title}>{t('emotionPatterns')}</Text>
        <Text style={styles.emptyText}>
          {t('recordToSeePatterns')}
        </Text>
      </View>
    );
  }
  
  return (
    <View style={styles.container}>
      <Text style={styles.title}>{t('emotionPatterns')}</Text>
      
      <View style={styles.chartContainer}>
        {topEmotions.map(([emotion, count]) => {
          const normalizedHeight = (count / maxCount) * 150; // Max height of 150
          
          return (
            <View key={emotion} style={styles.barContainer}>
              <Text style={styles.barValue}>{count}</Text>
              <View 
                style={[
                  styles.bar, 
                  { 
                    height: normalizedHeight, 
                    backgroundColor: colors.emotions[emotion as EmotionType] 
                  }
                ]} 
              />
              <Text style={styles.barLabel}>
                {t(emotion as keyof TranslationKey)}
              </Text>
            </View>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.card,
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 16,
  },
  emptyText: {
    fontSize: 14,
    color: colors.textLight,
    textAlign: 'center',
    marginVertical: 40,
  },
  chartContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    height: 200,
  },
  barContainer: {
    alignItems: 'center',
    width: BAR_WIDTH,
  },
  bar: {
    width: BAR_WIDTH - 10,
    borderRadius: 8,
    minHeight: 20,
  },
  barValue: {
    fontSize: 12,
    color: colors.textLight,
    marginBottom: 4,
  },
  barLabel: {
    fontSize: 12,
    color: colors.textLight,
    marginTop: 8,
  },
});