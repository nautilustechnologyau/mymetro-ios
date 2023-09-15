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

    var logger = os.Logger(subsystem: "au.mymetro.iphone", category: "GoogleAdController")
    var bannerView: GADBannerView!
    var interstitialAd: GADInterstitialAd?
    var interstitialDisplayedTime: Int64 = 0
    var stopShowCount: Int64 = 0

    let minStopShowCountBeforeShowingAd: Int64 = 7
    let minTimeElapsedBeforeShowingAd: Int64 = 60
    let adShowProbablity: Float = 0.4
    var rootViewController: UIViewController?
    var belowViewController: UIViewController?

    // MARK: - Banner Ad Helper Methods

    public func setRootViewControllers(viewController: UIViewController) {
        self.rootViewController = viewController
    }

    public func setBelowViewController(viewController: UIViewController) {
        self.belowViewController = viewController
    }

    public func isAdEnabled() -> Bool {
        return Bundle.main.object(forInfoDictionaryKey: "GADEnabled") as? Bool ?? false
    }

    public func initBannerView() {
        // we need a root view controller to display the ad
        if rootViewController == nil {
            return
        }

        if bannerView != nil {
            if bannerView.isDescendant(of: (rootViewController?.view)!) {
                bannerView.removeFromSuperview()
            }
        }

        // In this case, we instantiate the banner with desired ad size.
        bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.delegate = self
        bannerView.rootViewController = rootViewController
        bannerView.adUnitID = Bundle.main.object(forInfoDictionaryKey: "GADBannerAdUnitID") as? String

        addBannerViewToView(bannerView)
    }

    public func initInterstitialAd() {
        let request = GADRequest()
        let adUnitID = Bundle.main.object(forInfoDictionaryKey: "GADInterstitialAdUnitID") as? String ?? ""
        GADInterstitialAd.load(withAdUnitID: adUnitID,
                               request: request,
                               completionHandler: {[self] ad, error in
                                            if let error = error {
                                                logger.debug("Failed to load interstitial ad with error: \(error.localizedDescription)")
                                                return
                                            }
                                        interstitialAd = ad
                                        interstitialAd?.fullScreenContentDelegate = self
                                    })
    }

    public func addBannerViewToView(_ bannerView: GADBannerView) {
        if bannerView.isDescendant(of: (rootViewController?.view)!) {
            return
        }

        if belowViewController != nil {
            rootViewController!.view.insertSubview(bannerView, aboveSubview: belowViewController!.view)
        } else {
            rootViewController!.view.addSubview(bannerView)
        }
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        rootViewController!.view.removeConstraints(rootViewController!.view.constraints)
        rootViewController!.view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                attribute: .top,
                relatedBy: .equal,
                toItem: rootViewController!.view.safeAreaLayoutGuide,
                attribute: .top,
                multiplier: 1,
                constant: 0),
             NSLayoutConstraint(item: bannerView,
                attribute: .centerX,
                relatedBy: .equal,
                toItem: rootViewController!.view.safeAreaLayoutGuide,
                attribute: .centerX,
                multiplier: 1,
                constant: 0)])

        loadBannerAd()
    }

    func loadBannerAd() {
        // Step 2 - Determine the view width to use for the ad width.
        let frame = { () -> CGRect in
            // Here safe area is taken into account, hence the view frame is used
            // after the view has been laid out.
            if #available(iOS 11.0, *) {
                return rootViewController!.view.frame.inset(by: rootViewController!.view.safeAreaInsets)
            } else {
                return rootViewController!.view.frame
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

    func loadInterstitialAd(viewController: UIViewController) {
        if interstitialAd == nil {
            logger.debug("Interstitial ad has not been loaded yet")
            return
        }

        // check probablity
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
            showInterstitialAd(viewController: viewController)
            return
        }

        if stopShowCount <= minStopShowCountBeforeShowingAd {
            return
        }

        // show add when user in on the map for more than minTimeElapsedBeforeShowingAd
        let currentTimeInSec = Int64(Date().timeIntervalSince1970)
        let timeDiff = currentTimeInSec - interstitialDisplayedTime
        if timeDiff > minTimeElapsedBeforeShowingAd {
            showInterstitialAd(viewController: viewController)
            return
        }

        logger.debug("Not showing ad because it is too early")
    }

    func showInterstitialAd(viewController: UIViewController) {
        interstitialAd?.present(fromRootViewController: viewController)
        interstitialDisplayedTime = Int64(Date().timeIntervalSince1970)
        stopShowCount = 0
    }

    public func hideBannerAd() {
        if bannerView != nil {
            if bannerView.isDescendant(of: (rootViewController?.view)!) {
                bannerView.removeFromSuperview()
            }
        }

        if belowViewController != nil {
            NSLayoutConstraint.activate([
                belowViewController!.view.bottomAnchor.constraint(equalTo: rootViewController!.view.bottomAnchor),
                belowViewController!.view.rightAnchor.constraint(equalTo: rootViewController!.view.rightAnchor),
                belowViewController!.view.leftAnchor.constraint(equalTo: rootViewController!.view.leftAnchor),
            ])
            rootViewController!.view.removeConstraints(
                [NSLayoutConstraint(item: belowViewController!.view!,
                                   attribute: .top,
                                   relatedBy: .equal,
                                   toItem: rootViewController!.view.safeAreaLayoutGuide,
                                   attribute: .top,
                                   multiplier: 1,
                                   constant: 0),
                 NSLayoutConstraint(item: belowViewController!.view!,
                                   attribute: .centerX,
                                   relatedBy: .equal,
                                   toItem: rootViewController!.view.safeAreaLayoutGuide,
                                   attribute: .centerX,
                                   multiplier: 1,
                                   constant: 0)
                ])
            rootViewController!.view.addConstraints(
                [NSLayoutConstraint(item: belowViewController!.view!,
                                   attribute: .top,
                                   relatedBy: .equal,
                                   toItem: rootViewController!.view.safeAreaLayoutGuide,
                                   attribute: .top,
                                   multiplier: 1,
                                   constant: 0),
                 NSLayoutConstraint(item: belowViewController!.view!,
                                   attribute: .centerX,
                                   relatedBy: .equal,
                                   toItem: rootViewController!.view.safeAreaLayoutGuide,
                                   attribute: .centerX,
                                   multiplier: 1,
                                   constant: 0)
                ])
        }
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
        hideBannerAd()
        loadBannerAd()
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
