import Foundation

/// Shared metaprogression plus the persistent state for each playable mode.
struct GameProgress: Codable {
    var coins: Int
    var evolutionUnlocked: Bool
    var evolutionUnlockedWithCoins: Bool
    var ghostModeUnlocked: Bool
    var unlockedCharacters: Set<String>
    var ownedAbilities: Set<AbilityType>
    var ownedWeapons: Set<WeaponType>
    var ownedOriginalUpgrades: Set<OriginalUpgrade>
    var originalProgress: ModeProgress
    var evolutionProgress: ModeProgress
    var ghostProgress: ModeProgress
    var lastSelectedMode: GameMode
    var godModeEnabled: Bool
    var soundEnabled: Bool
    var hapticsEnabled: Bool

    init(
        coins: Int,
        evolutionUnlocked: Bool,
        evolutionUnlockedWithCoins: Bool,
        ghostModeUnlocked: Bool,
        unlockedCharacters: Set<String>,
        ownedAbilities: Set<AbilityType>,
        ownedWeapons: Set<WeaponType>,
        ownedOriginalUpgrades: Set<OriginalUpgrade>,
        originalProgress: ModeProgress,
        evolutionProgress: ModeProgress,
        ghostProgress: ModeProgress,
        lastSelectedMode: GameMode,
        godModeEnabled: Bool,
        soundEnabled: Bool,
        hapticsEnabled: Bool
    ) {
        self.coins = coins
        self.evolutionUnlocked = evolutionUnlocked
        self.evolutionUnlockedWithCoins = evolutionUnlockedWithCoins
        self.ghostModeUnlocked = ghostModeUnlocked
        self.unlockedCharacters = unlockedCharacters
        self.ownedAbilities = ownedAbilities
        self.ownedWeapons = ownedWeapons
        self.ownedOriginalUpgrades = ownedOriginalUpgrades
        self.originalProgress = originalProgress
        self.evolutionProgress = evolutionProgress
        self.ghostProgress = ghostProgress
        self.lastSelectedMode = lastSelectedMode
        self.godModeEnabled = godModeEnabled
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
    }
}

extension GameProgress {
    static let starterCharacterIDs = Set(
        CharacterDefinition.catalog
            .filter(\.startsUnlocked)
            .map(\.id)
    )

    static let starterAbilities: Set<AbilityType> = [.dash]
    static let starterWeapons: Set<WeaponType> = [.blaster]
    static let starterOriginalUpgrades: Set<OriginalUpgrade> = []

    static let defaultProgress = GameProgress(
        coins: 0,
        evolutionUnlocked: false,
        evolutionUnlockedWithCoins: false,
        ghostModeUnlocked: false,
        unlockedCharacters: starterCharacterIDs,
        ownedAbilities: starterAbilities,
        ownedWeapons: starterWeapons,
        ownedOriginalUpgrades: starterOriginalUpgrades,
        originalProgress: .defaultOriginal,
        evolutionProgress: .defaultEvolution,
        ghostProgress: .defaultGhost,
        lastSelectedMode: .original,
        godModeEnabled: false,
        soundEnabled: true,
        hapticsEnabled: true
    )

    static let godModeProgress = GameProgress(
        coins: 9_999,
        evolutionUnlocked: true,
        evolutionUnlockedWithCoins: true,
        ghostModeUnlocked: true,
        unlockedCharacters: Set(CharacterDefinition.catalog.map(\.id)),
        ownedAbilities: Set(AbilityType.allCases),
        ownedWeapons: Set(WeaponType.allCases),
        ownedOriginalUpgrades: Set(OriginalUpgrade.allCases),
        originalProgress: .defaultOriginal,
        evolutionProgress: .defaultEvolution,
        ghostProgress: .defaultGhost,
        lastSelectedMode: .evolution,
        godModeEnabled: true,
        soundEnabled: true,
        hapticsEnabled: true
    )
}

extension GameProgress {
    func modeProgress(for mode: GameMode) -> ModeProgress {
        switch mode {
        case .original:
            originalProgress
        case .evolution:
            evolutionProgress
        case .ghost:
            ghostProgress
        }
    }

    mutating func updateModeProgress(for mode: GameMode, _ transform: (inout ModeProgress) -> Void) {
        switch mode {
        case .original:
            transform(&originalProgress)
        case .evolution:
            transform(&evolutionProgress)
        case .ghost:
            transform(&ghostProgress)
        }
    }

    func selectedCharacterID(for mode: GameMode) -> String {
        modeProgress(for: mode).selectedCharacterID
    }

    func isModeUnlocked(_ mode: GameMode) -> Bool {
        switch mode {
        case .original:
            true
        case .evolution:
            evolutionUnlocked
        case .ghost:
            ghostModeUnlocked
        }
    }

    func highScore(for mode: GameMode) -> Int {
        modeProgress(for: mode).highScore
    }

    func owns(_ ability: AbilityType, for mode: GameMode) -> Bool {
        (mode == .evolution || mode == .ghost) && ownedAbilities.contains(ability)
    }

