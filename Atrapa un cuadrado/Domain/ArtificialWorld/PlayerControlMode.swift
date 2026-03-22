import Foundation

enum PlayerControlMode: String, Codable, CaseIterable {
    case manual
    case automatic
    case hybrid
}

extension ArtificialWorldSnapshot {
    var controlMode: PlayerControlMode {
        get { PlayerControlMode(rawValue: controlModeRaw) ?? .manual }
        set { controlModeRaw = newValue.rawValue }
    }

    static func newGame(worldBoundsMidX: Double, shelterCenterY: Double) -> ArtificialWorldSnapshot {
        ArtificialWorldSnapshot(
            worldId: UUID(),
            playerPositionX: worldBoundsMidX,
            playerPositionY: shelterCenterY + 40,
            hunger: 0.88,
            energy: 0.92,
            shelterLevel: 1,
            inventoryItemIds: [],
            controlModeRaw: PlayerControlMode.manual.rawValue,
            lastSavedAt: Date(),
            unlockedWorldAbilityRaws: WorldAbility.allCases.map(\.rawValue)
        )
    }
}
