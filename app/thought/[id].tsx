import React from 'react';
import { StyleSheet, Text, View, ScrollView, TouchableOpacity, Share } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useThoughtStore } from '@/store/thoughtStore';
import { colors } from '@/constants/colors';
import { Edit2, Share2, Heart, Trash2 } from 'lucide-react-native';
import { useTranslation } from '@/hooks/useTranslation';

export default function ThoughtDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const thought = useThoughtStore((state) => state.getThought(id));
  const toggleFavorite = useThoughtStore((state) => state.toggleFavorite);
  const deleteThought = useThoughtStore((state) => state.deleteThought);
  const { t } = useTranslation();
  
  if (!thought) {
    router.replace('/');
    return null;
  }

  const formatDate = (timestamp: number) => {
    const date = new Date(timestamp);
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const handleEditReframe = () => {
    router.push(`/reframe/${id}`);
  };
  
  const handleShare = async () => {
    try {
      await Share.share({
        message: `Original thought: "${thought.content}"

${thought.reframe ? `Reframed perspective: "${thought.reframe.content}"` : ''}`,
        title: 'Thought from Reframe',
      });
    } catch (error) {
      console.error('Error sharing:', error);
    }
  };
  
  const handleFavorite = () => {
    toggleFavorite(id);
  };
  
  const handleDelete = () => {
    deleteThought(id);
    router.replace('/');
  };

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.contentContainer}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.actionsContainer}>
        <TouchableOpacity 
          style={styles.actionButton}
          onPress={handleShare}
        >
          <Share2 size={20} color={colors.text} />
        </TouchableOpacity>
        
        <TouchableOpacity 
          style={styles.actionButton}
          onPress={handleFavorite}
        >
          <Heart 
            size={20} 
            color={thought.favorite ? colors.accent : colors.text} 
            fill={thought.favorite ? colors.accent : 'none'} 
          />
        </TouchableOpacity>
        
        <TouchableOpacity 
          style={styles.actionButton}
          onPress={handleDelete}
        >
          <Trash2 size={20} color={colors.error} />
        </TouchableOpacity>
      </View>
      
      <View style={styles.card}>
        <Text style={styles.cardLabel}>{t('originalThought')}</Text>
        <Text style={styles.thoughtText}>{thought.content}</Text>
        
        <View style={styles.thoughtMeta}>
          <View 
            style={[
              styles.emotionTag, 
              { backgroundColor: colors.emotions[thought.emotion] }
            ]}
          >
            <Text style={styles.emotionText}>
              {t(thought.emotion as keyof TranslationKey)}
            </Text>
          </View>
          
          {thought.category && (
            <View style={styles.categoryTag}>
              <Text style={styles.categoryText}>{thought.category}</Text>
            </View>
          )}
        </View>
        
        {thought.tags && thought.tags.length > 0 && (
          <View style={styles.tagsContainer}>
            {thought.tags.map(tag => (
              <Text key={tag} style={styles.tagText}>#{tag}</Text>
            ))}
          </View>
        )}
        
        <Text style={styles.dateText}>{formatDate(thought.createdAt)}</Text>
      </View>
      
      {thought.reframe ? (
        <View style={styles.card}>
          <Text style={styles.cardLabel}>{t('reframedThought')}</Text>
          <Text style={styles.reframeText}>{thought.reframe.content}</Text>
          
          {thought.reframe.aiGenerated && (
            <View style={styles.aiGeneratedTag}>
              <Text style={styles.aiGeneratedText}>{t('aiGenerated')}</Text>
            </View>
          )}
          
          <Text style={styles.dateText}>{formatDate(thought.reframe.createdAt)}</Text>
          
          <TouchableOpacity 
            style={styles.editButton}
            onPress={handleEditReframe}
          >
            <Edit2 size={16} color={colors.primary} />
            <Text style={styles.editButtonText}>{t('editReframe')}</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <View style={styles.reframePromptCard}>
          <Text style={styles.reframePromptText}>
            {t('notReframedYet')}
          </Text>
          <TouchableOpacity 
            style={styles.reframeButton}
            onPress={handleEditReframe}
          >
            <Text style={styles.reframeButtonText}>{t('reframeNow')}</Text>
          </TouchableOpacity>
        </View>
      )}
      
      <View style={styles.insightCard}>
        <Text style={styles.insightTitle}>{t('insights')}</Text>
        <Text style={styles.insightText}>
          {getInsightForEmotion(thought.emotion)}
        </Text>
      </View>
    </ScrollView>
  );
}

