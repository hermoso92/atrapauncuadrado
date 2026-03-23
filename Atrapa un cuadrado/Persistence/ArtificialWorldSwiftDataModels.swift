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
    // FASE5: Zone unlock flags (encoded Set<String>)
    var zoneUnlockFlagsData: Data
    // FASE5: Danger zones (encoded [DangerZone])
    var dangerZonesData: Data
    var companionStatsData: Data

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
        unlockedAbilitiesData: Data = Data(),
        zoneUnlockFlagsData: Data = Data(),
        dangerZonesData: Data = Data(),
        companionStatsData: Data = Data()
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
        self.zoneUnlockFlagsData = zoneUnlockFlagsData
        self.dangerZonesData = dangerZonesData
        self.companionStatsData = companionStatsData
    }
}

@Model
final class PersistedAgentMemoryRecord {
    @Attribute(.unique) var entryId: UUID
    var summary: String
    var createdAt: Date
    var relatedEventKind: String?
    var dangerZonesData: Data

    init(entryId: UUID, summary: String, createdAt: Date, relatedEventKind: String?, dangerZonesData: Data = Data()) {
        self.entryId = entryId
        self.summary = summary
        self.createdAt = createdAt
        self.relatedEventKind = relatedEventKind
        self.dangerZonesData = dangerZonesData
    }
}

// MARK: - Achievement Model

@Model
final class PersistedAchievement {
    @Attribute(.unique) var achievementId: String
    var unlockedAt: Date?
    var notified: Bool

    init(achievementId: String, unlockedAt: Date? = nil, notified: Bool = false) {
        self.achievementId = achievementId
        self.unlockedAt = unlockedAt
        self.notified = notified
    }

    var isUnlocked: Bool {
        unlockedAt != nil
    }
}

// MARK: - Zone State Model

@Model
final class PersistedZoneState {
    @Attribute(.unique) var zoneId: String
    var unlocked: Bool
    var unlockedAt: Date?

    init(zoneId: String, unlocked: Bool = false, unlockedAt: Date? = nil) {
        self.zoneId = zoneId
        self.unlocked = unlocked
        self.unlockedAt = unlockedAt
    }
}
