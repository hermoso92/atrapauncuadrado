import Foundation

final class SaveManager {
    static let shared = SaveManager()

    private let userDefaults: UserDefaults
    private let progressKey = "atrapa_un_cuadrado.progress"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadProgress() -> GameProgress {
        guard let data = userDefaults.data(forKey: progressKey) else {
            return .defaultProgress
        }
        if let migrated = migratedLegacyProgress(from: data) {
            save(migrated)
            return normalized(migrated)
        }
        if let progress = try? JSONDecoder().decode(GameProgress.self, from: data) {
            return normalized(progress)
        }
        return .defaultProgress
    }

    func save(_ progress: GameProgress) {
        let normalizedProgress = normalized(progress)
        guard let data = try? JSONEncoder().encode(normalizedProgress) else {
            return
        }
        userDefaults.set(data, forKey: progressKey)
    }

    func update(_ transform: (inout GameProgress) -> Void) -> GameProgress {
        var progress = loadProgress()
        transform(&progress)
        let normalizedProgress = normalized(progress)
        save(normalizedProgress)
        return normalizedProgress
    }

    func resetProgress() -> GameProgress {
        let progress = GameProgress.defaultProgress
        save(progress)
        return progress
    }

    private func normalized(_ progress: GameProgress) -> GameProgress {
        var normalizedProgress = progress
        let validCharacterIDs = Set(CharacterDefinition.catalog.map(\.id))

        if normalizedProgress.godModeEnabled {
            normalizedProgress.coins = max(9_999, normalizedProgress.coins)
            normalizedProgress.evolutionUnlocked = true
            normalizedProgress.evolutionUnlockedWithCoins = true
            normalizedProgress.ghostModeUnlocked = true
            normalizedProgress.unlockedCharacters = validCharacterIDs
            normalizedProgress.ownedAbilities = Set(AbilityType.allCases)
            normalizedProgress.ownedWeapons = Set(WeaponType.allCases)
            normalizedProgress.ownedOriginalUpgrades = Set(OriginalUpgrade.allCases)
        } else {
            normalizedProgress.coins = max(0, normalizedProgress.coins)
            normalizedProgress.evolutionUnlocked = normalizedProgress.evolutionUnlocked || normalizedProgress.evolutionUnlockedWithCoins
            normalizedProgress.unlockedCharacters.formIntersection(validCharacterIDs)
            normalizedProgress.unlockedCharacters.formUnion(GameProgress.starterCharacterIDs)
            normalizedProgress.ownedAbilities.formIntersection(Set(AbilityType.allCases))
            normalizedProgress.ownedAbilities.formUnion(GameProgress.starterAbilities)
            normalizedProgress.ownedWeapons.formIntersection(Set(WeaponType.allCases))
            normalizedProgress.ownedWeapons.formUnion(GameProgress.starterWeapons)
            normalizedProgress.ownedOriginalUpgrades.formIntersection(Set(OriginalUpgrade.allCases))
            normalizedProgress.ownedOriginalUpgrades.formUnion(GameProgress.starterOriginalUpgrades)
        }

        normalizeSelectedWeapon(&normalizedProgress.evolutionProgress.selectedWeapon, ownedWeapons: normalizedProgress.ownedWeapons)
        normalizeSelectedWeapon(&normalizedProgress.ghostProgress.selectedWeapon, ownedWeapons: normalizedProgress.ownedWeapons)

        if !normalizedProgress.isModeUnlocked(normalizedProgress.lastSelectedMode) {
            normalizedProgress.lastSelectedMode = .original
        }

        if !normalizedProgress.unlockedCharacters.contains(normalizedProgress.originalProgress.selectedCharacterID) {
            normalizedProgress.originalProgress.selectedCharacterID = CharacterDefinition.classicCircle.id
        }
        if !normalizedProgress.unlockedCharacters.contains(normalizedProgress.evolutionProgress.selectedCharacterID) {
            normalizedProgress.evolutionProgress.selectedCharacterID = CharacterDefinition.classicCircle.id
        }
        if !normalizedProgress.unlockedCharacters.contains(normalizedProgress.ghostProgress.selectedCharacterID) {
            normalizedProgress.ghostProgress.selectedCharacterID = CharacterDefinition.prism.id
        }

        normalizedProgress.originalProgress.highScore = max(0, normalizedProgress.originalProgress.highScore)
        normalizedProgress.evolutionProgress.highScore = max(0, normalizedProgress.evolutionProgress.highScore)
        normalizedProgress.ghostProgress.highScore = max(0, normalizedProgress.ghostProgress.highScore)
        return normalizedProgress
    }

    private func normalizeSelectedWeapon(_ weapon: inout WeaponType, ownedWeapons: Set<WeaponType>) {
        if !ownedWeapons.contains(weapon) {
            weapon = .blaster
        }
    }

    private func migratedLegacyProgress(from data: Data) -> GameProgress? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let hasLegacyFields = object["highScore"] != nil || object["selectedCharacterID"] != nil
        let hasModernFields = object["originalProgress"] != nil || object["evolutionProgress"] != nil || object["ghostProgress"] != nil
        guard hasLegacyFields, !hasModernFields else {
            return nil
        }

        let coins = object["coins"] as? Int ?? 0
        let highScore = object["highScore"] as? Int ?? 0
        let selectedCharacterID = object["selectedCharacterID"] as? String ?? CharacterDefinition.classicCircle.id
        let unlockedCharacters = Set((object["unlockedCharacters"] as? [String]) ?? [])
        let ownedAbilityRawValues = (object["ownedAbilities"] as? [String]) ?? []
        let ownedAbilities = Set(ownedAbilityRawValues.compactMap(AbilityType.init(rawValue:)))
        let soundEnabled = object["soundEnabled"] as? Bool ?? true
        let hapticsEnabled = object["hapticsEnabled"] as? Bool ?? true

        return GameProgress(
            coins: coins,
            evolutionUnlocked: false,
            evolutionUnlockedWithCoins: false,
            ghostModeUnlocked: false,
            unlockedCharacters: unlockedCharacters,
            ownedAbilities: ownedAbilities,
            ownedWeapons: [.blaster],
            ownedOriginalUpgrades: [],
            originalProgress: ModeProgress(
                highScore: highScore,
                selectedCharacterID: CharacterDefinition.classicCircle.id,
                selectedWeapon: .blaster
            ),
            evolutionProgress: ModeProgress(
                highScore: 0,
                selectedCharacterID: selectedCharacterID,
                selectedWeapon: .blaster
            ),
            ghostProgress: .defaultGhost,
            lastSelectedMode: .original,
            godModeEnabled: false,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled
        )
    }
}

private struct LegacyGameProgress: Codable {
    var coins: Int
    var highScore: Int
    var unlockedCharacters: Set<String>
    var ownedAbilities: Set<AbilityType>
    var selectedCharacterID: String
    var soundEnabled: Bool
    var hapticsEnabled: Bool
}
