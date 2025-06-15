import React, { useEffect, useState } from 'react';
import { StyleSheet, View, Text, ActivityIndicator } from 'react-native';
import { BannerAd, BannerAdSize, TestIds } from 'react-native-google-mobile-ads';

// 실제 광고 ID로 교체 필요
const adUnitId = __DEV__ ? TestIds.BANNER : 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';

interface AdBannerProps {
  size?: BannerAdSize;
  style?: any;
  position?: 'top' | 'middle' | 'bottom';
  showLabel?: boolean;
}

export const AdBanner: React.FC<AdBannerProps> = ({ 
  size = BannerAdSize.BANNER,
  style,
  position = 'bottom',
  showLabel = false
}) => {
  const [isLoading, setIsLoading] = useState(true);
  const [isError, setIsError] = useState(false);

  return (
    <View style={[
      styles.container, 
      styles[position],
      style
    ]}>
      {showLabel && (
        <Text style={styles.label}>광고</Text>
      )}
      
      {isLoading && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="small" color="#6366f1" />
        </View>
      )}
      
      {!isError && (
        <BannerAd
          unitId={adUnitId}
          size={size}
          requestOptions={{
            requestNonPersonalizedAdsOnly: true,
          }}
          onAdLoaded={() => {
            setIsLoading(false);
            setIsError(false);
          }}
          onAdFailedToLoad={(error) => {
            console.warn('광고 로드 실패:', error);
            setIsLoading(false);
            setIsError(true);
          }}
        />
      )}
      
      {isError && (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>광고를 불러올 수 없습니다</Text>
        </View>
      )}
    </View>
  );
};

// 대형 배너 광고 컴포넌트
export const LargeBannerAd: React.FC<Omit<AdBannerProps, 'size'>> = (props) => (
  <AdBanner {...props} size={BannerAdSize.LARGE_BANNER} />
);

// 중간 사각형 광고 컴포넌트  
export const MediumRectangleAd: React.FC<Omit<AdBannerProps, 'size'>> = (props) => (
  <AdBanner {...props} size={BannerAdSize.MEDIUM_RECTANGLE} />
);

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#f8fafc',
    borderRadius: 12,
    overflow: 'hidden',
    marginVertical: 8,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  top: {
    marginTop: 0,
    marginBottom: 16,
  },
  middle: {
    marginVertical: 16,
  },
  bottom: {
    marginTop: 16,
    marginBottom: 0,
  },
  label: {
    position: 'absolute',
    top: 4,
    left: 8,
    fontSize: 10,
    color: '#64748b',
    backgroundColor: 'rgba(255, 255, 255, 0.8)',
    paddingHorizontal: 4,
    paddingVertical: 1,
    borderRadius: 4,
    zIndex: 1,
  },
  loadingContainer: {
    height: 60,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorContainer: {
    height: 60,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f1f5f9',
  },
  errorText: {
    fontSize: 12,
    color: '#64748b',
  },
}); 