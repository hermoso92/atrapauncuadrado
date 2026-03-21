import SpriteKit

final class PlayerNode: SKNode {
    let definition: CharacterDefinition
    let radius: CGFloat

    private let avatarContainer = SKNode()
    private let shieldRing = SKShapeNode(circleOfRadius: GameConfig.playerRadius + 10)
    private let trail = SKEmitterNode()

    private(set) var health: CGFloat = GameConfig.playerMaxHealth
    private(set) var currentVelocity: CGVector = .zero
    private var dashEndsAt: TimeInterval = 0
    private var magnetEndsAt: TimeInterval = 0
    private var shieldEndsAt: TimeInterval = 0
    private var overdriveEndsAt: TimeInterval = 0
    private var abilityCooldowns: [AbilityType: TimeInterval] = [:]

    init(definition: CharacterDefinition) {
        self.definition = definition
        self.radius = GameConfig.playerRadius
        super.init()

        zPosition = 5
        setupAvatar()
        setupTrail()
        setupShieldRing()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isShieldActive: Bool {
        shieldEndsAt > 0
    }

    var isDashActive: Bool {
        dashEndsAt > 0
    }

    var isMagnetActive: Bool {
        magnetEndsAt > 0
    }

    var isOverdriveActive: Bool {
        overdriveEndsAt > 0
    }

    var magnetRange: CGFloat {
        radius * 5.5 * definition.magnetRangeMultiplier
    }

    func update(
        deltaTime: TimeInterval,
        currentTime: TimeInterval,
        target: CGPoint?,
        movementVector: CGVector?,
        playableRect: CGRect,
        obstacles: [ObstacleNode]
    ) {
        if currentTime >= dashEndsAt {
            dashEndsAt = 0
        }
        if currentTime >= magnetEndsAt {
            magnetEndsAt = 0
        }
        if currentTime >= shieldEndsAt {
            shieldEndsAt = 0
        }
        if currentTime >= overdriveEndsAt {
            overdriveEndsAt = 0
        }

        shieldRing.isHidden = !isShieldActive
        trail.particleBirthRate = dashEndsAt > 0 || overdriveEndsAt > 0 ? 70 : 16

        let speedBoost: CGFloat = dashEndsAt > 0 ? 2.35 : (overdriveEndsAt > 0 ? 1.35 : 1)
        let maxSpeed = GameConfig.playerBaseSpeed * definition.speedMultiplier * speedBoost

        if let movementVector {
            let magnitude = min(1, hypot(movementVector.dx, movementVector.dy))
            if magnitude > 0.08 {
                let normalized = magnitude > 0
                    ? CGVector(dx: movementVector.dx / magnitude, dy: movementVector.dy / magnitude)
                    : .zero
                let desiredVelocity = CGVector(
                    dx: normalized.dx * maxSpeed * magnitude,
                    dy: normalized.dy * maxSpeed * magnitude
                )
                currentVelocity.dx += (desiredVelocity.dx - currentVelocity.dx) * min(1, CGFloat(deltaTime * 13.5))
                currentVelocity.dy += (desiredVelocity.dy - currentVelocity.dy) * min(1, CGFloat(deltaTime * 13.5))
            } else {
                currentVelocity.dx *= 0.58
                currentVelocity.dy *= 0.58
            }
        } else if let target {
            let vector = CGVector(dx: target.x - position.x, dy: target.y - position.y)
            let distance = hypot(vector.dx, vector.dy)
            if distance > GameConfig.touchDeadZone {
                let normalized = CGVector(dx: vector.dx / distance, dy: vector.dy / distance)
                let speedFactor = min(1, max(0.16, distance / GameConfig.touchSnapDistance))
                let desiredVelocity = CGVector(dx: normalized.dx * maxSpeed * speedFactor, dy: normalized.dy * maxSpeed * speedFactor)
                currentVelocity.dx += (desiredVelocity.dx - currentVelocity.dx) * min(1, CGFloat(deltaTime * 13.5))
                currentVelocity.dy += (desiredVelocity.dy - currentVelocity.dy) * min(1, CGFloat(deltaTime * 13.5))
            } else {
                currentVelocity.dx *= 0.58
                currentVelocity.dy *= 0.58
            }
        } else {
            currentVelocity.dx *= 0.80
            currentVelocity.dy *= 0.80
        }

        let proposedPosition = CGPoint(
            x: position.x + currentVelocity.dx * deltaTime,
            y: position.y + currentVelocity.dy * deltaTime
        )

        position = resolveMovement(to: proposedPosition, playableRect: playableRect, obstacles: obstacles)
    }

    func canActivate(_ ability: AbilityType, currentTime: TimeInterval, ownedAbilities: Set<AbilityType>) -> Bool {
        guard ownedAbilities.contains(ability) else {
            return false
        }
        return currentTime >= (abilityCooldowns[ability] ?? 0)
    }

    func activate(_ ability: AbilityType, currentTime: TimeInterval) {
        switch ability {
        case .dash:
            dashEndsAt = currentTime + GameConfig.dashDuration
            abilityCooldowns[ability] = currentTime + GameConfig.dashCooldown
        case .magnet:
            magnetEndsAt = currentTime + GameConfig.magnetDuration
            abilityCooldowns[ability] = currentTime + GameConfig.magnetCooldown
        case .shield:
            shieldEndsAt = currentTime + GameConfig.shieldDuration
            abilityCooldowns[ability] = currentTime + GameConfig.shieldCooldown
        case .pulse:
            abilityCooldowns[ability] = currentTime + GameConfig.pulseCooldown
        case .overdrive:
            overdriveEndsAt = currentTime + GameConfig.overdriveDuration
            abilityCooldowns[ability] = currentTime + GameConfig.overdriveCooldown
        }
    }

    func cooldownProgress(for ability: AbilityType, currentTime: TimeInterval) -> CGFloat {
        let endTime = abilityCooldowns[ability] ?? 0
        guard currentTime < endTime else {
            return 0
        }

        let totalDuration: TimeInterval
        switch ability {
        case .dash:
            totalDuration = GameConfig.dashCooldown
        case .magnet:
            totalDuration = GameConfig.magnetCooldown
        case .shield:
            totalDuration = GameConfig.shieldCooldown
        case .pulse:
            totalDuration = GameConfig.pulseCooldown
        case .overdrive:
            totalDuration = GameConfig.overdriveCooldown
        }

        return CGFloat((endTime - currentTime) / totalDuration)
    }

    func remainingCooldown(for ability: AbilityType, currentTime: TimeInterval) -> TimeInterval {
        max(0, (abilityCooldowns[ability] ?? 0) - currentTime)
    }

    func visualState(for ability: AbilityType, currentTime: TimeInterval, ownedAbilities: Set<AbilityType>) -> AbilityVisualState {
        guard ownedAbilities.contains(ability) else {
            return .locked
        }

        switch ability {
        case .dash where dashEndsAt > currentTime:
            return .active
        case .magnet where magnetEndsAt > currentTime:
            return .active
        case .shield where shieldEndsAt > currentTime:
            return .active
        case .overdrive where overdriveEndsAt > currentTime:
            return .active
        default:
            return canActivate(ability, currentTime: currentTime, ownedAbilities: ownedAbilities) ? .ready : .coolingDown
        }
    }

    @discardableResult
    func applyDamage(_ amount: CGFloat) -> Bool {
        guard !isShieldActive else {
            return false
        }
        health = max(0, health - amount)
        run(.sequence([
            .fadeAlpha(to: 0.35, duration: GameConfig.damageFlashDuration),
            .fadeAlpha(to: 1, duration: GameConfig.damageFlashDuration)
        ]))
        return true
    }

    func restoreFullHealth() {
        health = GameConfig.playerMaxHealth
    }

    func repel(from point: CGPoint, force: CGFloat) {
        let direction = CGVector(dx: position.x - point.x, dy: position.y - point.y).normalized
        currentVelocity.dx += direction.dx * force
        currentVelocity.dy += direction.dy * force
    }

    func applyDashImpulse(direction: CGVector?) {
        let sourceVector: CGVector
        if let direction, (direction.dx != 0 || direction.dy != 0) {
            sourceVector = direction.normalized
        } else if currentVelocity.dx != 0 || currentVelocity.dy != 0 {
            sourceVector = currentVelocity.normalized
        } else {
            sourceVector = CGVector(dx: 1, dy: 0)
        }

        let impulse = GameConfig.playerBaseSpeed * 1.95 * definition.speedMultiplier
        currentVelocity.dx = sourceVector.dx * impulse
        currentVelocity.dy = sourceVector.dy * impulse
    }

    private func setupAvatar() {
        addChild(avatarContainer)

        switch definition.style {
        case .circle:
            let outer = SKShapeNode(circleOfRadius: radius)
            outer.fillColor = definition.primaryColor
            outer.strokeColor = .white
            outer.lineWidth = 2
            avatarContainer.addChild(outer)

            let core = SKShapeNode(circleOfRadius: radius * 0.42)
            core.fillColor = definition.secondaryColor.withAlphaComponent(0.28)
            core.strokeColor = .clear
            avatarContainer.addChild(core)
        case .stickman:
            let head = SKShapeNode(circleOfRadius: radius * 0.38)
            head.fillColor = .clear
            head.strokeColor = definition.primaryColor
            head.lineWidth = 3
            head.position = CGPoint(x: 0, y: radius * 0.82)
            avatarContainer.addChild(head)

            let bodyPath = CGMutablePath()
            bodyPath.move(to: CGPoint(x: 0, y: radius * 0.4))
            bodyPath.addLine(to: CGPoint(x: 0, y: -radius * 0.7))
            bodyPath.move(to: CGPoint(x: -radius * 0.7, y: 0))
            bodyPath.addLine(to: CGPoint(x: radius * 0.7, y: 0))
            bodyPath.move(to: CGPoint(x: 0, y: -radius * 0.7))
            bodyPath.addLine(to: CGPoint(x: -radius * 0.55, y: -radius * 1.4))
            bodyPath.move(to: CGPoint(x: 0, y: -radius * 0.7))
            bodyPath.addLine(to: CGPoint(x: radius * 0.55, y: -radius * 1.4))

            let body = SKShapeNode(path: bodyPath)
            body.strokeColor = definition.primaryColor
            body.lineWidth = 3
            body.lineCap = .round
            avatarContainer.addChild(body)
        case .diamond:
            let diamondPath = CGMutablePath()
            diamondPath.move(to: CGPoint(x: 0, y: radius * 1.2))
            diamondPath.addLine(to: CGPoint(x: radius * 1.1, y: 0))
            diamondPath.addLine(to: CGPoint(x: 0, y: -radius * 1.2))
            diamondPath.addLine(to: CGPoint(x: -radius * 1.1, y: 0))
            diamondPath.closeSubpath()

            let diamond = SKShapeNode(path: diamondPath)
            diamond.fillColor = definition.primaryColor
            diamond.strokeColor = definition.secondaryColor
            diamond.lineWidth = 2
            avatarContainer.addChild(diamond)

            let core = SKShapeNode(circleOfRadius: radius * 0.28)
            core.fillColor = definition.secondaryColor
            core.strokeColor = .clear
            avatarContainer.addChild(core)
        }
    }

    private func setupShieldRing() {
        shieldRing.strokeColor = Palette.success
        shieldRing.lineWidth = 3
        shieldRing.glowWidth = 3
        shieldRing.fillColor = .clear
        shieldRing.isHidden = true
        addChild(shieldRing)
    }

    private func setupTrail() {
        trail.particleTexture = nil
        trail.particleBirthRate = 0
        trail.particleLifetime = 0.3
        trail.particleScale = 0.09
        trail.particleScaleRange = 0.05
        trail.particleAlphaSpeed = -3
        trail.particleSpeed = 0
        trail.particlePositionRange = CGVector(dx: radius * 0.4, dy: radius * 0.4)
        trail.particleColor = definition.primaryColor
        trail.targetNode = parent
        trail.zPosition = -1
        addChild(trail)
    }

    private func resolveMovement(to proposedPosition: CGPoint, playableRect: CGRect, obstacles: [ObstacleNode]) -> CGPoint {
        let clamped = CGPoint(
            x: min(max(proposedPosition.x, playableRect.minX + radius), playableRect.maxX - radius),
            y: min(max(proposedPosition.y, playableRect.minY + radius), playableRect.maxY - radius)
        )

        let fullRect = CGRect(
            x: clamped.x - radius,
            y: clamped.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        if obstacles.contains(where: { $0.obstacleRect.intersects(fullRect) }) {
            let xOnly = CGPoint(x: clamped.x, y: position.y)
            let xRect = CGRect(x: xOnly.x - radius, y: xOnly.y - radius, width: radius * 2, height: radius * 2)
            if !obstacles.contains(where: { $0.obstacleRect.intersects(xRect) }) {
                currentVelocity.dy = 0
                return xOnly
            }

            let yOnly = CGPoint(x: position.x, y: clamped.y)
            let yRect = CGRect(x: yOnly.x - radius, y: yOnly.y - radius, width: radius * 2, height: radius * 2)
            if !obstacles.contains(where: { $0.obstacleRect.intersects(yRect) }) {
                currentVelocity.dx = 0
                return yOnly
            }

            let nudged = nudgedEscapePosition(from: clamped, playableRect: playableRect, obstacles: obstacles)
            if nudged != position {
                currentVelocity.dx *= 0.25
                currentVelocity.dy *= 0.25
                return nudged
            }

            currentVelocity = .zero
            return position
        }

        return clamped
    }

    private func nudgedEscapePosition(from point: CGPoint, playableRect: CGRect, obstacles: [ObstacleNode]) -> CGPoint {
        let offsets: [CGVector] = [
            CGVector(dx: 18, dy: 0),
            CGVector(dx: -18, dy: 0),
            CGVector(dx: 0, dy: 18),
            CGVector(dx: 0, dy: -18),
            CGVector(dx: 14, dy: 14),
            CGVector(dx: -14, dy: 14),
            CGVector(dx: 14, dy: -14),
            CGVector(dx: -14, dy: -14),
        ]

        for offset in offsets {
            let candidate = CGPoint(
                x: min(max(point.x + offset.dx, playableRect.minX + radius), playableRect.maxX - radius),
                y: min(max(point.y + offset.dy, playableRect.minY + radius), playableRect.maxY - radius)
            )
            let candidateRect = CGRect(
                x: candidate.x - radius,
                y: candidate.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            if !obstacles.contains(where: { $0.obstacleRect.intersects(candidateRect) }) {
                return candidate
            }
        }

        return position
    }
}
