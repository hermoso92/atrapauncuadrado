import CoreGraphics
import Foundation

// MARK: - Zone Unlock Requirements

/// Requirements that must be met to unlock a zone.
enum ZoneUnlockRequirement: Equatable {
    case shelterLevel(Int)
    case achievement(String)
    case itemCount(itemId: String, count: Int)
    case enemyDefeats(Int)
    case allOf([ZoneUnlockRequirement])
    case anyOf([ZoneUnlockRequirement])
}

// MARK: - World Zone

/// Represents a zone/biome in the world with its own entities and unlock requirements.
struct WorldZone: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let bounds: CGRect
    let unlockRequirements: [ZoneUnlockRequirement]
    let entityConfig: ZoneEntityConfiguration
    let isDefault: Bool

    /// Whether this zone is unlocked for the player.
    func isUnlocked(
        shelterLevel: Int,
        unlockedAchievements: Set<String>,
        inventoryItemCounts: [String: Int],
        enemyDefeats: Int
    ) -> Bool {
        unlockRequirements.allSatisfy { req in
            meetsRequirement(
                req,
                shelterLevel: shelterLevel,
                unlockedAchievements: unlockedAchievements,
                inventoryItemCounts: inventoryItemCounts,
                enemyDefeats: enemyDefeats
            )
        }
    }

    private func meetsRequirement(
        _ req: ZoneUnlockRequirement,
        shelterLevel: Int,
        unlockedAchievements: Set<String>,
        inventoryItemCounts: [String: Int],
        enemyDefeats: Int
    ) -> Bool {
        switch req {
        case .shelterLevel(let level):
            return shelterLevel >= level
        case .achievement(let id):
            return unlockedAchievements.contains(id)
        case .itemCount(let itemId, let count):
            return (inventoryItemCounts[itemId] ?? 0) >= count
        case .enemyDefeats(let count):
            return enemyDefeats >= count
        case .allOf(let requirements):
            return requirements.allSatisfy { r in
                meetsRequirement(r, shelterLevel: shelterLevel, unlockedAchievements: unlockedAchievements, inventoryItemCounts: inventoryItemCounts, enemyDefeats: enemyDefeats)
            }
        case .anyOf(let requirements):
            return requirements.contains { r in
                meetsRequirement(r, shelterLevel: shelterLevel, unlockedAchievements: unlockedAchievements, inventoryItemCounts: inventoryItemCounts, enemyDefeats: enemyDefeats)
            }
        }
    }
}

/// Configuration of entity spawning within a zone.
struct ZoneEntityConfiguration: Equatable {
    let hostileSpawnRate: Double       // spawns per minute
    let passiveSpawnRate: Double
    let legendarySpawnRate: Double
    let maxHostile: Int
    let maxPassive: Int
    let legendaryCooldown: TimeInterval
}

// MARK: - Codable Extensions

extension ZoneUnlockRequirement: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case shelterLevel
        case achievementId
        case itemId
        case itemCount
        case enemyDefeats
        case requirements
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "shelterLevel":
            let level = try container.decode(Int.self, forKey: .shelterLevel)
            self = .shelterLevel(level)
        case "achievement":
            let id = try container.decode(String.self, forKey: .achievementId)
            self = .achievement(id)
        case "itemCount":
            let itemId = try container.decode(String.self, forKey: .itemId)
            let count = try container.decode(Int.self, forKey: .itemCount)
            self = .itemCount(itemId: itemId, count: count)
        case "enemyDefeats":
            let count = try container.decode(Int.self, forKey: .enemyDefeats)
            self = .enemyDefeats(count)
        case "allOf":
            let requirements = try container.decode([ZoneUnlockRequirement].self, forKey: .requirements)
            self = .allOf(requirements)
        case "anyOf":
            let requirements = try container.decode([ZoneUnlockRequirement].self, forKey: .requirements)
            self = .anyOf(requirements)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown requirement type: \(type)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .shelterLevel(let level):
            try container.encode("shelterLevel", forKey: .type)
            try container.encode(level, forKey: .shelterLevel)
        case .achievement(let id):
            try container.encode("achievement", forKey: .type)
            try container.encode(id, forKey: .achievementId)
        case .itemCount(let itemId, let count):
            try container.encode("itemCount", forKey: .type)
            try container.encode(itemId, forKey: .itemId)
            try container.encode(count, forKey: .itemCount)
        case .enemyDefeats(let count):
            try container.encode("enemyDefeats", forKey: .type)
            try container.encode(count, forKey: .enemyDefeats)
        case .allOf(let requirements):
            try container.encode("allOf", forKey: .type)
            try container.encode(requirements, forKey: .requirements)
        case .anyOf(let requirements):
            try container.encode("anyOf", forKey: .type)
            try container.encode(requirements, forKey: .requirements)
        }
    }
}

extension WorldZone: Codable {}
extension ZoneEntityConfiguration: Codable {}
