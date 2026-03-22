import CoreGraphics
import Foundation

// MARK: - Entity Spawner

/// Factory for creating and managing world entities based on zone configuration.
final class EntitySpawner {
    private var activeEntities: [Entity] = []
    private var spawnTimers: [String: TimeInterval] = [:]

    let worldBounds: CGRect

    init(worldBounds: CGRect) {
        self.worldBounds = worldBounds
    }

    // MARK: - Spawning

    /// Spawns entities based on the active zone configuration.
    func spawnForZone(_ zone: WorldZone, delta: TimeInterval) -> [Entity] {
        var spawned: [Entity] = []
        let config = zone.entityConfig

        // Hostile spawning
        let hostileCount = activeEntities.filter { $0.isHostile }.count
        if hostileCount < config.maxHostile {
            spawnTimers["hostile", default: 0] += delta
            let interval = 60.0 / config.hostileSpawnRate
            if spawnTimers["hostile"]! >= interval {
                let entity = HostileEntityFactory.create(at: randomPosition(in: zone.bounds))
                spawned.append(entity)
                activeEntities.append(entity)
                spawnTimers["hostile"] = 0
            }
        }

        // Passive spawning
        let passiveCount = activeEntities.filter { $0.isPassive }.count
        if passiveCount < config.maxPassive {
            spawnTimers["passive", default: 0] += delta
            let interval = 60.0 / config.passiveSpawnRate
            if spawnTimers["passive"]! >= interval {
                let entity = PassiveEntityFactory.create(at: randomPosition(in: zone.bounds))
                spawned.append(entity)
                activeEntities.append(entity)
                spawnTimers["passive"] = 0
            }
        }

        return spawned
    }

    /// Spawns a legendary entity at the given position.
    func spawnLegendary(at position: CGPoint, condition: SpawnCondition) -> Entity {
        let entity = LegendaryEntityFactory.create(at: position, spawnCondition: condition)
        activeEntities.append(entity)
        return entity
    }

    // MARK: - Entity Management

    /// Updates all entities and returns IDs to remove.
    func tick(context: EntityContext) -> [UUID] {
        var toRemove: [UUID] = []

        for i in activeEntities.indices {
            let action = activeEntities[i].behavior(in: context)
            switch action {
            case .despawn:
                toRemove.append(activeEntities[i].id)
            default:
                break
            }
        }

        activeEntities.removeAll { toRemove.contains($0.id) }
        return toRemove
    }

    /// Removes a specific entity.
    func removeEntity(_ id: UUID) {
        activeEntities.removeAll { $0.id == id }
    }

    /// Returns all active entities.
    var entities: [Entity] {
        activeEntities
    }

    /// Returns entities of a specific type.
    var hostileEntities: [Entity] {
        activeEntities.filter { $0.isHostile }
    }

    var passiveEntities: [Entity] {
        activeEntities.filter { $0.isPassive }
    }

    var legendaryEntities: [Entity] {
        activeEntities.filter { $0.isLegendary }
    }

    /// Returns harvestable entities within range.
    func harvestableEntities(near position: CGPoint, range: CGFloat = 50) -> [Entity] {
        activeEntities.filter { entity in
            guard entity.isHarvestable else { return false }
            let dist = hypot(entity.position.x - position.x, entity.position.y - position.y)
            return dist <= range
        }
    }

    /// Clears all entities.
    func clear() {
        activeEntities.removeAll()
        spawnTimers.removeAll()
    }

    // MARK: - Private Helpers

    private func randomPosition(in bounds: CGRect) -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: bounds.minX...bounds.maxX),
            y: CGFloat.random(in: bounds.minY...bounds.maxY)
        )
    }
}

// MARK: - Default Spawn Configuration

extension EntitySpawner {
    /// Default zone configuration for the starting zone.
    static func defaultZoneConfig() -> ZoneEntityConfiguration {
        ZoneEntityConfiguration(
            hostileSpawnRate: 2.0,
            passiveSpawnRate: 5.0,
            legendarySpawnRate: 0.1,
            maxHostile: 5,
            maxPassive: 10,
            legendaryCooldown: 600
        )
    }
}