    func owns(_ weapon: WeaponType, for mode: GameMode) -> Bool {
        (mode == .evolution || mode == .ghost) && ownedWeapons.contains(weapon)
    }

    func owns(_ upgrade: OriginalUpgrade, for mode: GameMode) -> Bool {
        mode == .original && ownedOriginalUpgrades.contains(upgrade)
    }

    mutating func selectCharacter(_ id: String, for mode: GameMode) {
        updateModeProgress(for: mode) { $0.selectedCharacterID = id }
    }

    func selectedWeapon(for mode: GameMode) -> WeaponType {
        switch mode {
        case .original:
            .blaster
        case .evolution:
            evolutionProgress.selectedWeapon
        case .ghost:
            ghostProgress.selectedWeapon
        }
    }

    mutating func equipWeapon(_ weapon: WeaponType, for mode: GameMode) {
        guard mode != .original else {
            return
        }
        updateModeProgress(for: mode) { $0.selectedWeapon = weapon }
    }

    mutating func recordCompletedRun(for mode: GameMode, score: Int, coinsEarned: Int) {
        coins += coinsEarned
        lastSelectedMode = mode
        updateModeProgress(for: mode) { modeProgress in
            modeProgress.highScore = max(modeProgress.highScore, score)
        }
    }
}

extension GameProgress {
    private enum CodingKeys: String, CodingKey {
        case coins
        case evolutionUnlocked
        case evolutionUnlockedWithCoins
        case ghostModeUnlocked
        case unlockedCharacters
        case ownedAbilities
        case ownedWeapons
        case ownedOriginalUpgrades
        case originalProgress
        case evolutionProgress
        case ghostProgress
        case selectedWeapon
        case lastSelectedMode
        case godModeEnabled
        case soundEnabled
        case hapticsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coins = try container.decodeIfPresent(Int.self, forKey: .coins) ?? 0
        evolutionUnlocked = try container.decodeIfPresent(Bool.self, forKey: .evolutionUnlocked) ?? false
        evolutionUnlockedWithCoins = try container.decodeIfPresent(Bool.self, forKey: .evolutionUnlockedWithCoins) ?? false
        ghostModeUnlocked = try container.decodeIfPresent(Bool.self, forKey: .ghostModeUnlocked) ?? false
        unlockedCharacters = try container.decodeIfPresent(Set<String>.self, forKey: .unlockedCharacters) ?? []
        ownedAbilities = try container.decodeIfPresent(Set<AbilityType>.self, forKey: .ownedAbilities) ?? [.dash]
        ownedWeapons = try container.decodeIfPresent(Set<WeaponType>.self, forKey: .ownedWeapons) ?? [.blaster]
        ownedOriginalUpgrades = try container.decodeIfPresent(Set<OriginalUpgrade>.self, forKey: .ownedOriginalUpgrades) ?? []
        originalProgress = try container.decodeIfPresent(ModeProgress.self, forKey: .originalProgress) ?? .defaultOriginal
        let legacySelectedWeapon = try container.decodeIfPresent(WeaponType.self, forKey: .selectedWeapon) ?? .blaster
        evolutionProgress = try container.decodeIfPresent(ModeProgress.self, forKey: .evolutionProgress) ?? ModeProgress(
            highScore: 0,
            selectedCharacterID: CharacterDefinition.classicCircle.id,
            selectedWeapon: legacySelectedWeapon
        )
        ghostProgress = try container.decodeIfPresent(ModeProgress.self, forKey: .ghostProgress) ?? ModeProgress(
            highScore: 0,
            selectedCharacterID: CharacterDefinition.prism.id,
            selectedWeapon: legacySelectedWeapon
        )
        lastSelectedMode = try container.decodeIfPresent(GameMode.self, forKey: .lastSelectedMode) ?? .original
        godModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .godModeEnabled) ?? false
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coins, forKey: .coins)
        try container.encode(evolutionUnlocked, forKey: .evolutionUnlocked)
        try container.encode(evolutionUnlockedWithCoins, forKey: .evolutionUnlockedWithCoins)
        try container.encode(ghostModeUnlocked, forKey: .ghostModeUnlocked)
        try container.encode(unlockedCharacters, forKey: .unlockedCharacters)
        try container.encode(ownedAbilities, forKey: .ownedAbilities)
        try container.encode(ownedWeapons, forKey: .ownedWeapons)
        try container.encode(ownedOriginalUpgrades, forKey: .ownedOriginalUpgrades)
        try container.encode(originalProgress, forKey: .originalProgress)
        try container.encode(evolutionProgress, forKey: .evolutionProgress)
        try container.encode(ghostProgress, forKey: .ghostProgress)
        try container.encode(evolutionProgress.selectedWeapon, forKey: .selectedWeapon)
        try container.encode(lastSelectedMode, forKey: .lastSelectedMode)
        try container.encode(godModeEnabled, forKey: .godModeEnabled)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(hapticsEnabled, forKey: .hapticsEnabled)
    }
}
