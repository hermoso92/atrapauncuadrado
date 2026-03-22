import Foundation

// MARK: - DTOs (Domain, Codable para persistencia y sync futuro)

struct ArtificialWorldSnapshot: Codable, Equatable, Sendable {
    var worldId: UUID
    var playerPositionX: Double
    var playerPositionY: Double
    var hunger: Double
    var energy: Double
    var shelterLevel: Int
    var inventoryItemIds: [String]
    var controlModeRaw: String
    var lastSavedAt: Date
    /// Raw values de `WorldAbility` desbloqueadas; vacío en datos legacy = todas en runtime.
    var unlockedWorldAbilityRaws: [String]

    init(
        worldId: UUID,
        playerPositionX: Double,
        playerPositionY: Double,
        hunger: Double,
        energy: Double,
        shelterLevel: Int,
        inventoryItemIds: [String],
        controlModeRaw: String,
        lastSavedAt: Date,
        unlockedWorldAbilityRaws: [String] = []
    ) {
        self.worldId = worldId
        self.playerPositionX = playerPositionX
        self.playerPositionY = playerPositionY
        self.hunger = hunger
        self.energy = energy
        self.shelterLevel = shelterLevel
        self.inventoryItemIds = inventoryItemIds
        self.controlModeRaw = controlModeRaw
        self.lastSavedAt = lastSavedAt
        self.unlockedWorldAbilityRaws = unlockedWorldAbilityRaws
    }
}

struct AgentMemoryEntry: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var summary: String
    var createdAt: Date
    var relatedEventKind: String?
}

/// Persistencia del mundo artificial; implementación SwiftData en `Persistence/`.
@MainActor
protocol WorldRepository: AnyObject {
    func loadSnapshot() throws -> ArtificialWorldSnapshot?
    func saveSnapshot(_ snapshot: ArtificialWorldSnapshot) throws
    func appendMemoryEntry(_ entry: AgentMemoryEntry) throws
    func recentMemoryEntries(limit: Int) throws -> [AgentMemoryEntry]
}
