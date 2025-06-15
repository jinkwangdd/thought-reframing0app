import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

// 알림 카테고리 정의
export enum NotificationType {
  DAILY_REMINDER = 'daily_reminder',
  STRESS_CHECK = 'stress_check',
  REFRAME_ENCOURAGEMENT = 'reframe_encouragement',
  POSITIVE_AFFIRMATION = 'positive_affirmation',
  MINDFULNESS_BREAK = 'mindfulness_break',
  ACHIEVEMENT_CELEBRATION = 'achievement_celebration'
}

interface NotificationSchedule {
  id: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: any;
  trigger: Notifications.NotificationTriggerInput;
}

// 스마트 메시지 템플릿
const notificationMessages = {
  [NotificationType.DAILY_REMINDER]: [
    '🌅 오늘도 새로운 시작이에요',
    '💭 마음 체크 시간',
    '🌱 성장의 순간'
  ],
  [NotificationType.STRESS_CHECK]: [
    '😤 스트레스 체크 시간',
    '🌊 마음의 파도 가라앉히기'
  ],
  [NotificationType.REFRAME_ENCOURAGEMENT]: [
    '✨ 리프레이밍 도전!',
    '🔄 생각 전환의 힘'
  ],
  [NotificationType.POSITIVE_AFFIRMATION]: [
    '💪 당신은 충분히 강해요',
    '🌟 오늘의 긍정 에너지'
  ],
  [NotificationType.MINDFULNESS_BREAK]: [
    '🧘‍♀️ 마음챙김 시간',
    '🌬️ 호흡에 집중하기'
  ],
  [NotificationType.ACHIEVEMENT_CELEBRATION]: [
    '🎉 축하합니다!',
    '👏 멋진 성과예요'
  ]
};

class NotificationService {
  private isRegistered = false;
  private pushToken: string | null = null;

  async initialize(): Promise<void> {
    try {
      // 알림 권한 요청
      const { status: existingStatus } = await Notifications.getPermissionsAsync();
      let finalStatus = existingStatus;

      if (existingStatus !== 'granted') {
        const { status } = await Notifications.requestPermissionsAsync();
        finalStatus = status;
      }

      if (finalStatus !== 'granted') {
        console.warn('푸시 알림 권한이 거부되었습니다.');
        return;
      }

      // 푸시 토큰 획득
      if (Device.isDevice) {
        this.pushToken = (await Notifications.getExpoPushTokenAsync()).data;
        await AsyncStorage.setItem('pushToken', this.pushToken);
      }

      // 알림 핸들러 설정
      Notifications.setNotificationHandler({
        handleNotification: async () => ({
          shouldShowAlert: true,
          shouldPlaySound: true,
          shouldSetBadge: false,
        }),
      });

      this.isRegistered = true;
      console.log('푸시 알림 서비스 초기화 완료');
      
      // 초기 알림 스케줄 설정
      await this.setupDefaultNotifications();
      
    } catch (error) {
      console.error('푸시 알림 초기화 실패:', error);
    }
  }

  private async setupDefaultNotifications(): Promise<void> {
    // 기존 알림 모두 취소
    await Notifications.cancelAllScheduledNotificationsAsync();

    // 매일 오전 9시 - 일일 리마인더
    await Notifications.scheduleNotificationAsync({
      identifier: 'daily_morning',
      content: {
        title: '🌅 오늘도 새로운 시작이에요',
        body: '오늘 하루는 어떤 생각들이 떠오르고 있나요?',
        data: { type: NotificationType.DAILY_REMINDER },
        sound: true,
      },
      trigger: {
        hour: 9,
        minute: 0,
        repeats: true,
      },
    });

    // 매일 저녁 8시 - 긍정 확언
    await Notifications.scheduleNotificationAsync({
      identifier: 'evening_affirmation',
      content: {
        title: '🌟 오늘의 긍정 에너지',
        body: '당신의 존재 자체가 소중합니다. 스스로에게 친절하세요.',
        data: { type: NotificationType.POSITIVE_AFFIRMATION },
        sound: true,
      },
      trigger: {
        hour: 20,
        minute: 0,
        repeats: true,
      },
    });
  }

  // 리프레이밍 격려 알림
  async scheduleReframeReminder(unreframedCount: number): Promise<void> {
    if (!this.isRegistered) return;

    await Notifications.scheduleNotificationAsync({
      identifier: 'reframe_reminder',
      content: {
        title: '✨ 리프레이밍 도전!',
        body: `${unreframedCount}개의 생각이 리프레이밍을 기다리고 있어요!`,
        data: { type: NotificationType.REFRAME_ENCOURAGEMENT },
        sound: true,
      },
      trigger: {
        seconds: 3600, // 1시간 후
      },
    });
  }

  // 연속 기록 달성 축하 알림
  async celebrateStreak(days: number): Promise<void> {
    if (!this.isRegistered) return;

    await Notifications.scheduleNotificationAsync({
      identifier: 'streak_celebration',
      content: {
        title: `🔥 ${days}일 연속 기록!`,
        body: '꾸준한 노력이 대단해요!',
        data: { type: NotificationType.ACHIEVEMENT_CELEBRATION, days },
        sound: true,
      },
      trigger: {
        seconds: 1,
      },
    });
  }

  // 알림 비활성화
  async disableNotifications(): Promise<void> {
    await Notifications.cancelAllScheduledNotificationsAsync();
    console.log('모든 알림이 비활성화되었습니다.');
  }

  // 푸시 토큰 반환
  getPushToken(): string | null {
    return this.pushToken;
  }

  // 알림 상태 확인
  isNotificationEnabled(): boolean {
    return this.isRegistered;
  }
}

export const notificationService = new NotificationService(); 