import SpriteKit

final class GameOverScene: BaseScene {
    private let mode: GameMode
    private let profile: GameModeProfile
    private let score: Int
    private let bestScore: Int
    private let coinsEarned: Int
    private let roundReached: Int
    private var hasMovedToView = false

    init(sceneSize: CGSize, gameMode: GameMode, score: Int, bestScore: Int, coinsEarned: Int, roundReached: Int) {
        self.mode = gameMode
        self.profile = GameModeProfile.profile(for: gameMode)
        self.score = score
        self.bestScore = bestScore
        self.coinsEarned = coinsEarned
        self.roundReached = roundReached
        super.init(sceneSize: sceneSize, gameMode: gameMode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        hasMovedToView = true
        buildScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard hasMovedToView else { return }
        buildScene()
    }

    private func buildScene() {
        removeAllChildren()
        setupBackdrop(
            title: "FIN DE RUN \(mode.title.uppercased())",
            subtitle: profile.gameOverSubtitle
        )

        let hero = makePanel(
            size: CGSize(width: size.width - 42, height: 138),
            stroke: performanceColor,
            fill: Palette.panel.withAlphaComponent(0.94)
        )
        hero.position = CGPoint(x: size.width / 2, y: size.height - 270)
        hero.glowWidth = 4
        addChild(hero)

        let scoreBadge = makeBadge(text: "RESULTADO", tint: performanceColor)
        scoreBadge.position = CGPoint(x: 0, y: 42)
        hero.addChild(scoreBadge)

        let scoreTitle = makeLabel(
            text: "Score \(score)",
            fontNamed: GameConfig.titleFont,
            fontSize: 34,
            color: Palette.warning,
            width: hero.frame.width - 34,
            lines: 1
        )
        scoreTitle.position = CGPoint(x: 0, y: 14)
        hero.addChild(scoreTitle)

        let rating = makeLabel(
            text: performanceTitle,
            fontNamed: GameConfig.coinFont,
            fontSize: 13,
            color: performanceColor,
            width: hero.frame.width - 34,
            lines: 2
        )
        rating.position = CGPoint(x: 0, y: -16)
        hero.addChild(rating)

        let sub = makeLabel(
            text: score >= bestScore ? "Nuevo techo o empate. La run ha dejado marca." : "El mejor registro sigue en \(bestScore).",
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: Palette.textSecondary,
            width: hero.frame.width - 34,
            lines: 2
        )
        sub.position = CGPoint(x: 0, y: -46)
        hero.addChild(sub)

        let cards = [
            ("BEST", "\(bestScore)", Palette.stroke),
            ("BANK+", "\(coinsEarned)", Palette.warning),
            (profile.roundLabelTitle.uppercased(), "\(roundReached)", Palette.success)
        ]

        let cardWidth = (size.width - 62) / 3
        for (index, item) in cards.enumerated() {
            let card = makePanel(
                size: CGSize(width: cardWidth, height: 92),
                stroke: item.2,
                fill: Palette.panel.withAlphaComponent(0.92),
                cornerRadius: 24
            )
            let x = 16 + cardWidth / 2 + CGFloat(index) * (cardWidth + 7)
            card.position = CGPoint(x: x, y: size.height - 430)
            addChild(card)

            let badge = makeLabel(
                text: item.0,
                fontNamed: GameConfig.coinFont,
                fontSize: 10,
                color: item.2,
                width: cardWidth - 18,
                lines: 1
            )
            badge.position = CGPoint(x: 0, y: 20)
            card.addChild(badge)

            let iconPlate = SKShapeNode(rectOf: CGSize(width: 30, height: 30), cornerRadius: 10)
            iconPlate.fillColor = item.2.withAlphaComponent(0.12)
            iconPlate.strokeColor = item.2.withAlphaComponent(0.5)
            iconPlate.lineWidth = 1.2
            iconPlate.position = CGPoint(x: 0, y: -2)
            card.addChild(iconPlate)

            let icon = makeLabel(
                text: metricSymbol(for: item.0),
                fontNamed: GameConfig.titleFont,
                fontSize: 14,
                color: item.2,
                width: 18,
                lines: 1
            )
            icon.position = CGPoint(x: 0, y: 8)
            iconPlate.addChild(icon)

            let value = makeLabel(
                text: item.1,
                fontNamed: GameConfig.titleFont,
                fontSize: 24,
                color: Palette.textPrimary,
                width: cardWidth - 18,
                lines: 1
            )
            value.position = CGPoint(x: 0, y: -28)
            card.addChild(value)
        }

        let actionPanel = makePanel(
            size: CGSize(width: size.width - 42, height: 164),
            stroke: performanceColor.withAlphaComponent(0.7),
            fill: Palette.panel.withAlphaComponent(0.9),
            cornerRadius: 28
        )
        actionPanel.position = CGPoint(x: size.width / 2, y: 174)
        addChild(actionPanel)

        let actionLabel = makeLabel(
            text: "SIGUIENTE PASO",
            fontNamed: GameConfig.coinFont,
            fontSize: 10,
            color: performanceColor,
            width: actionPanel.frame.width - 30,
            lines: 1
        )
        actionLabel.position = CGPoint(x: 0, y: 56)
        actionPanel.addChild(actionLabel)

        let retry = MenuButtonNode(actionID: "retry", title: "Reintentar", subtitle: "Entrar directo a otra run")
        retry.position = CGPoint(x: size.width / 2, y: 204)
        addChild(retry)

        let menu = MenuButtonNode(actionID: "menu", title: "Volver al modo", subtitle: "Cambiar carga o visitar arsenal")
        menu.position = CGPoint(x: size.width / 2, y: 122)
        addChild(menu)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self),
              let button = button(at: location) else {
            return
        }

        switch button.actionID {
        case "retry":
            soundManager.playButtonTap()
            hapticsManager.tap()
            present(GameScene(sceneSize: size, gameMode: mode))
        case "menu":
            soundManager.playButtonTap()
            hapticsManager.tap()
            present(MainMenuScene(sceneSize: size, gameMode: mode))
        default:
            break
        }
    }

