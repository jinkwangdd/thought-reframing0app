//
//  thoughtsreframerApp.swift
//  thoughtsreframer
//
//  Created by Solum on 2025/06/13.
//

import SwiftUI
import GoogleMobileAds
import UserNotifications

@main
struct thoughtsreframerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var adManager = AdManager()
    @StateObject private var thoughtViewModel = ThoughtViewModel()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(thoughtViewModel)
                .environmentObject(adManager)
                .environmentObject(notificationManager)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowInterstitialAd"))) { _ in
                    adManager.showInterstitialAd()
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 시뮬레이터에서는 AdMob 초기화를 건너뛰어 coretelephony 오류 방지
        #if !targetEnvironment(simulator)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #endif
        
        // 푸시 알림 권한 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("푸시 알림 권한 허용됨")
            } else {
                print("푸시 알림 권한 거부됨")
            }
        }
        
        return true
    }
}

// MARK: - 광고 매니저
class AdManager: NSObject, ObservableObject {
    @Published var isInitialized = false
    @Published var interstitialAd: GADInterstitialAd?
    @Published var bannerAd: GADBannerView?
    
    // Test Ad Unit IDs (실제 배포시 변경 필요)
    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    
    override init() {
        super.init()
        initializeAds()
    }
    
    func initializeAds() {
        GADMobileAds.sharedInstance().start { [weak self] status in
            DispatchQueue.main.async {
                self?.isInitialized = true
                self?.loadInterstitialAd()
                self?.createBannerAd()
            }
        }
    }
    
    // MARK: - Banner Ad
    func createBannerAd() {
        bannerAd = GADBannerView(adSize: GADAdSizeBanner)
        bannerAd?.adUnitID = bannerAdUnitID
        bannerAd?.delegate = self
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Root view controller를 찾을 수 없습니다.")
            return
        }
        bannerAd?.rootViewController = rootViewController
        
        let request = GADRequest()
        bannerAd?.load(request)
    }
    
    // MARK: - Interstitial Ad
    func loadInterstitialAd() {
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: interstitialAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("전면 광고 로드 실패: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self?.interstitialAd = ad
                self?.interstitialAd?.fullScreenContentDelegate = self
            }
        }
    }
    
    func showInterstitialAd() {
        guard let interstitialAd = interstitialAd else {
            print("전면 광고가 준비되지 않았습니다.")
            loadInterstitialAd() // 재로드 시도
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Root view controller를 찾을 수 없습니다.")
            return
        }
        
        interstitialAd.present(fromRootViewController: rootViewController)
    }
}

// MARK: - GADBannerViewDelegate
extension AdManager: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("배너 광고 로드 성공")
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("배너 광고 로드 실패: \(error.localizedDescription)")
    }
}

// MARK: - GADFullScreenContentDelegate (수정된 버전)
extension AdManager: GADFullScreenContentDelegate {
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("전면 광고 노출됨")
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("전면 광고 표시 실패: \(error.localizedDescription)")
        loadInterstitialAd() // 재로드
    }
    
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("전면 광고 표시 시작")
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("전면 광고 닫힘")
        loadInterstitialAd() // 다음 광고 미리 로드
    }
}

// MARK: - SwiftUI Banner Ad View
struct AdBannerView: UIViewRepresentable {
    @EnvironmentObject var adManager: AdManager
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            bannerView.rootViewController = window.rootViewController
        }
        
        let request = GADRequest()
        bannerView.load(request)
        
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 업데이트 로직 (필요시)
    }
}

// MARK: - 푸시 알림 매니저
class NotificationManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Re:Frame 일일 체크"
        content.body = "오늘 하루는 어떠셨나요? 감정을 기록하고 마음을 돌봐주세요 💙"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 20  // 저녁 8시
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 스케줄링 에러: \(error)")
            } else {
                print("일일 알림 설정 완료")
            }
        }
    }
    
    func scheduleWeeklyReview() {
        let content = UNMutableNotificationContent()
        content.title = "Re:Frame 주간 리뷰"
        content.body = "이번 주 감정 패턴을 확인하고 성장한 부분을 돌아보세요 ✨"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // 일요일
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklyReview", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("주간 알림 스케줄링 에러: \(error)")
            } else {
                print("주간 알림 설정 완료")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("모든 알림 취소")
    }
}
