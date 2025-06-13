export type EmotionType = 
  | 'anger'
  | 'anxiety'
  | 'sadness'
  | 'fear'
  | 'shame'
  | 'disappointment'
  | 'frustration'
  | 'guilt'
  | 'neutral'
  | 'joy'
  | 'gratitude'
  | 'calm'
  | 'hope';

export type EmotionCategory = 'negative' | 'positive' | 'neutral';

export interface Thought {
  id: string;
  content: string;
  emotion: EmotionType;
  category?: string;
  createdAt: number;
  reframe?: {
    content: string;
    createdAt: number;
    aiGenerated?: boolean;
  };
  tags?: string[];
  favorite?: boolean;
}

export interface MoodEntry {
  date: string; // YYYY-MM-DD format
  mood: number; // 1-5 scale
  emotions: EmotionType[];
  note?: string;
}