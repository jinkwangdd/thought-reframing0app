import React, { useState } from 'react';
import { StyleSheet, Text, View, ScrollView, TouchableOpacity, Dimensions } from 'react-native';
import { useThoughtStore } from '@/store/thoughtStore';
import { useMoodStore } from '@/store/moodStore';
import { colors } from '@/constants/colors';
import EmotionChart from '@/components/EmotionChart';
import { Calendar, TrendingUp, Award, Filter } from 'lucide-react-native';
import { useTranslation } from '@/hooks/useTranslation';

const { width } = Dimensions.get('window');

export default function InsightsScreen() {
  const [timeRange, setTimeRange] = useState<'week' | 'month' | 'all'>('week');
  const { t } = useTranslation();
  
  const thoughts = useThoughtStore((state) => state.thoughts);
  const reframeRate = useThoughtStore((state) => state.getReframeRate());
  const averageMood = useMoodStore((state) => state.getAverageMood(timeRange === 'week' ? 7 : timeRange === 'month' ? 30 : undefined));
  
  const getTimeRangeLabel = () => {
    switch (timeRange) {
      case 'week': return t('pastSevenDays');
      case 'month': return t('pastThirtyDays');
      case 'all': return t('allTime');
    }
  };
  
  const getFilteredThoughts = () => {
    if (timeRange === 'all') return thoughts;
    
    const now = Date.now();
    const msInDay = 24 * 60 * 60 * 1000;
    const daysToFilter = timeRange === 'week' ? 7 : 30;
    const cutoff = now - (daysToFilter * msInDay);
    
    return thoughts.filter(thought => thought.createdAt >= cutoff);
  };
  
  const filteredThoughts = getFilteredThoughts();
  const totalThoughts = filteredThoughts.length;
  const reframedThoughts = filteredThoughts.filter(thought => thought.reframe).length;
  
  // Calculate most common emotion
  const emotionCounts: Record<string, number> = {};
  filteredThoughts.forEach(thought => {
    emotionCounts[thought.emotion] = (emotionCounts[thought.emotion] || 0) + 1;
  });
  
  let mostCommonEmotion = 'none';
  let maxCount = 0;
  
  Object.entries(emotionCounts).forEach(([emotion, count]) => {
    if (count > maxCount) {
      mostCommonEmotion = emotion;
      maxCount = count;
    }
  });

  return (
    <View style={styles.container}>
      <View style={styles.filterContainer}>
        <Text style={styles.filterLabel}>
          <Filter size={16} color={colors.textLight} /> {getTimeRangeLabel()}
        </Text>
        
        <View style={styles.timeRangeButtons}>
          <TouchableOpacity
            style={[
              styles.timeRangeButton,
              timeRange === 'week' && styles.activeTimeRange
            ]}
            onPress={() => setTimeRange('week')}
          >
            <Text
              style={[
                styles.timeRangeText,
                timeRange === 'week' && styles.activeTimeRangeText
              ]}
            >
              {t('week')}
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[
              styles.timeRangeButton,
              timeRange === 'month' && styles.activeTimeRange
            ]}
            onPress={() => setTimeRange('month')}
          >
            <Text
              style={[
                styles.timeRangeText,
                timeRange === 'month' && styles.activeTimeRangeText
              ]}
            >
              {t('month')}
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[
              styles.timeRangeButton,
              timeRange === 'all' && styles.activeTimeRange
            ]}
            onPress={() => setTimeRange('all')}
          >
            <Text
              style={[
                styles.timeRangeText,
                timeRange === 'all' && styles.activeTimeRangeText
              ]}
            >
              {t('all')}
            </Text>
          </TouchableOpacity>
        </View>
      </View>
      
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.contentContainer}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.statsContainer}>
          <View style={styles.statCard}>
            <View style={styles.statIconContainer}>
              <Calendar size={20} color={colors.primary} />
            </View>
            <Text style={styles.statValue}>{totalThoughts}</Text>
            <Text style={styles.statLabel}>{t('thoughts')}</Text>
          </View>
          
          <View style={styles.statCard}>
            <View style={styles.statIconContainer}>
              <TrendingUp size={20} color={colors.secondary} />
            </View>
            <Text style={styles.statValue}>{reframeRate.toFixed(0)}%</Text>
            <Text style={styles.statLabel}>{t('reframed')}</Text>
          </View>
          
          <View style={styles.statCard}>
            <View style={styles.statIconContainer}>
              <Award size={20} color={colors.accent} />
            </View>
            <Text style={styles.statValue}>{averageMood.toFixed(1)}</Text>
            <Text style={styles.statLabel}>{t('avgMood')}</Text>
          </View>
        </View>
        
        <EmotionChart />
        
        <View style={styles.insightsCard}>
          <Text style={styles.insightsTitle}>{t('yourInsights')}</Text>
          
          {totalThoughts > 0 ? (
            <>
              <View style={styles.insightItem}>
                <Text style={styles.insightLabel}>{t('mostCommonEmotion')}</Text>
                <Text style={styles.insightValue}>
                  {t(mostCommonEmotion as keyof TranslationKey)}
                </Text>
              </View>
              
              <View style={styles.insightItem}>
                <Text style={styles.insightLabel}>{t('thoughtsReframed')}</Text>
                <Text style={styles.insightValue}>
                  {reframedThoughts} {t('of')} {totalThoughts}
                </Text>
              </View>
              
              {reframedThoughts > 0 && (
                <View style={styles.insightItem}>
                  <Text style={styles.insightLabel}>{t('averageTimeToReframe')}</Text>
                  <Text style={styles.insightValue}>
                    {calculateAverageReframeTime(filteredThoughts, t)}
                  </Text>
                </View>
              )}
              
              <Text style={styles.insightTip}>
                {getInsightTip(mostCommonEmotion, reframeRate, t)}
              </Text>
            </>
          ) : (
            <Text style={styles.emptyInsight}>
              {t('recordToSeeInsights')}
            </Text>
          )}
        </View>
      </ScrollView>
    </View>
  );
}

