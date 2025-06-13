import React, { useState } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, ScrollView, KeyboardAvoidingView, Platform } from 'react-native';
import { useRouter } from 'expo-router';
import { useThoughtStore } from '@/store/thoughtStore';
import { colors } from '@/constants/colors';
import EmotionSelector from '@/components/EmotionSelector';
import CategorySelector from '@/components/CategorySelector';
import TagInput from '@/components/TagInput';
import { EmotionType } from '@/types/thought';
import { useTranslation } from '@/hooks/useTranslation';

export default function NewThoughtScreen() {
  const router = useRouter();
  const addThought = useThoughtStore((state) => state.addThought);
  const { t } = useTranslation();
  
  const [thought, setThought] = useState('');
  const [emotion, setEmotion] = useState<EmotionType>('neutral');
  const [category, setCategory] = useState<string | undefined>(undefined);
  const [tags, setTags] = useState<string[]>([]);
  
  const handleSave = () => {
    if (thought.trim().length === 0) return;
    
    const id = addThought(thought.trim(), emotion, category, tags.length > 0 ? tags : undefined);
    router.push(`/reframe/${id}`);
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 100 : 0}
    >
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.contentContainer}
        keyboardShouldPersistTaps="handled"
      >
        <Text style={styles.label}>{t('whatsOnYourMind')}</Text>
        <TextInput
          style={styles.input}
          placeholder={t('writeDownThought')}
          placeholderTextColor={colors.textExtraLight}
          value={thought}
          onChangeText={setThought}
          multiline
          autoFocus
        />
        
        <EmotionSelector
          selectedEmotion={emotion}
          onSelect={setEmotion}
        />
        
        <CategorySelector
          selectedCategory={category}
          onSelect={setCategory}
        />
        
        <TagInput
          tags={tags}
          onTagsChange={setTags}
        />
        
        <TouchableOpacity
          style={[
            styles.saveButton,
            thought.trim().length === 0 && styles.disabledButton,
          ]}
          onPress={handleSave}
          disabled={thought.trim().length === 0}
        >
          <Text style={styles.saveButtonText}>{t('continueToReframe')}</Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
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
  label: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 12,
  },
  input: {
    backgroundColor: colors.card,
    borderRadius: 16,
    padding: 16,
    minHeight: 120,
    fontSize: 16,
    color: colors.text,
    textAlignVertical: 'top',
    marginBottom: 16,
    borderWidth: 1,
    borderColor: colors.border,
  },
  saveButton: {
    backgroundColor: colors.primary,
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    marginTop: 16,
    shadowColor: colors.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 4,
  },
  disabledButton: {
    backgroundColor: colors.primaryLight,
    opacity: 0.7,
  },
  saveButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
});