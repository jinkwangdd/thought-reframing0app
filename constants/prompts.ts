export const reframePrompts = [
  "What evidence supports this thought? What evidence contradicts it?",
  "Is there another way to look at this situation?",
  "What would I tell a friend who had this thought?",
  "Am I confusing a thought with a fact?",
  "Am I focusing on the negative and ignoring the positive?",
  "Am I jumping to conclusions without enough evidence?",
  "What's the worst that could happen? Could I handle that?",
  "What's the most likely outcome?",
  "Will this matter in 5 years? In 1 year? In 1 month?",
  "Is this thought helpful to me right now?",
  "Am I taking this situation too personally?",
  "Am I expecting perfection from myself?",
  "What would someone I admire say about this situation?",
  "What parts of this situation can I control, and what parts can't I control?",
  "What strengths or resources do I have that could help me handle this?"
];

export const aiSystemPrompt = `You are a supportive cognitive behavioral therapy assistant. 
Your goal is to help the user reframe negative thoughts into more balanced, realistic perspectives.
Be empathetic but also gently challenge distorted thinking patterns.
Provide a thoughtful alternative perspective in 2-3 sentences.
Do not be overly positive or dismissive of genuine concerns.
Focus on helping the user see the situation more objectively.

When responding, identify the cognitive distortion pattern (if present) from these common types:
- All-or-nothing thinking
- Overgeneralization
- Mental filtering
- Discounting the positive
- Jumping to conclusions
- Magnification or minimization
- Emotional reasoning
- Should statements
- Labeling
- Personalization and blame

Then offer a more balanced perspective that acknowledges the user's feelings while introducing more helpful thoughts.`;

export const thoughtCategories = [
  "Work & Career",
  "Relationships",
  "Health & Wellness",
  "Self-Image",
  "Future & Goals",
  "Past Regrets",
  "Daily Stressors",
  "Social Situations"
];

export const journalPrompts = [
  "What made you smile today?",
  "What's something you're looking forward to?",
  "What's a small win you had recently?",
  "What's something you're grateful for today?",
  "What's something you learned recently?",
  "What's a challenge you're facing, and what's one step you can take toward addressing it?",
  "What's something you'd like to tell yourself right now?",
  "What's a quality you appreciate about yourself?",
  "What's something that brought you peace today?",
  "What's a boundary you'd like to set or maintain?"
];