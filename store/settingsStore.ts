import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Language } from '@/types/language';

interface SettingsState {
  username: string;
  reminderEnabled: boolean;
  reminderTime: string; // HH:MM format
  darkMode: 'system' | 'light' | 'dark';
  aiEnabled: boolean;
  onboardingCompleted: boolean;
  streakGoal: number;
  language: Language;
  setUsername: (name: string) => void;
  toggleReminder: () => void;
  setReminderTime: (time: string) => void;
  setDarkMode: (mode: 'system' | 'light' | 'dark') => void;
  toggleAI: () => void;
  completeOnboarding: () => void;
  setStreakGoal: (goal: number) => void;
  setLanguage: (language: Language) => void;
}

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      username: '',
      reminderEnabled: false,
      reminderTime: '20:00', // Default to 8 PM
      darkMode: 'system',
      aiEnabled: true,
      onboardingCompleted: false,
      streakGoal: 7,
      language: 'en', // Default language is English
      
      setUsername: (name) => set({ username: name }),
      
      toggleReminder: () => set((state) => ({ 
        reminderEnabled: !state.reminderEnabled 
      })),
      
      setReminderTime: (time) => set({ reminderTime: time }),
      
      setDarkMode: (mode) => set({ darkMode: mode }),
      
      toggleAI: () => set((state) => ({ 
        aiEnabled: !state.aiEnabled 
      })),
      
      completeOnboarding: () => set({ onboardingCompleted: true }),
      
      setStreakGoal: (goal) => set({ streakGoal: goal }),
      
      setLanguage: (language) => set({ language }),
    }),
    {
      name: 'settings-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);