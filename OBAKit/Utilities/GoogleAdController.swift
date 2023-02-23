//
//  GoogleAdController.swift
//  OBAKit
//
//  Copyright © Open Transit Software Foundation
//  This source code is licensed under the Apache 2.0 license found in the
//  LICENSE file in the root directory of this source tree.
//

import os.log

import UIKit
import GoogleMobileAds
import OBAKitCore

class GoogleAdController: NSObject,
                          GADBannerViewDelegate,
                          GADFullScreenContentDelegate {

    var logger = os.Logger(subsystem: "au.mymetro.iphone", category: "MapViewController")
    var bannerView: GADBannerView!
    var interstitialAd: GADInterstitialAd?
    var interstitialDisplayedTime: Int64 = 0
    var stopShowCount: Int64 = 0
    var bannerViewAdded: Bool = false

    let minStopShowCountBeforeShowingAd: Int64 = 7
    let minTimeElapsedBeforeShowingAd: Int64 = 60
    let adShowProbablity: Float = 0.4
    let viewController: UIViewController

    /// This is the default initializer for `AdUtils`.
    /// - Parameter application: The application object
    public init(viewController: UIViewController) {
        self.viewController = viewController
    }

    // MARK: - Banner Ad Helper Methods

    public func isAdEnabled() -> Bool {
        return Bundle.main.object(forInfoDictionaryKey: "GADEnabled") as? Bool ?? false
    }

    public func initBannerView(belowView: UIView? = nil) {
        // In this case, we instantiate the banner with desired ad size.
        bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.delegate = self
        bannerView.rootViewController = viewController
        bannerView.adUnitID = Bundle.main.object(forInfoDictionaryKey: "GADBannerAdUnitID") as? String

        addBannerViewToView(bannerView, belowView: belowView)
    }

    public func initInterstitialAd() {
        let request = GADRequest()
        let adUnitID = Bundle.main.object(forInfoDictionaryKey: "GADInterstitialAdUnitID") as? String ?? ""
        GADInterstitialAd.load(withAdUnitID: adUnitID,
                               request: request,
                               completionHandler: { [self] ad, error in
            if let error = error {
                logger.debug("Failed to load interstitial ad with error: \(error.localizedDescription)")
                return
            }
            interstitialAd = ad
            interstitialAd?.fullScreenContentDelegate = self
        }
        )
    }

    public func addBannerViewToView(_ bannerView: GADBannerView, belowView: UIView? = nil) {
        if !bannerViewAdded {
            if let belowView = belowView {
                viewController.view.insertSubview(bannerView, belowSubview: belowView)
            } else {
                viewController.view.addSubview(bannerView)
            }
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            bannerViewAdded = true
            loadBannerAd()
        }

        viewController.view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .top,
                                relatedBy: .equal,
                                toItem: viewController.view.safeAreaLayoutGuide,
                                attribute: .top,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: viewController.view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])
    }

    func loadBannerAd() {
        // Step 2 - Determine the view width to use for the ad width.
        let frame = { () -> CGRect in
            // Here safe area is taken into account, hence the view frame is used
            // after the view has been laid out.
            if #available(iOS 11.0, *) {
                return viewController.view.frame.inset(by: viewController.view.safeAreaInsets)
            } else {
                return viewController.view.frame
            }
        }()

        let viewWidth = frame.size.width

        // Step 3 - Get Adaptive GADAdSize and set the ad view.
        // Here the current interface orientation is used. If the ad is being preloaded
        // for a future orientation change or different orientation, the function for the
        // relevant orientation should be used.
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)

        // Step 4 - Create an ad request and load the adaptive banner ad.
        bannerView.load(GADRequest())
        logger.debug("GADRequest sent")
    }

    func loadInterstitialAd() {
        if interstitialAd == nil {
            logger.debug("Interstitial ad has not been loaded yet")
            return
        }

        // check probablity
        // let probablity = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let probablity = Float.random(in: 0..<1)
        if probablity < adShowProbablity {
            return
        }

        // will not show ad before minimum stop show count
        if stopShowCount < minStopShowCountBeforeShowingAd {
            logger.debug("Not showing ad before minimum stop show count")
            return
        }

        if stopShowCount > minStopShowCountBeforeShowingAd && interstitialDisplayedTime == 0 {
            showInterstitialAd()
            return
        }

        if stopShowCount <= minStopShowCountBeforeShowingAd {
            return
        }

        // show add when user in on the map for more than minTimeElapsedBeforeShowingAd
        let currentTimeInSec = Int64(Date().timeIntervalSince1970)
        let timeDiff = currentTimeInSec - interstitialDisplayedTime
        if timeDiff > minTimeElapsedBeforeShowingAd {
            showInterstitialAd()
            return
        }

        logger.debug("Not showing ad because it is too early")
    }

    func showInterstitialAd() {
        interstitialAd?.present(fromRootViewController: viewController)
        interstitialDisplayedTime = Int64(Date().timeIntervalSince1970)
        stopShowCount = 0
    }

    // MARK: - Banner View Delegates (GADBannerViewDelegate)

    public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Add banner to view and add constraints as above.
        bannerView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            bannerView.alpha = 1
        })
        logger.debug("bannerViewDidReceiveAd")
    }

    public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        logger.debug("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
        bannerView.removeFromSuperview()
        bannerViewAdded = false
    }

    public func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        logger.debug("bannerViewDidRecordImpression")
    }

    public func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        logger.debug("bannerViewWillPresentScreen")
    }

    public func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        logger.debug("bannerViewWillDIsmissScreen")
    }

    public func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        logger.debug("bannerViewDidDismissScreen")
    }

    // MARK: - Interstitial Ad Delegates (GADFullScreenContentDelegate)

    /// Tells the delegate that the ad failed to present full screen content.
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitialAd = nil
        logger.debug("Ad did fail to present full screen content: \(error.localizedDescription)")
    }

    /// Tells the delegate that the ad will present full screen content.
    public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        logger.debug("Ad will present full screen content.")
    }

    /// Tells the delegate that the ad dismissed full screen content.
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        logger.debug("Ad did dismiss full screen content. Loading again.")
        // load ad again
        interstitialAd = nil
        initInterstitialAd()
    }
}
