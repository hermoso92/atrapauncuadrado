import Foundation

enum PurchaseResult: Equatable {
    case purchased
    case equipped
    case alreadyOwned
    case insufficientFunds
    case unavailable
}

final class StoreManager {
    static let shared = StoreManager()
    static let evolutionUnlockCoinCost = 1_000

    let characters = CharacterDefinition.catalog
    let abilities = AbilityType.allCases
    let weapons = WeaponType.allCases
    let originalUpgrades = OriginalUpgrade.allCases

    init() {}

    func purchaseCharacter(id: String, saveManager: SaveManager = .shared) -> PurchaseResult {
        guard let definition = characters.first(where: { $0.id == id }) else {
            return .unavailable
        }

        let progress = saveManager.loadProgress()
        guard progress.evolutionUnlocked else {
            return .unavailable
        }
        guard !progress.unlockedCharacters.contains(id) else {
            return .alreadyOwned
        }
        guard progress.coins >= definition.price else {
            return .insufficientFunds
        }

        _ = saveManager.update { mutableProgress in
            mutableProgress.coins -= definition.price
            mutableProgress.unlockedCharacters.insert(id)
            mutableProgress.ownedWeapons.insert(definition.defaultWeapon)
        }
        return .purchased
    }

    func purchaseAbility(_ ability: AbilityType, saveManager: SaveManager = .shared) -> PurchaseResult {
        let progress = saveManager.loadProgress()
        guard progress.evolutionUnlocked else {
            return .unavailable
        }
        guard !progress.ownedAbilities.contains(ability) else {
            return .alreadyOwned
        }
        guard progress.coins >= ability.price else {
            return .insufficientFunds
        }

        _ = saveManager.update { mutableProgress in
            mutableProgress.coins -= ability.price
            mutableProgress.ownedAbilities.insert(ability)
        }
        return .purchased
    }

    func purchaseWeapon(_ weapon: WeaponType, for gameMode: GameMode, saveManager: SaveManager = .shared) -> PurchaseResult {
        let progress = saveManager.loadProgress()
        guard progress.evolutionUnlocked else {
            return .unavailable
        }
        if progress.ownedWeapons.contains(weapon) {
            if progress.selectedWeapon(for: gameMode) == weapon {
                return .alreadyOwned
            }
            _ = saveManager.update { $0.equipWeapon(weapon, for: gameMode) }
            return .equipped
        }
        guard progress.coins >= weapon.price else {
            return .insufficientFunds
        }

        _ = saveManager.update { mutableProgress in
            mutableProgress.coins -= weapon.price
            mutableProgress.ownedWeapons.insert(weapon)
            mutableProgress.equipWeapon(weapon, for: gameMode)
        }
        return .purchased
    }

    func purchaseOriginalUpgrade(_ upgrade: OriginalUpgrade, saveManager: SaveManager = .shared) -> PurchaseResult {
        let progress = saveManager.loadProgress()
        guard !progress.ownedOriginalUpgrades.contains(upgrade) else {
            return .alreadyOwned
        }
        guard progress.coins >= upgrade.price else {
            return .insufficientFunds
        }

        _ = saveManager.update { mutableProgress in
            mutableProgress.coins -= upgrade.price
            mutableProgress.ownedOriginalUpgrades.insert(upgrade)
        }
        return .purchased
    }

    func purchaseEvolutionUnlock(saveManager: SaveManager = .shared) -> PurchaseResult {
        let progress = saveManager.loadProgress()
        guard !progress.evolutionUnlocked else {
            return .alreadyOwned
        }
        guard progress.coins >= Self.evolutionUnlockCoinCost else {
            return .insufficientFunds
        }

        _ = saveManager.update { mutableProgress in
            mutableProgress.coins -= Self.evolutionUnlockCoinCost
            mutableProgress.evolutionUnlockedWithCoins = true
            mutableProgress.evolutionUnlocked = true
        }
        return .purchased
    }

    func canAffordCharacter(id: String, progress: GameProgress) -> Bool {
        guard let definition = characters.first(where: { $0.id == id }) else {
            return false
        }
        return progress.coins >= definition.price
    }

    func canAffordAbility(_ ability: AbilityType, progress: GameProgress) -> Bool {
        progress.coins >= ability.price
    }

    func canAffordWeapon(_ weapon: WeaponType, progress: GameProgress) -> Bool {
        progress.coins >= weapon.price
    }

    func canAffordOriginalUpgrade(_ upgrade: OriginalUpgrade, progress: GameProgress) -> Bool {
        progress.coins >= upgrade.price
    }
}
