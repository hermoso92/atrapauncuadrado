import SpriteKit

/// Selector de jugadores para multijugador local (placeholder hasta implementar 2-4 jugadores).
final class PlayerSelectScene: BaseScene {

    override init(sceneSize: CGSize, gameMode: GameMode? = nil, dependencies: SceneDependencies? = nil) {
        super.init(sceneSize: sceneSize, gameMode: nil, dependencies: dependencies)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        telemetry.logEvent("multiplayer_player_select_shown", parameters: [:])
        buildScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        buildScene()
    }

    private func buildScene() {
        removeAllChildren()
        setupBackdrop(
            title: "MULTIJUGADOR LOCAL",
            subtitle: "Mismo dispositivo, varios jugadores."
        )

        let panelW = size.width - 44
        let panelH = min(220, size.height * 0.32)
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 26)
        panel.fillColor = Palette.panel.withAlphaComponent(0.94)
        panel.strokeColor = Palette.accent
        panel.lineWidth = 2
        panel.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
        addChild(panel)

        let hint = makeLabel(
            text: "Próximamente: elegir entre 2 y 4 jugadores, nombres y colores antes de la partida local.",
            fontNamed: GameConfig.coinFont,
            fontSize: 13,
            color: Palette.textSecondary,
            width: panelW - 36,
            lines: 5
        )
        hint.verticalAlignmentMode = .center
        hint.horizontalAlignmentMode = .center
        hint.position = .zero
        panel.addChild(hint)

        let back = MenuButtonNode(
            actionID: "back.modes",
            title: "Modos",
            subtitle: "Volver al selector",
            size: CGSize(width: 200, height: 56)
        )
        back.position = CGPoint(x: size.width / 2, y: 80)
        addChild(back)
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

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self),
              let button = button(at: location) else {
            return
        }
        switch button.actionID {
        case "back.modes":
            soundManager.playButtonTap()
            hapticsManager.tap()
            present(ModeSelectScene(sceneSize: size, dependencies: deps))
        default:
            break
        }
    }
}