    private var performanceTitle: String {
        switch score {
        case 0..<60:
            "Entrada fria. Aun no has roto el ritmo."
        case 60..<140:
            "Base firme. Ya hay control real."
        case 140..<260:
            "Run fuerte. Ya impusiste presencia."
        default:
            "Dominio total. Esta run ya marca el tono."
        }
    }

    private var performanceColor: UIColor {
        switch score {
        case 0..<60:
            Palette.textSecondary
        case 60..<140:
            Palette.warning
        case 140..<260:
            Palette.stroke
        default:
            Palette.success
        }
    }

    private func metricSymbol(for title: String) -> String {
        switch title {
        case "BEST":
            return "^"
        case "BANK+":
            return "$"
        default:
            return "#"
        }
    }

    private func makePanel(size: CGSize, stroke: UIColor, fill: UIColor, cornerRadius: CGFloat = 28) -> SKShapeNode {
        let panel = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        panel.fillColor = fill
        panel.strokeColor = stroke
        panel.lineWidth = 2
        return panel
    }

    private func makeBadge(text: String, tint: UIColor) -> SKShapeNode {
        let badge = SKShapeNode(rectOf: CGSize(width: 120, height: 28), cornerRadius: 14)
        badge.fillColor = tint.withAlphaComponent(0.12)
        badge.strokeColor = tint
        badge.lineWidth = 1.2

        let label = makeLabel(
            text: text,
            fontNamed: GameConfig.coinFont,
            fontSize: 10,
            color: tint,
            width: 100,
            lines: 1
        )
        label.position = CGPoint(x: 0, y: 8)
        badge.addChild(label)
        return badge
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
