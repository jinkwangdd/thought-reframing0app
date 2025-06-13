import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { colors } from '@/constants/colors';
import { useMoodStore } from '@/store/moodStore';
import { useSettingsStore } from '@/store/settingsStore';
import { Flame } from 'lucide-react-native';
import { useTranslation } from '@/hooks/useTranslation';

export default function StreakCard() {
  const streak = useMoodStore((state) => state.getStreak());
  const streakGoal = useSettingsStore((state) => state.streakGoal);
  const { t } = useTranslation();
  
  const progress = Math.min(streak / streakGoal, 1);
  
  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Flame size={20} color={colors.accent} />
        <Text style={styles.title}>Current Streak</Text>
      </View>
      
      <View style={styles.streakContainer}>
        <Text style={styles.streakCount}>{streak}</Text>
        <Text style={styles.streakLabel}>{t('days')}</Text>
      </View>
      
      <View style={styles.progressContainer}>
        <View style={styles.progressBackground}>
          <View 
            style={[
              styles.progressFill,
              { width: `${progress * 100}%` }
            ]} 
          />
        </View>
        <Text style={styles.goalText}>{t('streakGoal')}: {streakGoal} {t('days')}</Text>
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
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  title: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
    marginLeft: 8,
  },
  streakContainer: {
    flexDirection: 'row',
    alignItems: 'baseline',
    marginBottom: 16,
  },
  streakCount: {
    fontSize: 36,
    fontWeight: '700',
    color: colors.accent,
  },
  streakLabel: {
    fontSize: 16,
    color: colors.textLight,
    marginLeft: 8,
  },
  progressContainer: {
    marginTop: 4,
  },
  progressBackground: {
    height: 8,
    backgroundColor: colors.border,
    borderRadius: 4,
    marginBottom: 8,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.accent,
    borderRadius: 4,
  },
  goalText: {
    fontSize: 12,
    color: colors.textLight,
    textAlign: 'right',
  },
});