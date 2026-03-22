import CoreGraphics
import Foundation

// MARK: - Legendary Drop

/// Represents the reward from a legendary entity.
struct LegendaryDrop: Codable, Equatable {
    let id: String
    let name: String
    let coinValue: Int
    let rarity: Rarity

    enum Rarity: String, Codable {
        case common
        case uncommon
        case rare
        case epic
        case legendary
    }
}

// MARK: - Default Legendary Drops

extension LegendaryDrop {
    static let goldenSquare = LegendaryDrop(id: "drop_golden_square", name: "Golden Square", coinValue: 500, rarity: .rare)
    static let prismaticShard = LegendaryDrop(id: "drop_prismatic_shard", name: "Prismatic Shard", coinValue: 1000, rarity: .epic)
    static let ancientCore = LegendaryDrop(id: "drop_ancient_core", name: "Ancient Core", coinValue: 2000, rarity: .legendary)

    static let all: [LegendaryDrop] = [goldenSquare, prismaticShard, ancientCore]

    static func drop(for id: String) -> LegendaryDrop? {
        all.first { $0.id == id }
    }
}

// MARK: - Legendary Entity Factory

/// Factory for creating legendary (rare spawn) entities.
enum LegendaryEntityFactory {
    /// Creates a new legendary entity at the given position.
    static func create(
        at position: CGPoint,
        uniqueDrop: String = "drop_golden_square",
        spawnCondition: SpawnCondition = .timer(seconds: 300)
    ) -> Entity {
        Entity(
            id: UUID(),
            position: position,
            kind: .legendary(uniqueDrop: uniqueDrop, spawnCondition: spawnCondition)
        )
    }
}

// MARK: - Legendary Behavior Helpers

extension Entity {
    /// Updates legendary entity spawn timer.
    mutating func updateLegendarySpawn(delta: TimeInterval) {
        guard !isSpawned else { return }
        spawnTimer += delta
        // Actual spawn triggered externally based on condition
    }

    /// Triggers legendary entity spawn.
    mutating func triggerSpawn() {
        isSpawned = true
    }

    /// Collects the legendary drop. Returns nil if not spawned.
    mutating func collectDrop() -> LegendaryDrop? {
        guard isSpawned else { return nil }
        isSpawned = false
        spawnTimer = 0
        return LegendaryDrop.drop(for: legendaryDrop)
    }

    /// Whether this legendary entity is ready to spawn.
    var canSpawn: Bool {
        !isSpawned && spawnTimer >= 300 // 5 minutes minimum
    }
}

// MARK: - Default Legendary Configuration

extension LegendaryEntityFactory {
    static let defaultCooldown: TimeInterval = 300 // 5 minutes
    static let defaultDrop = LegendaryDrop.goldenSquare
}
