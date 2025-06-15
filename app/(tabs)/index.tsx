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
import { AdBanner } from '@/components/AdBanner';

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
          
          {/* 🌟 영감을 주는 명언 */}
          <View style={styles.quoteContainer}>
            <Text style={styles.quoteText}>
              "당신의 생각을 바꾸면, 당신의 세상이 바뀝니다"
            </Text>
            <Text style={styles.quoteAuthor}>- 마야 안젤루</Text>
          </View>
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
    backgroundColor: 'linear-gradient(135deg, #e8f2ff 0%, #f4f0ff 50%, #fef7f7 100%)',
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    padding: 24,
    paddingBottom: 48,
  },
  header: {
    marginTop: 16,
    marginBottom: 40,
    paddingHorizontal: 8,
    alignItems: 'center',
  },
  greeting: {
    fontSize: 36,
    fontWeight: '800',
    color: '#1a1d29',
    marginBottom: 12,
    letterSpacing: -0.8,
    textAlign: 'center',
    textShadowColor: 'rgba(255, 255, 255, 0.8)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
  },
  subtitle: {
    fontSize: 20,
    color: '#6b7280',
    fontWeight: '600',
    letterSpacing: -0.3,
    textAlign: 'center',
    opacity: 0.9,
  },
  addButton: {
    backgroundColor: '#7c3aed',
    borderRadius: 28,
    padding: 24,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 36,
    marginHorizontal: 8,
    shadowColor: '#7c3aed',
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.35,
    shadowRadius: 20,
    elevation: 12,
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  addButtonText: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: '800',
    marginLeft: 14,
    letterSpacing: -0.4,
    textShadowColor: 'rgba(0, 0, 0, 0.1)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
  },
  section: {
    marginBottom: 36,
    backgroundColor: 'rgba(255, 255, 255, 0.95)',
    borderRadius: 32,
    padding: 28,
    marginHorizontal: 4,
    shadowColor: 'rgba(139, 92, 246, 0.15)',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 1,
    shadowRadius: 24,
    elevation: 8,
    borderWidth: 1.5,
    borderColor: 'rgba(255, 255, 255, 0.6)',
    backdropFilter: 'blur(20px)',
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 24,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(139, 92, 246, 0.1)',
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '800',
    color: '#2d1b69',
    letterSpacing: -0.6,
    textShadowColor: 'rgba(139, 92, 246, 0.1)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
  },
  quoteContainer: {
    marginTop: 24,
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    borderRadius: 24,
    padding: 20,
    marginHorizontal: 8,
    shadowColor: 'rgba(139, 92, 246, 0.2)',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 1,
    shadowRadius: 16,
    elevation: 6,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.7)',
    backdropFilter: 'blur(20px)',
  },
  quoteText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#4c1d95',
    textAlign: 'center',
    lineHeight: 26,
    letterSpacing: -0.2,
    fontStyle: 'italic',
    marginBottom: 8,
  },
  quoteAuthor: {
    fontSize: 14,
    fontWeight: '500',
    color: '#7c3aed',
    textAlign: 'center',
    opacity: 0.8,
    letterSpacing: 0.5,
  },
});