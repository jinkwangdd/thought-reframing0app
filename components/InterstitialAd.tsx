import React, { useEffect, useState, useCallback } from 'react';
import { InterstitialAd, AdEventType, TestIds } from 'react-native-google-mobile-ads';

// 실제 광고 ID로 교체 필요
const adUnitId = __DEV__ ? TestIds.INTERSTITIAL : 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';

// 전면 광고 인스턴스 생성
const interstitial = InterstitialAd.createForAdUnitId(adUnitId, {
  requestNonPersonalizedAdsOnly: true,
});

interface InterstitialAdManagerProps {
  onAdClosed?: () => void;
  onAdFailedToLoad?: (error: any) => void;
  cooldownMinutes?: number; // 광고 간 최소 대기 시간 (분)
}

// 전면 광고 관리 클래스
export class InterstitialAdManager {
  private static instance: InterstitialAdManager;
  private isLoaded = false;
  private isLoading = false;
  private lastShowTime = 0;
  private cooldownMinutes = 5; // 5분 쿨다운
  private onAdClosed?: () => void;
  private onAdFailedToLoad?: (error: any) => void;

  private constructor(options?: InterstitialAdManagerProps) {
    this.cooldownMinutes = options?.cooldownMinutes || 5;
    this.onAdClosed = options?.onAdClosed;
    this.onAdFailedToLoad = options?.onAdFailedToLoad;
    this.setupEventListeners();
    this.loadAd();
  }

  public static getInstance(options?: InterstitialAdManagerProps): InterstitialAdManager {
    if (!InterstitialAdManager.instance) {
      InterstitialAdManager.instance = new InterstitialAdManager(options);
    }
    return InterstitialAdManager.instance;
  }

  private setupEventListeners(): void {
    // 광고 로드 완료
    interstitial.addAdEventListener(AdEventType.LOADED, () => {
      console.log('전면 광고 로드 완료');
      this.isLoaded = true;
      this.isLoading = false;
    });

    // 광고 로드 실패
    interstitial.addAdEventListener(AdEventType.ERROR, (error) => {
      console.warn('전면 광고 로드 실패:', error);
      this.isLoaded = false;
      this.isLoading = false;
      if (this.onAdFailedToLoad) {
        this.onAdFailedToLoad(error);
      }
      // 5초 후 재시도
      setTimeout(() => this.loadAd(), 5000);
    });

    // 광고 표시 시작
    interstitial.addAdEventListener(AdEventType.OPENED, () => {
      console.log('전면 광고 표시 시작');
    });

    // 광고 닫힘
    interstitial.addAdEventListener(AdEventType.CLOSED, () => {
      console.log('전면 광고 닫힘');
      this.isLoaded = false;
      this.lastShowTime = Date.now();
      
      if (this.onAdClosed) {
        this.onAdClosed();
      }
      
      // 새 광고를 미리 로드
      setTimeout(() => this.loadAd(), 1000);
    });
  }

  private loadAd(): void {
    if (this.isLoading || this.isLoaded) {
      return;
    }

    this.isLoading = true;
    interstitial.load();
  }

  public async showAd(): Promise<boolean> {
    // 쿨다운 체크
    const now = Date.now();
    const timeSinceLastAd = now - this.lastShowTime;
    const cooldownMs = this.cooldownMinutes * 60 * 1000;

    if (timeSinceLastAd < cooldownMs) {
      console.log('광고 쿨다운 중...');
      return false;
    }

    // 여기서 실제 광고 표시 로직 구현
    console.log('전면 광고 표시');
    this.lastShowTime = Date.now();
    return true;
  }

  public isAdReady(): boolean {
    return this.isLoaded;
  }

  public getTimeUntilNextAd(): number {
    const now = Date.now();
    const timeSinceLastAd = now - this.lastShowTime;
    const cooldownMs = this.cooldownMinutes * 60 * 1000;
    
    if (timeSinceLastAd >= cooldownMs) {
      return 0;
    }
    
    return Math.ceil((cooldownMs - timeSinceLastAd) / 1000);
  }

  public preloadAd(): void {
    this.loadAd();
  }
}

// 리프레이밍 전면 광고 전용 훅
export const useReframingInterstitial = (onReframingComplete?: () => void) => {
  const [adManager] = useState(() => InterstitialAdManager.getInstance());

  const showReframingAd = async () => {
    const success = await adManager.showAd();
    
    if (!success && onReframingComplete) {
      // 광고를 보여줄 수 없는 경우 바로 리프레이밍 진행
      onReframingComplete();
    }
    
    return success;
  };

  return {
    showReframingAd,
    isAdReady: () => adManager.isAdReady(),
    getTimeUntilNextAd: () => adManager.getTimeUntilNextAd(),
  };
};

// 일반적인 전면 광고 사용 훅
export const useInterstitialAd = (options?: InterstitialAdManagerProps) => {
  const [adManager] = useState(() => InterstitialAdManager.getInstance(options));

  const showAd = useCallback(async () => {
    return await adManager.showAd();
  }, [adManager]);

  return {
    showAd,
    isAdReady: adManager.isAdReady.bind(adManager),
    getTimeUntilNextAd: adManager.getTimeUntilNextAd.bind(adManager),
    preloadAd: adManager.preloadAd.bind(adManager),
  };
}; 