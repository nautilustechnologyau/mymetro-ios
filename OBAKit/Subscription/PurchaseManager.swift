import Foundation
import StoreKit

@MainActor
class PurchaseManager: NSObject, ObservableObject {

    private let productIds = ["MYMETRO_ADS_FREE_MONTHLY", "MYMETRO_ADS_FREE_YEARLY"]

    @Published
    private(set) var products: [Product] = []
    
    @Published
    private(set) var purchasedProductIDs = Set<String>()

    private let entitlementManager: EntitlementManager
    private var productsLoaded = false
    private var updates: Task<Void, Never>? = nil

    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        super.init()
        self.updates = observeTransactionUpdates()
        SKPaymentQueue.default().add(self)
    }

    deinit {
        self.updates?.cancel()
    }

    func loadProducts() async throws {
        guard !self.productsLoaded else { return }
        self.products = try await Product.products(for: productIds)
        self.productsLoaded = true
    }
    
    func canMakePurchases() -> Bool { return SKPaymentQueue.canMakePayments() }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case let .success(.verified(transaction)):
            // Successful purchase
            await transaction.finish()
            await self.updatePurchasedProducts()
        case let .success(.unverified(_, error)):
            // Successful purchase but transaction/receipt can't be verified
            // Could be a jailbroken phone
            break
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or
            // approval from Ask to Buy
            break
        case .userCancelled:
            // ^^^
            break
        @unknown default:
            break
        }
    }

    func updatePurchasedProducts() async {
        self.purchasedProductIDs.removeAll()
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }

        self.entitlementManager.adsFree = !self.purchasedProductIDs.isEmpty
    }
    
    func restorePurchase() {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await verificationResult in Transaction.updates {
                // Using verificationResult directly would be better
                // but this way works for this tutorial
                await self.updatePurchasedProducts()
            }
        }
    }
}

extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        /*Task<Void, Never> {
            do {
                try await updatePurchasedProducts()
            } catch {
                print(error)
            }
        }*/
    }

    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
}
