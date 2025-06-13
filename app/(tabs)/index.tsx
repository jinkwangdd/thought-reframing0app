import React, { useEffect } from 'react';
import { StyleSheet, Text, View, ScrollView, TouchableOpacity, Animated } from 'react-native';
import { useRouter } from 'expo-router';
import { Plus, ArrowRight } from 'lucide-react-native';
import { useThoughtStore } from '@/store/thoughtStore';
import { useSettingsStore } from '@/store/settingsStore';
import { colors } from '@/constants/colors';
import ThoughtCard from '@/components/ThoughtCard';
import EmptyState from '@/components/EmptyState';
import MoodTracker from '@/components/MoodTracker';
import StreakCard from '@/components/StreakCard';
import { useTranslation } from '@/hooks/useTranslation';

export default function HomeScreen() {
  const router = useRouter();
  const thoughts = useThoughtStore((state) => state.thoughts);
  const username = useSettingsStore((state) => state.username);
  const onboardingCompleted = useSettingsStore((state) => state.onboardingCompleted);
  const completeOnboarding = useSettingsStore((state) => state.completeOnboarding);
  
  const { t } = useTranslation();
  
  const fadeAnim = new Animated.Value(0);
  
  useEffect(() => {
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 500,
      useNativeDriver: true,
    }).start();
    
    // Auto-complete onboarding for existing users
    if (!onboardingCompleted && thoughts.length > 0) {
      completeOnboarding();
    }
  }, []);
  
  const recentThoughts = thoughts.slice(0, 3);
  const hasUnreframedThoughts = thoughts.some((thought) => !thought.reframe);
  
  const handleNewThought = () => {
    router.push('/new-thought');
  };

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return t('greeting_morning');
    if (hour < 18) return t('greeting_afternoon');
    return t('greeting_evening');
  };

  return (
    <Animated.View style={[styles.container, { opacity: fadeAnim }]}>
      <ScrollView 
        style={styles.scrollView}
        contentContainerStyle={styles.contentContainer}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Text style={styles.greeting}>
            {getGreeting()}{username ? `, ${username}` : ''}
          </Text>
          <Text style={styles.subtitle}>{t('howAreYouFeeling')}</Text>
        </View>
        
        <MoodTracker />
        
        <StreakCard />
        
        <TouchableOpacity 
          style={styles.addButton} 
          onPress={handleNewThought}
          activeOpacity={0.8}
        >
          <Plus size={20} color="#FFFFFF" />
          <Text style={styles.addButtonText}>{t('recordThought')}</Text>
        </TouchableOpacity>
        
        {hasUnreframedThoughts && (
          <View style={styles.section}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>{t('thoughtsToReframe')}</Text>
              <TouchableOpacity 
                onPress={() => router.push('/history?filter=unreframed')}
                hitSlop={{ top: 10, right: 10, bottom: 10, left: 10 }}
              >
                <ArrowRight size={16} color={colors.primary} />
              </TouchableOpacity>
            </View>
            
            {thoughts
              .filter((thought) => !thought.reframe)
              .slice(0, 2)
              .map((thought) => (
                <ThoughtCard key={thought.id} thought={thought} />
              ))}
          </View>
        )}
        
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>{t('recentThoughts')}</Text>
            <TouchableOpacity 
              onPress={() => router.push('/history')}
              hitSlop={{ top: 10, right: 10, bottom: 10, left: 10 }}
            >
              <ArrowRight size={16} color={colors.primary} />
            </TouchableOpacity>
          </View>
          
          {recentThoughts.length > 0 ? (
            recentThoughts.map((thought) => (
              <ThoughtCard key={thought.id} thought={thought} />
            ))
          ) : (
            <EmptyState 
              title={t('noThoughtsYet')}
              message={t('noThoughtsMessage')}
            />
          )}
        </View>
      </ScrollView>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    padding: 16,
    paddingBottom: 32,
  },
  header: {
    marginTop: 8,
    marginBottom: 24,
  },
  greeting: {
    fontSize: 24,
    fontWeight: '700',
    color: colors.text,
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 16,
    color: colors.textLight,
  },
  addButton: {
    backgroundColor: colors.primary,
    borderRadius: 12,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 24,
    shadowColor: colors.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 4,
  },
  addButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
  section: {
    marginBottom: 24,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.text,
  },
});