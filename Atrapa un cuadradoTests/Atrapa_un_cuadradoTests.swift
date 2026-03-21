//
//  Atrapa_un_cuadradoTests.swift
//  Atrapa un cuadradoTests
//
//  Created by Antonio Hermoso on 20/3/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import AtrapaUnCuadrado

@MainActor
struct Atrapa_un_cuadradoTests {

    @Test func defaultProgressHasCoreContentUnlocked() async throws {
        let defaults = UserDefaults(suiteName: "Atrapa_un_cuadradoTests.default")!
        defaults.removePersistentDomain(forName: "Atrapa_un_cuadradoTests.default")

        let saveManager = SaveManager(userDefaults: defaults)
        let progress = saveManager.loadProgress()

        #expect(progress.coins == 0)
        #expect(!progress.evolutionUnlocked)
        #expect(progress.unlockedCharacters.contains(CharacterDefinition.classicCircle.id))
        #expect(progress.ownedAbilities.contains(AbilityType.dash))
        #expect(progress.lastSelectedMode == GameMode.original)
    }

    @Test func purchasingCharacterConsumesCoinsAndUnlocksIt() async throws {
        let defaults = UserDefaults(suiteName: "Atrapa_un_cuadradoTests.purchase")!
        defaults.removePersistentDomain(forName: "Atrapa_un_cuadradoTests.purchase")

        let saveManager = SaveManager(userDefaults: defaults)
        var progress = GameProgress.defaultProgress
        progress.coins = 250
        progress.evolutionUnlocked = true
        saveManager.save(progress)

        let result = StoreManager().purchaseCharacter(id: CharacterDefinition.stickman.id, saveManager: saveManager)

        #expect(result == .purchased)
        let updatedProgress = saveManager.loadProgress()
        #expect(updatedProgress.coins == 180)
        #expect(updatedProgress.unlockedCharacters.contains(CharacterDefinition.stickman.id))
        #expect(updatedProgress.ownedWeapons.contains(CharacterDefinition.stickman.defaultWeapon))
        #expect(updatedProgress.selectedWeapon(for: .evolution) == .blaster)
    }

    @Test func modeProgressRemainsSeparatedFromGlobalMetaProgress() async throws {
        var progress = GameProgress.defaultProgress
        progress.selectCharacter(CharacterDefinition.prism.id, for: .evolution)
        progress.recordCompletedRun(for: .evolution, score: 90, coinsEarned: 6)

        #expect(progress.highScore(for: .evolution) == 90)
        #expect(progress.highScore(for: .original) == 0)
        #expect(progress.selectedCharacterID(for: .evolution) == CharacterDefinition.prism.id)
        #expect(progress.selectedCharacterID(for: .original) == CharacterDefinition.classicCircle.id)
        #expect(progress.coins == 6)
    }

    @Test func resetProgressReturnsToDefaultState() async throws {
        let defaults = UserDefaults(suiteName: "Atrapa_un_cuadradoTests.reset")!
        defaults.removePersistentDomain(forName: "Atrapa_un_cuadradoTests.reset")

        let saveManager = SaveManager(userDefaults: defaults)
        var progress = GameProgress.defaultProgress
        progress.coins = 400
        progress.unlockedCharacters.insert(CharacterDefinition.prism.id)
        progress.ownedWeapons.insert(.rail)
        progress.selectCharacter(CharacterDefinition.prism.id, for: .evolution)
        progress.equipWeapon(.rail, for: .evolution)
        saveManager.save(progress)

        let resetProgress = saveManager.resetProgress()

        #expect(resetProgress.coins == 0)
        #expect(!resetProgress.evolutionUnlocked)
        #expect(resetProgress.unlockedCharacters == GameProgress.starterCharacterIDs)
        #expect(resetProgress.ownedWeapons == GameProgress.starterWeapons)
        #expect(resetProgress.selectedWeapon(for: .evolution) == .blaster)
        #expect(resetProgress.selectedWeapon(for: .ghost) == .blaster)
        #expect(resetProgress.selectedCharacterID(for: .evolution) == CharacterDefinition.classicCircle.id)
    }

