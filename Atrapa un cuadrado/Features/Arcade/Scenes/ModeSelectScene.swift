import SpriteKit

/// Distribuye strip + 4 tarjetas según altura de escena (iPhone pequeño vs grande).
private struct ModeSelectMetrics {
    let cardSize: CGSize
    let rowSpacing: CGFloat
    let stripSize: CGSize
    let stripCenterY: CGFloat
    let firstCardCenterY: CGFloat
    let footerCenterY: CGFloat
    let bankFont: CGFloat
    let summaryFont: CGFloat
    let cardTitleFont: CGFloat
    let awTitleFont: CGFloat
    let hookFont: CGFloat
    let minorFont: CGFloat
    let iconSide: CGFloat
    let panelCorner: CGFloat

    static func make(for scene: CGSize) -> ModeSelectMetrics {
        let w = scene.width
        let h = scene.height
        let topMax = h - 138
        let bottomReserve: CGFloat = h < 640 ? 46 : 52
        var cardHeight: CGFloat = h < 720 ? 86 : 104
        var rowSpacing: CGFloat = h < 720 ? 94 : 112
        var stripHeight: CGFloat = h < 720 ? 72 : 88

        while cardHeight >= 72 {
            let y3 = bottomReserve + cardHeight / 2
            let y0 = y3 + 3 * rowSpacing
            let stripCenter = y0 + cardHeight / 2 + 10 + stripHeight / 2
            if stripCenter <= topMax {
                let tight = h < 720
                return ModeSelectMetrics(
                    cardSize: CGSize(width: w - 46, height: cardHeight),
                    rowSpacing: rowSpacing,
                    stripSize: CGSize(width: w - 42, height: stripHeight),
                    stripCenterY: stripCenter,
                    firstCardCenterY: y0,
                    footerCenterY: h < 640 ? 26 : 34,
                    bankFont: tight ? 20 : 22,
                    summaryFont: tight ? 11 : 12,
                    cardTitleFont: tight ? 18 : 20,
                    awTitleFont: tight ? 19 : 22,
                    hookFont: tight ? 10 : 11,
                    minorFont: 10,
                    iconSide: tight ? 56 : 64,
                    panelCorner: tight ? 22 : 28
                )
            }
            cardHeight -= 4
            rowSpacing -= 2
            stripHeight -= 2
        }

        let cardHeightFinal: CGFloat = 72
        let rowSpacingFinal: CGFloat = 86
        let stripHeightFinal: CGFloat = 64
        let y3 = bottomReserve + cardHeightFinal / 2
        let y0 = y3 + 3 * rowSpacingFinal
        let stripCenter = min(topMax, y0 + cardHeightFinal / 2 + 8 + stripHeightFinal / 2)
        return ModeSelectMetrics(
            cardSize: CGSize(width: w - 46, height: cardHeightFinal),
            rowSpacing: rowSpacingFinal,
            stripSize: CGSize(width: w - 42, height: stripHeightFinal),
            stripCenterY: stripCenter,
            firstCardCenterY: y0,
            footerCenterY: 24,
            bankFont: 18,
            summaryFont: 10,
            cardTitleFont: 17,
            awTitleFont: 18,
            hookFont: 10,
            minorFont: 9,
            iconSide: 52,
            panelCorner: 20
        )
    }
}

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
        telemetry.logEvent("arcade_mode_select_shown", parameters: [:])
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

        let m = ModeSelectMetrics.make(for: size)

        let strip = makePanel(
            size: m.stripSize,
            stroke: Palette.stroke,
            fill: Palette.panel.withAlphaComponent(0.94),
            cornerRadius: m.panelCorner
        )
        strip.position = CGPoint(x: size.width / 2, y: m.stripCenterY)
        addChild(strip)

        let bank = makeLabel(
            text: "Banco \(progress.coins) monedas",
            fontNamed: GameConfig.titleFont,
            fontSize: m.bankFont,
            color: Palette.warning,
            width: strip.frame.width - 34,
            lines: 1
        )
        bank.position = CGPoint(x: 0, y: m.stripSize.height < 80 ? 14 : 18)
        strip.addChild(bank)

        let summary = makeLabel(
            text: "Ultima run arcade: \(progress.lastSelectedMode.title)  •  Toca una tarjeta.",
            fontNamed: GameConfig.coinFont,
            fontSize: m.summaryFont,
            color: Palette.textSecondary,
            width: strip.frame.width - 34,
            lines: 2
        )
        summary.position = CGPoint(x: 0, y: m.stripSize.height < 80 ? -10 : -12)
        strip.addChild(summary)

        for (index, mode) in GameMode.allCases.enumerated() {
            let card = modeCard(for: mode, metrics: m)
            card.position = CGPoint(x: size.width / 2, y: m.firstCardCenterY - CGFloat(index) * m.rowSpacing)
            addChild(card)
        }

        let worldIndex = GameMode.allCases.count
        let worldCard = artificialWorldCard(metrics: m)
        worldCard.position = CGPoint(x: size.width / 2, y: m.firstCardCenterY - CGFloat(worldIndex) * m.rowSpacing)
        addChild(worldCard)

        let footer = makeLabel(
            text: "Los tres primeros son el arcade original; el cuarto es el modo persistente nuevo.",
            fontNamed: GameConfig.coinFont,
            fontSize: m.hookFont,
            color: Palette.textSecondary.withAlphaComponent(0.72),
            width: size.width - 60,
            lines: 2
        )
        footer.position = CGPoint(x: size.width / 2, y: m.footerCenterY)
        addChild(footer)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let location = touch.location(in: self)

        if nodeName(at: location, withPrefix: "world.") == "world.artificial" {
            telemetry.logEvent("arcade_mode_select_world", parameters: [:])
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
        telemetry.logEvent("arcade_mode_selected", parameters: ["mode": mode.rawValue])
        soundManager.playButtonTap()
        hapticsManager.tap()
        present(MainMenuScene(sceneSize: size, gameMode: mode))
    }

    private func artificialWorldCard(metrics m: ModeSelectMetrics) -> SKShapeNode {
        let size = m.cardSize
        let accent = Palette.accent
        let card = makePanel(
            size: size,
            stroke: accent,
            fill: Palette.panel.withAlphaComponent(0.94),
            cornerRadius: m.panelCorner
        )
        card.name = "world.artificial"
        card.isAccessibilityElement = true
        card.accessibilityLabel = "Mundo artificial, Artificial World"
        card.lineWidth = 2.5
        card.glowWidth = 4

        let barH = max(24, size.height - 18)
        let accentBar = SKShapeNode(rectOf: CGSize(width: 10, height: barH), cornerRadius: 5)
        accentBar.fillColor = accent
        accentBar.strokeColor = .clear
        accentBar.position = CGPoint(x: -size.width / 2 + 18, y: 0)
        card.addChild(accentBar)

        let iconR = m.iconSide / 2
        let iconPanel = SKShapeNode(rectOf: CGSize(width: m.iconSide, height: m.iconSide), cornerRadius: iconR * 0.62)
        iconPanel.fillColor = accent.withAlphaComponent(0.14)
        iconPanel.strokeColor = accent.withAlphaComponent(0.65)
        iconPanel.lineWidth = 1.5
        iconPanel.position = CGPoint(x: size.width / 2 - iconR - 20, y: 4)
        card.addChild(iconPanel)

        let grid = SKShapeNode(rectOf: CGSize(width: m.iconSide * 0.44, height: m.iconSide * 0.44), cornerRadius: 6)
        grid.fillColor = accent.withAlphaComponent(0.2)
        grid.strokeColor = accent
        grid.lineWidth = 2
        iconPanel.addChild(grid)

        let titleY: CGFloat = size.height < 92 ? 26 : 30
        let title = makeLabel(
            text: "ARTIFICIAL WORLD",
            fontNamed: GameConfig.titleFont,
            fontSize: m.awTitleFont,
            color: Palette.textPrimary,
            width: size.width - m.iconSide - 56,
            lines: 1
        )
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -size.width / 2 + 36, y: titleY)
        card.addChild(title)

        let badge = SKShapeNode(rectOf: CGSize(width: 118, height: 22), cornerRadius: 11)
        badge.fillColor = Palette.success.withAlphaComponent(0.12)
        badge.strokeColor = Palette.success
        badge.lineWidth = 1.2
        badge.position = CGPoint(x: -size.width / 2 + 94, y: 4)
        card.addChild(badge)

        let badgeLabel = makeLabel(
            text: "MODO NUEVO",
            fontNamed: GameConfig.coinFont,
            fontSize: m.minorFont,
            color: Palette.success,
            width: 100,
            lines: 1
        )
        badgeLabel.position = CGPoint(x: 0, y: 6)
        badge.addChild(badgeLabel)

        let hook = makeLabel(
            text: "Mapa persistente, refugio, recursos y agente. No sustituye al arcade.",
            fontNamed: GameConfig.coinFont,
            fontSize: m.hookFont,
            color: Palette.textSecondary,
            width: size.width - m.iconSide - 64,
            lines: 3
        )
        hook.horizontalAlignmentMode = .left
        hook.position = CGPoint(x: -size.width / 2 + 36, y: -20)
        card.addChild(hook)

        let actionPlate = SKShapeNode(rectOf: CGSize(width: 84, height: 20), cornerRadius: 10)
        actionPlate.fillColor = Palette.success.withAlphaComponent(0.12)
        actionPlate.strokeColor = Palette.success
        actionPlate.lineWidth = 1.2
        actionPlate.position = CGPoint(x: size.width / 2 - iconR - 20, y: -34)
        card.addChild(actionPlate)

        let action = makeLabel(
            text: "ENTRAR",
            fontNamed: GameConfig.coinFont,
            fontSize: m.minorFont,
            color: Palette.success,
            width: 72,
            lines: 1
        )
        action.position = CGPoint(x: 0, y: 5)
        actionPlate.addChild(action)

        return card
    }

    private func modeCard(for mode: GameMode, metrics m: ModeSelectMetrics) -> SKShapeNode {
        let size = m.cardSize
        let unlocked = progress.isModeUnlocked(mode)
        let active = mode == progress.lastSelectedMode
        let card = makePanel(
            size: size,
            stroke: unlocked ? mode.summaryAccent : Palette.textSecondary,
            fill: unlocked ? Palette.panel.withAlphaComponent(active ? 0.96 : 0.9) : Palette.panel.withAlphaComponent(0.62),
            cornerRadius: m.panelCorner
        )
        card.name = "mode.\(mode.rawValue)"
        card.lineWidth = active ? 3 : 2
        card.glowWidth = active ? 5 : 0

        let barH = max(24, size.height - 18)
        let accentBar = SKShapeNode(rectOf: CGSize(width: 10, height: barH), cornerRadius: 5)
        accentBar.fillColor = unlocked ? mode.summaryAccent : Palette.textSecondary
        accentBar.strokeColor = .clear
        accentBar.position = CGPoint(x: -size.width / 2 + 18, y: 0)
        card.addChild(accentBar)

        let iconR = m.iconSide / 2
        let iconPanel = SKShapeNode(rectOf: CGSize(width: m.iconSide, height: m.iconSide), cornerRadius: iconR * 0.62)
        iconPanel.fillColor = (unlocked ? mode.summaryAccent : Palette.textSecondary).withAlphaComponent(0.12)
        iconPanel.strokeColor = unlocked ? mode.summaryAccent.withAlphaComponent(0.7) : Palette.textSecondary.withAlphaComponent(0.6)
        iconPanel.lineWidth = 1.5
        iconPanel.position = CGPoint(x: size.width / 2 - iconR - 20, y: 4)
        card.addChild(iconPanel)

        let titleY: CGFloat = size.height < 92 ? 26 : 30
        let title = makeLabel(
            text: mode.title.uppercased(),
            fontNamed: GameConfig.titleFont,
            fontSize: m.cardTitleFont,
            color: unlocked ? Palette.textPrimary : Palette.textSecondary,
            width: size.width - m.iconSide - 56,
            lines: 1
        )
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -size.width / 2 + 36, y: titleY)
        card.addChild(title)

        let badge = SKShapeNode(rectOf: CGSize(width: 126, height: 22), cornerRadius: 11)
        badge.fillColor = (unlocked ? mode.summaryAccent : Palette.warning).withAlphaComponent(0.12)
        badge.strokeColor = unlocked ? mode.summaryAccent : Palette.warning
        badge.lineWidth = 1.2
        badge.position = CGPoint(x: -size.width / 2 + 94, y: 4)
        card.addChild(badge)

        let badgeLabel = makeLabel(
            text: unlocked ? mode.selectorBadge.uppercased() : "BLOQUEADO",
            fontNamed: GameConfig.coinFont,
            fontSize: m.minorFont,
            color: unlocked ? mode.summaryAccent : Palette.warning,
            width: 112,
            lines: 1
        )
        badgeLabel.position = CGPoint(x: 0, y: 6)
        badge.addChild(badgeLabel)

        let hook = makeLabel(
            text: unlocked ? compactHook(for: mode) : mode.lockedHint,
            fontNamed: GameConfig.coinFont,
            fontSize: m.hookFont,
            color: unlocked ? Palette.textSecondary : Palette.warning,
            width: size.width - m.iconSide - 64,
            lines: 3
        )
        hook.horizontalAlignmentMode = .left
        hook.position = CGPoint(x: -size.width / 2 + 36, y: -20)
        card.addChild(hook)

        let actionPlate = SKShapeNode(rectOf: CGSize(width: 84, height: 20), cornerRadius: 10)
        actionPlate.fillColor = (unlocked ? Palette.success : Palette.textSecondary).withAlphaComponent(0.12)
        actionPlate.strokeColor = unlocked ? Palette.success : Palette.textSecondary.withAlphaComponent(0.6)
        actionPlate.lineWidth = 1.2
        actionPlate.position = CGPoint(x: size.width / 2 - iconR - 20, y: -34)
        card.addChild(actionPlate)

        let action = makeLabel(
            text: unlocked ? "ENTRAR" : mode.accessLabel.uppercased(),
            fontNamed: GameConfig.coinFont,
            fontSize: m.minorFont,
            color: unlocked ? Palette.success : Palette.textSecondary,
            width: 72,
            lines: 2
        )
        action.position = CGPoint(x: 0, y: 5)
        actionPlate.addChild(action)

        let glyph = modeGlyph(for: mode, unlocked: unlocked, iconSide: m.iconSide)
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

    private func modeGlyph(for mode: GameMode, unlocked: Bool, iconSide: CGFloat) -> SKNode {
        let container = SKNode()
        let r = iconSide * 0.32

        switch mode {
        case .original:
            let ring = SKShapeNode(circleOfRadius: r)
            ring.strokeColor = unlocked ? Palette.warning : Palette.textSecondary
            ring.lineWidth = 3
            ring.fillColor = .clear
            container.addChild(ring)

            let core = SKShapeNode(circleOfRadius: r * 0.38)
            core.fillColor = (unlocked ? Palette.warning : Palette.textSecondary).withAlphaComponent(0.26)
            core.strokeColor = .clear
            container.addChild(core)
        case .evolution:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: r * 1.1))
            path.addLine(to: CGPoint(x: r * 0.88, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -r * 1.1))
            path.addLine(to: CGPoint(x: -r * 0.88, y: 0))
            path.closeSubpath()
            let shard = SKShapeNode(path: path)
            shard.fillColor = (unlocked ? Palette.stroke : Palette.textSecondary).withAlphaComponent(0.18)
            shard.strokeColor = unlocked ? Palette.stroke : Palette.textSecondary
            shard.lineWidth = 2.5
            container.addChild(shard)
        case .ghost:
            for index in 0..<3 {
                let slash = SKShapeNode(rectOf: CGSize(width: r * 1.4 - CGFloat(index) * 4, height: 3), cornerRadius: 2)
                slash.fillColor = unlocked ? mode.summaryAccent : Palette.textSecondary
                slash.strokeColor = .clear
                slash.position = CGPoint(x: 0, y: r * 0.44 - CGFloat(index) * 8)
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
