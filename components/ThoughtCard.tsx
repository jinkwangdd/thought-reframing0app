import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Animated } from 'react-native';
import { useRouter } from 'expo-router';
import { Thought } from '@/types/thought';
import { colors } from '@/constants/colors';
import { ArrowRightCircle, Heart } from 'lucide-react-native';
import { useThoughtStore } from '@/store/thoughtStore';
import { useTranslation } from '@/hooks/useTranslation';

interface ThoughtCardProps {
  thought: Thought;
  showActions?: boolean;
}

export default function ThoughtCard({ thought, showActions = true }: ThoughtCardProps) {
  const router = useRouter();
  const toggleFavorite = useThoughtStore((state) => state.toggleFavorite);
  const { t } = useTranslation();
  
  const formatDate = (timestamp: number) => {
    const date = new Date(timestamp);
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const handlePress = () => {
    if (thought.reframe) {
      router.push(`/thought/${thought.id}`);
    } else {
      router.push(`/reframe/${thought.id}`);
    }
  };

  const handleFavorite = (e: any) => {
    e.stopPropagation();
    toggleFavorite(thought.id);
  };

  return (
    <TouchableOpacity 
      style={styles.container} 
      onPress={handlePress}
      activeOpacity={0.7}
    >
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          <View 
            style={[
              styles.emotionIndicator, 
              { backgroundColor: colors.emotions[thought.emotion] }
            ]} 
          />
          <Text style={styles.date}>{formatDate(thought.createdAt)}</Text>
        </View>
        
        {showActions && (
          <TouchableOpacity 
            onPress={handleFavorite}
            hitSlop={{ top: 10, right: 10, bottom: 10, left: 10 }}
          >
            <Heart 
              size={16} 
              color={thought.favorite ? colors.accent : colors.textExtraLight} 
              fill={thought.favorite ? colors.accent : 'none'} 
            />
          </TouchableOpacity>
        )}
      </View>
      
      {thought.category && (
        <View style={styles.categoryContainer}>
          <Text style={styles.categoryText}>{thought.category}</Text>
        </View>
      )}
      
      <Text style={styles.content} numberOfLines={2}>
        {thought.content}
      </Text>
      
      <View style={styles.footer}>
        {thought.reframe ? (
          <Text style={styles.reframeStatus}>
            {thought.reframe.aiGenerated ? t('aiGenerated') : t('reframedThought')}
          </Text>
        ) : (
          <View style={styles.reframePrompt}>
            <Text style={styles.reframePromptText}>{t('reframeYourThought')}</Text>
            <ArrowRightCircle size={16} color={colors.primary} />
          </View>
        )}
      </View>
    </TouchableOpacity>
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
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  emotionIndicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 8,
  },
  date: {
    fontSize: 12,
    color: colors.textExtraLight,
  },
  categoryContainer: {
    backgroundColor: colors.border,
    alignSelf: 'flex-start',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    marginBottom: 8,
  },
  categoryText: {
    fontSize: 10,
    color: colors.textLight,
    fontWeight: '500',
  },
  content: {
    fontSize: 16,
    color: colors.text,
    marginBottom: 12,
    lineHeight: 22,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  reframeStatus: {
    fontSize: 12,
    color: colors.success,
    fontWeight: '500',
  },
  reframePrompt: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  reframePromptText: {
    fontSize: 12,
    color: colors.primary,
    fontWeight: '500',
  },
});