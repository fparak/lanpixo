import SwiftUI
import GoogleMobileAds
import UserMessagingPlatform

enum AdConfiguration {
    static var testMode: Bool { Bundle.main.object(forInfoDictionaryKey: "LanpixoAdEnvironment") as? String != "live" }
    static let application = "ca-app-pub-4333526146021563~5868530963"
    static var banner: String { testMode ? "ca-app-pub-3940256099942544/2435281174" : "ca-app-pub-4333526146021563/4931300928" }
    static var interstitial: String { testMode ? "ca-app-pub-3940256099942544/4411468910" : "ca-app-pub-4333526146021563/1546589686" }
    static var rewarded: String { testMode ? "ca-app-pub-3940256099942544/1712485313" : "ca-app-pub-4333526146021563/2040966599" }
    static func request() -> Request {
        let request = Request()
        let extras = Extras(); extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        return request
    }
}

@MainActor final class AdService: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published private(set) var canRequest = false
    @Published private(set) var privacyRequired = false
    @Published private(set) var busy = false
    @Published private(set) var message = ""
    @Published private(set) var credits = 0
    @Published private(set) var generation = UUID()
    private var ledger = AdCreditLedger()
    private let defaults: UserDefaults
    private var launched = false
    private var initialized = false
    private var sdkReady = false
    private var epoch = UUID()
    private var paused = false
    private var rewardedAd: RewardedAd?
    private var interstitialAd: InterstitialAd?
    private var interstitialLoadedAt = Date.distantPast
    private var loadingInterstitial = false
    private var completedScans = 0
    private var lastFullScreen = Date()
    private var rewardToken: UUID?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        if let data = defaults.data(forKey: "adCreditLedger"), let saved = try? JSONDecoder().decode(AdCreditLedger.self, from: data) { ledger = saved }
        ledger.finish(completed: false) // Refund a reservation interrupted by process death.
        persist()
    }
    private func persist() {
        if let data = try? JSONEncoder().encode(ledger) { defaults.set(data, forKey: "adCreditLedger") }
        credits = ledger.balance
    }
    func reserveCredit() -> Bool { let result = ledger.reserve(); persist(); return result }
    func finishCredit(completed: Bool) { ledger.finish(completed: completed); persist() }
    func completedScan() { completedScans += 1 }

    func start() {
        guard !launched else { return }
        launched = true
        updateConsent()
    }
    func updateConsent() {
        guard !busy, !paused else { return }
        busy = true; invalidateAds()
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if error != nil { self.message = "consentError"; self.finishConsent(); return }
                do { try await ConsentForm.loadAndPresentIfRequired(from: nil); self.message = "" }
                catch { self.message = "consentError" }
                self.finishConsent()
            }
        }
    }
    private func finishConsent() {
        let allowed = ConsentInformation.shared.canRequestAds
        canRequest = allowed && sdkReady
        privacyRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        busy = false
        if allowed, !initialized {
            initialized = true
            MobileAds.shared.requestConfiguration.setPublisherFirstPartyIDEnabled(false)
            MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .disabled
            MobileAds.shared.requestConfiguration.coarseLocationCollectionEnabled = false
            MobileAds.shared.start { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.sdkReady = true
                    self.canRequest = ConsentInformation.shared.canRequestAds
                    self.prepareInterstitial()
                }
            }
        } else if canRequest { prepareInterstitial() }
    }
    func privacyOptions() {
        guard !busy, !paused, privacyRequired else { return }
        busy = true; invalidateAds(); canRequest = false
        Task {
            do { try await ConsentForm.presentPrivacyOptionsForm(from: nil); message = "" }
            catch { message = "consentError" }
            finishConsent()
        }
    }
    private func invalidateAds() {
        epoch = UUID(); generation = UUID()
        rewardedAd = nil; interstitialAd = nil; loadingInterstitial = false
    }
    func setNetworkBusy(_ active: Bool) {
        paused = active
        if active { invalidateAds() }
    }
    func prepareInterstitial() {
        guard canRequest, initialized, !paused, !busy, !loadingInterstitial, interstitialAd == nil else { return }
        loadingInterstitial = true
        let token = epoch
        Task {
            do {
                let ad = try await InterstitialAd.load(with: AdConfiguration.interstitial, request: AdConfiguration.request())
                guard epoch == token, canRequest, !paused else { return }
                interstitialAd = ad; ad.fullScreenContentDelegate = self; interstitialLoadedAt = Date()
            } catch { /* An unavailable ad never blocks navigation. */ }
            if epoch == token { loadingInterstitial = false }
        }
    }
    func leaveResults() {
        guard canRequest, !paused, !busy,
              AdFrequencyPolicy.eligible(completions: completedScans, lastShown: lastFullScreen, now: Date()),
              Date().timeIntervalSince(interstitialLoadedAt) < 3600,
              let ad = interstitialAd, UIApplication.shared.applicationState == .active else { prepareInterstitial(); return }
        interstitialAd = nil
        do { try ad.canPresent(from: nil) } catch { prepareInterstitial(); return }
        busy = true; completedScans = 0; lastFullScreen = Date()
        ad.present(from: nil)
    }
    func watchReward() {
        guard canRequest, !paused, !busy else { return }
        busy = true; message = "loading"
        let token = UUID(); rewardToken = token
        let currentEpoch = epoch
        Task {
            do {
                let ad = try await RewardedAd.load(with: AdConfiguration.rewarded, request: AdConfiguration.request())
                guard epoch == currentEpoch, canRequest, !paused, UIApplication.shared.applicationState == .active else {
                    busy = false; message = "adError"; rewardToken = nil; return
                }
                try ad.canPresent(from: nil)
                rewardedAd = ad; ad.fullScreenContentDelegate = self; message = ""
                ad.present(from: nil) { [weak self] in
                    guard let self, self.rewardToken == token else { return }
                    self.rewardToken = nil // Exactly one credit, only SDK's earned callback.
                    self.ledger.earn(); self.persist(); self.message = "earned"
                }
            } catch { busy = false; rewardToken = nil; message = "adError"; rewardedAd = nil }
        }
    }
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if rewardToken != nil { message = "closed" }
        rewardToken = nil; rewardedAd = nil; interstitialAd = nil
        busy = false; lastFullScreen = Date()
    }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardToken = nil; rewardedAd = nil; interstitialAd = nil
        busy = false; message = "adError"; lastFullScreen = Date()
    }
}

struct AdBanner: UIViewRepresentable {
    let width: CGFloat
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: width))
        banner.adUnitID = AdConfiguration.banner
        banner.load(AdConfiguration.request())
        return banner
    }
    func updateUIView(_ uiView: BannerView, context: Context) {}
    static func dismantleUIView(_ uiView: BannerView, coordinator: ()) {
        uiView.delegate = nil; uiView.removeFromSuperview()
    }
}

struct AdBannerSlot: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var ads: AdService
    @State private var width: CGFloat = 320
    var body: some View {
        if ads.canRequest, !ads.busy, !model.busy {
            GeometryReader { proxy in
                let size = currentOrientationAnchoredAdaptiveBanner(width: proxy.size.width)
                VStack(spacing: 4) {
                    Text(model.text("Advertisement", "Reklam")).font(.caption2).foregroundStyle(.secondary)
                    AdBanner(width: proxy.size.width).id("\(proxy.size.width)-\(ads.generation)")
                        .frame(width: size.size.width, height: size.size.height)
                }.frame(maxWidth: .infinity)
                    .onAppear { width = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, value in width = value }
            }.frame(height: currentOrientationAnchoredAdaptiveBanner(width: max(1, width)).size.height + 24).padding(.horizontal, 16)
        }
    }
}
