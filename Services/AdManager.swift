import Foundation
import GoogleMobileAds

class AdManager: NSObject {
    static let shared = AdManager()
    
    // Dummy Ad Unit IDs
    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    
    private var interstitial: GADInterstitialAd?
    
    override init() {
        super.init()
        loadInterstitial()
    }
    
    func loadInterstitial() {
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: interstitialAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                return
            }
            self?.interstitial = ad
        }
    }
    
    func showInterstitial(from viewController: UIViewController) {
        if let interstitial = interstitial {
            interstitial.present(fromRootViewController: viewController)
            loadInterstitial() // 다음 광고를 미리 로드
        }
    }
    
    func createBannerView() -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = bannerAdUnitID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.load(GADRequest())
        return bannerView
    }
} 