function calculateAverageReframeTime(thoughts: any[], t: (key: keyof TranslationKey) => string) {
  const reframedThoughts = thoughts.filter(t => t.reframe);
  if (reframedThoughts.length === 0) return t('notAvailable');
  
  let totalTime = 0;
  reframedThoughts.forEach(thought => {
    const timeToReframe = thought.reframe.createdAt - thought.createdAt;
    totalTime += timeToReframe;
  });
  
  const avgTimeMs = totalTime / reframedThoughts.length;
  const avgTimeHours = avgTimeMs / (1000 * 60 * 60);
  
  if (avgTimeHours < 1) {
    return `${Math.round(avgTimeHours * 60)} ${t('minutes')}`;
  } else if (avgTimeHours < 24) {
    return `${Math.round(avgTimeHours)} ${t('hours')}`;
  } else {
    return `${Math.round(avgTimeHours / 24)} ${t('days')}`;
  }
}

function getInsightTip(emotion: string, reframeRate: number, t: (key: keyof TranslationKey) => string) {
  if (reframeRate < 30) {
    return t('tryToReframeMore');
  }
  
  switch (emotion) {
    case 'anxiety':
      return t('anxietyTip');
    case 'anger':
      return t('angerTip');
    case 'sadness':
      return t('sadnessTip');
    case 'fear':
      return t('fearTip');
    default:
      return t('keepTrackingThoughts');
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  filterContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  filterLabel: {
    fontSize: 14,
    color: colors.textLight,
    flexDirection: 'row',
    alignItems: 'center',
  },
  timeRangeButtons: {
    flexDirection: 'row',
    backgroundColor: colors.border,
    borderRadius: 20,
    padding: 2,
  },
  timeRangeButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 18,
  },
  activeTimeRange: {
    backgroundColor: colors.card,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 1,
    elevation: 1,
  },
  timeRangeText: {
    fontSize: 12,
    color: colors.textLight,
  },
  activeTimeRangeText: {
    color: colors.text,
    fontWeight: '500',
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    padding: 16,
    paddingBottom: 32,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  statCard: {
    width: (width - 48) / 3,
    backgroundColor: colors.card,
    borderRadius: 16,
    padding: 16,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.background,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  statValue: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.text,
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: colors.textLight,
    textAlign: 'center',
  },
  insightsCard: {
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
  insightsTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 16,
  },
  insightItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  insightLabel: {
    fontSize: 14,
    color: colors.textLight,
  },
  insightValue: {
    fontSize: 14,
    fontWeight: '500',
    color: colors.text,
  },
  insightTip: {
    fontSize: 14,
    color: colors.primary,
    fontStyle: 'italic',
    marginTop: 8,
    lineHeight: 20,
  },
  emptyInsight: {
    fontSize: 14,
    color: colors.textLight,
    textAlign: 'center',
    marginVertical: 20,
  },
});