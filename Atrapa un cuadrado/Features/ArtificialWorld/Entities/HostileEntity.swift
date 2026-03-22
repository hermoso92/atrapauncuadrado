import CoreGraphics
import Foundation

// MARK: - Hostile Entity Factory

/// Factory for creating hostile entities.
enum HostileEntityFactory {
    /// Creates a new hostile entity at the given position.
    static func create(
        at position: CGPoint,
        damage: Double = 15,
        patrolRadius: CGFloat = 120
    ) -> Entity {
        Entity(
            id: UUID(),
            position: position,
            kind: .hostile(damage: damage, patrolRadius: patrolRadius)
        )
    }

    /// Creates multiple hostile entities in the given bounds.
    static func createBatch(
        count: Int,
        in bounds: CGRect,
        damage: Double = 15,
        patrolRadius: CGFloat = 120
    ) -> [Entity] {
        (0..<count).map { _ in
            create(
                at: randomPosition(in: bounds),
                damage: damage,
                patrolRadius: patrolRadius
            )
        }
    }

    private static func randomPosition(in bounds: CGRect) -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: bounds.minX...bounds.maxX),
            y: CGFloat.random(in: bounds.minY...bounds.maxY)
        )
    }
}

// MARK: - Hostile Behavior Helpers

extension Entity {
    /// Calculates damage if this entity attacks.
    var attackDamage: Double {
        hostileDamage
    }

    /// Whether this entity can attack the player.
    func canAttackPlayer(at playerPosition: CGPoint, playerInShelter: Bool) -> Bool {
        guard isHostile else { return false }
        let distToPlayer = hypot(position.x - playerPosition.x, position.y - playerPosition.y)
        return distToPlayer < 40 && !playerInShelter
    }
}
