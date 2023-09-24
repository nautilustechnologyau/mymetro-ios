import os
import UIKit
import StoreKit
import OBAKitCore

class SubscriptionViewController: UIViewController {
    let logger = os.Logger(subsystem: "au.mymetro.iphone", category: "SubscriptionViewController")

    var yearButton: UIButton!
    var monthButton: UIButton!

    let application: Application

    var stackView: UIStackView

    var entitlementManager: EntitlementManager

    var purchaseManager: PurchaseManager

    var purchaseButtons: [UIButton] = []

    public init(application: Application) {
        self.application = application
        self.entitlementManager = application.entitlementManager
        self.purchaseManager = application.purchaseManager
        self.stackView = UIStackView()
        super.init(nibName: nil, bundle: nil)

        title = OBALoc("subscription_controller.title", value: "Buy Ads Free Subscription", comment: "Title of the buy subscription")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ThemeColors.shared.systemBackground
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillProportionally
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            stackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -8),
            stackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8),
        ])
        
        Task<Void, Never> {
            do {
                try await purchaseManager.loadProducts()
                setupUI()
            } catch {
                logger.error("Error updating purchased products: \(error)")
            }
        }
    }

    func setupTitleLabel() {
        let label: UILabel = UILabel()
        label.text = OBALoc("subscription_controller.header", value: "Tired of Ads? Purchase Ads Free Subscription and Remove Them Now!", comment: "Header of the buy subscription")
        label.contentMode = .left
        label.isHighlighted = true
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        label.baselineAdjustment = .alignBaselines
        label.font = .preferredFont(forTextStyle: .subheadline)
        self.stackView.addArrangedSubview(label)
    }

    func setupDescriptionLabel() {
        let label: UILabel = UILabel()
        label.text = OBALoc("subscription_controller.description", value: "Though we are trying to show ads at a minimal level, we understand that seeing ads sometimes can be annoying. However, ads help us covering the huge cost to keep infrastructures running on the cloud. It also supports the on-going development to improve the app.\n\nPurchasing subscription is optional. By purchasing the subscription you will enjoy ads free in-app experience. Your purchase will be a great support for us!", comment: "Description of the buy subscription")
        label.contentMode = .left
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHighlighted = true
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        label.baselineAdjustment = .alignBaselines
        label.font = .preferredFont(forTextStyle: .footnote)
        self.stackView.addArrangedSubview(label)
    }

    func setupConditionLabel() {
        let label: UILabel = UILabel()
        label.text = OBALoc("subscription_controller.terms", value: "Payments will be charged using your Apple ID. The subscription will be automatically renewed unless you cancel at least 24 hours before the expiry. You can manage your subscription from your account settings in App Store.\n\nBy purchasing subscription you are agreeing to MyMetro Terms of Use.", comment: "Terms of the buy subscription")
        label.contentMode = .left
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHighlighted = true
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        label.baselineAdjustment = .alignBaselines
        label.font = .preferredFont(forTextStyle: .caption1)
        self.stackView.addArrangedSubview(label)
    }

    func setupLegalButtons() {
        let legalView: UIView = UIView()
        legalView.translatesAutoresizingMaskIntoConstraints = false
        let legalStackView = UIStackView()
        legalStackView.translatesAutoresizingMaskIntoConstraints = false
        legalStackView.distribution = .fillProportionally
        legalStackView.axis = .horizontal
        legalStackView.spacing = 8
        legalStackView.alignment = .center
        
        let privacyBtn: UIButton = UIButton(type: .system, primaryAction: UIAction(title: "") { action in
            guard let url = Bundle.main.privacyPolicyURL else { return }
            self.application.open(url, options: [:], completionHandler: nil)
        })
        privacyBtn.setTitle(OBALoc("subscription_controller.privacy_title", value: "Privacy Policy", comment: "Privacy policy button title"), for: .normal)
        legalStackView.addArrangedSubview(privacyBtn)
        
        let termsBtn: UIButton = UIButton(type: .system, primaryAction: UIAction(title: "") { action in
            guard let url = Bundle.main.termsOfUseURL else { return }
            self.application.open(url, options: [:], completionHandler: nil)
        })
        termsBtn.setTitle(OBALoc("subscription_controller.terms_title", value: "Terms of Use", comment: "Terms of use button title"), for: .normal)
        legalStackView.addArrangedSubview(termsBtn)
        
        stackView.addArrangedSubview(legalStackView)
    }

    func setupButtons() {
        purchaseButtons.removeAll()
        for product in purchaseManager.products {
            var config1: UIButton.Configuration = .filled()
            config1.cornerStyle = .dynamic
            config1.buttonSize = .small
            config1.background.backgroundColor = ThemeColors.shared.brand
            let btn: UIButton = UIButton(configuration: config1, primaryAction: UIAction(title: "") { action in
                self.purchaseProduct(product: product)
            })
            btn.widthAnchor.constraint(equalToConstant: 260).isActive = true
            btn.setTitle(productTitle(item: product), for: .normal)
            
            stackView.addArrangedSubview(btn)
            purchaseButtons.append(btn)
        }
        
        var config2: UIButton.Configuration = .borderedTinted()
        config2.cornerStyle = .dynamic
        config2.buttonSize = .small
        let restoreBtn: UIButton = UIButton(configuration: config2, primaryAction: UIAction(title: "") { _ in
            self.restorePurchase()
        })
        restoreBtn.setTitle("Restore Purchase", for: .normal)
        restoreBtn.widthAnchor.constraint(equalToConstant: 260).isActive = true
        stackView.addArrangedSubview(restoreBtn)
    }

    // MARK: - UI

    func setupUI() {
        setupTitleLabel()
        setupDescriptionLabel()
        setupButtons()
        updatePurchaseButtonStatus()
        setupConditionLabel()
        setupLegalButtons()
    }

    func productTitle(item: Product) -> String {
        return "\(item.displayName) \(item.displayPrice)"
    }

    func purchaseProduct(product: Product) {
        Task<Void, Never> {
            do {
                try await purchaseManager.purchase(product)
                if entitlementManager.adsFree {
                    GoogleAdController.getInstance(application: application).hideBannerAd()
                }
                updatePurchaseButtonStatus()
            } catch {
                logger.error("Error purchasing product: \(error)")
            }
        }
    }

    func restorePurchase() {
        Task<Void, Never> {
            do {
                try await AppStore.sync()
                // try await purchaseManager.restorePurchase()
                try await purchaseManager.updatePurchasedProducts()
                if entitlementManager.adsFree {
                    GoogleAdController.getInstance(application: application).hideBannerAd()
                }
                updatePurchaseButtonStatus()
            } catch {
                logger.error("Error restoring product: \(error)")
            }
        }
    }

    func updatePurchaseButtonStatus() {
        for button in purchaseButtons {
            if self.entitlementManager.adsFree || !self.purchaseManager.canMakePurchases() {
                button.isEnabled = false
            } else {
                button.isEnabled = true
            }
        }
    }
}
