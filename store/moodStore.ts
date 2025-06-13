import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { MoodEntry, EmotionType } from '@/types/thought';

interface MoodState {
  entries: MoodEntry[];
  addEntry: (mood: number, emotions: EmotionType[], note?: string) => void;
  getEntryByDate: (date: string) => MoodEntry | undefined;
  getEntriesByDateRange: (startDate: string, endDate: string) => MoodEntry[];
  getAverageMood: (days?: number) => number;
  getMostFrequentEmotions: (days?: number) => Record<EmotionType, number>;
  getStreak: () => number;
}

export const useMoodStore = create<MoodState>()(
  persist(
    (set, get) => ({
      entries: [],
      
      addEntry: (mood, emotions, note) => {
        const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
        
        set((state) => {
          // Check if entry for today already exists
          const existingEntryIndex = state.entries.findIndex(entry => entry.date === today);
          
          if (existingEntryIndex >= 0) {
            // Update existing entry
            const updatedEntries = [...state.entries];
            updatedEntries[existingEntryIndex] = {
              date: today,
              mood,
              emotions,
              note
            };
            return { entries: updatedEntries };
          } else {
            // Add new entry
            return {
              entries: [
                {
                  date: today,
                  mood,
                  emotions,
                  note
                },
                ...state.entries
              ]
            };
          }
        });
      },
      
      getEntryByDate: (date) => {
        return get().entries.find(entry => entry.date === date);
      },
      
      getEntriesByDateRange: (startDate, endDate) => {
        return get().entries.filter(entry => {
          return entry.date >= startDate && entry.date <= endDate;
        });
      },
      
      getAverageMood: (days = 7) => {
        const today = new Date();
        const startDate = new Date();
        startDate.setDate(today.getDate() - days);
        
        const startDateStr = startDate.toISOString().split('T')[0];
        const todayStr = today.toISOString().split('T')[0];
        
        const recentEntries = get().getEntriesByDateRange(startDateStr, todayStr);
        
        if (recentEntries.length === 0) return 0;
        
        const sum = recentEntries.reduce((acc, entry) => acc + entry.mood, 0);
        return sum / recentEntries.length;
      },
      
      getMostFrequentEmotions: (days = 7) => {
        const today = new Date();
        const startDate = new Date();
        startDate.setDate(today.getDate() - days);
        
        const startDateStr = startDate.toISOString().split('T')[0];
        const todayStr = today.toISOString().split('T')[0];
        
        const recentEntries = get().getEntriesByDateRange(startDateStr, todayStr);
        
        const emotionCounts: Record<EmotionType, number> = {
          anger: 0,
          anxiety: 0,
          sadness: 0,
          fear: 0,
          shame: 0,
          disappointment: 0,
          frustration: 0,
          guilt: 0,
          neutral: 0,
          joy: 0,
          gratitude: 0,
          calm: 0,
          hope: 0
        };
        
        recentEntries.forEach(entry => {
          entry.emotions.forEach(emotion => {
            emotionCounts[emotion]++;
          });
        });
        
        return emotionCounts;
      },
      
      getStreak: () => {
        const entries = get().entries;
        if (entries.length === 0) return 0;
        
        // Sort entries by date (newest first)
        const sortedEntries = [...entries].sort((a, b) => 
          new Date(b.date).getTime() - new Date(a.date).getTime()
        );
        
        const today = new Date().toISOString().split('T')[0];
        
        // Check if there's an entry for today
        if (sortedEntries[0].date !== today) return 0;
        
        let streak = 1;
        let currentDate = new Date(today);
        
        for (let i = 1; i < sortedEntries.length; i++) {
          // Move to previous day
          currentDate.setDate(currentDate.getDate() - 1);
          const expectedDate = currentDate.toISOString().split('T')[0];
          
          if (sortedEntries[i].date === expectedDate) {
            streak++;
          } else {
            break;
          }
        }
        
        return streak;
      },
    }),
    {
      name: 'mood-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);