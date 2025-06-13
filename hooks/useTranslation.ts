import { useCallback } from 'react';
import { useSettingsStore } from '@/store/settingsStore';
import translations from '@/constants/translations';
import { TranslationKey } from '@/types/language';

export function useTranslation() {
  const language = useSettingsStore((state) => state.language);
  
  const t = useCallback((key: keyof TranslationKey) => {
    const currentTranslations = translations[language] || translations.en;
    return currentTranslations[key] || translations.en[key];
  }, [language]);
  
  return { t, language };
}