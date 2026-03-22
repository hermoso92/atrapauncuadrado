import Foundation

/// Servicios compartidos por escenas SpriteKit; inyectable para tests o variantes.
final class SceneDependencies {
    let saveManager: SaveManager
    let storeManager: StoreManager
    let purchaseManager: PurchaseManager
    let soundManager: SoundManager
    let hapticsManager: HapticsManager

    init(
        saveManager: SaveManager = .shared,
        storeManager: StoreManager = .shared,
        purchaseManager: PurchaseManager = .shared,
        soundManager: SoundManager = .shared,
        hapticsManager: HapticsManager = .shared
    ) {
        self.saveManager = saveManager
        self.storeManager = storeManager
        self.purchaseManager = purchaseManager
        self.soundManager = soundManager
        self.hapticsManager = hapticsManager
    }

    static let live = SceneDependencies()
}
