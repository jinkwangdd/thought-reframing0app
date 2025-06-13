import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Thought, EmotionType } from '@/types/thought';

interface ThoughtState {
  thoughts: Thought[];
  addThought: (content: string, emotion: EmotionType, category?: string, tags?: string[]) => string;
  addReframe: (id: string, content: string, aiGenerated?: boolean) => void;
  getThought: (id: string) => Thought | undefined;
  deleteThought: (id: string) => void;
  updateThought: (id: string, updates: Partial<Thought>) => void;
  toggleFavorite: (id: string) => void;
  getThoughtsByEmotion: (emotion: EmotionType) => Thought[];
  getThoughtsByCategory: (category: string) => Thought[];
  getThoughtsByTag: (tag: string) => Thought[];
  getReframedThoughts: () => Thought[];
  getUnreframedThoughts: () => Thought[];
  getFavoriteThoughts: () => Thought[];
  getEmotionStats: () => Record<EmotionType, number>;
  getReframeRate: () => number;
  searchThoughts: (query: string) => Thought[];
}

export const useThoughtStore = create<ThoughtState>()(
  persist(
    (set, get) => ({
      thoughts: [],
      
      addThought: (content, emotion, category, tags) => {
        const id = Date.now().toString();
        set((state) => ({
          thoughts: [
            {
              id,
              content,
              emotion,
              category,
              tags,
              createdAt: Date.now(),
            },
            ...state.thoughts,
          ],
        }));
        return id;
      },
      
      addReframe: (id, content, aiGenerated = false) => {
        set((state) => ({
          thoughts: state.thoughts.map((thought) =>
            thought.id === id
              ? {
                  ...thought,
                  reframe: {
                    content,
                    createdAt: Date.now(),
                    aiGenerated,
                  },
                }
              : thought
          ),
        }));
      },
      
      getThought: (id) => {
        return get().thoughts.find((thought) => thought.id === id);
      },
      
      deleteThought: (id) => {
        set((state) => ({
          thoughts: state.thoughts.filter((thought) => thought.id !== id),
        }));
      },
      
      updateThought: (id, updates) => {
        set((state) => ({
          thoughts: state.thoughts.map((thought) =>
            thought.id === id ? { ...thought, ...updates } : thought
          ),
        }));
      },
      
      toggleFavorite: (id) => {
        set((state) => ({
          thoughts: state.thoughts.map((thought) =>
            thought.id === id ? { ...thought, favorite: !thought.favorite } : thought
          ),
        }));
      },
      
      getThoughtsByEmotion: (emotion) => {
        return get().thoughts.filter((thought) => thought.emotion === emotion);
      },
      
      getThoughtsByCategory: (category) => {
        return get().thoughts.filter((thought) => thought.category === category);
      },
      
      getThoughtsByTag: (tag) => {
        return get().thoughts.filter((thought) => thought.tags?.includes(tag));
      },
      
      getReframedThoughts: () => {
        return get().thoughts.filter((thought) => thought.reframe);
      },
      
      getUnreframedThoughts: () => {
        return get().thoughts.filter((thought) => !thought.reframe);
      },
      
      getFavoriteThoughts: () => {
        return get().thoughts.filter((thought) => thought.favorite);
      },
      
      getEmotionStats: () => {
        const stats: Record<EmotionType, number> = {
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
        
        get().thoughts.forEach((thought) => {
          stats[thought.emotion]++;
        });
        
        return stats;
      },
      
      getReframeRate: () => {
        const total = get().thoughts.length;
        if (total === 0) return 0;
        
        const reframed = get().thoughts.filter((thought) => thought.reframe).length;
        return (reframed / total) * 100;
      },
      
      searchThoughts: (query) => {
        const lowerQuery = query.toLowerCase();
        return get().thoughts.filter(
          (thought) => 
            thought.content.toLowerCase().includes(lowerQuery) ||
            thought.reframe?.content.toLowerCase().includes(lowerQuery) ||
            thought.tags?.some(tag => tag.toLowerCase().includes(lowerQuery)) ||
            thought.category?.toLowerCase().includes(lowerQuery)
        );
      },
    }),
    {
      name: 'thought-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);