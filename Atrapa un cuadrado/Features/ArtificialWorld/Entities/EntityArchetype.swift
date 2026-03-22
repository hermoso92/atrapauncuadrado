import CoreGraphics
import Foundation

// MARK: - Entity Type

/// Defines the behavior archetype of an entity in the world.
enum EntityKind: Equatable {
    case hostile(damage: Double, patrolRadius: CGFloat)
    case passive(resourceYield: Int, respawnTime: TimeInterval)
    case legendary(uniqueDrop: String, spawnCondition: SpawnCondition)
}

/// Condition for legendary entity spawns.
enum SpawnCondition: Equatable {
    case timer(seconds: TimeInterval)
    case achievement(id: String)
    case zoneUnlocked(zoneId: String)
}

// MARK: - Entity

/// Represents an entity in the world with its state and behavior.
struct Entity: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    var velocity: CGVector
    var kind: EntityKind

    // State for hostile entities
    var patrolTarget: CGPoint?
    var lastAttackTime: TimeInterval = 0

    // State for passive entities
    var isHarvested: Bool = false
    var respawnTimer: TimeInterval = 0
    var originalPosition: CGPoint

    // State for legendary entities
    var isSpawned: Bool = false
    var spawnTimer: TimeInterval = 0
    var spawnPoint: CGPoint

    init(id: UUID = UUID(), position: CGPoint, kind: EntityKind) {
        self.id = id
        self.position = position
        self.velocity = .zero
        self.kind = kind
        self.originalPosition = position
        self.spawnPoint = position
    }

    // MARK: - Type Helpers

    var isHostile: Bool {
        if case .hostile = kind { return true }
        return false
    }

    var isPassive: Bool {
        if case .passive = kind { return true }
        return false
    }

    var isLegendary: Bool {
        if case .legendary = kind { return true }
        return false
    }

    var isHarvestable: Bool {
        switch kind {
        case .passive(let yield, _): return !isHarvested && yield > 0
        case .legendary: return isSpawned
        case .hostile: return false
        }
    }

    // MARK: - Hostile Helpers

    var hostileDamage: Double {
        if case .hostile(let damage, _) = kind { return damage }
        return 0
    }

    var hostilePatrolRadius: CGFloat {
        if case .hostile(_, let radius) = kind { return radius }
        return 120
    }

    // MARK: - Passive Helpers

    var passiveResourceYield: Int {
        if case .passive(let yield, _) = kind { return yield }
        return 0
    }

    var passiveRespawnTime: TimeInterval {
        if case .passive(_, let time) = kind { return time }
        return 60
    }

    // MARK: - Legendary Helpers

    var legendaryDrop: String {
        if case .legendary(let drop, _) = kind { return drop }
        return ""
    }

    var legendaryCondition: SpawnCondition {
        if case .legendary(_, let condition) = kind { return condition }
        return .timer(seconds: 300)
    }

    // MARK: - Behavior

    /// Returns the action to take given the current context.
    mutating func behavior(in context: EntityContext) -> EntityAction {
        switch kind {
        case .hostile:
            return hostileBehavior(in: context)
        case .passive:
            return passiveBehavior(in: context)
        case .legendary:
            return legendaryBehavior(in: context)
        }
    }

    private mutating func hostileBehavior(in context: EntityContext) -> EntityAction {
        let distToPlayer = hypot(position.x - context.playerPosition.x, position.y - context.playerPosition.y)

        // Attack if player is close and outside shelter
        if distToPlayer < 40 && !context.playerInShelter {
            lastAttackTime = context.tickDelta
            return .attack(targetId: UUID())
        }

        // Chase player if nearby but not in shelter
        if distToPlayer < hostilePatrolRadius && !context.playerInShelter {
            return .moveTo(context.playerPosition)
        }

        // Patrol behavior
        if let target = patrolTarget {
            let distToTarget = hypot(position.x - target.x, position.y - target.y)
            if distToTarget < 10 {
                // Pick new patrol target
                patrolTarget = randomPatrolPoint(center: position, radius: hostilePatrolRadius, bounds: context.worldBounds)
                return .moveTo(patrolTarget!)
            }
            return .moveTo(target)
        }

        patrolTarget = randomPatrolPoint(center: position, radius: hostilePatrolRadius, bounds: context.worldBounds)
        return patrolTarget.map { .moveTo($0) } ?? .idle
    }

    private mutating func passiveBehavior(in context: EntityContext) -> EntityAction {
        if isHarvested {
            respawnTimer += context.tickDelta
            if respawnTimer >= passiveRespawnTime {
                isHarvested = false
                position = originalPosition
                respawnTimer = 0
                return .spawn(at: originalPosition)
            }
            return .idle
        }
        return .idle
    }

    private mutating func legendaryBehavior(in context: EntityContext) -> EntityAction {
        if !isSpawned {
            spawnTimer += context.tickDelta
            // Spawn when timer exceeds (external conditions checked by scene)
            if spawnTimer >= 300 { // 5 minutes default
                isSpawned = true
                return .spawn(at: spawnPoint)
            }
            return .idle
        }

        // If player is close, they can collect
        let distToPlayer = hypot(position.x - context.playerPosition.x, position.y - context.playerPosition.y)
        if distToPlayer < 50 && !context.playerInShelter {
            return .harvest(targetId: id)
        }

        return .idle
    }

    // MARK: - Actions

    mutating func harvest() -> Int {
        guard isHarvestable else { return 0 }
        isHarvested = true
        respawnTimer = 0
        return passiveResourceYield
    }

    mutating func collectLegendaryDrop() -> String? {
        guard isSpawned else { return nil }
        isSpawned = false
        spawnTimer = 0
        return legendaryDrop
    }

    mutating func reset() {
        isHarvested = false
        isSpawned = false
        position = originalPosition
        respawnTimer = 0
        spawnTimer = 0
        patrolTarget = nil
    }

    private func randomPatrolPoint(center: CGPoint, radius: CGFloat, bounds: CGRect) -> CGPoint {
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let r = CGFloat.random(in: 0...radius)
        let x = center.x + cos(angle) * r
        let y = center.y + sin(angle) * r
        return CGPoint(
            x: min(max(x, bounds.minX + 20), bounds.maxX - 20),
            y: min(max(y, bounds.minY + 20), bounds.maxY - 20)
        )
    }
}

// MARK: - Entity Context

/// Context provided to entities when evaluating behavior each tick.
struct EntityContext {
    let playerPosition: CGPoint
    let playerInShelter: Bool
    let shelterCenter: CGPoint
    let shelterRadius: CGFloat
    let worldBounds: CGRect
    let tickDelta: TimeInterval
}

/// Actions an entity can take each tick.
enum EntityAction: Equatable {
    case idle
    case moveTo(CGPoint)
    case attack(targetId: UUID)
    case fleeFrom(CGPoint)
    case harvest(targetId: UUID)
    case despawn
    case spawn(at: CGPoint)
}
