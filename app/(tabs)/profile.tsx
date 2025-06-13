import React, { useState } from 'react';
import { StyleSheet, Text, View, TouchableOpacity, ScrollView, Alert, Switch, TextInput } from 'react-native';
import { useThoughtStore } from '@/store/thoughtStore';
import { useSettingsStore } from '@/store/settingsStore';
import { colors } from '@/constants/colors';
import { Settings, Info, Heart, Trash2, Bell, Moon, User, Target, Globe } from 'lucide-react-native';
import { useTranslation } from '@/hooks/useTranslation';
import { Language } from '@/types/language';

export default function ProfileScreen() {
  const thoughts = useThoughtStore((state) => state.thoughts);
  const deleteThought = useThoughtStore((state) => state.deleteThought);
  const reframeRate = useThoughtStore((state) => state.getReframeRate());
  
  const username = useSettingsStore((state) => state.username);
  const setUsername = useSettingsStore((state) => state.setUsername);
  const reminderEnabled = useSettingsStore((state) => state.reminderEnabled);
  const toggleReminder = useSettingsStore((state) => state.toggleReminder);
  const reminderTime = useSettingsStore((state) => state.reminderTime);
  const setReminderTime = useSettingsStore((state) => state.setReminderTime);
  const darkMode = useSettingsStore((state) => state.darkMode);
  const setDarkMode = useSettingsStore((state) => state.setDarkMode);
  const aiEnabled = useSettingsStore((state) => state.aiEnabled);
  const toggleAI = useSettingsStore((state) => state.toggleAI);
  const streakGoal = useSettingsStore((state) => state.streakGoal);
  const setStreakGoal = useSettingsStore((state) => state.setStreakGoal);
  const language = useSettingsStore((state) => state.language);
  const setLanguage = useSettingsStore((state) => state.setLanguage);
  
  const { t } = useTranslation();
  
  const [isEditingName, setIsEditingName] = useState(false);
  const [nameInput, setNameInput] = useState(username);
  
  const totalThoughts = thoughts.length;
  const reframedThoughts = thoughts.filter((thought) => thought.reframe).length;
  
  const handleSaveName = () => {
    setUsername(nameInput.trim());
    setIsEditingName(false);
  };
  
  const handleClearData = () => {
    Alert.alert(
      t('clearDataConfirm'),
      t('clearDataWarning'),
      [
        { text: t('cancel'), style: "cancel" },
        { 
          text: t('delete'), 
          style: "destructive",
          onPress: () => {
            thoughts.forEach(thought => deleteThought(thought.id));
          }
        }
      ]
    );
  };

  const handleDarkModeChange = (mode: 'system' | 'light' | 'dark') => {
    setDarkMode(mode);
  };

  const handleStreakGoalChange = (goal: number) => {
    setStreakGoal(Math.max(1, Math.min(goal, 30)));
  };

  const handleLanguageChange = (lang: Language) => {
    setLanguage(lang);
  };

  return (
    <ScrollView 
      style={styles.container}
      contentContainerStyle={styles.contentContainer}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.profileHeader}>
        <View style={styles.avatarContainer}>
          <Text style={styles.avatarText}>
            {username ? username.charAt(0).toUpperCase() : '?'}
          </Text>
        </View>
        
        {isEditingName ? (
          <View style={styles.nameEditContainer}>
            <TextInput
              style={styles.nameInput}
              value={nameInput}
              onChangeText={setNameInput}
              placeholder={t('edit')}
              placeholderTextColor={colors.textExtraLight}
              autoFocus
            />
            <TouchableOpacity 
              style={styles.saveNameButton}
              onPress={handleSaveName}
            >
              <Text style={styles.saveNameText}>{t('save')}</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <TouchableOpacity 
            style={styles.nameContainer}
            onPress={() => setIsEditingName(true)}
          >
            <Text style={styles.nameText}>
              {username || t('edit')}
            </Text>
            <Text style={styles.editNameText}>{t('edit')}</Text>
          </TouchableOpacity>
        )}
      </View>
      
      <View style={styles.statsContainer}>
        <View style={styles.statCard}>
          <Text style={styles.statValue}>{totalThoughts}</Text>
          <Text style={styles.statLabel}>{t('recentThoughts')}</Text>
        </View>
        
        <View style={styles.statCard}>
          <Text style={styles.statValue}>{reframedThoughts}</Text>
          <Text style={styles.statLabel}>{t('reframedThought')}</Text>
        </View>
        
        <View style={styles.statCard}>
          <Text style={styles.statValue}>{reframeRate.toFixed(0)}%</Text>
          <Text style={styles.statLabel}>{t('thoughtsReframed')}</Text>
        </View>
      </View>
      
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>{t('preferences')}</Text>
        
        <View style={styles.settingItem}>
          <View style={styles.settingLeft}>
            <Bell size={20} color={colors.text} />
            <Text style={styles.settingText}>{t('dailyReminder')}</Text>
          </View>
          <Switch
            value={reminderEnabled}
            onValueChange={toggleReminder}
            trackColor={{ false: colors.border, true: colors.primaryLight }}
            thumbColor={reminderEnabled ? colors.primary : '#f4f3f4'}
          />
        </View>
        
        {reminderEnabled && (
          <View style={styles.settingItem}>
            <View style={styles.settingLeft}>
              <Text style={styles.settingSubtext}>{t('reminderTime')}</Text>
            </View>
            <TextInput
              style={styles.timeInput}
              value={reminderTime}
              onChangeText={setReminderTime}
              placeholder="20:00"
              keyboardType="numbers-and-punctuation"
            />
          </View>
        )}
        
        <View style={styles.settingItem}>
          <View style={styles.settingLeft}>
            <Target size={20} color={colors.text} />
            <Text style={styles.settingText}>{t('streakGoal')}</Text>
          </View>
          <View style={styles.streakGoalContainer}>
            <TouchableOpacity
              style={styles.streakButton}
              onPress={() => handleStreakGoalChange(streakGoal - 1)}
              disabled={streakGoal <= 1}
            >
              <Text style={styles.streakButtonText}>-</Text>
            </TouchableOpacity>
            <Text style={styles.streakGoalText}>{streakGoal} {t('days')}</Text>
            <TouchableOpacity
              style={styles.streakButton}
              onPress={() => handleStreakGoalChange(streakGoal + 1)}
              disabled={streakGoal >= 30}
            >
              <Text style={styles.streakButtonText}>+</Text>
            </TouchableOpacity>
          </View>
        </View>
        
        <View style={styles.settingItem}>
          <View style={styles.settingLeft}>
            <Moon size={20} color={colors.text} />
            <Text style={styles.settingText}>{t('darkMode')}</Text>
          </View>
          <View style={styles.darkModeOptions}>
            <TouchableOpacity
              style={[
                styles.darkModeOption,
                darkMode === 'system' && styles.selectedDarkMode
              ]}
              onPress={() => handleDarkModeChange('system')}
            >
              <Text
                style={[
                  styles.darkModeText,
                  darkMode === 'system' && styles.selectedDarkModeText
                ]}
              >
                {t('system')}
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.darkModeOption,
                darkMode === 'light' && styles.selectedDarkMode
              ]}
              onPress={() => handleDarkModeChange('light')}
            >
              <Text
                style={[
                  styles.darkModeText,
                  darkMode === 'light' && styles.selectedDarkModeText
                ]}
              >
                {t('light')}
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.darkModeOption,
                darkMode === 'dark' && styles.selectedDarkMode
              ]}
              onPress={() => handleDarkModeChange('dark')}
            >
              <Text
                style={[
                  styles.darkModeText,
                  darkMode === 'dark' && styles.selectedDarkModeText
                ]}
              >
                {t('dark')}
              </Text>
            </TouchableOpacity>
          </View>
        </View>
        
        <View style={styles.settingItem}>
          <View style={styles.settingLeft}>
            <User size={20} color={colors.text} />
            <Text style={styles.settingText}>{t('aiSuggestions')}</Text>
          </View>
          <Switch
            value={aiEnabled}
            onValueChange={toggleAI}
            trackColor={{ false: colors.border, true: colors.primaryLight }}
            thumbColor={aiEnabled ? colors.primary : '#f4f3f4'}
          />
        </View>
        
        <View style={styles.settingItem}>
          <View style={styles.settingLeft}>
            <Globe size={20} color={colors.text} />
            <Text style={styles.settingText}>{t('language')}</Text>
          </View>
          <View style={styles.languageOptions}>
            <TouchableOpacity
              style={[
                styles.languageOption,
                language === 'en' && styles.selectedLanguage
              ]}
              onPress={() => handleLanguageChange('en')}
            >
              <Text
                style={[
                  styles.languageText,
                  language === 'en' && styles.selectedLanguageText
                ]}
              >
                {t('english')}
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.languageOption,
                language === 'ko' && styles.selectedLanguage
              ]}
              onPress={() => handleLanguageChange('ko')}
            >
              <Text
                style={[
                  styles.languageText,
                  language === 'ko' && styles.selectedLanguageText
                ]}
              >
                {t('korean')}
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
      
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>{t('about')}</Text>
        
        <TouchableOpacity style={styles.menuItem}>
          <Info size={20} color={colors.text} />
          <Text style={styles.menuItemText}>{t('aboutReframing')}</Text>
        </TouchableOpacity>
        
        <TouchableOpacity style={styles.menuItem}>
          <Heart size={20} color={colors.text} />
          <Text style={styles.menuItemText}>{t('rateApp')}</Text>
        </TouchableOpacity>
        
        <TouchableOpacity 
          style={[styles.menuItem, styles.dangerItem]}
          onPress={handleClearData}
        >
          <Trash2 size={20} color={colors.error} />
          <Text style={[styles.menuItemText, styles.dangerText]}>{t('clearAllData')}</Text>
        </TouchableOpacity>
      </View>
      
      <View style={styles.footer}>
        <Text style={styles.footerText}>{t('version')}</Text>
        <Text style={styles.footerSubtext}>{t('tagline')}</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  contentContainer: {
    padding: 16,
    paddingBottom: 32,
  },
  profileHeader: {
    alignItems: 'center',
    marginBottom: 24,
  },
  avatarContainer: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  avatarText: {
    fontSize: 32,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  nameContainer: {
    alignItems: 'center',
  },
  nameText: {
    fontSize: 20,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 4,
  },
  editNameText: {
    fontSize: 14,
    color: colors.primary,
  },
  nameEditContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  nameInput: {
    backgroundColor: colors.card,
    borderRadius: 8,
    padding: 8,
    fontSize: 16,
    color: colors.text,
    width: 200,
    marginRight: 8,
    borderWidth: 1,
    borderColor: colors.border,
  },
  saveNameButton: {
    backgroundColor: colors.primary,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  saveNameText: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 24,
  },
  statCard: {
    flex: 1,
    backgroundColor: colors.card,
    borderRadius: 16,
    padding: 16,
    marginHorizontal: 4,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statValue: {
    fontSize: 24,
    fontWeight: '700',
    color: colors.primary,
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: colors.textLight,
    textAlign: 'center',
  },
  section: {
    backgroundColor: colors.card,
    borderRadius: 16,
    padding: 16,
    marginBottom: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 16,
  },
  settingItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  settingLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  settingText: {
    fontSize: 16,
    color: colors.text,
    marginLeft: 12,
  },
  settingSubtext: {
    fontSize: 14,
    color: colors.textLight,
    marginLeft: 32,
  },
  timeInput: {
    backgroundColor: colors.background,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 6,
    fontSize: 14,
    color: colors.text,
    width: 80,
    textAlign: 'center',
  },
  darkModeOptions: {
    flexDirection: 'row',
    backgroundColor: colors.border,
    borderRadius: 8,
    padding: 2,
  },
  darkModeOption: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  selectedDarkMode: {
    backgroundColor: colors.card,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 1,
    elevation: 1,
  },
  darkModeText: {
    fontSize: 12,
    color: colors.textLight,
  },
  selectedDarkModeText: {
    color: colors.text,
    fontWeight: '500',
  },
  languageOptions: {
    flexDirection: 'row',
    backgroundColor: colors.border,
    borderRadius: 8,
    padding: 2,
  },
  languageOption: {
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 6,
  },
  selectedLanguage: {
    backgroundColor: colors.card,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 1,
    elevation: 1,
  },
  languageText: {
    fontSize: 12,
    color: colors.textLight,
  },
  selectedLanguageText: {
    color: colors.text,
    fontWeight: '500',
  },
  streakGoalContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  streakButton: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: colors.border,
    justifyContent: 'center',
    alignItems: 'center',
  },
  streakButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
  },
  streakGoalText: {
    fontSize: 14,
    color: colors.text,
    marginHorizontal: 12,
    width: 60,
    textAlign: 'center',
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  menuItemText: {
    fontSize: 16,
    color: colors.text,
    marginLeft: 12,
  },
  dangerItem: {
    borderBottomWidth: 0,
  },
  dangerText: {
    color: colors.error,
  },
  footer: {
    alignItems: 'center',
    marginTop: 8,
  },
  footerText: {
    fontSize: 14,
    color: colors.textLight,
    marginBottom: 4,
  },
  footerSubtext: {
    fontSize: 12,
    color: colors.textExtraLight,
  },
});