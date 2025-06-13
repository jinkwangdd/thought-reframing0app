import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, ScrollView, KeyboardAvoidingView, Platform, ActivityIndicator } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useThoughtStore } from '@/store/thoughtStore';
import { useSettingsStore } from '@/store/settingsStore';
import { colors } from '@/constants/colors';
import PromptCard from '@/components/PromptCard';
import { reframePrompts, aiSystemPrompt } from '@/constants/prompts';
import { Sparkles } from 'lucide-react-native';
import { useTranslation } from '@/hooks/useTranslation';

export default function ReframeScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const thought = useThoughtStore((state) => state.getThought(id));
  const addReframe = useThoughtStore((state) => state.addReframe);
  const aiEnabled = useSettingsStore((state) => state.aiEnabled);
  const { t } = useTranslation();
  
  const [reframe, setReframe] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [selectedPrompt, setSelectedPrompt] = useState('');
  const [aiError, setAiError] = useState('');
  
  useEffect(() => {
    if (!thought) {
      router.replace('/');
    }
  }, [thought, router]);

  if (!thought) {
    return null;
  }

  const handleSave = () => {
    if (reframe.trim().length === 0) return;
    
    addReframe(id, reframe.trim(), false);
    router.replace(`/thought/${id}`);
  };

  const handleAIReframe = async () => {
    setIsLoading(true);
    setAiError('');
    try {
      const response = await fetch('https://toolkit.rork.com/text/llm/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messages: [
            { role: 'system', content: aiSystemPrompt },
            { 
              role: 'user', 
              content: `Please help me reframe this negative thought: "${thought.content}". 
              I'm feeling ${thought.emotion}.
              ${selectedPrompt ? `I'm considering this question: ${selectedPrompt}` : ''}
              ${thought.category ? `This is related to: ${thought.category}` : ''}` 
            }
          ]
        }),
      });
      
      const data = await response.json();
      if (data.completion) {
        setReframe(data.completion);
      } else {
        setAiError('Could not generate a response. Please try again.');
      }
    } catch (error) {
      console.error('Error getting AI reframe:', error);
      setAiError('An error occurred. Please check your connection and try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handlePromptSelect = (prompt: string) => {
    setSelectedPrompt(prompt);
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
        <View style={styles.thoughtContainer}>
          <Text style={styles.thoughtLabel}>{t('yourThought')}</Text>
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
        </View>
        
        <View style={styles.promptsSection}>
          <Text style={styles.sectionTitle}>{t('helpfulPrompts')}</Text>
          <ScrollView 
            horizontal 
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.promptsContainer}
          >
            {reframePrompts.slice(0, 5).map((prompt, index) => (
              <PromptCard 
                key={index} 
                prompt={prompt} 
                onPress={() => handlePromptSelect(prompt)} 
              />
            ))}
          </ScrollView>
        </View>
        
        {selectedPrompt ? (
          <View style={styles.selectedPromptContainer}>
            <Text style={styles.selectedPromptLabel}>{t('considerThis')}</Text>
            <Text style={styles.selectedPromptText}>{selectedPrompt}</Text>
          </View>
        ) : null}
        
        <Text style={styles.label}>{t('reframeYourThought')}</Text>
        <TextInput
          style={styles.input}
          placeholder={t('writeBalancedPerspective')}
          placeholderTextColor={colors.textExtraLight}
          value={reframe}
          onChangeText={setReframe}
          multiline
        />
        
        {aiEnabled && (
          <>
            <TouchableOpacity
              style={styles.aiButton}
              onPress={handleAIReframe}
              disabled={isLoading}
            >
              {isLoading ? (
                <ActivityIndicator color="#FFFFFF" />
              ) : (
                <>
                  <Sparkles size={16} color="#FFFFFF" />
                  <Text style={styles.aiButtonText}>{t('getAISuggestion')}</Text>
                </>
              )}
            </TouchableOpacity>
            
            {aiError ? (
              <Text style={styles.errorText}>{aiError}</Text>
            ) : null}
          </>
        )}
        
        <TouchableOpacity
          style={[
            styles.saveButton,
            reframe.trim().length === 0 && styles.disabledButton,
          ]}
          onPress={handleSave}
          disabled={reframe.trim().length === 0}
        >
          <Text style={styles.saveButtonText}>{t('saveReframe')}</Text>
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
  thoughtContainer: {
    backgroundColor: colors.card,
    borderRadius: 16,
    padding: 16,
    marginBottom: 24,
    borderLeftWidth: 3,
    borderLeftColor: colors.primary,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  thoughtLabel: {
    fontSize: 14,
    color: colors.textLight,
    marginBottom: 8,
  },
  thoughtText: {
    fontSize: 16,
    color: colors.text,
    marginBottom: 12,
    lineHeight: 22,
  },
  thoughtMeta: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
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
  promptsSection: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 12,
  },
  promptsContainer: {
    paddingBottom: 8,
  },
  selectedPromptContainer: {
    backgroundColor: colors.secondaryLight,
    borderRadius: 16,
    padding: 16,
    marginBottom: 24,
  },
  selectedPromptLabel: {
    fontSize: 14,
    color: colors.textLight,
    marginBottom: 8,
  },
  selectedPromptText: {
    fontSize: 16,
    color: colors.text,
    fontWeight: '500',
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
  aiButton: {
    backgroundColor: colors.secondary,
    borderRadius: 12,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
    shadowColor: colors.secondary,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 3,
  },
  aiButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
  errorText: {
    color: colors.error,
    fontSize: 14,
    marginBottom: 12,
    textAlign: 'center',
  },
  saveButton: {
    backgroundColor: colors.primary,
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
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