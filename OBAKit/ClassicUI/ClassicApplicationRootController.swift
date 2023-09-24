//
//  ClassicApplicationRootController.swift
//  OBANext
//
//  Copyright © Open Transit Software Foundation
//  This source code is licensed under the Apache 2.0 license found in the
//  LICENSE file in the root directory of this source tree.
//
import os
import UIKit
import SwiftUI
import OBAKitCore
import GoogleMobileAds

@objc(OBAClassicApplicationRootController)
public class ClassicApplicationRootController: UIViewController {
    let logger = os.Logger(subsystem: "au.mymetro.iphone", category: "ClassicApplicationRootController")
    
    private let application: Application
    let tabController: TabViewController
    private let adController: GoogleAdController
    
    private var entitlementManager: EntitlementManager

    private var purchaseManager: PurchaseManager
    
    var purchaseObserver: NSKeyValueObservation?

    @objc public init(application: Application) {
        self.application = application
        self.tabController = TabViewController(application: application)
        self.adController = GoogleAdController.getInstance(application: application)
        
        entitlementManager = application.entitlementManager
        purchaseManager = application.purchaseManager

        super.init(nibName: nil, bundle: nil)

        self.application.viewRouter.rootController = self
        self.view.backgroundColor = ThemeColors.shared.brand // ThemeColors.shared.systemBackground
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(tabController.view)
        
        tabController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // tabController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tabController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tabController.view.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tabController.view.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
        ])
        
        Task<Void, Never> {
            do {
                try await purchaseManager.updatePurchasedProducts()
                setupAdsView()
            } catch {
                logger.error("Error updating purchased products: \(error)")
            }
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if adController.isAdEnabled() {
            coordinator.animate(alongsideTransition: { _ in
                self.adController.loadBannerAd()
            })
        }
    }
    
    public func hideBannerAd() {
        if adController.bannerView != nil {
            self.adController.bannerView.removeFromSuperview()
            NSLayoutConstraint.activate([
                tabController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            ])
        }
    }

    func setupAdsView() {
        if adController.isAdEnabled() {
            self.adController.setRootViewControllers(viewController: self)
            self.adController.setBelowViewController(viewController: tabController)
            self.adController.initBannerView()

            NSLayoutConstraint.activate([
                adController.bannerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tabController.view.topAnchor.constraint(equalTo: self.adController.bannerView.bottomAnchor),
                tabController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                tabController.view.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
                tabController.view.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            ])
            
            view.addConstraints(
                [NSLayoutConstraint(item: adController.bannerView,
                    attribute: .centerX,
                    relatedBy: .equal,
                    toItem: view.safeAreaLayoutGuide,
                    attribute: .centerX,
                    multiplier: 1,
                    constant: 0)
                ])
        } else {
            NSLayoutConstraint.activate([
                tabController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tabController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                tabController.view.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
                tabController.view.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            ])
        }
    }
    
    // MARK: - ALERT
    
    func showAlert(title: String) {
      let alert = UIAlertController(title: title, message: nil, preferredStyle: UIAlertController.Style.alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
      }))
      present(alert, animated: true, completion: nil)
    }
}
