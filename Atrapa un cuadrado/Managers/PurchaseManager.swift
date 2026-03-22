import Foundation
import os
import StoreKit

extension Notification.Name {
    static let purchaseManagerDidUpdate = Notification.Name("purchaseManagerDidUpdate")
}

@MainActor
final class PurchaseManager {
    enum ProductID: String, CaseIterable {
        case evolutionUnlock = "com.atrapauncuadrado.evolution_unlock"
    }

    enum ActionResult: Equatable {
        case success
        case restored
        case pending
        case cancelled
        case unavailable
        case failed(String)
    }

    static let shared = PurchaseManager(saveManager: .shared)

    private let saveManager: SaveManager
    private var productsByID: [String: Product] = [:]
    private var updatesTask: Task<Void, Never>?

    init(saveManager: SaveManager) {
        self.saveManager = saveManager
    }

    var evolutionPriceText: String {
        productsByID[ProductID.evolutionUnlock.rawValue]?.displayPrice ?? "Disponible en App Store"
    }

    var hasLoadedProducts: Bool {
        !productsByID.isEmpty
    }

    func start() {
        guard updatesTask == nil else {
            return
        }

        AppLog.purchase.info("PurchaseManager.start listening for transaction updates")

        updatesTask = Task(priority: .background) { [weak self] in
            guard let self else {
                return
            }
            for await result in Transaction.updates {
                await self.handle(transactionResult: result)
            }
        }

        Task {
            await refreshCatalog()
            await refreshEntitlements()
        }
    }

    func refreshCatalog() async {
        do {
            let products = try await Product.products(for: ProductID.allCases.map(\.rawValue))
            productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        } catch {
            productsByID = [:]
        }
        NotificationCenter.default.post(name: .purchaseManagerDidUpdate, object: nil)
    }

    @discardableResult
    func refreshEntitlements() async -> Bool {
        var ownsEvolution = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            guard transaction.revocationDate == nil else {
                continue
            }
            if transaction.productID == ProductID.evolutionUnlock.rawValue {
                ownsEvolution = true
            }
        }

        applyEvolutionAccess(appStoreUnlocked: ownsEvolution)

        NotificationCenter.default.post(name: .purchaseManagerDidUpdate, object: nil)
        return ownsEvolution
    }

    func purchaseEvolutionUnlock() async -> ActionResult {
        if saveManager.loadProgress().evolutionUnlocked {
            return .success
        }

        if !hasLoadedProducts {
            await refreshCatalog()
        }

        guard let product = productsByID[ProductID.evolutionUnlock.rawValue] else {
            return .unavailable
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    return .failed("La compra no se pudo verificar.")
                }
                await grantEntitlement(for: transaction)
                await transaction.finish()
                return .success
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed("Estado de compra desconocido.")
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func restorePurchases() async -> ActionResult {
        do {
            try await AppStore.sync()
            let ownsEvolution = await refreshEntitlements()
            return restoreResult(hasEvolutionEntitlement: ownsEvolution)
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = transactionResult else {
            return
        }
        await grantEntitlement(for: transaction)
        await transaction.finish()
    }

    private func grantEntitlement(for transaction: Transaction) async {
        if transaction.productID == ProductID.evolutionUnlock.rawValue {
            await refreshEntitlements()
        }
    }

    func applyEvolutionAccess(appStoreUnlocked: Bool) {
        _ = saveManager.update { progress in
            progress.evolutionUnlocked = appStoreUnlocked || progress.evolutionUnlockedWithCoins
        }
    }

    func restoreResult(hasEvolutionEntitlement: Bool) -> ActionResult {
        hasEvolutionEntitlement
            ? .restored
            : .failed("No se encontro ninguna compra para restaurar.")
    }
}