    @Test func godModeNormalizesProgressAndPersistsFlag() async throws {
        let defaults = UserDefaults(suiteName: "Atrapa_un_cuadradoTests.godmode")!
        defaults.removePersistentDomain(forName: "Atrapa_un_cuadradoTests.godmode")

        let saveManager = SaveManager(userDefaults: defaults)
        var progress = GameProgress.defaultProgress
        progress.godModeEnabled = true
        progress.coins = 50
        saveManager.save(progress)

        let updatedProgress = saveManager.loadProgress()

        #expect(updatedProgress.godModeEnabled)
        #expect(updatedProgress.coins >= 9_999)
        #expect(updatedProgress.evolutionUnlocked)
        #expect(updatedProgress.ownedAbilities == Set(AbilityType.allCases))
        #expect(updatedProgress.ownedWeapons == Set(WeaponType.allCases))
        #expect(updatedProgress.ownedOriginalUpgrades == Set(OriginalUpgrade.allCases))
    }

    @Test func purchasingOwnedWeaponEquipsItWithoutChargingAgain() async throws {
        let defaults = UserDefaults(suiteName: "Atrapa_un_cuadradoTests.weaponEquip")!
        defaults.removePersistentDomain(forName: "Atrapa_un_cuadradoTests.weaponEquip")

        let saveManager = SaveManager(userDefaults: defaults)
        var progress = GameProgress.defaultProgress
        progress.coins = 500
        progress.evolutionUnlocked = true
        progress.ownedWeapons.insert(.rail)
        progress.equipWeapon(.blaster, for: .evolution)
        saveManager.save(progress)

        let result = StoreManager().purchaseWeapon(.rail, for: .evolution, saveManager: saveManager)

        #expect(result == .equipped)
        let updatedProgress = saveManager.loadProgress()
        #expect(updatedProgress.coins == 500)
        #expect(updatedProgress.selectedWeapon(for: .evolution) == .rail)
    }

    @Test func projectileDamageKeepsBlueCaptureInstantAndRedSquaresTankier() async throws {
        let normalSquare = SquareNode(
            kind: .normal,
            position: .zero,
            velocity: .zero
        )
        let aggressiveSquare = SquareNode(
            kind: .aggressive,
            position: .zero,
            velocity: .zero
        )

        #expect(normalSquare.applyDamage(1))
        #expect(!aggressiveSquare.applyDamage(16))
        #expect(aggressiveSquare.applyDamage(18))
    }

    @Test func premiumCopyAvoidsHardcodedLocalizedPriceFallback() async throws {
        let defaults = UserDefaults(suiteName: "Atrapa_un_cuadradoTests.purchaseManager")!
        defaults.removePersistentDomain(forName: "Atrapa_un_cuadradoTests.purchaseManager")

        let purchaseManager = PurchaseManager(saveManager: SaveManager(userDefaults: defaults))

        #expect(GameMode.evolution.accessLabel == "Premium o 1000 monedas")
        #expect(purchaseManager.evolutionPriceText == "Disponible en App Store")
    }

    @Test func evolutionStoreItemsStayUnavailableWithoutPremiumEntitlement() async throws {
        let defaults = UserDefaults(suiteName: "Atrapa_un_cuadradoTests.entitlementGate")!
        defaults.removePersistentDomain(forName: "Atrapa_un_cuadradoTests.entitlementGate")

        let saveManager = SaveManager(userDefaults: defaults)
        var progress = GameProgress.defaultProgress
        progress.coins = 500
        saveManager.save(progress)

        let storeManager = StoreManager()

        #expect(storeManager.purchaseCharacter(id: CharacterDefinition.stickman.id, saveManager: saveManager) == .unavailable)
        #expect(storeManager.purchaseAbility(.magnet, saveManager: saveManager) == .unavailable)
        #expect(storeManager.purchaseWeapon(.rail, for: .evolution, saveManager: saveManager) == .unavailable)
    }

