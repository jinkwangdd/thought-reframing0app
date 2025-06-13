import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { colors } from '@/constants/colors';
import { useMoodStore } from '@/store/moodStore';
import EmotionSelector from './EmotionSelector';
import { EmotionType } from '@/types/thought';
import { useTranslation } from '@/hooks/useTranslation';

export default function MoodTracker() {
  const addMoodEntry = useMoodStore((state) => state.addEntry);
  const todayEntry = useMoodStore((state) => {
    const today = new Date().toISOString().split('T')[0];
    return state.getEntryByDate(today);
  });
  
  const { t } = useTranslation();
  
  const [mood, setMood] = useState<number>(todayEntry?.mood || 3);
  const [selectedEmotions, setSelectedEmotions] = useState<EmotionType[]>(
    todayEntry?.emotions || []
  );
  const [note, setNote] = useState<string>(todayEntry?.note || '');
  const [showEmotionSelector, setShowEmotionSelector] = useState(false);
  
  const moodLabels = ['Very Bad', 'Bad', 'Neutral', 'Good', 'Very Good'];
  const moodColors = [
    colors.emotions.sadness,
    colors.emotions.disappointment,
    colors.emotions.neutral,
    colors.emotions.calm,
    colors.emotions.joy
  ];
  
  const handleMoodSelect = (value: number) => {
    setMood(value);
  };
  
  const handleEmotionSelect = (emotion: EmotionType) => {
    if (selectedEmotions.includes(emotion)) {
      setSelectedEmotions(selectedEmotions.filter(e => e !== emotion));
    } else {
      setSelectedEmotions([...selectedEmotions, emotion]);
    }
  };
  
  const handleSave = () => {
    addMoodEntry(mood, selectedEmotions, note);
    setShowEmotionSelector(false);
  };
  
  return (
    <View style={styles.container}>
      <Text style={styles.title}>{t('howAreYouFeeling')}</Text>
      
      <View style={styles.moodSelector}>
        {[1, 2, 3, 4, 5].map((value) => (
          <TouchableOpacity
            key={value}
            style={[
              styles.moodButton,
              mood === value && { 
                backgroundColor: moodColors[value - 1],
                transform: [{ scale: 1.1 }]
              }
            ]}
            onPress={() => handleMoodSelect(value)}
          >
            <Text 
              style={[
                styles.moodEmoji,
                mood === value && { color: '#FFFFFF' }
              ]}
            >
              {value === 1 ? '😞' : 
               value === 2 ? '😕' : 
               value === 3 ? '😐' : 
               value === 4 ? '🙂' : '😄'}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
      
      <Text style={styles.moodLabel}>
        {moodLabels[mood - 1]}
      </Text>
      
      {!showEmotionSelector ? (
        <TouchableOpacity 
          style={styles.addEmotionsButton}
          onPress={() => setShowEmotionSelector(true)}
        >
          <Text style={styles.addEmotionsText}>
            {selectedEmotions.length > 0 
              ? `${selectedEmotions.length} emotions selected` 
              : 'Add specific emotions'}
          </Text>
        </TouchableOpacity>
      ) : (
        <View style={styles.emotionSelectorContainer}>
          <EmotionSelector 
            selectedEmotion={selectedEmotions[0] || 'neutral'}
            onSelect={handleEmotionSelect}
            showPositiveEmotions={true}
          />
          
          <TouchableOpacity 
            style={styles.saveButton}
            onPress={handleSave}
          >
            <Text style={styles.saveButtonText}>{t('save')}</Text>
          </TouchableOpacity>
        </View>
      )}
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
    textAlign: 'center',
  },
  moodSelector: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  moodButton: {
    width: 50,
    height: 50,
    borderRadius: 25,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background,
  },
  moodEmoji: {
    fontSize: 24,
  },
  moodLabel: {
    textAlign: 'center',
    fontSize: 16,
    color: colors.text,
    marginBottom: 16,
    fontWeight: '500',
  },
  addEmotionsButton: {
    padding: 12,
    borderRadius: 8,
    backgroundColor: colors.border,
    alignItems: 'center',
  },
  addEmotionsText: {
    color: colors.textLight,
    fontWeight: '500',
  },
  emotionSelectorContainer: {
    marginTop: 8,
  },
  saveButton: {
    backgroundColor: colors.primary,
    borderRadius: 12,
    padding: 12,
    alignItems: 'center',
    marginTop: 16,
  },
  saveButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
});