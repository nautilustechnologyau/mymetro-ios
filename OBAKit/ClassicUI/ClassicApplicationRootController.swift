//
//  ClassicApplicationRootController.swift
//  OBANext
//
//  Copyright © Open Transit Software Foundation
//  This source code is licensed under the Apache 2.0 license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit
import SwiftUI
import OBAKitCore
import GoogleMobileAds

@objc(OBAClassicApplicationRootController)
public class ClassicApplicationRootController: UIViewController {
    private let application: Application
    let tabController: TabViewController
    private let adController: GoogleAdController

    @objc public init(application: Application) {
        self.application = application
        self.tabController = TabViewController(application: application)
        self.adController = GoogleAdController()

        super.init(nibName: nil, bundle: nil)

        self.application.viewRouter.rootController = self
        self.view.backgroundColor = ThemeColors.shared.brand // ThemeColors.shared.systemBackground

        tabController.view.translatesAutoresizingMaskIntoConstraints = false
        tabController.view.window?.rootViewController = self
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

        NSLayoutConstraint.activate([
            tabController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            tabController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            //tabController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            //tabController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        if self.adController.isAdEnabled() {
            self.adController.setRootViewControllers(viewController: self)
            self.adController.setBelowViewController(viewController: tabController)
            self.adController.initBannerView()

            NSLayoutConstraint.activate([
                tabController.view.topAnchor.constraint(equalTo: self.adController.bannerView.bottomAnchor),
                tabController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                tabController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
                tabController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
                tabController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tabController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
            
            //view.removeConstraints(view.constraints)
            /*view.addConstraints(
                [NSLayoutConstraint(item: tabController.view as Any,
                                    attribute: .left,
                                    relatedBy: .equal,
                                    toItem: view.safeAreaLayoutGuide,
                                    attribute: .left,
                                    multiplier: 1,
                                    constant: 0),
                 NSLayoutConstraint(item: tabController.view as Any,
                                    attribute: .right,
                                    relatedBy: .equal,
                                    toItem: view.safeAreaLayoutGuide,
                                    attribute: .right,
                                    multiplier: 1,
                                    constant: 0)
                ])*/
        } else {
            NSLayoutConstraint.activate([
                tabController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                tabController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
                tabController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            ])

            view.removeConstraints(view.constraints)
            view.addConstraints(
                [NSLayoutConstraint(item: tabController.view as Any,
                                    attribute: .top,
                                    relatedBy: .equal,
                                    toItem: view.safeAreaLayoutGuide,
                                    attribute: .top,
                                    multiplier: 1,
                                    constant: 0),
                 NSLayoutConstraint(item: tabController.view as Any,
                                    attribute: .centerX,
                                    relatedBy: .equal,
                                    toItem: view.safeAreaLayoutGuide,
                                    attribute: .centerX,
                                    multiplier: 1,
                                    constant: 0),
                 NSLayoutConstraint(item: tabController.view as Any,
                                    attribute: .left,
                                    relatedBy: .equal,
                                    toItem: view.safeAreaLayoutGuide,
                                    attribute: .left,
                                    multiplier: 1,
                                    constant: 0),
                 NSLayoutConstraint(item: tabController.view as Any,
                                    attribute: .right,
                                    relatedBy: .equal,
                                    toItem: view.safeAreaLayoutGuide,
                                    attribute: .right,
                                    multiplier: 1,
                                    constant: 0)
                ])
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
        self.adController.bannerView.removeFromSuperview()
        NSLayoutConstraint.activate([
            tabController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            tabController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])
        view.removeConstraints([NSLayoutConstraint(item: tabController.view as Any,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: view.safeAreaLayoutGuide,
                                                  attribute: .top,
                                                  multiplier: 1,
                                                  constant: 0),
                                NSLayoutConstraint(item: tabController.view as Any,
                                                  attribute: .centerX,
                                                  relatedBy: .equal,
                                                  toItem: view.safeAreaLayoutGuide,
                                                  attribute: .centerX,
                                                  multiplier: 1,
                                                  constant: 0)
                              ])
        view.addConstraints(
            [NSLayoutConstraint(item: tabController.view as Any,
                                attribute: .top,
                                relatedBy: .equal,
                                toItem: view.safeAreaLayoutGuide,
                                attribute: .top,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: tabController.view as Any,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view.safeAreaLayoutGuide,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])
    }
}
