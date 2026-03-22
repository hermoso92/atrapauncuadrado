import SpriteKit
import UIKit

private let squareSize: CGFloat = 24

private func fillColor(for kind: ArtificialWorldSquareKind) -> UIColor {
    switch kind {
    case .common: Palette.stroke
    case .nutritious: Palette.success
    case .hostile: Palette.danger
    case .rare: UIColor(red: 0.60, green: 0.53, blue: 1.00, alpha: 1)
    case .resource: Palette.warning
    }
}

@MainActor
final class ArtificialWorldScene: BaseScene {
    private let worldRepository: WorldRepository
    private let memoryStore: AgentMemoryStore
    private let telemetry: TelemetryLogging
    private let clock: GameClock

    private let worldNode = SKNode()
    private let hudNode = SKNode()
    private let playerNode = SKShapeNode(circleOfRadius: GameConfig.playerRadius)
    private var snapshot: ArtificialWorldSnapshot
    private var squares: [WorldSquareBody] = []
    private var squareNodes: [UUID: SKShapeNode] = [:]

    private var targetPoint: CGPoint?
    private var lastUpdateTime: TimeInterval = 0
    private var saveTimer: TimeInterval = 0
    private var memoryLogTimer: TimeInterval = 0
    private var playerVelocity = CGVector.zero
    private var brain = WorldAgentBrain()
    private var lastTelemetryAgentState: WorldAgentBrainState?

    private let hungerLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
    private let energyLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
    private let modeLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
    private let agentLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
    private let inventoryLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
    #if DEBUG
    private let debugTelemetryLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
    #endif

    private var modeButton: MenuButtonNode!
    private var backButton: MenuButtonNode!
    private var homeButton: MenuButtonNode!
    private var arcadeRunButton: MenuButtonNode!
    private var shelterUpgradeButton: MenuButtonNode!
    private let shelterLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
    private var abilityButtons: [WorldAbility: MenuButtonNode] = [:]
    private var abilityCooldownEnds: [WorldAbility: TimeInterval] = [:]
    private var sprintUntil: TimeInterval = 0
    private var wideCaptureUntil: TimeInterval = 0
    private var scanUntil: TimeInterval = 0
    private var autoGatherUntil: TimeInterval = 0

    private var worldBounds: CGRect {
        CGRect(
            x: GameConfig.worldInset,
            y: 118,
            width: size.width - GameConfig.worldInset * 2,
            height: size.height - 268
        )
    }

    private var shelterRect: CGRect {
        let scale = ArtificialWorldSimulation.shelterScale(level: snapshot.shelterLevel)
        let w: CGFloat = 128 * scale
        let h: CGFloat = 76 * scale
        return CGRect(x: worldBounds.midX - w / 2, y: worldBounds.minY + 18, width: w, height: h)
    }

    private var shelterCenter: CGPoint {
        CGPoint(x: shelterRect.midX, y: shelterRect.midY)
    }

    private var shelterRadius: CGFloat {
        max(shelterRect.width, shelterRect.height) / 2
    }

    init(
        sceneSize: CGSize,
        dependencies: SceneDependencies? = nil,
        worldRepository: WorldRepository,
        memoryStore: AgentMemoryStore,
        telemetry: TelemetryLogging? = nil,
        clock: GameClock? = nil
    ) {
        self.worldRepository = worldRepository
        self.memoryStore = memoryStore
        self.telemetry = telemetry ?? AppTelemetry.shared
        self.clock = clock ?? SystemGameClock()
        self.snapshot = ArtificialWorldSnapshot(
            worldId: UUID(),
            playerPositionX: 0,
            playerPositionY: 0,
            hunger: 0.9,
            energy: 0.9,
            shelterLevel: 1,
            inventoryItemIds: [],
            controlModeRaw: PlayerControlMode.manual.rawValue,
            lastSavedAt: Date(),
            unlockedWorldAbilityRaws: []
        )
        super.init(sceneSize: sceneSize, gameMode: nil, dependencies: dependencies)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        telemetry.logEvent("world_entered", parameters: [:])
        do {
            if let loaded = try worldRepository.loadSnapshot() {
                snapshot = loaded
            } else {
                snapshot = ArtificialWorldSnapshot.newGame(
                    worldBoundsMidX: Double(worldBounds.midX),
                    shelterCenterY: Double(shelterCenter.y)
                )
            }
        } catch {
            snapshot = ArtificialWorldSnapshot.newGame(
                worldBoundsMidX: Double(worldBounds.midX),
                shelterCenterY: Double(shelterCenter.y)
            )
        }
        brain.reset()
        buildLevel()
        soundManager.playSoundscape(.menu)
    }

