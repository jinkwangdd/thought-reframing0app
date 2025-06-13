import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { colors } from '@/constants/colors';

interface PromptCardProps {
  prompt: string;
  onPress: () => void;
}

export default function PromptCard({ prompt, onPress }: PromptCardProps) {
  return (
    <TouchableOpacity 
      style={styles.container} 
      onPress={onPress}
      activeOpacity={0.7}
    >
      <Text style={styles.promptText}>{prompt}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.card,
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderLeftWidth: 3,
    borderLeftColor: colors.primary,
  },
  promptText: {
    fontSize: 16,
    color: colors.text,
    lineHeight: 22,
  },
});