function getInsightForEmotion(emotion: string) {
  switch (emotion) {
    case 'anger':
      return "Anger often arises when we feel our boundaries have been violated. Consider if there's a need you can express more directly.";
    case 'anxiety':
      return "Anxiety typically involves overestimating threats and underestimating our ability to cope. Try to focus on what you can control.";
    case 'sadness':
      return "Sadness is a natural response to loss. Allow yourself to feel it, but also consider what meaningful activities might help you move forward.";
    case 'fear':
      return "Fear helps us identify potential dangers. Ask yourself if the threat is as significant as it feels, and what resources you have to face it.";
    case 'shame':
      return "Shame often involves harsh self-judgment. Remember that making mistakes is part of being human, and self-compassion is more helpful than self-criticism.";
    case 'disappointment':
      return "Disappointment comes from unmet expectations. Consider if your expectations were realistic, and what you can learn from this experience.";
    case 'frustration':
      return "Frustration arises when our path is blocked. Try to identify alternative routes to your goal, or consider if the goal itself needs adjustment.";
    case 'guilt':
      return "Guilt can be productive when it helps us align with our values. Ask yourself what action you can take to make amends or do better next time.";
    default:
      return "Reframing your thoughts helps you challenge negative thinking patterns and develop a more balanced perspective.";
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  contentContainer: {
    padding: 16,
    paddingBottom: 32,
  },
  actionsContainer: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    marginBottom: 16,
  },
  actionButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.card,
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  card: {
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
  cardLabel: {
    fontSize: 14,
    color: colors.textLight,
    marginBottom: 8,
  },
  thoughtText: {
    fontSize: 18,
    color: colors.text,
    marginBottom: 16,
    lineHeight: 24,
  },
  reframeText: {
    fontSize: 18,
    color: colors.text,
    marginBottom: 16,
    lineHeight: 24,
    fontWeight: '500',
  },
  thoughtMeta: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 12,
  },
  emotionTag: {
    alignSelf: 'flex-start',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 16,
  },
  emotionText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '500',
  },
  categoryTag: {
    alignSelf: 'flex-start',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 16,
    backgroundColor: colors.border,
  },
  categoryText: {
    color: colors.textLight,
    fontSize: 12,
    fontWeight: '500',
  },
  tagsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 12,
    gap: 8,
  },
  tagText: {
    fontSize: 12,
    color: colors.textLight,
  },
  aiGeneratedTag: {
    alignSelf: 'flex-start',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 16,
    backgroundColor: colors.secondary,
    marginBottom: 12,
  },
  aiGeneratedText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '500',
  },
  dateText: {
    fontSize: 12,
    color: colors.textExtraLight,
  },
  editButton: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 16,
    alignSelf: 'flex-end',
  },
  editButtonText: {
    fontSize: 14,
    color: colors.primary,
    fontWeight: '500',
    marginLeft: 4,
  },
  reframePromptCard: {
    backgroundColor: colors.card,
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  reframePromptText: {
    fontSize: 16,
    color: colors.textLight,
    marginBottom: 16,
    textAlign: 'center',
  },
  reframeButton: {
    backgroundColor: colors.primary,
    borderRadius: 20,
    paddingHorizontal: 20,
    paddingVertical: 10,
  },
  reframeButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  insightCard: {
    backgroundColor: colors.secondaryLight,
    borderRadius: 16,
    padding: 16,
    marginTop: 8,
  },
  insightTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 8,
  },
  insightText: {
    fontSize: 14,
    color: colors.textLight,
    lineHeight: 20,
  },
});