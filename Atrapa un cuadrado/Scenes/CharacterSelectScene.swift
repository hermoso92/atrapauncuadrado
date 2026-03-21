import SpriteKit

final class CharacterSelectScene: BaseScene {
    private var buttons: [MenuButtonNode] = []
    private var progress = GameProgress.defaultProgress
    private var hasLoadedProgress = false

    init(sceneSize: CGSize, gameMode: GameMode) {
        super.init(sceneSize: sceneSize, gameMode: gameMode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        progress = saveManager.loadProgress()
        hasLoadedProgress = true
        buildScene()
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
        buttons.removeAll()

        setupBackdrop(title: "CARGA", subtitle: "Selecciona identidad, revisa stats y fija el arma que va contigo.")

        let selectedCharacter = CharacterDefinition.definition(for: progress.selectedCharacterID(for: gameMode))
        let topPanelHeight: CGFloat = gameMode == .original ? 168 : 216
        let topPanel = makePanel(
            size: CGSize(width: size.width - 42, height: topPanelHeight),
            stroke: selectedCharacter.primaryColor,
            fill: Palette.panel.withAlphaComponent(0.94)
        )
        topPanel.position = CGPoint(x: size.width / 2, y: size.height - 252)
        addChild(topPanel)

        let previewPlate = makePanel(
            size: CGSize(width: 96, height: 96),
            stroke: selectedCharacter.primaryColor,
            fill: selectedCharacter.primaryColor.withAlphaComponent(0.12),
            cornerRadius: 28
        )
        previewPlate.position = CGPoint(x: -topPanel.frame.width / 2 + 74, y: 10)
        topPanel.addChild(previewPlate)

        let preview = previewNode(for: selectedCharacter, scale: 1.5)
        preview.position = .zero
        previewPlate.addChild(preview)

        let badge = makeBadge(
            text: gameMode == .original ? "ARCADE BASE" : "CARGA ACTIVA",
            tint: selectedCharacter.primaryColor
        )
        badge.position = CGPoint(x: -26, y: 56)
        topPanel.addChild(badge)

        let title = makeLabel(
            text: selectedCharacter.title,
            fontNamed: GameConfig.titleFont,
            fontSize: 26,
            color: Palette.textPrimary,
            width: topPanel.frame.width - 174,
            lines: 1
        )
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -topPanel.frame.width / 2 + 140, y: 24)
        topPanel.addChild(title)

        let subtitle = makeLabel(
            text: selectedCharacter.subtitle,
            fontNamed: GameConfig.coinFont,
            fontSize: 13,
            color: Palette.textSecondary,
            width: topPanel.frame.width - 174,
            lines: 2
        )
        subtitle.horizontalAlignmentMode = .left
        subtitle.position = CGPoint(x: -topPanel.frame.width / 2 + 140, y: -2)
        topPanel.addChild(subtitle)

        let statStrip = makeLabel(
            text: "Vel x\(format(selectedCharacter.speedMultiplier))   •   Iman x\(format(selectedCharacter.magnetRangeMultiplier))   •   Perfil \(styleTitle(for: selectedCharacter))",
            fontNamed: GameConfig.coinFont,
            fontSize: 12,
            color: Palette.warning,
            width: topPanel.frame.width - 174,
            lines: 2
        )
        statStrip.horizontalAlignmentMode = .left
        statStrip.position = CGPoint(x: -topPanel.frame.width / 2 + 140, y: -40)
        topPanel.addChild(statStrip)

        let styleNote = makeLabel(
            text: styleSummary(for: selectedCharacter),
            fontNamed: GameConfig.coinFont,
            fontSize: 12,
            color: selectedCharacter.primaryColor,
            width: topPanel.frame.width - 174,
            lines: 2
        )
        styleNote.horizontalAlignmentMode = .left
        styleNote.position = CGPoint(x: -topPanel.frame.width / 2 + 140, y: -72)
        topPanel.addChild(styleNote)

        if gameMode != .original {
            let selectedWeapon = progress.selectedWeapon(for: gameMode)
            let weaponPanel = makePanel(
                size: CGSize(width: topPanel.frame.width - 22, height: 74),
                stroke: Palette.stroke,
                fill: Palette.background.withAlphaComponent(0.55),
                cornerRadius: 20
            )
            weaponPanel.position = CGPoint(x: 0, y: -130)
            topPanel.addChild(weaponPanel)

            let weaponTitle = makeLabel(
                text: "ARMA EQUIPADA",
                fontNamed: GameConfig.coinFont,
                fontSize: 11,
                color: Palette.stroke,
                width: weaponPanel.frame.width - 132,
                lines: 1
            )
            weaponTitle.horizontalAlignmentMode = .left
            weaponTitle.position = CGPoint(x: -weaponPanel.frame.width / 2 + 22, y: 18)
            weaponPanel.addChild(weaponTitle)

            let weaponName = makeLabel(
                text: selectedWeapon.title,
                fontNamed: GameConfig.titleFont,
                fontSize: 20,
                color: Palette.textPrimary,
                width: weaponPanel.frame.width - 132,
                lines: 1
            )
            weaponName.horizontalAlignmentMode = .left
            weaponName.position = CGPoint(x: -weaponPanel.frame.width / 2 + 22, y: -4)
            weaponPanel.addChild(weaponName)

            let weaponSubtitle = makeLabel(
                text: selectedWeapon.subtitle,
                fontNamed: GameConfig.coinFont,
                fontSize: 11,
                color: Palette.textSecondary,
                width: weaponPanel.frame.width - 132,
                lines: 2
            )
            weaponSubtitle.horizontalAlignmentMode = .left
            weaponSubtitle.position = CGPoint(x: -weaponPanel.frame.width / 2 + 22, y: -26)
            weaponPanel.addChild(weaponSubtitle)

            let previousWeaponButton = MenuButtonNode(actionID: "weapon.previous", title: "Prev", subtitle: "Arma", size: CGSize(width: 76, height: 50))
            previousWeaponButton.position = CGPoint(x: weaponPanel.frame.width / 2 - 82, y: 0)
            weaponPanel.addChild(previousWeaponButton)

            let nextWeaponButton = MenuButtonNode(actionID: "weapon.next", title: "Next", subtitle: "Arma", size: CGSize(width: 76, height: 50))
            nextWeaponButton.position = CGPoint(x: weaponPanel.frame.width / 2 - 2, y: 0)
            weaponPanel.addChild(nextWeaponButton)

            buttons.append(contentsOf: [previousWeaponButton, nextWeaponButton])
        }

        let deckHeader = makeSectionHeader(
            title: "BANCO DE PERSONAJES",
            subtitle: "Toca una tarjeta para fijar el cuerpo que entra en la run.",
            y: size.height - 392
        )
        addChild(deckHeader)

        let cards = CharacterDefinition.catalog
        let columns = 2
        let cardSize = CGSize(width: (size.width - 58) / 2, height: 126)
        let startY = size.height - 500

        for (index, character) in cards.enumerated() {
            let column = index % columns
            let row = index / columns
            let x = 16 + cardSize.width / 2 + CGFloat(column) * (cardSize.width + 10)
            let y = startY - CGFloat(row) * 142
            let card = characterCard(for: character, size: cardSize, selectedID: selectedCharacter.id)
            card.position = CGPoint(x: x, y: y)
            addChild(card)
        }

        let footerPanel = makePanel(
            size: CGSize(width: size.width - 42, height: 76),
            stroke: Palette.textSecondary,
            fill: Palette.panel.withAlphaComponent(0.92),
            cornerRadius: 24
        )
        footerPanel.position = CGPoint(x: size.width / 2, y: 94)
        addChild(footerPanel)

        let footerText = makeLabel(
            text: footerSummary(for: gameMode, character: selectedCharacter),
            fontNamed: GameConfig.coinFont,
            fontSize: 12,
            color: Palette.textSecondary,
            width: footerPanel.frame.width - 170,
            lines: 2
        )
        footerText.horizontalAlignmentMode = .left
        footerText.position = CGPoint(x: -footerPanel.frame.width / 2 + 18, y: 14)
        footerPanel.addChild(footerText)

        let backButton = MenuButtonNode(actionID: "back", title: "Volver", subtitle: "Menu", size: CGSize(width: 132, height: 52))
        backButton.position = CGPoint(x: 0, y: 30)
        addChild(backButton)

        let storeButton = MenuButtonNode(actionID: "store", title: "Arsenal", subtitle: "Tienda", size: CGSize(width: 132, height: 52))
        storeButton.position = CGPoint(x: size.width - 90, y: 30)
        addChild(storeButton)

        buttons.append(contentsOf: [backButton, storeButton])
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else {
            return
        }

        if let button = button(at: location) {
            guard let gameMode else {
                return
            }
            switch button.actionID {
            case "weapon.previous":
                cycleWeapon(step: -1)
            case "weapon.next":
                cycleWeapon(step: 1)
            case "back":
                soundManager.playButtonTap()
                hapticsManager.tap()
                present(MainMenuScene(sceneSize: size, gameMode: gameMode))
            case "store":
                soundManager.playButtonTap()
                hapticsManager.tap()
                present(StoreScene(sceneSize: size, gameMode: gameMode))
            default:
                break
            }
            return
        }

        guard let cardName = nodeName(at: location, withPrefix: "character.card.") else {
            return
        }
        let id = String(cardName.dropFirst("character.card.".count))
        guard progress.unlockedCharacters.contains(id) else {
            soundManager.playWarning()
            hapticsManager.warning()
            return
        }

        guard let gameMode else {
            return
        }

        progress = saveManager.update { mutableProgress in
            mutableProgress.selectCharacter(id, for: gameMode)
            let selectedWeapon = mutableProgress.selectedWeapon(for: gameMode)
            if !mutableProgress.ownedWeapons.contains(selectedWeapon) {
                let selectedCharacter = CharacterDefinition.definition(for: id)
                let fallbackWeapon = mutableProgress.ownedWeapons.contains(selectedCharacter.defaultWeapon) ? selectedCharacter.defaultWeapon : .blaster
                mutableProgress.equipWeapon(fallbackWeapon, for: gameMode)
            }
        }
        soundManager.playSuccess()
        hapticsManager.success()
        buildScene()
    }

