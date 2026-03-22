import Foundation

/// Servicios compartidos por escenas SpriteKit; inyectable para tests o variantes.
@MainActor
final class SceneDependencies {
    let saveManager: SaveManager
    let storeManager: StoreManager
    let purchaseManager: PurchaseManager
    let soundManager: SoundManager
    let hapticsManager: HapticsManager
    let telemetry: TelemetryLogging

    init(
        saveManager: SaveManager = .shared,
        storeManager: StoreManager = .shared,
        purchaseManager: PurchaseManager = .shared,
        soundManager: SoundManager = .shared,
        hapticsManager: HapticsManager = .shared,
        telemetry: TelemetryLogging = AppTelemetry.shared
    ) {
        self.saveManager = saveManager
        self.storeManager = storeManager
        self.purchaseManager = purchaseManager
        self.soundManager = soundManager
        self.hapticsManager = hapticsManager
        self.telemetry = telemetry
    }

    static let live = SceneDependencies()
}
