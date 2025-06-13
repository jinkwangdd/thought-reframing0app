import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { EmotionType } from '@/types/thought';
import { colors } from '@/constants/colors';
import { useTranslation } from '@/hooks/useTranslation';

interface EmotionSelectorProps {
  selectedEmotion: EmotionType;
  onSelect: (emotion: EmotionType) => void;
  showPositiveEmotions?: boolean;
}

const negativeEmotions: { type: EmotionType; labelKey: keyof TranslationKey }[] = [
  { type: 'anger', labelKey: 'anger' },
  { type: 'anxiety', labelKey: 'anxiety' },
  { type: 'sadness', labelKey: 'sadness' },
  { type: 'fear', labelKey: 'fear' },
  { type: 'shame', labelKey: 'shame' },
  { type: 'disappointment', labelKey: 'disappointment' },
  { type: 'frustration', labelKey: 'frustration' },
  { type: 'guilt', labelKey: 'guilt' },
];

const positiveEmotions: { type: EmotionType; labelKey: keyof TranslationKey }[] = [
  { type: 'joy', labelKey: 'joy' },
  { type: 'gratitude', labelKey: 'gratitude' },
  { type: 'calm', labelKey: 'calm' },
  { type: 'hope', labelKey: 'hope' },
];

const neutralEmotions: { type: EmotionType; labelKey: keyof TranslationKey }[] = [
  { type: 'neutral', labelKey: 'neutral' },
];

export default function EmotionSelector({ selectedEmotion, onSelect, showPositiveEmotions = false }: EmotionSelectorProps) {
  const { t } = useTranslation();
  
  const emotions = showPositiveEmotions 
    ? [...negativeEmotions, ...positiveEmotions, ...neutralEmotions]
    : [...negativeEmotions, ...neutralEmotions];

  return (
    <View style={styles.container}>
      <Text style={styles.label}>{t('howAreYouFeelingQuestion')}</Text>
      <ScrollView 
        horizontal 
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.emotionsContainer}
      >
        {emotions.map((emotion) => (
          <TouchableOpacity
            key={emotion.type}
            style={[
              styles.emotionButton,
              { backgroundColor: selectedEmotion === emotion.type ? colors.emotions[emotion.type] : 'transparent' },
              { borderColor: colors.emotions[emotion.type] },
            ]}
            onPress={() => onSelect(emotion.type)}
            activeOpacity={0.7}
          >
            <Text
              style={[
                styles.emotionText,
                { color: selectedEmotion === emotion.type ? '#FFFFFF' : colors.emotions[emotion.type] },
              ]}
            >
              {t(emotion.labelKey)}
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
  emotionsContainer: {
    paddingVertical: 8,
    gap: 8,
  },
  emotionButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
    marginRight: 8,
  },
  emotionText: {
    fontSize: 14,
    fontWeight: '500',
  },
});