import SpriteKit

@MainActor
class BaseScene: SKScene {
    let saveManager = SaveManager.shared
    let storeManager = StoreManager.shared
    let purchaseManager = PurchaseManager.shared
    let soundManager = SoundManager.shared
    let hapticsManager = HapticsManager.shared
    let gameMode: GameMode?
    var modeProfile: GameModeProfile? {
        gameMode.map(GameModeProfile.profile(for:))
    }

    init(sceneSize: CGSize, gameMode: GameMode? = nil) {
        self.gameMode = gameMode
        super.init(size: sceneSize)
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupBackdrop(title: String, subtitle: String, playsMenuSoundscape: Bool = true) {
        if playsMenuSoundscape {
            soundManager.playSoundscape(menuSoundscape)
        }

        let accentColor = modeAccentColor
        let showsHeroPanel = !title.isEmpty || !subtitle.isEmpty
        let gradient = SKShapeNode(rectOf: CGSize(width: size.width * 1.5, height: size.height * 1.5), cornerRadius: 0)
        gradient.fillColor = Palette.background
        gradient.strokeColor = .clear
        gradient.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(gradient)

        let upperGlow = SKShapeNode(circleOfRadius: min(size.width, size.height) * 0.32)
        upperGlow.fillColor = accentColor.withAlphaComponent(0.10)
        upperGlow.strokeColor = .clear
        upperGlow.position = CGPoint(x: size.width * 0.78, y: size.height * 0.78)
        addChild(upperGlow)

        let glowLeft = SKShapeNode(circleOfRadius: min(size.width, size.height) * 0.24)
        glowLeft.fillColor = accentColor.withAlphaComponent(0.08)
        glowLeft.strokeColor = .clear
        glowLeft.position = CGPoint(x: size.width * 0.16, y: size.height * 0.22)
        addChild(glowLeft)

        let meshSpacing = max(54, size.height / 8.8)
        for index in 0...Int(size.height / meshSpacing) + 1 {
            let line = SKShapeNode(rectOf: CGSize(width: size.width * 1.05, height: 1), cornerRadius: 0)
            line.strokeColor = accentColor.withAlphaComponent(index.isMultiple(of: 2) ? 0.08 : 0.03)
            line.lineWidth = 1
            line.position = CGPoint(x: size.width / 2, y: CGFloat(index) * meshSpacing - 20)
            addChild(line)
        }

        for index in 0...Int(size.width / 72) + 1 {
            let column = SKShapeNode(rectOf: CGSize(width: 1, height: size.height * 1.08), cornerRadius: 0)
            column.strokeColor = accentColor.withAlphaComponent(index.isMultiple(of: 2) ? 0.04 : 0.02)
            column.lineWidth = 1
            column.position = CGPoint(x: CGFloat(index) * 72 - 12, y: size.height / 2)
            addChild(column)
        }

        let halo = SKShapeNode(circleOfRadius: min(size.width, size.height) * 0.18)
        halo.fillColor = Palette.warning.withAlphaComponent(0.08)
        halo.strokeColor = .clear
        halo.position = CGPoint(x: size.width * 0.28, y: size.height * 0.72)
        addChild(halo)
        upperGlow.run(.repeatForever(.sequence([
            .scale(to: 1.06, duration: 2.8),
            .scale(to: 0.96, duration: 2.2)
        ])))
        halo.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.26, duration: 2.4),
            .fadeAlpha(to: 0.10, duration: 1.8)
        ])))

        for index in 0..<9 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.6))
            spark.fillColor = (index.isMultiple(of: 3) ? Palette.warning : accentColor).withAlphaComponent(0.32)
            spark.strokeColor = .clear
            spark.position = CGPoint(
                x: CGFloat.random(in: 24...(size.width - 24)),
                y: CGFloat.random(in: 80...(size.height - (showsHeroPanel ? 180 : 60)))
            )
            spark.zPosition = 0
            addChild(spark)
            let drift = CGFloat.random(in: 14...36)
            let duration = Double.random(in: 2.8...5.2)
            spark.run(.repeatForever(.sequence([
                .group([
                    .moveBy(x: CGFloat.random(in: -18...18), y: drift, duration: duration),
                    .fadeAlpha(to: CGFloat.random(in: 0.08...0.34), duration: duration)
                ]),
                .group([
                    .moveBy(x: CGFloat.random(in: -18...18), y: -drift, duration: duration),
                    .fadeAlpha(to: CGFloat.random(in: 0.16...0.42), duration: duration)
                ])
            ])))
        }

        guard showsHeroPanel else {
            return
        }

        let heroSize = CGSize(width: min(size.width - 42, 446), height: 108)
        let heroPanel = SKShapeNode(rectOf: heroSize, cornerRadius: 32)
        heroPanel.fillColor = Palette.panel.withAlphaComponent(0.90)
        heroPanel.strokeColor = accentColor
        heroPanel.lineWidth = 2
        heroPanel.glowWidth = 3
        heroPanel.position = CGPoint(x: size.width / 2, y: size.height - 140)
        addChild(heroPanel)

        let badge = SKShapeNode(rectOf: CGSize(width: 132, height: 28), cornerRadius: 14)
        badge.fillColor = accentColor.withAlphaComponent(0.14)
        badge.strokeColor = accentColor
        badge.lineWidth = 1.5
        badge.position = CGPoint(x: 0, y: 30)
        heroPanel.addChild(badge)

        let badgeLabel = SKLabelNode(fontNamed: GameConfig.coinFont)
        badgeLabel.text = modeBadgeText
        badgeLabel.fontSize = 10
        badgeLabel.fontColor = accentColor
        badgeLabel.position = CGPoint(x: 0, y: 8)
        badge.addChild(badgeLabel)

        let accentDot = SKShapeNode(circleOfRadius: 5)
        accentDot.fillColor = accentColor
        accentDot.strokeColor = .clear
        accentDot.position = CGPoint(x: -heroSize.width / 2 + 26, y: 0)
        heroPanel.addChild(accentDot)

        let titleNode = SKLabelNode(fontNamed: GameConfig.titleFont)
        titleNode.text = title
        titleNode.fontSize = 34
        titleNode.fontColor = Palette.textPrimary
        titleNode.horizontalAlignmentMode = .center
        titleNode.position = CGPoint(x: 0, y: 4)
        heroPanel.addChild(titleNode)

        let subtitleNode = SKLabelNode(fontNamed: GameConfig.coinFont)
        subtitleNode.text = subtitle
        subtitleNode.fontSize = 13
        subtitleNode.fontColor = Palette.textSecondary
        subtitleNode.horizontalAlignmentMode = .center
        subtitleNode.verticalAlignmentMode = .top
        subtitleNode.preferredMaxLayoutWidth = heroPanel.frame.width - 56
        subtitleNode.numberOfLines = 2
        subtitleNode.lineBreakMode = .byWordWrapping
        subtitleNode.position = CGPoint(x: 0, y: -18)
        heroPanel.addChild(subtitleNode)
    }

    func button(at location: CGPoint) -> MenuButtonNode? {
        for candidate in nodes(at: location) {
            var current: SKNode? = candidate
            while let node = current {
                if let button = node as? MenuButtonNode {
                    return button
                }
                current = node.parent
            }
        }
        return nil
    }

    func nodeName(at location: CGPoint, withPrefix prefix: String) -> String? {
        for node in nodes(at: location) {
            var current: SKNode? = node
            while let candidate = current {
                if let name = candidate.name, name.hasPrefix(prefix) {
                    return name
                }
                current = candidate.parent
            }
        }
        return nil
    }

    func present(_ scene: SKScene) {
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: .fade(withDuration: 0.22))
    }

    private var menuSoundscape: SoundManager.Soundscape {
        switch gameMode {
        case .ghost:
            .ghostRun
        default:
            .menu
        }
    }

    private var modeAccentColor: UIColor {
        switch gameMode {
        case .original:
            Palette.warning
        case .evolution:
            Palette.stroke
        case .ghost:
            Palette.accent
        case nil:
            Palette.stroke
        }
    }

    private var modeBadgeText: String {
        switch gameMode {
        case .original:
            "ARCADE BASE"
        case .evolution:
            "ARSENAL LIVE"
        case .ghost:
            "PROTOCOLO"
        case nil:
            "ATRAPA"
        }
    }
}
