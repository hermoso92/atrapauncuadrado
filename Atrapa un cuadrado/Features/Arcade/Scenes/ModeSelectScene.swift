import SpriteKit

final class ModeSelectScene: BaseScene {
    private var progress = GameProgress.defaultProgress
    private var hasLoadedProgress = false

    override init(sceneSize: CGSize, gameMode: GameMode? = nil, dependencies: SceneDependencies? = nil) {
        super.init(sceneSize: sceneSize, gameMode: nil, dependencies: dependencies)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        progress = saveManager.loadProgress()
        hasLoadedProgress = true
        buildScene()
        Task { @MainActor [weak self] in
            await self?.purchaseManager.refreshEntitlements()
            guard let self else {
                return
            }
            self.progress = self.saveManager.loadProgress()
            self.buildScene()
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard hasLoadedProgress else { return }
        buildScene()
    }

    private func buildScene() {
        removeAllChildren()
        setupBackdrop(
            title: "ATRAPA UN CUADRADO",
            subtitle: "Cuatro modos: Clasico, Arsenal, Fantasma y Mundo artificial."
        )

        let strip = makePanel(
            size: CGSize(width: size.width - 42, height: 88),
            stroke: Palette.stroke,
            fill: Palette.panel.withAlphaComponent(0.94)
        )
        strip.position = CGPoint(x: size.width / 2, y: size.height - 200)
        addChild(strip)

        let bank = makeLabel(
            text: "Banco \(progress.coins) monedas",
            fontNamed: GameConfig.titleFont,
            fontSize: 22,
            color: Palette.warning,
            width: strip.frame.width - 34,
            lines: 1
        )
        bank.position = CGPoint(x: 0, y: 18)
        strip.addChild(bank)

        let summary = makeLabel(
            text: "Ultima run arcade: \(progress.lastSelectedMode.title)  •  Toca una tarjeta.",
            fontNamed: GameConfig.coinFont,
            fontSize: 12,
            color: Palette.textSecondary,
            width: strip.frame.width - 34,
            lines: 2
        )
        summary.position = CGPoint(x: 0, y: -12)
        strip.addChild(summary)

        let cardSize = CGSize(width: size.width - 46, height: 108)
        let spacing: CGFloat = 116
        let startY = size.height - 292

        for (index, mode) in GameMode.allCases.enumerated() {
            let card = modeCard(for: mode, size: cardSize)
            card.position = CGPoint(x: size.width / 2, y: startY - CGFloat(index) * spacing)
            addChild(card)
        }

        let worldIndex = GameMode.allCases.count
        let worldCard = artificialWorldCard(size: cardSize)
        worldCard.position = CGPoint(x: size.width / 2, y: startY - CGFloat(worldIndex) * spacing)
        addChild(worldCard)

        let footer = makeLabel(
            text: "Los tres primeros son el arcade original; el cuarto es el modo persistente nuevo.",
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: Palette.textSecondary.withAlphaComponent(0.72),
            width: size.width - 60,
            lines: 2
        )
        footer.position = CGPoint(x: size.width / 2, y: 36)
        addChild(footer)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let location = touch.location(in: self)

        if nodeName(at: location, withPrefix: "world.") == "world.artificial" {
            soundManager.playButtonTap()
            hapticsManager.tap()
            AppLaunchPreferences.lastExperience = .artificialWorld
            let repo = ArtificialWorldPersistence.worldRepository()
            let memory = ArtificialWorldPersistence.agentMemoryStore()
            present(ArtificialWorldScene(sceneSize: size, worldRepository: repo, memoryStore: memory))
            return
        }

        guard let modeName = nodeName(at: location, withPrefix: "mode.") else {
            return
        }

        let rawValue = String(modeName.dropFirst("mode.".count))
        guard let mode = GameMode(rawValue: rawValue) else {
            return
        }

        guard progress.isModeUnlocked(mode) else {
            soundManager.playWarning()
            hapticsManager.warning()
            return
        }

        _ = saveManager.update { progress in
            progress.lastSelectedMode = mode
        }
        AppLaunchPreferences.lastExperience = .arcadeHub
        soundManager.playButtonTap()
        hapticsManager.tap()
        present(MainMenuScene(sceneSize: size, gameMode: mode))
    }

    private func artificialWorldCard(size: CGSize) -> SKShapeNode {
        let accent = Palette.accent
        let card = makePanel(
            size: size,
            stroke: accent,
            fill: Palette.panel.withAlphaComponent(0.94),
            cornerRadius: 28
        )
        card.name = "world.artificial"
        card.lineWidth = 2.5
        card.glowWidth = 4

        let accentBar = SKShapeNode(rectOf: CGSize(width: 10, height: size.height - 22), cornerRadius: 5)
        accentBar.fillColor = accent
        accentBar.strokeColor = .clear
        accentBar.position = CGPoint(x: -size.width / 2 + 18, y: 0)
        card.addChild(accentBar)

        let iconPanel = SKShapeNode(rectOf: CGSize(width: 64, height: 64), cornerRadius: 20)
        iconPanel.fillColor = accent.withAlphaComponent(0.14)
        iconPanel.strokeColor = accent.withAlphaComponent(0.65)
        iconPanel.lineWidth = 1.5
        iconPanel.position = CGPoint(x: size.width / 2 - 52, y: 4)
        card.addChild(iconPanel)

        let grid = SKShapeNode(rectOf: CGSize(width: 28, height: 28), cornerRadius: 6)
        grid.fillColor = accent.withAlphaComponent(0.2)
        grid.strokeColor = accent
        grid.lineWidth = 2
        iconPanel.addChild(grid)

        let title = makeLabel(
            text: "ARTIFICIAL WORLD",
            fontNamed: GameConfig.titleFont,
            fontSize: 22,
            color: Palette.textPrimary,
            width: size.width - 150,
            lines: 1
        )
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -size.width / 2 + 36, y: 30)
        card.addChild(title)

        let badge = SKShapeNode(rectOf: CGSize(width: 120, height: 24), cornerRadius: 12)
        badge.fillColor = Palette.success.withAlphaComponent(0.12)
        badge.strokeColor = Palette.success
        badge.lineWidth = 1.2
        badge.position = CGPoint(x: -size.width / 2 + 96, y: 4)
        card.addChild(badge)

        let badgeLabel = makeLabel(
            text: "MODO NUEVO",
            fontNamed: GameConfig.coinFont,
            fontSize: 10,
            color: Palette.success,
            width: 104,
            lines: 1
        )
        badgeLabel.position = CGPoint(x: 0, y: 7)
        badge.addChild(badgeLabel)

        let hook = makeLabel(
            text: "Mapa persistente, refugio, recursos y agente. No sustituye al arcade.",
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: Palette.textSecondary,
            width: size.width - 160,
            lines: 3
        )
        hook.horizontalAlignmentMode = .left
        hook.position = CGPoint(x: -size.width / 2 + 36, y: -22)
        card.addChild(hook)

        let actionPlate = SKShapeNode(rectOf: CGSize(width: 88, height: 22), cornerRadius: 11)
        actionPlate.fillColor = Palette.success.withAlphaComponent(0.12)
        actionPlate.strokeColor = Palette.success
        actionPlate.lineWidth = 1.2
        actionPlate.position = CGPoint(x: size.width / 2 - 52, y: -36)
        card.addChild(actionPlate)

        let action = makeLabel(
            text: "ENTRAR",
            fontNamed: GameConfig.coinFont,
            fontSize: 10,
            color: Palette.success,
            width: 76,
            lines: 1
        )
        action.position = CGPoint(x: 0, y: 6)
        actionPlate.addChild(action)

        return card
    }

