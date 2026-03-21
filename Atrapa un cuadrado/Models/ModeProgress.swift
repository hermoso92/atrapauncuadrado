import Foundation

struct ModeProgress: Codable {
    var highScore: Int
    var selectedCharacterID: String
    var selectedWeapon: WeaponType
}

extension ModeProgress {
    static let defaultOriginal = ModeProgress(
        highScore: 0,
        selectedCharacterID: CharacterDefinition.classicCircle.id,
        selectedWeapon: .blaster
    )

    static let defaultEvolution = ModeProgress(
        highScore: 0,
        selectedCharacterID: CharacterDefinition.classicCircle.id,
        selectedWeapon: .blaster
    )

    static let defaultGhost = ModeProgress(
        highScore: 0,
        selectedCharacterID: CharacterDefinition.prism.id,
        selectedWeapon: .blaster
    )
}
