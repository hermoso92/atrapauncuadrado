import SpriteKit

enum SquareKind: CaseIterable {
    case normal
    case fast
    case evasive
    case aggressive

    var fillColor: UIColor {
        switch self {
        case .normal:
            return Palette.stroke
        case .fast:
            return Palette.warning
        case .evasive:
            return UIColor(red: 0.60, green: 0.53, blue: 1.00, alpha: 1)
        case .aggressive:
            return Palette.danger
        }
    }

    var reward: Int {
        switch self {
        case .normal:
            10
        case .fast:
            14
        case .evasive:
            18
        case .aggressive:
            24
        }
    }

    var coins: Int {
        switch self {
        case .normal:
            2
        case .fast:
            3
        case .evasive:
            4
        case .aggressive:
            5
        }
    }

    var damage: CGFloat {
        switch self {
        case .aggressive:
            16
        default:
            0
        }
    }

    var speedMultiplier: CGFloat {
        switch self {
        case .normal:
            1
        case .fast:
            1.8
        case .evasive:
            1.15
        case .aggressive:
            1.35
        }
    }
}

final class SquareNode: SKShapeNode {
    let kind: SquareKind
    let sizeValue: CGFloat = 26
    var velocity: CGVector
    private(set) var health: CGFloat
    private var directionChangeTimer: TimeInterval = 0

    init(kind: SquareKind, position: CGPoint, velocity: CGVector) {
        self.kind = kind
        self.velocity = velocity
        self.health = kind.maxHealth
        super.init()

        let rect = CGRect(x: -sizeValue / 2, y: -sizeValue / 2, width: sizeValue, height: sizeValue)
        path = CGPath(rect: rect, transform: nil)
        self.position = position
        fillColor = kind.fillColor
        strokeColor = .white
        lineWidth = 1.5
        glowWidth = 2
        zPosition = 4
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var captureRadius: CGFloat {
        sizeValue * 0.85
    }

    @discardableResult
    func applyDamage(_ amount: CGFloat) -> Bool {
        health = max(0, health - amount)
        return health <= 0
    }

    func update(deltaTime: TimeInterval, currentTime: TimeInterval, playableRect: CGRect, obstacles: [ObstacleNode], playerPosition: CGPoint, speedMultiplier: CGFloat) {
        directionChangeTimer -= deltaTime

        if kind == .evasive && directionChangeTimer <= 0 {
            let away = CGVector(dx: position.x - playerPosition.x, dy: position.y - playerPosition.y).normalized
            let jitter = CGVector.randomUnit.scaled(by: GameConfig.squareBaseSpeed * 0.9)
            velocity = away.scaled(by: GameConfig.squareBaseSpeed * 1.3) + jitter
            directionChangeTimer = 0.8
        } else if kind == .aggressive {
            let chase = CGVector(dx: playerPosition.x - position.x, dy: playerPosition.y - position.y).normalized
            let desired = chase.scaled(by: GameConfig.squareBaseSpeed * 1.9 * speedMultiplier)
            velocity.dx += (desired.dx - velocity.dx) * CGFloat(deltaTime * 3.5)
            velocity.dy += (desired.dy - velocity.dy) * CGFloat(deltaTime * 3.5)
        } else if directionChangeTimer <= 0 {
            velocity.dx += CGFloat.random(in: -45...45)
            velocity.dy += CGFloat.random(in: -45...45)
            directionChangeTimer = Double.random(in: 0.9...1.7)
        }

        let limitedVelocity = velocity.clampedMagnitude(max: GameConfig.squareBaseSpeed * kind.speedMultiplier * speedMultiplier * 2.4)
        velocity = limitedVelocity
        position.x += velocity.dx * deltaTime
        position.y += velocity.dy * deltaTime

        let half = sizeValue / 2
        if position.x < playableRect.minX + half || position.x > playableRect.maxX - half {
            velocity.dx *= -1
            position.x = min(max(position.x, playableRect.minX + half), playableRect.maxX - half)
        }
        if position.y < playableRect.minY + half || position.y > playableRect.maxY - half {
            velocity.dy *= -1
            position.y = min(max(position.y, playableRect.minY + half), playableRect.maxY - half)
        }

        let frameRect = CGRect(x: position.x - half, y: position.y - half, width: sizeValue, height: sizeValue)
        if let obstacle = obstacles.first(where: { $0.obstacleRect.intersects(frameRect) }) {
            let center = CGPoint(x: obstacle.obstacleRect.midX, y: obstacle.obstacleRect.midY)
            let push = CGVector(dx: position.x - center.x, dy: position.y - center.y).normalized
            velocity.dx = push.dx * abs(velocity.dx + 40)
            velocity.dy = push.dy * abs(velocity.dy + 40)
            position.x += velocity.dx * deltaTime
            position.y += velocity.dy * deltaTime
        }
    }
}

private extension SquareKind {
    var maxHealth: CGFloat {
        switch self {
        case .normal:
            return 1
        case .fast:
            return 1
        case .evasive:
            return 1
        case .aggressive:
            return 34
        }
    }
}