    private func modeCard(for mode: GameMode, size: CGSize) -> SKShapeNode {
        let unlocked = progress.isModeUnlocked(mode)
        let active = mode == progress.lastSelectedMode
        let card = makePanel(
            size: size,
            stroke: unlocked ? mode.summaryAccent : Palette.textSecondary,
            fill: unlocked ? Palette.panel.withAlphaComponent(active ? 0.96 : 0.9) : Palette.panel.withAlphaComponent(0.62),
            cornerRadius: 28
        )
        card.name = "mode.\(mode.rawValue)"
        card.lineWidth = active ? 3 : 2
        card.glowWidth = active ? 5 : 0

        let accentBar = SKShapeNode(rectOf: CGSize(width: 10, height: size.height - 22), cornerRadius: 5)
        accentBar.fillColor = unlocked ? mode.summaryAccent : Palette.textSecondary
        accentBar.strokeColor = .clear
        accentBar.position = CGPoint(x: -size.width / 2 + 18, y: 0)
        card.addChild(accentBar)

        let iconPanel = SKShapeNode(rectOf: CGSize(width: 64, height: 64), cornerRadius: 20)
        iconPanel.fillColor = (unlocked ? mode.summaryAccent : Palette.textSecondary).withAlphaComponent(0.12)
        iconPanel.strokeColor = unlocked ? mode.summaryAccent.withAlphaComponent(0.7) : Palette.textSecondary.withAlphaComponent(0.6)
        iconPanel.lineWidth = 1.5
        iconPanel.position = CGPoint(x: size.width / 2 - 52, y: 4)
        card.addChild(iconPanel)

        let title = makeLabel(
            text: mode.title.uppercased(),
            fontNamed: GameConfig.titleFont,
            fontSize: 20,
            color: unlocked ? Palette.textPrimary : Palette.textSecondary,
            width: size.width - 150,
            lines: 1
        )
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -size.width / 2 + 36, y: 30)
        card.addChild(title)

