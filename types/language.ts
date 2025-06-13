export type Language = 'en' | 'ko';

export interface TranslationKey {
  // Common
  appName: string;
  save: string;
  cancel: string;
  delete: string;
  edit: string;
  
  // Home
  greeting_morning: string;
  greeting_afternoon: string;
  greeting_evening: string;
  howAreYouFeeling: string;
  recordThought: string;
  thoughtsToReframe: string;
  recentThoughts: string;
  noThoughtsYet: string;
  noThoughtsMessage: string;
  
  // Emotions
  anger: string;
  anxiety: string;
  sadness: string;
  fear: string;
  shame: string;
  disappointment: string;
  frustration: string;
  guilt: string;
  neutral: string;
  joy: string;
  gratitude: string;
  calm: string;
  hope: string;
  
  // Thought Entry
  whatsOnYourMind: string;
  writeDownThought: string;
  howAreYouFeelingQuestion: string;
  categorizeThought: string;
  addTags: string;
  addTagsPlaceholder: string;
  continueToReframe: string;
  
  // Reframe
  yourThought: string;
  helpfulPrompts: string;
  considerThis: string;
  reframeYourThought: string;
  writeBalancedPerspective: string;
  getAISuggestion: string;
  saveReframe: string;
  
  // Thought Detail
  originalThought: string;
  reframedThought: string;
  aiGenerated: string;
  editReframe: string;
  notReframedYet: string;
  reframeNow: string;
  insights: string;
  
  // Journal
  journalPrompt: string;
  tapToRefresh: string;
  searchThoughts: string;
  noMatchingThoughts: string;
  journalEmpty: string;
  journalEmptyMessage: string;
  
  // Insights
  emotionPatterns: string;
  recordToSeePatterns: string;
  yourInsights: string;
  mostCommonEmotion: string;
  thoughtsReframed: string;
  averageTimeToReframe: string;
  recordToSeeInsights: string;
  pastSevenDays: string;
  pastThirtyDays: string;
  allTime: string;
  week: string;
  month: string;
  all: string;
  thoughts: string;
  reframed: string;
  avgMood: string;
  of: string;
  minutes: string;
  hours: string;
  days: string;
  notAvailable: string;
  tryToReframeMore: string;
  anxietyTip: string;
  angerTip: string;
  sadnessTip: string;
  fearTip: string;
  keepTrackingThoughts: string;
  
  // Profile
  preferences: string;
  dailyReminder: string;
  reminderTime: string;
  streakGoal: string;
  days: string;
  darkMode: string;
  system: string;
  light: string;
  dark: string;
  aiSuggestions: string;
  language: string;
  english: string;
  korean: string;
  about: string;
  aboutReframing: string;
  rateApp: string;
  clearAllData: string;
  clearDataConfirm: string;
  clearDataWarning: string;
  version: string;
  tagline: string;
  
  // Categories
  workAndCareer: string;
  relationships: string;
  healthAndWellness: string;
  selfImage: string;
  futureAndGoals: string;
  pastRegrets: string;
  dailyStressors: string;
  socialSituations: string;
  
  // Journal
  none: string;
}