    override func willMove(from view: SKView) {
        persistSnapshot()
        super.willMove(from: view)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        // Tamaños intermedios (0 o casi 0) al rotar o redimensionar rompen CGFloat.random(in:) y cierran la app.
        guard size.width >= 280, size.height >= 420, oldSize != size else { return }
        if !squares.isEmpty {
            buildLevel()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let deltaTime = min(1.0 / 30.0, currentTime - lastUpdateTime)
        lastUpdateTime = currentTime

        let inShelter = shelterRect.contains(playerNode.position)
        let regenMult = ArtificialWorldSimulation.shelterRegenMultiplier(level: snapshot.shelterLevel)
        if inShelter {
            ArtificialWorldSimulation.regenInsideShelter(
                delta: deltaTime,
                multiplier: regenMult,
                hunger: &snapshot.hunger,
                energy: &snapshot.energy
            )
        } else {
            ArtificialWorldSimulation.decayOutsideShelter(delta: deltaTime, hunger: &snapshot.hunger, energy: &snapshot.energy)
        }

        let autoSteer = shouldUseAgentSteering(inShelter: inShelter)
        if autoSteer {
            let bodies = squares
            if let steer = brain.nextSteerTarget(
                now: currentTime,
                player: playerNode.position,
                hunger: snapshot.hunger,
                energy: snapshot.energy,
                shelterCenter: shelterCenter,
                shelterRadius: shelterRadius,
                squares: bodies,
                worldBounds: worldBounds
            ) {
                targetPoint = steer
            }
            if brain.state != lastTelemetryAgentState {
                lastTelemetryAgentState = brain.state
                telemetry.logEvent("agent_decision", parameters: ["state": brain.state.rawValue])
            }
        } else {
            lastTelemetryAgentState = nil
        }

        movePlayer(deltaTime: deltaTime, toward: targetPoint, currentTime: currentTime)

        updateSquares(deltaTime: deltaTime, currentTime: currentTime)
        resolveCapturesAndDamage(currentTime: currentTime)
        refreshScanHighlight(currentTime: currentTime)
        updateHUD(currentTime: currentTime)

        saveTimer += deltaTime
        if saveTimer >= 4 {
            saveTimer = 0
            persistSnapshot()
        }

        memoryLogTimer += deltaTime
        if memoryLogTimer >= 28 {
            memoryLogTimer = 0
            logAgentMemorySummary(currentTime: currentTime)
        }

        if snapshot.hunger <= 0 || snapshot.energy <= 0 {
            snapshot.hunger = max(0.05, snapshot.hunger)
            snapshot.energy = max(0.05, snapshot.energy)
            showBriefStatus("Umbral critico: refugio o nutrientes.", color: Palette.danger)
            telemetry.logEvent("world_critical_needs", parameters: [:])
        }
    }

    private func shouldUseAgentSteering(inShelter: Bool) -> Bool {
        switch snapshot.controlMode {
        case .manual:
            return false
        case .automatic:
            return true
        case .hybrid:
            if inShelter { return false }
            return snapshot.hunger < 0.30 || snapshot.energy < 0.28
        }
    }

    private func movePlayer(deltaTime: TimeInterval, toward target: CGPoint?, currentTime: TimeInterval) {
        let sprintOn = currentTime < sprintUntil
        let maxSpeed = GameConfig.playerBaseSpeed * 0.95 * ArtificialWorldSimulation.speedMultiplier(sprintActive: sprintOn)
        if let target {
            let v = CGVector(dx: target.x - playerNode.position.x, dy: target.y - playerNode.position.y)
            let d = hypot(v.dx, v.dy)
            if d > 6 {
                let n = CGVector(dx: v.dx / d, dy: v.dy / d)
                let desired = CGVector(dx: n.dx * maxSpeed, dy: n.dy * maxSpeed)
                playerVelocity.dx += (desired.dx - playerVelocity.dx) * min(1, CGFloat(deltaTime * 12))
                playerVelocity.dy += (desired.dy - playerVelocity.dy) * min(1, CGFloat(deltaTime * 12))
            } else {
                playerVelocity.dx *= 0.65
                playerVelocity.dy *= 0.65
            }
        } else {
            playerVelocity.dx *= 0.78
            playerVelocity.dy *= 0.78
        }

        var next = CGPoint(
            x: playerNode.position.x + playerVelocity.dx * deltaTime,
            y: playerNode.position.y + playerVelocity.dy * deltaTime
        )
        let r = GameConfig.playerRadius
        next.x = min(max(next.x, worldBounds.minX + r), worldBounds.maxX - r)
        next.y = min(max(next.y, worldBounds.minY + r), worldBounds.maxY - r)
        playerNode.position = next

        snapshot.playerPositionX = Double(next.x)
        snapshot.playerPositionY = Double(next.y)
    }

    private func updateSquares(deltaTime: TimeInterval, currentTime: TimeInterval) {
        let magnet = shouldApplyWorldMagnet(currentTime: currentTime)
        for index in squares.indices {
            var sq = squares[index]
            if magnet, sq.kind != .hostile {
                let pull = CGVector(
                    dx: playerNode.position.x - sq.position.x,
                    dy: playerNode.position.y - sq.position.y
                )
                let d = max(28, hypot(pull.dx, pull.dy))
                let n = CGVector(dx: pull.dx / d, dy: pull.dy / d)
                let strength: CGFloat = (currentTime < autoGatherUntil) ? 95 : 42
                sq.velocity.dx += n.dx * strength * CGFloat(deltaTime)
                sq.velocity.dy += n.dy * strength * CGFloat(deltaTime)
            }
            if sq.kind == .hostile {
                let chase = CGVector(
                    dx: playerNode.position.x - sq.position.x,
                    dy: playerNode.position.y - sq.position.y
                )
                let n = chase.normalized
                let desired = CGVector(dx: n.dx * 95, dy: n.dy * 95)
                sq.velocity.dx += (desired.dx - sq.velocity.dx) * CGFloat(deltaTime * 2.8)
                sq.velocity.dy += (desired.dy - sq.velocity.dy) * CGFloat(deltaTime * 2.8)
            }
            sq.velocity = sq.velocity.clampedMagnitude(max: 110)
            sq.position.x += sq.velocity.dx * deltaTime
            sq.position.y += sq.velocity.dy * deltaTime
            let half = squareSize / 2
            if sq.position.x < worldBounds.minX + half || sq.position.x > worldBounds.maxX - half {
                sq.velocity.dx *= -1
                sq.position.x = min(max(sq.position.x, worldBounds.minX + half), worldBounds.maxX - half)
            }
            if sq.position.y < worldBounds.minY + half || sq.position.y > worldBounds.maxY - half {
                sq.velocity.dy *= -1
                sq.position.y = min(max(sq.position.y, worldBounds.minY + half), worldBounds.maxY - half)
            }
            squares[index] = sq
            squareNodes[sq.id]?.position = sq.position
        }
    }

    private func shouldApplyWorldMagnet(currentTime: TimeInterval) -> Bool {
        if currentTime < autoGatherUntil, snapshot.canUse(.autoGather) {
            return true
        }
        guard snapshot.canUse(.autoGather) else { return false }
        switch snapshot.controlMode {
        case .automatic:
            return true
        case .hybrid:
            return shouldUseAgentSteering(inShelter: shelterRect.contains(playerNode.position))
        case .manual:
            return false
        }
    }

    private func resolveCapturesAndDamage(currentTime: TimeInterval) {
        let pr = GameConfig.playerRadius
        let wide = currentTime < wideCaptureUntil
        let capR = ArtificialWorldSimulation.effectiveCaptureRadius(base: squareSize * 0.55, wideCaptureActive: wide)
        var toRemove: [UUID] = []
        for sq in squares {
            let d = hypot(sq.position.x - playerNode.position.x, sq.position.y - playerNode.position.y)
            if d > pr + capR {
                continue
            }
            if sq.kind.contactDamage > 0.1 {
                snapshot.energy = max(0, snapshot.energy - sq.kind.contactDamage / 120)
                hapticsManager.damage()
                showBriefStatus("Contacto hostil", color: Palette.danger)
                toRemove.append(sq.id)
                telemetry.logEvent("world_hostile_hit", parameters: ["kind": sq.kind.rawValue])
                continue
            }
            snapshot.hunger = min(1, snapshot.hunger + sq.kind.hungerRestore)
            snapshot.energy = min(1, snapshot.energy + sq.kind.energyRestore)
            if sq.kind == .rare || sq.kind == .resource {
                let prefix = sq.kind == .rare ? "rare" : "res"
                snapshot.inventoryItemIds.append("\(prefix)_\(UUID().uuidString.prefix(8))")
                if snapshot.inventoryItemIds.count > 48 {
                    snapshot.inventoryItemIds.removeFirst(snapshot.inventoryItemIds.count - 48)
                }
            }
            toRemove.append(sq.id)
            soundManager.playCapture()
            hapticsManager.capture(strength: 1)
            telemetry.logEvent("world_entity_captured", parameters: ["kind": sq.kind.rawValue])
        }
        for id in toRemove {
            squares.removeAll { $0.id == id }
            squareNodes[id]?.removeFromParent()
            squareNodes[id] = nil
        }
    }

    private func buildLevel() {
        removeAllChildren()
        worldNode.removeAllChildren()
        hudNode.removeAllChildren()
        squares.removeAll()
        squareNodes.removeAll()

        worldNode.zPosition = 0
        hudNode.zPosition = 50

        setupBackdrop(title: "ARTIFICIAL WORLD", subtitle: "Mundo persistente. Refugio, recursos y agente.")
        addChild(worldNode)
        addChild(hudNode)

        let frame = SKShapeNode(rect: worldBounds, cornerRadius: 22)
        frame.fillColor = UIColor(red: 0.04, green: 0.06, blue: 0.09, alpha: 0.92)
        frame.strokeColor = Palette.accent
        frame.lineWidth = 2
        worldNode.addChild(frame)

        let shelterShape = SKShapeNode(rect: shelterRect, cornerRadius: 14)
        shelterShape.fillColor = Palette.success.withAlphaComponent(0.18)
        shelterShape.strokeColor = Palette.success
        shelterShape.lineWidth = 1.5
        worldNode.addChild(shelterShape)

        playerNode.fillColor = Palette.stroke
        playerNode.strokeColor = .white
        playerNode.lineWidth = 2
        playerNode.position = CGPoint(x: snapshot.playerPositionX, y: snapshot.playerPositionY)
        playerNode.zPosition = 5
        worldNode.addChild(playerNode)

        spawnInitialSquares()

        hungerLabel.fontSize = 13
        hungerLabel.horizontalAlignmentMode = .left
        hungerLabel.position = CGPoint(x: 22, y: size.height - 86)
        hudNode.addChild(hungerLabel)

        energyLabel.fontSize = 13
        energyLabel.horizontalAlignmentMode = .left
        energyLabel.position = CGPoint(x: 22, y: size.height - 108)
        hudNode.addChild(energyLabel)

        modeLabel.fontSize = 12
        modeLabel.horizontalAlignmentMode = .left
        modeLabel.position = CGPoint(x: 22, y: size.height - 130)
        hudNode.addChild(modeLabel)

        agentLabel.fontSize = 11
        agentLabel.horizontalAlignmentMode = .left
        agentLabel.fontColor = Palette.textSecondary
        agentLabel.position = CGPoint(x: 22, y: size.height - 152)
        hudNode.addChild(agentLabel)

        inventoryLabel.fontSize = 11
        inventoryLabel.horizontalAlignmentMode = .right
        inventoryLabel.position = CGPoint(x: size.width - 22, y: size.height - 86)
        hudNode.addChild(inventoryLabel)

        shelterLabel.fontSize = 11
        shelterLabel.horizontalAlignmentMode = .right
        shelterLabel.fontColor = Palette.success
        shelterLabel.position = CGPoint(x: size.width - 22, y: size.height - 108)
        hudNode.addChild(shelterLabel)

        homeButton = MenuButtonNode(actionID: "nav.hub", title: "Modos", subtitle: "Clasico, Arsenal, Fantasma, AW", size: CGSize(width: 88, height: 44))
        homeButton.position = CGPoint(x: size.width - 56, y: size.height - 72)
        hudNode.addChild(homeButton)

        arcadeRunButton = MenuButtonNode(actionID: "arcade.run", title: "Run arcade", subtitle: "Desde el mundo", size: CGSize(width: 132, height: 44))
        arcadeRunButton.position = CGPoint(x: size.width / 2, y: size.height - 72)
        hudNode.addChild(arcadeRunButton)

        shelterUpgradeButton = MenuButtonNode(actionID: "shelter.upgrade", title: "Refugio+", subtitle: "Mejorar", size: CGSize(width: 112, height: 44))
        shelterUpgradeButton.position = CGPoint(x: 70, y: size.height - 72)
        hudNode.addChild(shelterUpgradeButton)

        abilityButtons.removeAll()
        let row1Y: CGFloat = 118
        let row2Y: CGFloat = 60
        let col: [CGFloat] = [-118, 0, 118]
        let row1: [WorldAbility] = [.returnToShelter, .scan, .dash]
        let row2: [WorldAbility] = [.sprint, .wideCapture, .autoGather]
        for (i, ability) in row1.enumerated() {
            let btn = MenuButtonNode(
                actionID: "wability.\(ability.rawValue)",
                title: ability.displayTitle,
                subtitle: "Listo",
                size: CGSize(width: 104, height: 44)
            )
            btn.position = CGPoint(x: size.width / 2 + col[i], y: row1Y)
            hudNode.addChild(btn)
            abilityButtons[ability] = btn
        }
        for (i, ability) in row2.enumerated() {
            let btn = MenuButtonNode(
                actionID: "wability.\(ability.rawValue)",
                title: ability.displayTitle,
                subtitle: "Listo",
                size: CGSize(width: 104, height: 44)
            )
            btn.position = CGPoint(x: size.width / 2 + col[i], y: row2Y)
            hudNode.addChild(btn)
            abilityButtons[ability] = btn
        }

        modeButton = MenuButtonNode(actionID: "mode.cycle", title: "Control", subtitle: snapshot.controlMode.rawValue, size: CGSize(width: 100, height: 48))
        modeButton.position = CGPoint(x: size.width / 2 - 120, y: 48)
        hudNode.addChild(modeButton)

        backButton = MenuButtonNode(actionID: "back.menu", title: "Arcade", subtitle: "Clasico", size: CGSize(width: 100, height: 48))
        backButton.position = CGPoint(x: size.width / 2 + 120, y: 48)
        hudNode.addChild(backButton)

        #if DEBUG
        debugTelemetryLabel.fontSize = 9
        debugTelemetryLabel.horizontalAlignmentMode = .left
        debugTelemetryLabel.verticalAlignmentMode = .bottom
        debugTelemetryLabel.fontColor = Palette.textSecondary.withAlphaComponent(0.85)
        debugTelemetryLabel.position = CGPoint(x: 12, y: 118)
        debugTelemetryLabel.preferredMaxLayoutWidth = size.width - 24
        debugTelemetryLabel.numberOfLines = 4
        hudNode.addChild(debugTelemetryLabel)
        #endif
    }

    private func spawnInitialSquares() {
        let pad: CGFloat = 40
        let minX = worldBounds.minX + pad
        let maxX = worldBounds.maxX - pad
        let minY = worldBounds.minY + pad
        let maxY = worldBounds.maxY - pad
        guard minX < maxX, minY < maxY else {
            return
        }
        let kinds = ArtificialWorldSquareKind.allCases
        for _ in 0..<14 {
            let kind = kinds.randomElement()!
            let pos = CGPoint(
                x: CGFloat.random(in: minX...maxX),
                y: CGFloat.random(in: minY...maxY)
            )
            if shelterRect.contains(pos) { continue }
            let vel = CGVector(dx: CGFloat.random(in: -55...55), dy: CGFloat.random(in: -55...55))
            let id = UUID()
            let body = WorldSquareBody(id: id, position: pos, velocity: vel, kind: kind)
            squares.append(body)

            let node = SKShapeNode(rectOf: CGSize(width: squareSize, height: squareSize), cornerRadius: 4)
            node.fillColor = fillColor(for: kind)
            node.strokeColor = .white
            node.lineWidth = 1.2
            node.position = pos
            node.zPosition = 4
            worldNode.addChild(node)
            squareNodes[id] = node
        }
    }

    private func updateHUD(currentTime: TimeInterval) {
        hungerLabel.text = String(format: "Hambre %.0f%%", snapshot.hunger * 100)
        hungerLabel.fontColor = snapshot.hunger < 0.35 ? Palette.danger : Palette.textPrimary
        energyLabel.text = String(format: "Energia %.0f%%", snapshot.energy * 100)
        energyLabel.fontColor = snapshot.energy < 0.35 ? Palette.warning : Palette.textPrimary
        modeLabel.text = "Modo: \(snapshot.controlMode.rawValue) (hibrido = agente si bajas)"
        modeButton.updateSubtitle(snapshot.controlMode.rawValue)
        agentLabel.text = "Agente: \(brain.state.rawValue) — \(brain.utilitySummaryLine(player: playerNode.position, hunger: snapshot.hunger, energy: snapshot.energy, squares: squares))"
        inventoryLabel.text = "Inv \(snapshot.inventoryItemIds.count) items"
        shelterLabel.text = "Refugio nv.\(snapshot.shelterLevel)"
        let resCount = ArtificialWorldSimulation.resourceItemCount(inventoryItemIds: snapshot.inventoryItemIds)
        let upCost = ArtificialWorldSimulation.shelterUpgradeCost(currentLevel: snapshot.shelterLevel)
        shelterUpgradeButton.updateSubtitle(resCount >= upCost ? "\(upCost) res" : "faltan \(upCost - resCount)")

        for (ability, btn) in abilityButtons {
            guard snapshot.canUse(ability) else {
                btn.updateSubtitle("Bloq.")
                continue
            }
            let readyAt = abilityCooldownEnds[ability] ?? 0
            if currentTime < readyAt {
                btn.updateSubtitle(String(format: "%.1fs", readyAt - currentTime))
            } else {
                btn.updateSubtitle("Listo")
            }
        }

        #if DEBUG
        if let tel = telemetry as? AppTelemetry {
            let tail = tel.recentEvents.suffix(3).map { "\($0.name)" }.joined(separator: " | ")
            debugTelemetryLabel.text = "dbg tel: \(tail)"
        }
        #endif
    }

    private func showBriefStatus(_ text: String, color: UIColor) {
        agentLabel.text = text
        agentLabel.fontColor = color
        run(.sequence([.wait(forDuration: 0.9), .run { [weak self] in
            self?.agentLabel.fontColor = Palette.textSecondary
        }]))
    }

    private func logAgentMemorySummary(currentTime: TimeInterval) {
        let summary = "[\(brain.state.rawValue)] h:\(String(format: "%.2f", snapshot.hunger)) e:\(String(format: "%.2f", snapshot.energy)) sq:\(squares.count)"
        let entry = AgentMemoryEntry(id: UUID(), summary: summary, createdAt: Date(), relatedEventKind: "tick")
        try? memoryStore.append(entry)
    }

    private func persistSnapshot() {
        snapshot.lastSavedAt = Date()
        do {
            try worldRepository.saveSnapshot(snapshot)
        } catch {}
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if let button = button(at: location) {
            handleButton(button)
            return
        }
        let inShelter = shelterRect.contains(playerNode.position)
        let agentDriving = shouldUseAgentSteering(inShelter: inShelter)
        if snapshot.controlMode == .manual, worldBounds.contains(location) {
            targetPoint = location
        } else if snapshot.controlMode == .hybrid, !agentDriving, worldBounds.contains(location) {
            targetPoint = location
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self), worldBounds.contains(location) else { return }
        if snapshot.controlMode == .manual || snapshot.controlMode == .hybrid {
            targetPoint = location
        }
    }

    private func handleButton(_ button: MenuButtonNode) {
        let currentTime = lastUpdateTime == 0 ? CACurrentMediaTime() : lastUpdateTime
        switch button.actionID {
        case "mode.cycle":
            let all = PlayerControlMode.allCases
            let idx = all.firstIndex(of: snapshot.controlMode) ?? 0
            snapshot.controlMode = all[(idx + 1) % all.count]
            brain.reset()
            telemetry.logEvent("control_mode_changed", parameters: ["mode": snapshot.controlMode.rawValue])
            soundManager.playButtonTap()
            hapticsManager.tap()
        case "back.menu":
            persistSnapshot()
            AppLaunchPreferences.lastExperience = .arcadeHub
            telemetry.logEvent("world_exited", parameters: [:])
            soundManager.playButtonTap()
            hapticsManager.tap()
            present(ModeSelectScene(sceneSize: size))
        case "nav.hub":
            persistSnapshot()
            AppLaunchPreferences.lastExperience = .arcadeHub
            soundManager.playButtonTap()
            hapticsManager.tap()
            present(ModeSelectScene(sceneSize: size))
        case "arcade.run":
            persistSnapshot()
            let progress = saveManager.loadProgress()
            var mode = progress.lastSelectedMode
            if !progress.isModeUnlocked(mode) {
                mode = .original
            }
            ArcadeWorldBridge.returnToArtificialWorldAfterRun = true
            telemetry.logEvent("arcade_run_from_world", parameters: ["mode": mode.rawValue])
            soundManager.playButtonTap()
            hapticsManager.tap()
            present(GameScene(sceneSize: size, gameMode: mode))
        case "shelter.upgrade":
            tryUpgradeShelter()
        default:
            if button.actionID.hasPrefix("wability."),
               let raw = button.actionID.split(separator: ".").last,
               let ability = WorldAbility(rawValue: String(raw)) {
                tryActivateWorldAbility(ability, currentTime: currentTime)
            }
        }
    }

    private func tryUpgradeShelter() {
        let cost = ArtificialWorldSimulation.shelterUpgradeCost(currentLevel: snapshot.shelterLevel)
        let have = ArtificialWorldSimulation.resourceItemCount(inventoryItemIds: snapshot.inventoryItemIds)
        guard have >= cost else {
            showBriefStatus("Necesitas \(cost) recursos (items res_). Tienes \(have).", color: Palette.warning)
            return
        }
        var removed = 0
        while removed < cost {
            guard let idx = snapshot.inventoryItemIds.firstIndex(where: { $0.hasPrefix("res_") }) else {
                break
            }
            snapshot.inventoryItemIds.remove(at: idx)
            removed += 1
        }
        snapshot.shelterLevel += 1
        telemetry.logEvent("shelter_upgraded", parameters: ["level": "\(snapshot.shelterLevel)"])
        soundManager.playSuccess()
        hapticsManager.success()
        buildLevel()
    }

    private func tryActivateWorldAbility(_ ability: WorldAbility, currentTime: TimeInterval) {
        guard snapshot.canUse(ability) else {
            showBriefStatus("Habilidad bloqueada.", color: Palette.textSecondary)
            return
        }
        let readyAt = abilityCooldownEnds[ability] ?? 0
        guard currentTime >= readyAt else {
            return
        }
        abilityCooldownEnds[ability] = currentTime + ability.cooldownSeconds
        telemetry.logEvent("world_ability", parameters: ["ability": ability.rawValue])

        switch ability {
        case .returnToShelter:
            playerNode.position = shelterCenter
            playerVelocity = .zero
            targetPoint = nil
            snapshot.playerPositionX = Double(shelterCenter.x)
            snapshot.playerPositionY = Double(shelterCenter.y)
        case .scan:
            scanUntil = currentTime + 4.2
        case .sprint:
            sprintUntil = currentTime + 2.8
        case .wideCapture:
            wideCaptureUntil = currentTime + 7
        case .autoGather:
            autoGatherUntil = currentTime + 5
        case .dash:
            let dir: CGVector
            if let tp = targetPoint {
                let dx = tp.x - playerNode.position.x
                let dy = tp.y - playerNode.position.y
                let m = max(1, hypot(dx, dy))
                dir = CGVector(dx: dx / m * 320, dy: dy / m * 320)
            } else if hypot(playerVelocity.dx, playerVelocity.dy) > 4 {
                let n = playerVelocity.normalized
                dir = CGVector(dx: n.dx * 280, dy: n.dy * 280)
            } else {
                dir = CGVector(dx: 0, dy: 220)
            }
            playerVelocity.dx += dir.dx
            playerVelocity.dy += dir.dy
        }
        soundManager.playSuccess()
        hapticsManager.tap()
    }

    private func refreshScanHighlight(currentTime: TimeInterval) {
        let scanning = currentTime < scanUntil
        for sq in squares {
            guard let node = squareNodes[sq.id] else { continue }
            if scanning, snapshot.canUse(.scan), sq.kind == .hostile || sq.kind == .nutritious {
                node.strokeColor = Palette.warning
                node.lineWidth = 3
            } else {
                node.strokeColor = .white
                node.lineWidth = 1.2
            }
        }
    }
}