    private func characterCard(for character: CharacterDefinition, size: CGSize, selectedID: String) -> SKShapeNode {
        let unlocked = progress.unlockedCharacters.contains(character.id)
        let selected = selectedID == character.id
        let card = makePanel(
            size: size,
            stroke: unlocked ? (selected ? character.primaryColor : character.primaryColor.withAlphaComponent(0.84)) : Palette.textSecondary,
            fill: selected ? character.primaryColor.withAlphaComponent(0.2) : Palette.panel,
            cornerRadius: 24
        )
        card.name = "character.card.\(character.id)"
        card.lineWidth = selected ? 3 : 1.5

        let icon = previewNode(for: character, scale: 1)
        icon.position = CGPoint(x: -size.width / 2 + 42, y: 2)
        card.addChild(icon)

        let title = makeLabel(
            text: character.title,
            fontNamed: GameConfig.titleFont,
            fontSize: 18,
            color: Palette.textPrimary,
            width: size.width - 104,
            lines: 2
        )
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -size.width / 2 + 74, y: 26)
        card.addChild(title)

        let status = makeLabel(
            text: unlocked ? (selected ? "Activo" : "Disponible") : "\(character.price) monedas",
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: unlocked ? (selected ? character.primaryColor : Palette.success) : Palette.warning,
            width: size.width - 104,
            lines: 1
        )
        status.horizontalAlignmentMode = .left
        status.position = CGPoint(x: -size.width / 2 + 74, y: 0)
        card.addChild(status)

