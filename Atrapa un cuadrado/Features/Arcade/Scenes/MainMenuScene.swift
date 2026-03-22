import SpriteKit

final class MainMenuScene: BaseScene {
    private var progress = GameProgress.defaultProgress
    private var buttons: [MenuButtonNode] = []
    private let profile: GameModeProfile
    private var hasLoadedProgress = false

    init(sceneSize: CGSize, gameMode: GameMode, dependencies: SceneDependencies? = nil) {
        self.profile = GameModeProfile.profile(for: gameMode)
        super.init(sceneSize: sceneSize, gameMode: gameMode, dependencies: dependencies)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        progress = saveManager.loadProgress()
        hasLoadedProgress = true
        if let gameMode {
            telemetry.logEvent("arcade_main_menu_shown", parameters: ["mode": gameMode.rawValue])
        }
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
        guard let gameMode else {
            return
        }

        removeAllChildren()

        let isUnlocked = progress.isModeUnlocked(gameMode)
        setupBackdrop(
            title: gameMode.title.uppercased(),
            subtitle: isUnlocked ? gameMode.menuSubtitle : "Acceso bloqueado. \(gameMode.accessLabel)."
        )

        let heroPanel = SKShapeNode(rectOf: CGSize(width: size.width - 44, height: 146), cornerRadius: 30)
        heroPanel.fillColor = Palette.panel.withAlphaComponent(0.94)
        heroPanel.strokeColor = profile.modeAccentColor
        heroPanel.lineWidth = 2
        heroPanel.glowWidth = isUnlocked ? 4 : 0
        heroPanel.position = CGPoint(x: size.width / 2, y: size.height - 248)
        addChild(heroPanel)

        let accentBar = SKShapeNode(rectOf: CGSize(width: 10, height: 94), cornerRadius: 5)
        accentBar.fillColor = profile.modeAccentColor
        accentBar.strokeColor = .clear
        accentBar.position = CGPoint(x: -heroPanel.frame.width / 2 + 24, y: 0)
        heroPanel.addChild(accentBar)

        let badgePlate = SKShapeNode(rectOf: CGSize(width: 154, height: 28), cornerRadius: 14)
        badgePlate.fillColor = (isUnlocked ? profile.modeAccentColor : Palette.warning).withAlphaComponent(0.12)
        badgePlate.strokeColor = isUnlocked ? profile.modeAccentColor : Palette.warning
        badgePlate.lineWidth = 1.2
        badgePlate.position = CGPoint(x: -heroPanel.frame.width / 2 + 116, y: 46)
        heroPanel.addChild(badgePlate)

        let modeBadge = SKLabelNode(fontNamed: GameConfig.coinFont)
        modeBadge.text = (isUnlocked ? gameMode.selectorBadge : "Acceso bloqueado").uppercased()
        modeBadge.fontSize = 10
        modeBadge.fontColor = isUnlocked ? profile.modeAccentColor : Palette.warning
        modeBadge.position = CGPoint(x: 0, y: 8)
        badgePlate.addChild(modeBadge)

        let statNode = SKLabelNode(fontNamed: GameConfig.coinFont)
        statNode.text = "Banco \(progress.coins)   •   Mejor \(progress.highScore(for: gameMode))"
        statNode.fontSize = 15
        statNode.fontColor = profile.modeAccentColor
        statNode.horizontalAlignmentMode = .left
        statNode.position = CGPoint(x: -heroPanel.frame.width / 2 + 42, y: 14)
        heroPanel.addChild(statNode)

        let descriptionNode = SKLabelNode(fontNamed: GameConfig.coinFont)
        descriptionNode.text = isUnlocked ? profile.hudSubtitle : lockedModeDescription(for: gameMode)
        descriptionNode.fontSize = 14
        descriptionNode.fontColor = isUnlocked ? Palette.textSecondary : Palette.warning
        descriptionNode.horizontalAlignmentMode = .left
        descriptionNode.position = CGPoint(x: -heroPanel.frame.width / 2 + 42, y: -6)
        descriptionNode.preferredMaxLayoutWidth = size.width - 150
        descriptionNode.numberOfLines = 3
        descriptionNode.lineBreakMode = .byWordWrapping
        descriptionNode.verticalAlignmentMode = .top
        heroPanel.addChild(descriptionNode)

        if gameMode != .original, isUnlocked {
            let loadoutPlate = SKShapeNode(rectOf: CGSize(width: heroPanel.frame.width - 84, height: 30), cornerRadius: 15)
            loadoutPlate.fillColor = profile.modeAccentColor.withAlphaComponent(0.08)
            loadoutPlate.strokeColor = profile.modeAccentColor.withAlphaComponent(0.35)
            loadoutPlate.lineWidth = 1
            loadoutPlate.position = CGPoint(x: 14, y: -56)
            heroPanel.addChild(loadoutPlate)

            let selectedCharacter = CharacterDefinition.definition(for: progress.selectedCharacterID(for: gameMode))
            let loadoutNode = SKLabelNode(fontNamed: GameConfig.coinFont)
            loadoutNode.text = "Carga activa: \(selectedCharacter.title) + \(progress.selectedWeapon(for: gameMode).title)"
            loadoutNode.fontSize = 11
            loadoutNode.fontColor = profile.modeAccentColor
            loadoutNode.position = CGPoint(x: 0, y: 7)
            loadoutPlate.addChild(loadoutNode)
        }

        let modeMark = modeMarkNode(for: gameMode, unlocked: isUnlocked)
        modeMark.position = CGPoint(x: heroPanel.frame.width / 2 - 62, y: 4)
        heroPanel.addChild(modeMark)

        if !isUnlocked {
            buttons = [
                MenuButtonNode(actionID: "store", title: "Desbloquear", subtitle: "Revisa acceso, monedas o contenido"),
                MenuButtonNode(actionID: "settings", title: "Ajustes", subtitle: "Compras, codigo y soporte"),
                MenuButtonNode(actionID: "modes", title: "Selector", subtitle: "Volver a todos los modos")
            ]
        } else {
            buttons = [MenuButtonNode(actionID: "play", title: "Entrar", subtitle: "Ir directo a la partida")]
            if profile.showsCharacters {
                buttons.append(MenuButtonNode(actionID: "characters", title: "Carga", subtitle: "Personaje, rol y arma base"))
            }
            buttons.append(
                MenuButtonNode(
                    actionID: "store",
                    title: profile.showsAbilitiesInStore ? "Arsenal" : "Mejoras",
                    subtitle: profile.showsAbilitiesInStore ? "Compra armas, personajes y habilidades" : "Compra mejoras retro permanentes"
                )
            )
            buttons.append(MenuButtonNode(actionID: "settings", title: "Ajustes", subtitle: "Audio, codigo y opciones"))
            buttons.append(MenuButtonNode(actionID: "modes", title: "Selector", subtitle: "Cambiar de fantasia de juego"))
        }

        let topY = size.height - 426
        let bottomY: CGFloat = 118
        let spacing = buttons.count > 1 ? min(98, (topY - bottomY) / CGFloat(buttons.count - 1)) : 0
        for (index, button) in buttons.enumerated() {
            button.position = CGPoint(x: size.width / 2, y: topY - CGFloat(index) * spacing)
            addChild(button)
        }

        let footer = SKLabelNode(fontNamed: GameConfig.coinFont)
        footer.text = profile.menuFooter
        footer.fontSize = 12
        footer.fontColor = Palette.textSecondary.withAlphaComponent(0.7)
        footer.position = CGPoint(x: size.width / 2, y: 44)
        addChild(footer)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self),
              let button = button(at: location) else {
            return
        }