    @Test func premiumCanAlsoBeUnlockedWithCoins() async throws {
        let defaults = UserDefaults(suiteName: "Atrapa_un_cuadradoTests.premiumCoins")!
        defaults.removePersistentDomain(forName: "Atrapa_un_cuadradoTests.premiumCoins")

        let saveManager = SaveManager(userDefaults: defaults)
        var progress = GameProgress.defaultProgress
        progress.coins = 1_250
        saveManager.save(progress)

        let result = StoreManager().purchaseEvolutionUnlock(saveManager: saveManager)
        let updatedProgress = saveManager.loadProgress()

        #expect(result == .purchased)
        #expect(updatedProgress.evolutionUnlocked)
        #expect(updatedProgress.evolutionUnlockedWithCoins)
        #expect(updatedProgress.coins == 250)
    }

    @Test func coinPremiumUnlockSurvivesStoreKitRefreshWithoutAppStorePurchase() async throws {
        let defaults = UserDefaults(suiteName: "Atrapa_un_cuadradoTests.premiumRefresh")!
        defaults.removePersistentDomain(forName: "Atrapa_un_cuadradoTests.premiumRefresh")

        let saveManager = SaveManager(userDefaults: defaults)
        var progress = GameProgress.defaultProgress
        progress.coins = 1_250
        saveManager.save(progress)

        _ = StoreManager().purchaseEvolutionUnlock(saveManager: saveManager)

        let purchaseManager = PurchaseManager(saveManager: saveManager)
        purchaseManager.applyEvolutionAccess(appStoreUnlocked: false)

        let refreshedProgress = saveManager.loadProgress()
        #expect(refreshedProgress.evolutionUnlocked)
        #expect(refreshedProgress.evolutionUnlockedWithCoins)
    }

    @Test func restoringPurchasesNeedsRealAppStoreEntitlement() async throws {
        let defaults = UserDefaults(suiteName: "Atrapa_un_cuadradoTests.restoreResult")!
        defaults.removePersistentDomain(forName: "Atrapa_un_cuadradoTests.restoreResult")

        let saveManager = SaveManager(userDefaults: defaults)
        var progress = GameProgress.defaultProgress
        progress.evolutionUnlocked = true
        progress.evolutionUnlockedWithCoins = true
        saveManager.save(progress)

        let purchaseManager = PurchaseManager(saveManager: saveManager)

        #expect(purchaseManager.restoreResult(hasEvolutionEntitlement: false) == .failed("No se encontro ninguna compra para restaurar."))
        #expect(purchaseManager.restoreResult(hasEvolutionEntitlement: true) == .restored)
    }

    @Test func legacyMigrationKeepsClassicScoreOutOfEvolutionMode() async throws {
        let defaults = UserDefaults(suiteName: "Atrapa_un_cuadradoTests.legacyMigration")!
        defaults.removePersistentDomain(forName: "Atrapa_un_cuadradoTests.legacyMigration")

        let legacyPayload = """
        {
          "coins": 120,
          "highScore": 42,
          "unlockedCharacters": ["\(CharacterDefinition.classicCircle.id)"],
          "ownedAbilities": ["dash"],
          "selectedCharacterID": "\(CharacterDefinition.classicCircle.id)",
          "soundEnabled": true,
          "hapticsEnabled": true
        }
        """.data(using: .utf8)!
        defaults.set(legacyPayload, forKey: "atrapa_un_cuadrado.progress")

        let progress = SaveManager(userDefaults: defaults).loadProgress()

        #expect(progress.highScore(for: .original) == 42)
        #expect(progress.highScore(for: .evolution) == 0)
    }

    @Test func secretGhostModeCanBeUnlockedAndPersisted() async throws {
        let defaults = UserDefaults(suiteName: "Atrapa_un_cuadradoTests.ghostCode")!
        defaults.removePersistentDomain(forName: "Atrapa_un_cuadradoTests.ghostCode")

        let saveManager = SaveManager(userDefaults: defaults)
        let progress = saveManager.update { progress in
            progress.ghostModeUnlocked = true
        }

        #expect(progress.isModeUnlocked(.ghost))
        #expect(progress.highScore(for: .ghost) == 0)
        #expect(progress.selectedCharacterID(for: .ghost) == CharacterDefinition.prism.id)
        #expect(saveManager.loadProgress().ghostModeUnlocked)
    }
}