        let badge = SKShapeNode(rectOf: CGSize(width: 132, height: 24), cornerRadius: 12)
        badge.fillColor = (unlocked ? mode.summaryAccent : Palette.warning).withAlphaComponent(0.12)
        badge.strokeColor = unlocked ? mode.summaryAccent : Palette.warning
        badge.lineWidth = 1.2
        badge.position = CGPoint(x: -size.width / 2 + 96, y: 4)
        card.addChild(badge)

        let badgeLabel = makeLabel(
            text: unlocked ? mode.selectorBadge.uppercased() : "BLOQUEADO",
            fontNamed: GameConfig.coinFont,
            fontSize: 10,
            color: unlocked ? mode.summaryAccent : Palette.warning,
            width: 118,
            lines: 1
        )
        badgeLabel.position = CGPoint(x: 0, y: 7)
        badge.addChild(badgeLabel)

        let hook = makeLabel(
            text: unlocked ? compactHook(for: mode) : mode.lockedHint,
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: unlocked ? Palette.textSecondary : Palette.warning,
            width: size.width - 160,
            lines: 3
        )
        hook.horizontalAlignmentMode = .left
        hook.position = CGPoint(x: -size.width / 2 + 36, y: -22)
        card.addChild(hook)

        let actionPlate = SKShapeNode(rectOf: CGSize(width: 88, height: 22), cornerRadius: 11)
        actionPlate.fillColor = (unlocked ? Palette.success : Palette.textSecondary).withAlphaComponent(0.12)
        actionPlate.strokeColor = unlocked ? Palette.success : Palette.textSecondary.withAlphaComponent(0.6)
        actionPlate.lineWidth = 1.2
        actionPlate.position = CGPoint(x: size.width / 2 - 52, y: -36)
        card.addChild(actionPlate)

        let action = makeLabel(
            text: unlocked ? "ENTRAR" : mode.accessLabel.uppercased(),
            fontNamed: GameConfig.coinFont,
            fontSize: 10,
            color: unlocked ? Palette.success : Palette.textSecondary,
            width: 76,
            lines: 2
        )
        action.position = CGPoint(x: 0, y: 6)
        actionPlate.addChild(action)

        let glyph = modeGlyph(for: mode, unlocked: unlocked)
        glyph.position = .zero
        iconPanel.addChild(glyph)

        return card
    }

    private func compactHook(for mode: GameMode) -> String {
        switch mode {
        case .original:
            "Captura limpia, lectura pura y cero build."
        case .evolution:
            "Personajes, armas y habilidades con decisiones reales."
        case .ghost:
            "Version rota del juego. Mas presion, mas castigo."
        }
    }

    private func modeGlyph(for mode: GameMode, unlocked: Bool) -> SKNode {
        let container = SKNode()

        switch mode {
        case .original:
            let ring = SKShapeNode(circleOfRadius: 18)
            ring.strokeColor = unlocked ? Palette.warning : Palette.textSecondary
            ring.lineWidth = 3
            ring.fillColor = .clear
            container.addChild(ring)

            let core = SKShapeNode(circleOfRadius: 7)
            core.fillColor = (unlocked ? Palette.warning : Palette.textSecondary).withAlphaComponent(0.26)
            core.strokeColor = .clear
            container.addChild(core)
        case .evolution:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 16, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -20))
            path.addLine(to: CGPoint(x: -16, y: 0))
            path.closeSubpath()
            let shard = SKShapeNode(path: path)
            shard.fillColor = (unlocked ? Palette.stroke : Palette.textSecondary).withAlphaComponent(0.18)
            shard.strokeColor = unlocked ? Palette.stroke : Palette.textSecondary
            shard.lineWidth = 2.5
            container.addChild(shard)
        case .ghost:
            for index in 0..<3 {
                let slash = SKShapeNode(rectOf: CGSize(width: 26 - CGFloat(index) * 4, height: 3), cornerRadius: 2)
                slash.fillColor = unlocked ? mode.summaryAccent : Palette.textSecondary
                slash.strokeColor = .clear
                slash.position = CGPoint(x: 0, y: 8 - CGFloat(index) * 8)
                slash.zRotation = index.isMultiple(of: 2) ? 0.16 : -0.16
                container.addChild(slash)
            }
        }

        return container
    }

    private func makePanel(size: CGSize, stroke: UIColor, fill: UIColor, cornerRadius: CGFloat = 28) -> SKShapeNode {
        let panel = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        panel.fillColor = fill
        panel.strokeColor = stroke
        panel.lineWidth = 2
        return panel
    }

    private func makeLabel(text: String, fontNamed: String, fontSize: CGFloat, color: UIColor, width: CGFloat, lines: Int) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontNamed)
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.verticalAlignmentMode = .top
        label.horizontalAlignmentMode = .center
        label.preferredMaxLayoutWidth = width
        label.numberOfLines = lines
        label.lineBreakMode = .byWordWrapping
        return label
    }
}