        switch button.actionID {
        case "play":
            soundManager.playButtonTap()
            hapticsManager.tap()
            guard let gameMode else {
                return
            }
            present(GameScene(sceneSize: size, gameMode: gameMode))
        case "characters":
            soundManager.playButtonTap()
            hapticsManager.tap()
            guard let gameMode else {
                return
            }
            present(CharacterSelectScene(sceneSize: size, gameMode: gameMode))
        case "store":
            soundManager.playButtonTap()
            hapticsManager.tap()
            guard let gameMode else {
                return
            }
            let destinationMode: GameMode
            if progress.isModeUnlocked(gameMode) {
                destinationMode = gameMode
            } else {
                destinationMode = .original
            }
            present(StoreScene(sceneSize: size, gameMode: destinationMode))
        case "settings":
            soundManager.playButtonTap()
            hapticsManager.tap()
            guard let gameMode else {
                return
            }
            present(SettingsScene(sceneSize: size, gameMode: gameMode))
        case "modes":
            soundManager.playButtonTap()
            hapticsManager.tap()
            present(ModeSelectScene(sceneSize: size))
        default:
            break
        }
    }

    private func lockedModeDescription(for mode: GameMode) -> String {
        switch mode {
        case .original:
            return profile.hudSubtitle
        case .evolution:
            return "Desbloquea personajes, armas y habilidades con App Store o con 1000 monedas."
        case .ghost:
            return "Introduce el codigo amiguisimo en Ajustes para revelar este modo secreto."
        }
    }

    private func modeMarkNode(for mode: GameMode, unlocked: Bool) -> SKNode {
        let tint = unlocked ? profile.modeAccentColor : Palette.textSecondary
        let container = SKNode()

        switch mode {
        case .original:
            let ring = SKShapeNode(circleOfRadius: 26)
            ring.strokeColor = tint
            ring.lineWidth = 3
            ring.fillColor = .clear
            container.addChild(ring)

            let dot = SKShapeNode(circleOfRadius: 11)
            dot.fillColor = tint.withAlphaComponent(0.22)
            dot.strokeColor = .clear
            container.addChild(dot)
        case .evolution:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: 26, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -30))
            path.addLine(to: CGPoint(x: -26, y: 0))
            path.closeSubpath()
            let diamond = SKShapeNode(path: path)
            diamond.fillColor = tint.withAlphaComponent(0.18)
            diamond.strokeColor = tint
            diamond.lineWidth = 2.5
            container.addChild(diamond)
        case .ghost:
            for index in 0..<4 {
                let slash = SKShapeNode(rectOf: CGSize(width: 44 - CGFloat(index) * 6, height: 4), cornerRadius: 2)
                slash.fillColor = tint
                slash.strokeColor = .clear
                slash.position = CGPoint(x: 0, y: 18 - CGFloat(index) * 12)
                slash.zRotation = index.isMultiple(of: 2) ? 0.18 : -0.18
                container.addChild(slash)
            }
        }

        return container
    }
}
