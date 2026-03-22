import CoreGraphics
import Foundation

// MARK: - Resource Type

enum ResourceType: String, Codable, CaseIterable {
    case generic = "res_generic"
    case food = "res_food"
    case energy = "res_energy"
    case rare = "res_rare"

    var displayName: String {
        switch self {
        case .generic: return "Resource"
        case .food: return "Food"
        case .energy: return "Energy"
        case .rare: return "Rare Resource"
        }
    }

    var hungerRestore: Double {
        switch self {
        case .generic: return 0.1
        case .food: return 0.25
        case .energy: return 0.05
        case .rare: return 0.15
        }
    }

    var energyRestore: Double {
        switch self {
        case .generic: return 0.05
        case .food: return 0.05
        case .energy: return 0.25
        case .rare: return 0.15
        }
    }
}

// MARK: - Passive Entity Factory

/// Factory for creating passive (gatherable) entities.
enum PassiveEntityFactory {
    /// Creates a new passive entity at the given position.
    static func create(
        at position: CGPoint,
        resourceYield: Int = 1,
        respawnTime: TimeInterval = 60,
        resourceType: ResourceType = .generic
    ) -> Entity {
        Entity(
            id: UUID(),
            position: position,
            kind: .passive(resourceYield: resourceYield, respawnTime: respawnTime)
        )
    }

    /// Creates multiple passive entities in the given bounds.
    static func createBatch(
        count: Int,
        in bounds: CGRect,
        resourceType: ResourceType = .generic
    ) -> [Entity] {
        (0..<count).map { _ in
            let x = CGFloat.random(in: bounds.minX...bounds.maxX)
            let y = CGFloat.random(in: bounds.minY...bounds.maxY)
            return create(
                at: CGPoint(x: x, y: y),
                resourceYield: Int.random(in: 1...3),
                respawnTime: TimeInterval.random(in: 30...120),
                resourceType: resourceType
            )
        }
    }
}

// MARK: - Passive Behavior Helpers

extension Entity {
    /// Yields resources if harvested. Returns 0 if already harvested.
    mutating func harvestResource() -> Int {
        guard isHarvestable else { return 0 }
        isHarvested = true
        respawnTimer = 0
        return passiveResourceYield
    }

    /// Updates passive entity respawn timer.
    mutating func updatePassiveRespawn(delta: TimeInterval) {
        guard isHarvested else { return }
        respawnTimer += delta
        if respawnTimer >= passiveRespawnTime {
            isHarvested = false
            position = originalPosition
            respawnTimer = 0
        }
    }

    /// Progress percentage toward respawn (0.0 - 1.0).
    var respawnProgress: Double {
        guard isHarvested else { return 1.0 }
        return min(1.0, respawnTimer / passiveRespawnTime)
    }
}

// MARK: - Default Passive Configuration

extension PassiveEntityFactory {
    static let defaultConfig = (
        resourceYield: 2,
        respawnTime: 60.0 as TimeInterval,
        resourceType: ResourceType.generic
    )
}
