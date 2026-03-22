import SpriteKit

private final class ProjectileNode: SKShapeNode {
    var velocity: CGVector
    var damage: CGFloat
    var remainingLifetime: TimeInterval
    var hitsRemaining: Int

    init(color: UIColor, velocity: CGVector, damage: CGFloat, lifetime: TimeInterval, hitsRemaining: Int) {
        self.velocity = velocity
        self.damage = damage
        self.remainingLifetime = lifetime
        self.hitsRemaining = hitsRemaining
        super.init()

        path = CGPath(ellipseIn: CGRect(x: -6, y: -6, width: 12, height: 12), transform: nil)
        fillColor = color
        strokeColor = .white
        lineWidth = 1.2
        glowWidth = 2
        zPosition = 7
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class GameScene: BaseScene {
    private enum State {
        case active
        case pausedMenu
        case gameOver
    }

    private enum ActiveTouchRole {
        case movement
    }

    private let profile: GameModeProfile
    private let worldNode = SKNode()
    private let hudNode = SKNode()
    private let pauseOverlay = SKNode()
    private let targetIndicator = SKShapeNode(circleOfRadius: GameConfig.reticleRadius)
    private let statusLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
    private let dangerPulse = SKShapeNode(rect: .zero, cornerRadius: 0)
    private let joystickBase = SKShapeNode(circleOfRadius: GameConfig.joystickBaseRadius)
    private let joystickKnob = SKShapeNode(circleOfRadius: GameConfig.joystickKnobRadius)

    private var player: PlayerNode!
    private var progress = GameProgress.defaultProgress
    private var squares: [SquareNode] = []
    private var projectiles: [ProjectileNode] = []
    private var obstacles: [ObstacleNode] = []
    private var targetPoint: CGPoint?
    private var state: State = .active
    private var lastUpdateTime: TimeInterval = 0
    private var elapsedTime: TimeInterval = 0
    private var runTimers: ArcadeRunTimersState
    private var score = 0
    private var coinsEarned = 0
    private var damageCooldownEndsAt: TimeInterval = 0
    private var weaponCooldownEndsAt: TimeInterval = 0
    private var autoFireEndsAt: TimeInterval = 0
    private var lastAutoFireAt: TimeInterval = 0
    private var gameOverSaved = false
    private var activeTouches: [ObjectIdentifier: ActiveTouchRole] = [:]
    private var joystickVector: CGVector = .zero

    private let scoreLabel = SKLabelNode(fontNamed: GameConfig.titleFont)
    private let coinsLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
    private let roundLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
    private let modeLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
    private let comboLabel = SKLabelNode(fontNamed: GameConfig.titleFont)
    private let topHUDPanel = SKShapeNode(rectOf: .zero, cornerRadius: 0)
    private let bottomHUDPanel = SKShapeNode(rectOf: .zero, cornerRadius: 0)
    private let healthBar = SKShapeNode(rectOf: CGSize(width: 170, height: 16), cornerRadius: 8)
    private let healthFill = SKShapeNode(rectOf: CGSize(width: 166, height: 12), cornerRadius: 6)
    private var abilityButtons: [AbilityType: MenuButtonNode] = [:]
    private var attackButton: MenuButtonNode?
    private var comboCount = 0
    private var comboExpiresAt: TimeInterval = 0
    private var playableRect: CGRect {
        CGRect(
            x: GameConfig.worldInset,
            y: 118,
            width: size.width - (GameConfig.worldInset * 2),
            height: size.height - 246
        )
    }

    private var usesStickmanControls: Bool {
        profile.mode != .original && player?.definition.style == .stickman
    }

    private var joystickCenter: CGPoint {
        CGPoint(x: 92, y: 94)
    }

    private var joystickActivationRadius: CGFloat {
        GameConfig.joystickBaseRadius + GameConfig.joystickActivationPadding
    }

    private var isGodRun: Bool {
        progress.godModeEnabled
    }

    private var soundscape: SoundManager.Soundscape {
        switch profile.mode {
        case .original:
            .arcadeRun
        case .evolution:
            .evolutionRun
        case .ghost:
            .ghostRun
        }
    }

    init(sceneSize: CGSize, gameMode: GameMode, dependencies: SceneDependencies? = nil) {
        self.profile = GameModeProfile.profile(for: gameMode)
        self.runTimers = ArcadeRunTimersState(spawnInterval: profile.initialSpawnInterval, round: profile.startingRound)
        super.init(sceneSize: sceneSize, gameMode: gameMode, dependencies: dependencies)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        progress = saveManager.loadProgress()
        soundManager.playSoundscape(soundscape)
        buildScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        if player != nil {
            let preservedPosition = player.position
            soundManager.playSoundscape(soundscape)
            buildScene()
            player.position = CGPoint(
                x: min(max(preservedPosition.x, playableRect.minX + player.radius), playableRect.maxX - player.radius),
                y: min(max(preservedPosition.y, playableRect.minY + player.radius), playableRect.maxY - player.radius)
            )
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard state == .active else {
            lastUpdateTime = currentTime
            return
        }

        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let deltaTime = min(1.0 / 25.0, currentTime - lastUpdateTime)
        lastUpdateTime = currentTime
        elapsedTime += deltaTime
        if comboCount > 0, currentTime > comboExpiresAt {
            resetCombo(showStatusMessage: comboCount >= 4)
        }

        if isGodRun, player.health < GameConfig.playerMaxHealth {
            player.restoreFullHealth()
        }

        player.update(
            deltaTime: deltaTime,
            currentTime: currentTime,
            target: targetPoint,
            movementVector: usesStickmanControls ? joystickVector : nil,
            playableRect: playableRect,
            obstacles: obstacles
        )

        for square in squares {
            if profile.enabledAbilities.contains(.magnet), player.isMagnetActive {
                let distance = hypot(square.position.x - player.position.x, square.position.y - player.position.y)
                if distance < player.magnetRange {
                    let pull = CGVector(dx: player.position.x - square.position.x, dy: player.position.y - square.position.y).normalized
                    square.velocity.dx += pull.dx * 120 * deltaTime
                    square.velocity.dy += pull.dy * 120 * deltaTime
                }
            }

            square.update(
                deltaTime: deltaTime,
                currentTime: currentTime,
                playableRect: playableRect,
                obstacles: obstacles,
                playerPosition: player.position,
                speedMultiplier: runTimers.squareSpeedMultiplier
            )
        }

        updateProjectiles(deltaTime: deltaTime)
        handleAutoFire(currentTime: currentTime)
        handleSquareInteractions(currentTime: currentTime)
        let tick = runTimers.advance(deltaTime: deltaTime, profile: profile, squareCount: squares.count)
        if tick.shouldSpawn {
            spawnSquare()
        }
        if tick.shouldStepDifficulty {
            increaseDifficulty()
        }

        updateHUD(currentTime: currentTime)

        if player.health <= 0 {
            triggerGameOver()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let currentTime = lastUpdateTime == 0 ? CACurrentMediaTime() : lastUpdateTime
        for touch in touches {
            let location = touch.location(in: self)
            if let button = button(at: location) {
                handleButton(button, currentTime: currentTime)
                continue
            }

            guard state == .active else {
                continue
            }

            if usesStickmanControls {
                handleStickmanTouchBegan(touch, location: location, currentTime: currentTime)
            } else if playableRect.contains(location) {
                targetPoint = location
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard state == .active else {
            return
        }

        if usesStickmanControls {
            for touch in touches {
                let touchID = ObjectIdentifier(touch)
                guard activeTouches[touchID] == .movement else {
                    continue
                }
                updateJoystick(with: touch.location(in: self))
            }
            return
        }

        guard let location = touches.first?.location(in: self),
              playableRect.contains(location) else {
            return
        }
        targetPoint = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if usesStickmanControls {
            for touch in touches {
                releaseTouch(touch)
            }
            return
        }

        if state == .active, let location = touches.first?.location(in: self), playableRect.contains(location) {
            targetPoint = location
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard usesStickmanControls else {
            return
        }
        for touch in touches {
            releaseTouch(touch)
        }
    }

    private func buildScene() {
        removeAllChildren()
        squares.removeAll()
        projectiles.removeAll()
        obstacles.removeAll()
        abilityButtons.removeAll()
        attackButton = nil
        state = .active
        score = 0
        coinsEarned = 0
        runTimers = ArcadeRunTimersState(spawnInterval: profile.initialSpawnInterval, round: profile.startingRound)
        elapsedTime = 0
        damageCooldownEndsAt = 0
        weaponCooldownEndsAt = 0
        autoFireEndsAt = 0
        lastAutoFireAt = 0
        gameOverSaved = false
        targetPoint = nil
        lastUpdateTime = 0
        joystickVector = .zero
        activeTouches.removeAll()
        comboCount = 0
        comboExpiresAt = 0

        setupBackdrop(title: "", subtitle: "", playsMenuSoundscape: false)
        addChild(worldNode)
        addChild(hudNode)
        addChild(pauseOverlay)
        addChild(dangerPulse)
        worldNode.removeAllChildren()
        hudNode.removeAllChildren()
        pauseOverlay.removeAllChildren()

        buildArena()
        buildPlayer()
        buildHUD()
        buildJoystickIfNeeded()
        buildPauseOverlay()
        buildOverlayFeedback()

        for _ in 0..<profile.initialSquares {
            spawnSquare()
        }
        if profile.mode != .original, squares.allSatisfy({ $0.kind != .aggressive }) {
            spawnSquare(kind: .aggressive)
        }

        showStatus(startingStatusMessage, color: Palette.textSecondary)
    }

    private func buildArena() {
        let frameNode = SKShapeNode(rect: playableRect, cornerRadius: profile.arenaCornerRadius)
        frameNode.fillColor = profile.arenaFillColor
        frameNode.strokeColor = profile.arenaStrokeColor
        frameNode.lineWidth = profile.arenaLineWidth
        frameNode.glowWidth = profile.arenaGlowWidth
        worldNode.addChild(frameNode)

        if profile.allowsObstacles {
            buildObstacles()
        }

        targetIndicator.strokeColor = profile.targetIndicatorColor
        targetIndicator.lineWidth = 2
        targetIndicator.fillColor = profile.targetIndicatorColor.withAlphaComponent(0.08)
        targetIndicator.zPosition = 3
        targetIndicator.isHidden = true
        worldNode.addChild(targetIndicator)
    }

    private func buildPlayer() {
        let definition: CharacterDefinition
        if profile.mode == .original {
            definition = .classicCircle
        } else {
            definition = CharacterDefinition.definition(for: progress.selectedCharacterID(for: profile.mode))
        }

        player = PlayerNode(definition: definition)
        player.position = safePlayerSpawnPosition()
        player.restoreFullHealth()
        worldNode.addChild(player)
    }

    private func buildHUD() {
        topHUDPanel.path = CGPath(roundedRect: CGRect(x: 18, y: size.height - 146, width: size.width - 36, height: 96), cornerWidth: 28, cornerHeight: 28, transform: nil)
        topHUDPanel.fillColor = Palette.panel.withAlphaComponent(0.84)
        topHUDPanel.strokeColor = profile.modeAccentColor.withAlphaComponent(0.55)
        topHUDPanel.lineWidth = 1.5
        topHUDPanel.glowWidth = profile.mode == .original ? 0 : 2
        topHUDPanel.zPosition = 4
        hudNode.addChild(topHUDPanel)

        scoreLabel.fontSize = 28
        scoreLabel.fontColor = Palette.textPrimary
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 28, y: size.height - 76)
        scoreLabel.zPosition = 6
        hudNode.addChild(scoreLabel)

        coinsLabel.fontSize = 14
        coinsLabel.fontColor = Palette.warning
        coinsLabel.horizontalAlignmentMode = .left
        coinsLabel.position = CGPoint(x: 28, y: size.height - 104)
        coinsLabel.zPosition = 6
        hudNode.addChild(coinsLabel)

        roundLabel.fontSize = 14
        roundLabel.fontColor = Palette.textSecondary
        roundLabel.horizontalAlignmentMode = .left
        roundLabel.position = CGPoint(x: 28, y: size.height - 126)
        roundLabel.zPosition = 6
        hudNode.addChild(roundLabel)

        statusLabel.fontSize = 13
        statusLabel.fontColor = Palette.textSecondary
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height - 120)
        statusLabel.zPosition = 15
        hudNode.addChild(statusLabel)

        comboLabel.fontSize = 18
        comboLabel.fontColor = Palette.warning
        comboLabel.horizontalAlignmentMode = .right
        comboLabel.position = CGPoint(x: size.width - 28, y: size.height - 74)
        comboLabel.alpha = 0
        hudNode.addChild(comboLabel)

        modeLabel.fontSize = 12
        modeLabel.fontColor = profile.modeAccentColor
        modeLabel.horizontalAlignmentMode = .left
        modeLabel.position = CGPoint(x: 28, y: 66)
        modeLabel.zPosition = 6
        hudNode.addChild(modeLabel)

        bottomHUDPanel.path = CGPath(roundedRect: CGRect(x: 18, y: 18, width: size.width - 36, height: 66), cornerWidth: 24, cornerHeight: 24, transform: nil)
        bottomHUDPanel.fillColor = Palette.panel.withAlphaComponent(0.78)
        bottomHUDPanel.strokeColor = profile.modeAccentColor.withAlphaComponent(0.35)
        bottomHUDPanel.lineWidth = 1
        bottomHUDPanel.zPosition = 4
        hudNode.addChild(bottomHUDPanel)

        let pauseButton = MenuButtonNode(
            actionID: "pause",
            title: isGodRun ? "CTRL" : "II",
            subtitle: isGodRun ? "God" : nil,
            size: CGSize(width: isGodRun ? 72 : 56, height: 56)
        )
        pauseButton.position = CGPoint(x: size.width - 46, y: size.height - 88)
        pauseButton.zPosition = 30
        hudNode.addChild(pauseButton)

        healthBar.fillColor = Palette.panel
        healthBar.strokeColor = Palette.danger
        healthBar.lineWidth = 2
        healthBar.position = CGPoint(x: size.width - 126, y: size.height - 122)
        healthBar.zPosition = 10
        hudNode.addChild(healthBar)

        healthFill.fillColor = Palette.success
        healthFill.strokeColor = .clear
        healthFill.position = CGPoint.zero
        healthBar.addChild(healthFill)

        let abilities = availableAbilities
        let abilitiesStartX: CGFloat = usesStickmanControls ? 166 : 62
        for (index, ability) in abilities.enumerated() {
            let button = MenuButtonNode(actionID: "ability.\(ability.rawValue)", title: ability.title, subtitle: nil, size: CGSize(width: 88, height: 50))
            button.position = CGPoint(x: abilitiesStartX + CGFloat(index) * 96, y: 42)
            button.zPosition = 6
            hudNode.addChild(button)
            abilityButtons[ability] = button
        }

        if profile.mode != .original, !usesStickmanControls {
            let attackButton = MenuButtonNode(actionID: "attack", title: currentWeapon.title, subtitle: "Fuego", size: CGSize(width: 96, height: 56))
            attackButton.position = CGPoint(x: size.width - 62, y: 42)
            attackButton.zPosition = 25
            hudNode.addChild(attackButton)
            self.attackButton = attackButton
        }

        updateHUD(currentTime: 0)
    }

    private func buildJoystickIfNeeded() {
        joystickBase.removeFromParent()
        joystickKnob.removeFromParent()

        guard usesStickmanControls else {
            return
        }

        joystickBase.fillColor = Palette.panel.withAlphaComponent(0.78)
        joystickBase.strokeColor = Palette.stroke
        joystickBase.lineWidth = 2
        joystickBase.zPosition = 24
        joystickBase.position = joystickCenter
        hudNode.addChild(joystickBase)

        joystickKnob.fillColor = Palette.stroke.withAlphaComponent(0.28)
        joystickKnob.strokeColor = Palette.textPrimary
        joystickKnob.lineWidth = 2
        joystickKnob.zPosition = 25
        joystickKnob.position = joystickCenter
        hudNode.addChild(joystickKnob)
    }

    private func buildOverlayFeedback() {
        dangerPulse.path = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
        dangerPulse.fillColor = .clear
        dangerPulse.strokeColor = .clear
        dangerPulse.zPosition = 90
    }

    private func buildPauseOverlay() {
        let dim = SKShapeNode(rectOf: size, cornerRadius: 0)
        dim.fillColor = UIColor.black.withAlphaComponent(0.55)
        dim.strokeColor = .clear
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        pauseOverlay.addChild(dim)

        let panel = SKShapeNode(rectOf: CGSize(width: size.width - 62, height: isGodRun ? 286 : 228), cornerRadius: 32)
        panel.fillColor = Palette.panel.withAlphaComponent(0.96)
        panel.strokeColor = profile.pauseStrokeColor
        panel.lineWidth = 2
        panel.glowWidth = 4
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        pauseOverlay.addChild(panel)

        let badge = SKShapeNode(rectOf: CGSize(width: 164, height: 28), cornerRadius: 14)
        badge.fillColor = profile.pauseStrokeColor.withAlphaComponent(0.12)
        badge.strokeColor = profile.pauseStrokeColor.withAlphaComponent(0.5)
        badge.lineWidth = 1.2
        badge.position = CGPoint(x: size.width / 2, y: size.height / 2 + (isGodRun ? 102 : 88))
        pauseOverlay.addChild(badge)

        let badgeLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
        badgeLabel.text = isGodRun ? "MODO DIOS" : "RUN EN PAUSA"
        badgeLabel.fontSize = 10
        badgeLabel.fontColor = profile.pauseStrokeColor
        badgeLabel.position = CGPoint(x: 0, y: 8)
        badge.addChild(badgeLabel)

        let title = SKLabelNode(fontNamed: GameConfig.titleFont)
        title.text = isGodRun ? "CONTROL TOTAL" : "PAUSA \(gameMode?.title.uppercased() ?? "")"
        title.fontSize = 30
        title.fontColor = Palette.textPrimary
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + (isGodRun ? 64 : 52))
        pauseOverlay.addChild(title)

        let subtitle = SKLabelNode(fontNamed: GameConfig.coinFont)
        subtitle.text = isGodRun ? "Manipula la run o sal limpio guardando progreso." : "Respira, revisa la situacion y vuelve cuando quieras."
        subtitle.fontSize = 12
        subtitle.fontColor = Palette.textSecondary
        subtitle.preferredMaxLayoutWidth = size.width - 140
        subtitle.numberOfLines = 2
        subtitle.lineBreakMode = .byWordWrapping
        subtitle.verticalAlignmentMode = .top
        subtitle.position = CGPoint(x: size.width / 2, y: size.height / 2 + 18)
        pauseOverlay.addChild(subtitle)

        let resume = MenuButtonNode(actionID: "resume", title: "Reanudar", subtitle: "Seguir la partida")
        resume.position = CGPoint(x: size.width / 2, y: size.height / 2 - (isGodRun ? 26 : 16))
        pauseOverlay.addChild(resume)

        if isGodRun {
            let nextPhase = MenuButtonNode(actionID: "god.nextPhase", title: "Pasar fase", subtitle: "Sube ronda y reinicia arena")
            nextPhase.position = CGPoint(x: size.width / 2, y: size.height / 2 - 94)
            pauseOverlay.addChild(nextPhase)

            let endRun = MenuButtonNode(actionID: "god.endRun", title: "Morir", subtitle: "Cerrar run y guardar puntuacion")
            endRun.position = CGPoint(x: size.width / 2, y: size.height / 2 - 162)
            endRun.setVisualStyle(
                fillColor: Palette.danger.withAlphaComponent(0.16),
                strokeColor: Palette.danger,
                titleColor: Palette.textPrimary,
                subtitleColor: Palette.danger
            )
            pauseOverlay.addChild(endRun)
        }

        let menu = MenuButtonNode(actionID: "menu", title: "Salir al menu", subtitle: "Guardar progreso y volver")
        menu.position = CGPoint(x: size.width / 2, y: size.height / 2 - (isGodRun ? 230 : 84))
        pauseOverlay.addChild(menu)

        pauseOverlay.isHidden = true
        pauseOverlay.zPosition = 100
    }

    private func buildObstacles() {
        let layouts: [[CGRect]] = [
            [
                CGRect(x: playableRect.midX - 104, y: playableRect.midY - 18, width: 208, height: 36),
                CGRect(x: playableRect.minX + 58, y: playableRect.minY + 168, width: 82, height: 24)
            ],
            [
                CGRect(x: playableRect.minX + 66, y: playableRect.midY - 82, width: 34, height: 164),
                CGRect(x: playableRect.maxX - 100, y: playableRect.midY - 82, width: 34, height: 164)
            ],
            [
                CGRect(x: playableRect.midX - 22, y: playableRect.minY + 92, width: 44, height: 170),
                CGRect(x: playableRect.midX - 92, y: playableRect.maxY - 128, width: 184, height: 32)
            ]
        ]

        let selectedLayout = layouts[(runTimers.round - 1) % layouts.count]
        for rect in selectedLayout {
            let obstacle = ObstacleNode(rect: rect)
            worldNode.addChild(obstacle)
            obstacles.append(obstacle)
        }
    }

    private func spawnSquare(kind forcedKind: SquareKind? = nil) {
        let kind = forcedKind ?? nextSquareKind(for: runTimers.round)
        let position = randomSpawnPosition()
        let velocity = CGVector.randomUnit.scaled(
            by: GameConfig.squareBaseSpeed * kind.speedMultiplier * runTimers.squareSpeedMultiplier
        )
        let square = SquareNode(kind: kind, position: position, velocity: velocity)
        applyVisualStyle(to: square)
        square.glowWidth = profile.squareGlowWidth
        squares.append(square)
        worldNode.addChild(square)
    }

    private func nextSquareKind(for round: Int) -> SquareKind {
        if profile.mode == .original {
            let roll = Int.random(in: 0...100)
            let threshold = round >= 3 ? 55 : 82
            return roll > threshold ? .fast : .normal
        }

        let roll = Int.random(in: 0...100)
        if roll > aggressiveThreshold(for: round), profile.availableSquareKinds.contains(.aggressive) {
            return .aggressive
        }
        if round >= 2, roll > 58, profile.availableSquareKinds.contains(.evasive) {
            return .evasive
        }
        if roll > 34, profile.availableSquareKinds.contains(.fast) {
            return .fast
        }
        return .normal
    }

    private func randomSpawnPosition() -> CGPoint {
        var point = CGPoint.zero
        var attempts = 0
        repeat {
            point = CGPoint(
                x: CGFloat.random(in: playableRect.minX + 30...playableRect.maxX - 30),
                y: CGFloat.random(in: playableRect.minY + 30...playableRect.maxY - 30)
            )
            attempts += 1
        } while (hypot(point.x - player.position.x, point.y - player.position.y) < 120 ||
                 obstacles.contains(where: { $0.obstacleRect.contains(point) })) && attempts < 20
        return point
    }

    private func safePlayerSpawnPosition() -> CGPoint {
        let candidatePoints: [CGPoint] = [
            CGPoint(x: playableRect.midX, y: playableRect.midY),
            CGPoint(x: playableRect.midX, y: playableRect.minY + 96),
            CGPoint(x: playableRect.midX, y: playableRect.maxY - 96),
            CGPoint(x: playableRect.minX + 72, y: playableRect.midY),
            CGPoint(x: playableRect.maxX - 72, y: playableRect.midY),
            CGPoint(x: playableRect.minX + 72, y: playableRect.minY + 96),
            CGPoint(x: playableRect.maxX - 72, y: playableRect.minY + 96),
            CGPoint(x: playableRect.minX + 72, y: playableRect.maxY - 96),
            CGPoint(x: playableRect.maxX - 72, y: playableRect.maxY - 96)
        ]

        for point in candidatePoints {
            if isSafePlayerSpawn(point) {
                return point
            }
        }

        return CGPoint(x: playableRect.midX, y: playableRect.minY + 96)
    }

    private func isSafePlayerSpawn(_ point: CGPoint) -> Bool {
        let playerRect = CGRect(
            x: point.x - player.radius,
            y: point.y - player.radius,
            width: player.radius * 2,
            height: player.radius * 2
        )
        return !obstacles.contains(where: { $0.obstacleRect.intersects(playerRect) })
    }

    private func handleSquareInteractions(currentTime: TimeInterval) {
        var captured: [SquareNode] = []

        for square in squares {
            let distance = hypot(square.position.x - player.position.x, square.position.y - player.position.y)
            if distance > player.radius + square.captureRadius {
                continue
            }

            if shouldDamagePlayer(with: square, currentTime: currentTime) {
                player.repel(from: square.position, force: 160)
                bounce(square, awayFrom: player.position)
                continue
            }

            captured.append(square)
            spawnCaptureEffect(at: square.position, color: square.kind.fillColor)
        }

        guard !captured.isEmpty else {
            return
        }

        soundManager.playCapture()
        hapticsManager.capture(strength: captured.count)
        applyRewards(for: captured, currentTime: currentTime)

        for square in captured {
            square.removeFromParent()
        }
        squares.removeAll { captured.contains($0) }

        if Int.random(in: 0...100) > profile.respawnThreshold {
            spawnSquare()
        }
    }

    private func shouldDamagePlayer(with square: SquareNode, currentTime: TimeInterval) -> Bool {
        guard !isGodRun else {
            return false
        }
        guard damagingSquareKinds.contains(square.kind) else {
            return false
        }

        if profile.mode != .original, player.isShieldActive || player.isDashActive {
            return false
        }

        guard currentTime >= damageCooldownEndsAt else {
            return true
        }

        damageCooldownEndsAt = currentTime + 0.7
        if player.applyDamage(damageAmount(for: square.kind)) {
            flashDanger()
            resetCombo(showStatusMessage: comboCount >= 4)
            hapticsManager.damage()
            showStatus(damageMessage(for: square.kind), color: Palette.danger)
        }
        return true
    }

    private func spawnCaptureEffect(at position: CGPoint, color: UIColor) {
        let burst = SKShapeNode(circleOfRadius: profile.captureBurstRadius)
        burst.fillColor = color
        burst.strokeColor = .clear
        burst.position = position
        burst.zPosition = 6
        worldNode.addChild(burst)
        burst.run(.sequence([
            .group([
                .scale(to: profile.captureBurstScale, duration: profile.captureBurstDuration),
                .fadeOut(withDuration: profile.captureBurstDuration + 0.04)
            ]),
            .removeFromParent()
        ]))
    }

    private func increaseDifficulty() {
        runTimers.applyDifficultyStep(profile: profile)

        if profile.allowsObstacles {
            obstacles.forEach { $0.removeFromParent() }
            obstacles.removeAll()
            buildObstacles()

            let pulse = SKShapeNode(rect: playableRect, cornerRadius: 26)
            pulse.fillColor = Palette.danger.withAlphaComponent(0.12)
            pulse.strokeColor = .clear
            pulse.zPosition = 2
            worldNode.addChild(pulse)
            pulse.run(.sequence([.fadeOut(withDuration: 0.35), .removeFromParent()]))
        }

        let message = profile.mode == .original
            ? "\(profile.roundLabelTitle) \(runTimers.round): sube la velocidad."
            : (runTimers.round >= 4 ? "\(profile.roundLabelTitle) \(runTimers.round): entran patrones agresivos." : "\(profile.roundLabelTitle) \(runTimers.round): la tension escala.")
        showStatus(message, color: Palette.warning)
        if profile.mode != .original {
            hapticsManager.warning()
        }
    }

    private func updateHUD(currentTime: TimeInterval) {
        scoreLabel.text = "Score \(score)"
        coinsLabel.text = "Run +\(coinsEarned) monedas   Banco \(progress.coins + coinsEarned)"
        roundLabel.text = profile.mode == .original
            ? "\(profile.roundLabelTitle) \(runTimers.round)   Cuadrados \(squares.count)"
            : "\(profile.roundLabelTitle) \(runTimers.round)   Cuadrados \(squares.count)   Ritmo \(String(format: "%.1f", runTimers.squareSpeedMultiplier))x"
        modeLabel.text = profile.mode != .original ? "\(gameMode?.productTitle ?? "") / \(currentWeapon.title)" : gameMode?.productTitle
        let comboTier = comboTier
        comboLabel.text = comboCount >= 2 ? "Combo x\(comboTier)  •  \(comboCount)" : nil
        comboLabel.alpha = comboCount >= 2 ? 1 : 0
        comboLabel.fontColor = comboTier >= 3 ? Palette.accent : Palette.warning
        if let targetPoint, !usesStickmanControls {
            targetIndicator.position = targetPoint
            targetIndicator.isHidden = false
        } else {
            targetIndicator.isHidden = true
        }

        let width = max(20, 166 * (player.health / GameConfig.playerMaxHealth))
        let displayedWidth = isGodRun ? 166 : width
        healthFill.path = CGPath(roundedRect: CGRect(x: -83, y: -6, width: displayedWidth, height: 12), cornerWidth: 6, cornerHeight: 6, transform: nil)
        healthFill.fillColor = isGodRun ? Palette.stroke : (player.health > 50 ? Palette.success : (player.health > 25 ? Palette.warning : Palette.danger))

        for (ability, button) in abilityButtons {
            if isGodRun {
                button.updateSubtitle("∞")
                button.setVisualStyle(fillColor: Palette.stroke.withAlphaComponent(0.18), strokeColor: Palette.stroke, titleColor: Palette.textPrimary, subtitleColor: Palette.stroke)
                continue
            }
            let state = player.visualState(for: ability, currentTime: currentTime, ownedAbilities: ownedAbilitiesForCurrentMode)
            switch state {
            case .locked:
                button.updateSubtitle("Bloq.")
                button.setVisualStyle(fillColor: Palette.panel.withAlphaComponent(0.55), strokeColor: Palette.textSecondary, titleColor: Palette.textSecondary, subtitleColor: Palette.textSecondary)
            case .ready:
                button.updateSubtitle("Listo")
                button.setVisualStyle(fillColor: Palette.panel, strokeColor: Palette.success, titleColor: Palette.textPrimary, subtitleColor: Palette.success)
            case .coolingDown:
                let remaining = player.remainingCooldown(for: ability, currentTime: currentTime)
                button.updateSubtitle(String(format: "%.1fs", remaining))
                button.setVisualStyle(fillColor: Palette.panel, strokeColor: Palette.warning, titleColor: Palette.textPrimary, subtitleColor: Palette.warning)
            case .active:
                button.updateSubtitle("Activo")
                button.setVisualStyle(fillColor: Palette.stroke.withAlphaComponent(0.18), strokeColor: Palette.stroke, titleColor: Palette.textPrimary, subtitleColor: Palette.stroke)
            }
        }

        if let attackButton {
            let ready = isGodRun || currentTime >= weaponCooldownEndsAt
            attackButton.updateTitle(currentWeapon.title)
            attackButton.updateSubtitle(isGodRun ? "∞ fuego" : (ready ? "Fuego" : String(format: "%.1fs", max(0, weaponCooldownEndsAt - currentTime))))
            attackButton.setVisualStyle(
                fillColor: ready ? Palette.panel : Palette.panel.withAlphaComponent(0.6),
                strokeColor: ready ? (isGodRun ? Palette.stroke : currentWeaponStrokeColor) : Palette.textSecondary,
                titleColor: Palette.textPrimary,
                subtitleColor: ready ? (isGodRun ? Palette.stroke : currentWeaponStrokeColor) : Palette.textSecondary
            )
        }

        dangerPulse.fillColor = player.health <= 30 ? Palette.danger.withAlphaComponent(0.08) : .clear
    }

    private var originalCoinBonusPerCapture: Int {
        guard progress.owns(.coinPouch, for: profile.mode) else {
            return 0
        }
        return 1
    }

    private var originalScoreBonusPerCapture: Int {
        guard progress.owns(.scoreCharm, for: profile.mode) else {
            return 0
        }
        return 4
    }

    private var ownedAbilitiesForCurrentMode: Set<AbilityType> {
        profile.mode != .original ? progress.ownedAbilities.intersection(Set(availableAbilities)) : []
    }

    private var currentWeapon: WeaponType {
        guard profile.mode != .original else {
            return .blaster
        }
        let availableWeapons = progress.ownedWeapons
        let selectedWeapon = progress.selectedWeapon(for: profile.mode)
        if availableWeapons.contains(selectedWeapon) {
            return selectedWeapon
        }
        if availableWeapons.contains(player.definition.defaultWeapon) {
            return player.definition.defaultWeapon
        }
        return .blaster
    }

    private var availableAbilities: [AbilityType] {
        guard profile.mode != .original else {
            return []
        }
        return player?.definition.supportedAbilities.filter { profile.enabledAbilities.contains($0) } ?? []
    }

    private var currentWeaponStrokeColor: UIColor {
        switch currentWeapon {
        case .blaster:
            return Palette.stroke
        case .scatter:
            return Palette.warning
        case .rail:
            return Palette.accent
        }
    }

    private func handleButton(_ button: MenuButtonNode, currentTime: TimeInterval) {
        switch button.actionID {
        case "pause":
            soundManager.playPauseToggle()
            hapticsManager.tap()
            state = .pausedMenu
            targetPoint = nil
            resetJoystick()
            pauseOverlay.isHidden = false
            showStatus("Partida en pausa.", color: Palette.textSecondary)
        case "resume":
            soundManager.playPauseToggle()
            hapticsManager.tap()
            state = .active
            pauseOverlay.isHidden = true
            showStatus("Partida reanudada.", color: Palette.success)
        case "menu":
            soundManager.playButtonTap()
            hapticsManager.tap()
            guard let gameMode else {
                return
            }
            state = .pausedMenu
            targetPoint = nil
            resetJoystick()
            present(MainMenuScene(sceneSize: size, gameMode: gameMode))
        case "god.nextPhase":
            soundManager.playSuccess()
            hapticsManager.success()
            advanceToNextPhase()
        case "god.endRun":
            soundManager.playWarning()
            hapticsManager.warning()
            triggerGameOver(force: true)
        case "attack":
            soundManager.playButtonTap()
            hapticsManager.tap()
            fireWeapon(currentTime: currentTime, ignoreCooldown: isGodRun)
        case _ where button.actionID.hasPrefix("ability."):
            let rawValue = String(button.actionID.dropFirst("ability.".count))
            guard let ability = AbilityType(rawValue: rawValue),
                  availableAbilities.contains(ability),
                  state == .active,
                  (isGodRun || player.canActivate(ability, currentTime: currentTime, ownedAbilities: ownedAbilitiesForCurrentMode)) else {
                showStatus("Habilidad no disponible.", color: Palette.textSecondary)
                return
            }
            player.activate(ability, currentTime: currentTime)
            soundManager.playSuccess()
            hapticsManager.success()
            if ability == .dash {
                performDashBurst()
            }
            if ability == .pulse {
                performPulse()
            }
            if ability == .overdrive {
                autoFireEndsAt = currentTime + GameConfig.overdriveDuration
            }
            showStatus(statusMessage(for: ability), color: Palette.stroke)
            updateHUD(currentTime: currentTime)
        default:
            break
        }
    }

    private func triggerGameOver(force: Bool = false) {
        guard (!gameOverSaved || force),
              let gameMode else {
            return
        }
        gameOverSaved = true
        state = .gameOver

        let updatedProgress = saveManager.update { mutableProgress in
            mutableProgress.recordCompletedRun(for: gameMode, score: score, coinsEarned: coinsEarned)
        }
        soundManager.playGameOver()
        hapticsManager.error()

        let scene = GameOverScene(
            sceneSize: size,
            gameMode: gameMode,
            score: score,
            bestScore: updatedProgress.highScore(for: gameMode),
            coinsEarned: coinsEarned,
            roundReached: runTimers.round,
            returnToArtificialWorld: ArcadeWorldBridge.returnToArtificialWorldAfterRun
        )
        present(scene)
    }

    private func showStatus(_ text: String, color: UIColor) {
        statusLabel.removeAllActions()
        statusLabel.text = text
        statusLabel.fontColor = color
        statusLabel.alpha = 1
        statusLabel.run(.sequence([
            .wait(forDuration: 1.1),
            .fadeAlpha(to: 0.35, duration: 0.35)
        ]))
    }

    private func flashDanger() {
        dangerPulse.removeAllActions()
        dangerPulse.alpha = 1
        dangerPulse.run(.sequence([
            .fadeAlpha(to: 0.65, duration: 0.08),
            .fadeOut(withDuration: 0.24)
        ]))
    }

    private var damagingSquareKinds: Set<SquareKind> {
        switch profile.mode {
        case .original:
            return [.fast]
        case .evolution:
            return [.aggressive]
        case .ghost:
            return [.fast, .aggressive]
        }
    }

    private var startingStatusMessage: String {
        if isGodRun {
            return "Modo dios activo. Sin dano, sin cooldown y control total del ritmo."
        }
        switch profile.mode {
        case .original:
            return "Captura los azules. Los cuadrados rojos quitan vida."
        case .evolution:
            if usesStickmanControls {
                return "Stickman: joystick para moverte y toque libre para disparar."
            }
            return "Dispara para limpiar rojos. Las armas se compran en tienda."
        case .ghost:
            if usesStickmanControls {
                return "Fantasma: joystick, rafagas y lectura rapida. No pierdas la señal."
            }
            return "Protocolo Fantasma: dispara, depura glitches y encadena combos."
        }
    }

    private func damageAmount(for kind: SquareKind) -> CGFloat {
        switch (profile.mode, kind) {
        case (.original, .fast):
            return 24
        case (.evolution, .aggressive):
            return kind.damage
        case (.ghost, .fast):
            return 18
        case (.ghost, .aggressive):
            return 20
        default:
            return 0
        }
    }

    private func damageMessage(for kind: SquareKind) -> String {
        switch (profile.mode, kind) {
        case (.original, .fast):
            return "Golpe directo. Evita los cuadrados rojos."
        case (.evolution, .aggressive):
            return "Los cuadrados rojos piden dash o escudo."
        case (.ghost, .fast):
            return "La señal vibra demasiado. Baja el riesgo."
        case (.ghost, .aggressive):
            return "Error critico. Reposiciona o vas fuera."
        default:
            return "Has recibido dano."
        }
    }

    private func applyVisualStyle(to square: SquareNode) {
        if profile.mode == .original, square.kind == .fast {
            square.fillColor = Palette.danger
            square.strokeColor = .white
            return
        }

        square.strokeColor = profile.squareStrokeColor
    }

    private func bounce(_ square: SquareNode, awayFrom point: CGPoint) {
        let bounce = CGVector(dx: square.position.x - point.x, dy: square.position.y - point.y).normalized
        square.velocity = bounce.scaled(by: GameConfig.squareBaseSpeed * 2.1)
    }

    private func handleAutoFire(currentTime: TimeInterval) {
        guard currentTime < autoFireEndsAt,
              currentTime - lastAutoFireAt >= 0.45 else {
            return
        }
        lastAutoFireAt = currentTime
        fireWeapon(currentTime: currentTime, ignoreCooldown: true)
    }

    @discardableResult
    private func fireWeapon(currentTime: TimeInterval, ignoreCooldown: Bool = false, target overrideTarget: CGPoint? = nil) -> Bool {
        guard profile.mode != .original,
              state == .active,
              ignoreCooldown || isGodRun || currentTime >= weaponCooldownEndsAt else {
            return false
        }

        guard let target = overrideTarget ?? nearestSquarePosition() else {
            return false
        }
        let direction = CGVector(dx: target.x - player.position.x, dy: target.y - player.position.y).normalized
        guard direction.dx != 0 || direction.dy != 0 else {
            return false
        }
        let cooldown = currentWeapon.cooldown * TimeInterval(player.definition.attackCooldownMultiplier) * (player.isOverdriveActive ? 0.55 : 1)
        if !ignoreCooldown && !isGodRun {
            weaponCooldownEndsAt = currentTime + cooldown
        }

        for vector in projectileVectors(from: direction) {
            let projectile = ProjectileNode(
                color: currentWeaponStrokeColor,
                velocity: vector.scaled(by: currentWeapon.projectileSpeed * (player.isOverdriveActive ? 1.18 : 1)),
                damage: currentWeapon.damage * player.definition.projectileDamageMultiplier,
                lifetime: GameConfig.projectileLifetime,
                hitsRemaining: currentWeapon.maxHits + player.definition.projectilePierceBonus
            )
            projectile.position = player.position
            projectiles.append(projectile)
            worldNode.addChild(projectile)
        }

        updateHUD(currentTime: currentTime)
        return true
    }

    private func fireBurst(currentTime: TimeInterval, target: CGPoint, shotsRemaining: Int = 3, ignoresCooldown: Bool = false) {
        guard shotsRemaining > 0 else {
            return
        }

        let fired = fireWeapon(currentTime: currentTime, ignoreCooldown: ignoresCooldown, target: target)
        guard fired else {
            return
        }

        guard shotsRemaining > 1 else {
            return
        }

        let delay = 0.1
        let action = SKAction.sequence([
            .wait(forDuration: delay),
            .run { [weak self] in
                self?.fireBurst(
                    currentTime: currentTime + delay,
                    target: target,
                    shotsRemaining: shotsRemaining - 1,
                    ignoresCooldown: true
                )
            }
        ])
        run(action)
    }

    private func projectileVectors(from baseDirection: CGVector) -> [CGVector] {
        let count = currentWeapon.projectileCount
        guard count > 1 else {
            return [baseDirection]
        }

        let baseAngle = atan2(baseDirection.dy, baseDirection.dx)
        let startAngle = baseAngle - currentWeapon.spreadAngle / 2
        let step = currentWeapon.spreadAngle / CGFloat(count - 1)
        return (0..<count).map { index in
            let angle = startAngle + CGFloat(index) * step
            return CGVector(dx: cos(angle), dy: sin(angle))
        }
    }

    private func nearestSquarePosition() -> CGPoint? {
        squares.min(by: {
            hypot($0.position.x - player.position.x, $0.position.y - player.position.y) <
                hypot($1.position.x - player.position.x, $1.position.y - player.position.y)
        })?.position
    }

    private func handleStickmanTouchBegan(_ touch: UITouch, location: CGPoint, currentTime: TimeInterval) {
        let touchID = ObjectIdentifier(touch)

        if activeTouches[touchID] == nil,
           activeTouches.values.contains(.movement) == false,
           hypot(location.x - joystickCenter.x, location.y - joystickCenter.y) <= joystickActivationRadius {
            activeTouches[touchID] = .movement
            updateJoystick(with: location)
            return
        }

        fireBurst(currentTime: currentTime, target: location, ignoresCooldown: isGodRun)
    }

    private func updateJoystick(with location: CGPoint) {
        let rawVector = CGVector(dx: location.x - joystickCenter.x, dy: location.y - joystickCenter.y)
        let distance = hypot(rawVector.dx, rawVector.dy)

        guard distance > 0 else {
            joystickVector = .zero
            joystickKnob.position = joystickCenter
            return
        }

        let limitedDistance = min(distance, GameConfig.joystickBaseRadius)
        let normalized = CGVector(dx: rawVector.dx / distance, dy: rawVector.dy / distance)
        joystickVector = CGVector(
            dx: normalized.dx * (limitedDistance / GameConfig.joystickBaseRadius),
            dy: normalized.dy * (limitedDistance / GameConfig.joystickBaseRadius)
        )
        joystickKnob.position = CGPoint(
            x: joystickCenter.x + normalized.dx * limitedDistance,
            y: joystickCenter.y + normalized.dy * limitedDistance
        )
    }

    private func releaseTouch(_ touch: UITouch) {
        let touchID = ObjectIdentifier(touch)
        guard let role = activeTouches.removeValue(forKey: touchID) else {
            return
        }

        if role == .movement {
            resetJoystick()
        }
    }

    private func resetJoystick() {
        joystickVector = .zero
        joystickKnob.position = joystickCenter
        activeTouches = activeTouches.filter { $0.value != .movement }
    }

    private func updateProjectiles(deltaTime: TimeInterval) {
        guard !projectiles.isEmpty else {
            return
        }

        var removedSquares = Set<ObjectIdentifier>()

        for projectile in projectiles {
            projectile.remainingLifetime -= deltaTime
            projectile.position.x += projectile.velocity.dx * deltaTime
            projectile.position.y += projectile.velocity.dy * deltaTime

            if projectile.remainingLifetime <= 0 || !playableRect.contains(projectile.position) {
                projectile.removeFromParent()
                continue
            }

            for square in squares {
                let squareID = ObjectIdentifier(square)
                if removedSquares.contains(squareID) {
                    continue
                }

                let distance = hypot(square.position.x - projectile.position.x, square.position.y - projectile.position.y)
                if distance > square.captureRadius {
                    continue
                }

                projectile.hitsRemaining -= 1
                let destroyed = square.applyDamage(projectile.damage)
                if destroyed {
                    removedSquares.insert(squareID)
                    spawnCaptureEffect(at: square.position, color: currentWeaponStrokeColor)
                } else {
                    square.run(.sequence([
                        .fadeAlpha(to: 0.45, duration: 0.05),
                        .fadeAlpha(to: 1, duration: 0.08)
                    ]))
                }
                if projectile.hitsRemaining <= 0 {
                    projectile.removeFromParent()
                    break
                }
            }
        }

        if !removedSquares.isEmpty {
            let removedNodes = squares.filter { removedSquares.contains(ObjectIdentifier($0)) }
            hapticsManager.capture(strength: removedNodes.count)
            applyRewards(for: removedNodes, currentTime: lastUpdateTime)
            removedNodes.forEach { $0.removeFromParent() }
            squares.removeAll { removedSquares.contains(ObjectIdentifier($0)) }
        }

        projectiles.removeAll { $0.parent == nil }
    }

    private func performPulse() {
        let pulseRadius = GameConfig.pulseRadius * player.definition.pulseRadiusMultiplier
        let pulseNode = SKShapeNode(circleOfRadius: pulseRadius)
        pulseNode.position = player.position
        pulseNode.strokeColor = currentWeaponStrokeColor
        pulseNode.lineWidth = 3
        pulseNode.fillColor = currentWeaponStrokeColor.withAlphaComponent(0.08)
        pulseNode.zPosition = 6
        worldNode.addChild(pulseNode)
        pulseNode.run(.sequence([
            .group([
                .scale(to: 1.15, duration: 0.18),
                .fadeOut(withDuration: 0.18)
            ]),
            .removeFromParent()
        ]))

        let affected = squares.filter {
            hypot($0.position.x - player.position.x, $0.position.y - player.position.y) <= pulseRadius
        }
        if affected.isEmpty {
            showStatus("Pulso sin objetivos.", color: Palette.warning)
            return
        }

        hapticsManager.capture(strength: affected.count)
        applyRewards(for: affected, currentTime: lastUpdateTime)
        for square in affected {
            spawnCaptureEffect(at: square.position, color: Palette.warning)
            square.removeFromParent()
        }
        let removed = Set(affected.map(ObjectIdentifier.init))
        squares.removeAll { removed.contains(ObjectIdentifier($0)) }
    }

    private var comboTier: Int {
        max(1, min(5, 1 + comboCount / 4))
    }

    private func performDashBurst() {
        let direction: CGVector
        if usesStickmanControls, joystickVector.dx != 0 || joystickVector.dy != 0 {
            direction = joystickVector
        } else if let targetPoint {
            direction = CGVector(dx: targetPoint.x - player.position.x, dy: targetPoint.y - player.position.y)
        } else {
            direction = player.currentVelocity
        }

        player.applyDashImpulse(direction: direction)

        let burst = SKShapeNode(circleOfRadius: player.radius + 4)
        burst.position = player.position
        burst.strokeColor = Palette.stroke
        burst.lineWidth = 3
        burst.fillColor = Palette.stroke.withAlphaComponent(0.08)
        burst.zPosition = 6
        worldNode.addChild(burst)
        burst.run(.sequence([
            .group([
                .scale(to: 1.75, duration: 0.16),
                .fadeOut(withDuration: 0.18)
            ]),
            .removeFromParent()
        ]))
    }

    private func applyRewards(for capturedSquares: [SquareNode], currentTime: TimeInterval) {
        guard !capturedSquares.isEmpty else {
            return
        }

        comboCount = currentTime <= comboExpiresAt ? comboCount + capturedSquares.count : capturedSquares.count
        comboExpiresAt = currentTime + 2.4

        for square in capturedSquares {
            score += square.kind.reward + originalScoreBonusPerCapture
            coinsEarned += Int((CGFloat(square.kind.coins + originalCoinBonusPerCapture) * profile.runCoinsMultiplier).rounded())
        }

        let tier = comboTier
        if tier > 1 {
            score += (tier - 1) * 3 * capturedSquares.count
        }
        if comboCount >= 8, comboCount.isMultiple(of: 4) {
            coinsEarned += 1
        }

        if comboCount >= 4 {
            comboLabel.removeAllActions()
            comboLabel.run(.sequence([
                .scale(to: 1.08, duration: 0.08),
                .scale(to: 1, duration: 0.12)
            ]))
            showStatus("Combo x\(tier) en marcha.", color: tier >= 3 ? Palette.accent : Palette.warning)
        }
    }

    private func resetCombo(showStatusMessage: Bool) {
        guard comboCount > 0 else {
            return
        }
        if showStatusMessage {
            showStatus("Racha perdida.", color: Palette.textSecondary)
        }
        comboCount = 0
        comboExpiresAt = 0
    }

    private func aggressiveThreshold(for round: Int) -> Int {
        switch round {
        case 0...1:
            return 80
        case 2:
            return 72
        case 3:
            return 64
        default:
            return 52
        }
    }

    private func statusMessage(for ability: AbilityType) -> String {
        switch ability {
        case .dash:
            return "Dash ejecutado. Cruza huecos y recolocate."
        case .magnet:
            return "Iman activado."
        case .shield:
            return "Escudo activado."
        case .pulse:
            return "Pulso activado."
        case .overdrive:
            return "Overdrive activado."
        }
    }

    private func advanceToNextPhase() {
        runTimers.round += 1
        runTimers.squareSpeedMultiplier *= 1.1
        runTimers.spawnInterval = max(0.36, runTimers.spawnInterval * 0.88)
        runTimers.spawnTimer = 0
        runTimers.difficultyTimer = 0
        targetPoint = nil
        resetJoystick()

        squares.forEach { $0.removeFromParent() }
        squares.removeAll()
        projectiles.forEach { $0.removeFromParent() }
        projectiles.removeAll()
        obstacles.removeAll()
        worldNode.removeAllChildren()

        buildArena()
        worldNode.addChild(player)
        player.position = safePlayerSpawnPosition()
        player.restoreFullHealth()
        pauseOverlay.isHidden = true
        state = .active

        let spawnCount = min(profile.maxSquares, profile.initialSquares + runTimers.round)
        for _ in 0..<spawnCount {
            spawnSquare()
        }
        if profile.mode != .original, squares.allSatisfy({ $0.kind != .aggressive }) {
            spawnSquare(kind: .aggressive)
        }
        showStatus("Fase \(runTimers.round). Arena recombinada.", color: Palette.stroke)
    }
}
