import Foundation
import SwiftData

@MainActor
final class SwiftDataWorldRepository: WorldRepository, AgentMemoryStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadSnapshot() throws -> ArtificialWorldSnapshot? {
        var descriptor = FetchDescriptor<PersistedWorldState>()
        descriptor.fetchLimit = 1
        let rows = try context.fetch(descriptor)
        guard let row = rows.first else {
            return nil
        }
        let ids = (try? JSONDecoder().decode([String].self, from: row.inventoryItemIdsData)) ?? []
        let abilityRaws = (try? JSONDecoder().decode([String].self, from: row.unlockedAbilitiesData)) ?? []
        return ArtificialWorldSnapshot(
            worldId: row.worldId,
            playerPositionX: row.playerPositionX,
            playerPositionY: row.playerPositionY,
            hunger: row.hunger,
            energy: row.energy,
            shelterLevel: row.shelterLevel,
            inventoryItemIds: ids,
            controlModeRaw: row.controlModeRaw,
            lastSavedAt: row.lastSavedAt,
            unlockedWorldAbilityRaws: abilityRaws
        )
    }

    func saveSnapshot(_ snapshot: ArtificialWorldSnapshot) throws {
        var descriptor = FetchDescriptor<PersistedWorldState>()
        descriptor.fetchLimit = 1
        let rows = try context.fetch(descriptor)
        let idsData = (try? JSONEncoder().encode(snapshot.inventoryItemIds)) ?? Data()
        let abilitiesData = (try? JSONEncoder().encode(snapshot.unlockedWorldAbilityRaws)) ?? Data()
        if let existing = rows.first {
            existing.worldId = snapshot.worldId
            existing.playerPositionX = snapshot.playerPositionX
            existing.playerPositionY = snapshot.playerPositionY
            existing.hunger = snapshot.hunger
            existing.energy = snapshot.energy
            existing.shelterLevel = snapshot.shelterLevel
            existing.inventoryItemIdsData = idsData
            existing.controlModeRaw = snapshot.controlModeRaw
            existing.lastSavedAt = snapshot.lastSavedAt
            existing.unlockedAbilitiesData = abilitiesData
        } else {
            let row = PersistedWorldState(
                worldId: snapshot.worldId,
                playerPositionX: snapshot.playerPositionX,
                playerPositionY: snapshot.playerPositionY,
                hunger: snapshot.hunger,
                energy: snapshot.energy,
                shelterLevel: snapshot.shelterLevel,
                inventoryItemIdsData: idsData,
                controlModeRaw: snapshot.controlModeRaw,
                lastSavedAt: snapshot.lastSavedAt,
                unlockedAbilitiesData: abilitiesData
            )
            context.insert(row)
        }
        try context.save()
    }

    func appendMemoryEntry(_ entry: AgentMemoryEntry) throws {
        let row = PersistedAgentMemoryRecord(
            entryId: entry.id,
            summary: entry.summary,
            createdAt: entry.createdAt,
            relatedEventKind: entry.relatedEventKind
        )
        context.insert(row)
        try context.save()
    }

    func recentMemoryEntries(limit: Int) throws -> [AgentMemoryEntry] {
        var descriptor = FetchDescriptor<PersistedAgentMemoryRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let rows = try context.fetch(descriptor)
        return rows.map {
            AgentMemoryEntry(id: $0.entryId, summary: $0.summary, createdAt: $0.createdAt, relatedEventKind: $0.relatedEventKind)
        }
    }

    func append(_ entry: AgentMemoryEntry) throws {
        try appendMemoryEntry(entry)
    }

    func recent(limit: Int) throws -> [AgentMemoryEntry] {
        try recentMemoryEntries(limit: limit)
    }
}