        let weapon = makeLabel(
            text: "Arma base: \(character.defaultWeapon.title)",
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: progress.ownedWeapons.contains(character.defaultWeapon) ? Palette.stroke : Palette.textSecondary,
            width: size.width - 104,
            lines: 1
        )
        weapon.horizontalAlignmentMode = .left
        weapon.position = CGPoint(x: -size.width / 2 + 74, y: -20)
        card.addChild(weapon)

        let note = makeLabel(
            text: unlocked ? styleSummary(for: character) : "Compra en tienda para añadirlo a tu banco.",
            fontNamed: GameConfig.coinFont,
            fontSize: 10,
            color: unlocked ? Palette.textSecondary : Palette.warning,
            width: size.width - 104,
            lines: 2
        )
        note.horizontalAlignmentMode = .left
        note.position = CGPoint(x: -size.width / 2 + 74, y: -40)
        card.addChild(note)

        return card
    }

    private func previewNode(for character: CharacterDefinition, scale: CGFloat) -> SKNode {
        let container = SKNode()
        container.setScale(scale)
        switch character.style {
        case .circle:
            let circle = SKShapeNode(circleOfRadius: 22)
            circle.fillColor = character.primaryColor
            circle.strokeColor = .white
            circle.lineWidth = 2
            container.addChild(circle)
        case .stickman:
            let head = SKShapeNode(circleOfRadius: 8)
            head.strokeColor = character.primaryColor
            head.lineWidth = 2
            head.position = CGPoint(x: 0, y: 14)
            container.addChild(head)

            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 6))
            path.addLine(to: CGPoint(x: 0, y: -18))
            path.move(to: CGPoint(x: -14, y: -2))
            path.addLine(to: CGPoint(x: 14, y: -2))
            path.move(to: CGPoint(x: 0, y: -18))
            path.addLine(to: CGPoint(x: -12, y: -34))
            path.move(to: CGPoint(x: 0, y: -18))
            path.addLine(to: CGPoint(x: 12, y: -34))

            let body = SKShapeNode(path: path)
            body.strokeColor = character.primaryColor
            body.lineWidth = 2
            container.addChild(body)
        case .diamond:
            let diamond = SKShapeNode(path: {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: 24))
                path.addLine(to: CGPoint(x: 20, y: 0))
                path.addLine(to: CGPoint(x: 0, y: -24))
                path.addLine(to: CGPoint(x: -20, y: 0))
                path.closeSubpath()
                return path
            }())
            diamond.fillColor = character.primaryColor
            diamond.strokeColor = character.secondaryColor
            diamond.lineWidth = 2
            container.addChild(diamond)
        }
        return container
    }

    private func styleSummary(for character: CharacterDefinition) -> String {
        switch character.style {
        case .circle:
            return "Balanceado y limpio. Ideal para runs donde todo depende de lectura fina."
        case .stickman:
            return "Movilidad alta y burst tactico. Muy bueno para abrir espacio bajo presion."
        case .diamond:
            return "Mas dano y pulso mas violento. Pide manos finas pero devuelve impacto."
        }
    }

    private func styleTitle(for character: CharacterDefinition) -> String {
        switch character.style {
        case .circle:
            "Equilibrio"
        case .stickman:
            "Movilidad"
        case .diamond:
            "Impacto"
        }
    }

    private func cycleWeapon(step: Int) {
        guard let gameMode else {
            return
        }

        let availableWeapons = WeaponType.allCases.filter { progress.ownedWeapons.contains($0) }
        guard !availableWeapons.isEmpty else {
            soundManager.playWarning()
            hapticsManager.warning()
            return
        }

        let currentIndex = availableWeapons.firstIndex(of: progress.selectedWeapon(for: gameMode)) ?? 0
        let nextIndex = (currentIndex + step + availableWeapons.count) % availableWeapons.count
        let selectedWeapon = availableWeapons[nextIndex]

        progress = saveManager.update { mutableProgress in
            mutableProgress.equipWeapon(selectedWeapon, for: gameMode)
        }
        soundManager.playSuccess()
        hapticsManager.tap()
        buildScene()
    }

    private func footerSummary(for gameMode: GameMode, character: CharacterDefinition) -> String {
        if gameMode == .original {
            return "Clasico ignora build externa. Aqui solo cambias lectura visual y estilo de presencia."
        }
        return "Build actual: \(character.title) + \(progress.selectedWeapon(for: gameMode).title). Compra mas piezas en Arsenal para abrir rutas nuevas."
    }

    private func makePanel(size: CGSize, stroke: UIColor, fill: UIColor, cornerRadius: CGFloat = 28) -> SKShapeNode {
        let panel = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        panel.fillColor = fill
        panel.strokeColor = stroke
        panel.lineWidth = 2
        return panel
    }

    private func makeBadge(text: String, tint: UIColor) -> SKShapeNode {
        let badge = SKShapeNode(rectOf: CGSize(width: 126, height: 28), cornerRadius: 14)
        badge.fillColor = tint.withAlphaComponent(0.14)
        badge.strokeColor = tint
        badge.lineWidth = 1.5

        let label = makeLabel(
            text: text,
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: tint,
            width: 110,
            lines: 1
        )
        label.position = CGPoint(x: 0, y: 8)
        badge.addChild(label)
        return badge
    }

    private func makeSectionHeader(title: String, subtitle: String, y: CGFloat) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: size.width / 2, y: y)

        let titleNode = makeLabel(
            text: title,
            fontNamed: GameConfig.titleFont,
            fontSize: 20,
            color: Palette.textPrimary,
            width: size.width - 48,
            lines: 1
        )
        titleNode.position = CGPoint(x: 0, y: 10)
        container.addChild(titleNode)

        let subtitleNode = makeLabel(
            text: subtitle,
            fontNamed: GameConfig.coinFont,
            fontSize: 12,
            color: Palette.textSecondary,
            width: size.width - 48,
            lines: 2
        )
        subtitleNode.position = CGPoint(x: 0, y: -12)
        container.addChild(subtitleNode)

        return container
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

    private func format(_ value: CGFloat) -> String {
        String(format: "%.2f", value)
    }
}
