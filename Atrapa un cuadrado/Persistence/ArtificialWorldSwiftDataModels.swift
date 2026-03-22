import Foundation
import SwiftData

@Model
final class PersistedWorldState {
    @Attribute(.unique) var worldId: UUID
    var playerPositionX: Double
    var playerPositionY: Double
    var hunger: Double
    var energy: Double
    var shelterLevel: Int
    var inventoryItemIdsData: Data
    var controlModeRaw: String
    var lastSavedAt: Date
    var unlockedAbilitiesData: Data

    init(
        worldId: UUID,
        playerPositionX: Double,
        playerPositionY: Double,
        hunger: Double,
        energy: Double,
        shelterLevel: Int,
        inventoryItemIdsData: Data,
        controlModeRaw: String,
        lastSavedAt: Date,
        unlockedAbilitiesData: Data = Data()
    ) {
        self.worldId = worldId
        self.playerPositionX = playerPositionX
        self.playerPositionY = playerPositionY
        self.hunger = hunger
        self.energy = energy
        self.shelterLevel = shelterLevel
        self.inventoryItemIdsData = inventoryItemIdsData
        self.controlModeRaw = controlModeRaw
        self.lastSavedAt = lastSavedAt
        self.unlockedAbilitiesData = unlockedAbilitiesData
    }
}

@Model
final class PersistedAgentMemoryRecord {
    @Attribute(.unique) var entryId: UUID
    var summary: String
    var createdAt: Date
    var relatedEventKind: String?

    init(entryId: UUID, summary: String, createdAt: Date, relatedEventKind: String?) {
        self.entryId = entryId
        self.summary = summary
        self.createdAt = createdAt
        self.relatedEventKind = relatedEventKind
    }
}
