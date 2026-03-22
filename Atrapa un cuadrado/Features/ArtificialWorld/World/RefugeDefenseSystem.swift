import CoreGraphics
import Foundation

// MARK: - Refuge Defense System

/// Manages patrol enemies that protect the refuge when the player is outside.
final class RefugeDefenseSystem {
    private var patrolEntities: [Entity] = []
    private var patrolSpawnTimer: TimeInterval = 0
    private let patrolSpawnInterval: TimeInterval = 10 // seconds between spawns

    private let maxPatrols: Int
    private let patrolDamage: Double
    private let patrolPatrolRadius: CGFloat

    init(maxPatrols: Int = 3, patrolDamage: Double = 10, patrolPatrolRadius: CGFloat = 150) {
        self.maxPatrols = maxPatrols
        self.patrolDamage = patrolDamage
        self.patrolPatrolRadius = patrolPatrolRadius
    }

    // MARK: - State

    var activePatrolCount: Int {
        patrolEntities.count
    }

    var patrols: [Entity] {
        patrolEntities
    }

    // MARK: - Tick

    /// Updates the defense system. Returns damage to apply to player if hit.
    func tick(
        delta: TimeInterval,
        playerPosition: CGPoint,
        shelterCenter: CGPoint,
        shelterRadius: CGFloat,
        worldBounds: CGRect
    ) -> Double {
        let distToShelter = hypot(playerPosition.x - shelterCenter.x, playerPosition.y - shelterCenter.y)
        let playerInShelter = distToShelter < shelterRadius

        if playerInShelter {
            // Player is safe - return patrols to spawn
            return returnPatrols(to: shelterCenter, worldBounds: worldBounds)
        } else {
            // Player outside - activate patrols
            return activatePatrols(
                delta: delta,
                playerPosition: playerPosition,
                shelterCenter: shelterCenter
            )
        }
    }

    private func activatePatrols(
        delta: TimeInterval,
        playerPosition: CGPoint,
        shelterCenter: CGPoint
    ) -> Double {
        var damage: Double = 0

        // Spawn new patrols if needed
        if patrolEntities.count < maxPatrols {
            patrolSpawnTimer += delta
            if patrolSpawnTimer >= patrolSpawnInterval {
                let patrol = createPatrol(at: shelterCenter)
                patrolEntities.append(patrol)
                patrolSpawnTimer = 0
            }
        }

        // Update existing patrols
        for i in patrolEntities.indices {
            // Move toward player
            patrolEntities[i].position = moveToward(
                from: patrolEntities[i].position,
                target: playerPosition,
                speed: 60 * delta
            )

            // Check collision with player
            let dist = hypot(patrolEntities[i].position.x - playerPosition.x,
                           patrolEntities[i].position.y - playerPosition.y)
            if dist < 30 {
                damage += patrolDamage
            }
        }

        return damage
    }

    private func returnPatrols(to shelterCenter: CGPoint, worldBounds: CGRect) -> Double {
        // Move patrols back to shelter and remove if close enough
        var toRemove: [Int] = []

        for i in patrolEntities.indices {
            let dist = hypot(patrolEntities[i].position.x - shelterCenter.x,
                           patrolEntities[i].position.y - shelterCenter.y)

            if dist < 50 {
                toRemove.append(i)
            } else {
                patrolEntities[i].position = moveToward(
                    from: patrolEntities[i].position,
                    target: shelterCenter,
                    speed: 100 * (1.0 / 60.0) // Slower return
                )
            }
        }

        // Remove patrols that returned
        for i in toRemove.reversed() {
            patrolEntities.remove(at: i)
        }

        return 0 // No damage when player is in shelter
    }

    // MARK: - Spawn

    private func createPatrol(at position: CGPoint) -> Entity {
        Entity(
            id: UUID(),
            position: position,
            kind: .hostile(damage: patrolDamage, patrolRadius: patrolPatrolRadius)
        )
    }

    // MARK: - Helpers

    private func moveToward(from: CGPoint, target: CGPoint, speed: CGFloat) -> CGPoint {
        let dx = target.x - from.x
        let dy = target.y - from.y
        let dist = hypot(dx, dy)

        if dist < speed {
            return target
        }

        let ratio = speed / dist
        return CGPoint(
            x: from.x + dx * ratio,
            y: from.y + dy * ratio
        )
    }

    // MARK: - Reset

    /// Resets all patrols (called on new session).
    func reset() {
        patrolEntities.removeAll()
        patrolSpawnTimer = 0
    }

    /// Clears all patrols immediately.
    func clear() {
        patrolEntities.removeAll()
    }
}

// MARK: - Default Configuration

extension RefugeDefenseSystem {
    static let defaultConfig = (
        maxPatrols: 3,
        patrolDamage: 10.0,
        patrolPatrolRadius: 150.0,
        patrolSpawnInterval: 10.0
    )
}
