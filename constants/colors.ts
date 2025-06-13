export const colors = {
  primary: '#7B68EE',         // Medium Slate Blue - calming yet energetic
  primaryLight: '#9F8FFF',    // Lighter version of primary
  primaryDark: '#5A4CBE',     // Darker version of primary
  secondary: '#64D2FF',       // Light Blue - refreshing and clear
  secondaryLight: '#A5E8FF',  // Lighter version of secondary
  secondaryDark: '#3AA8D9',   // Darker version of secondary
  accent: '#FF9F7F',          // Soft Coral - warm and encouraging
  background: '#F8F9FC',      // Off-white with slight blue tint
  card: '#FFFFFF',            // Pure white for cards
  text: '#2D3142',            // Dark blue-gray for primary text
  textLight: '#5C6079',       // Medium blue-gray for secondary text
  textExtraLight: '#9DA0B4',  // Light blue-gray for tertiary text
  border: '#EBEDF5',          // Light gray with blue tint for borders
  error: '#FF6B6B',           // Soft red for errors
  success: '#4CAF50',         // Green for success states
  warning: '#FFC107',         // Amber for warnings
  info: '#2196F3',            // Blue for information
  emotions: {
    anger: '#FF6B6B',         // Soft red
    anxiety: '#FFD166',       // Amber yellow
    sadness: '#73B0F4',       // Soft blue
    fear: '#9575CD',          // Lavender
    shame: '#7986CB',         // Blue-purple
    disappointment: '#4DB6AC',// Teal
    frustration: '#FF8A65',   // Coral
    guilt: '#BA68C8',         // Purple
    neutral: '#90A4AE',       // Blue-gray
    joy: '#66BB6A',           // Green
    gratitude: '#81C784',     // Light green
    calm: '#4FC3F7',          // Sky blue
    hope: '#7CB342'           // Lime green
  }
};

export default {
  light: {
    text: colors.text,
    background: colors.background,
    tint: colors.primary,
    tabIconDefault: colors.textExtraLight,
    tabIconSelected: colors.primary,
  },
};