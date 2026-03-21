import SpriteKit
import UIKit

final class MenuButtonNode: SKNode {
    let actionID: String

    private let buttonSize: CGSize
    private let shadowNode: SKShapeNode
    private let backgroundNode: SKShapeNode
    private let accentNode: SKShapeNode
    private let iconPlateNode: SKShapeNode
    private let iconNode: SKLabelNode
    private let titleNode: SKLabelNode
    private let subtitleNode: SKLabelNode
    private let detailNode: SKLabelNode
    private var fillColorValue = Palette.panel
    private var strokeColorValue = Palette.stroke

    init(actionID: String, title: String, subtitle: String? = nil, size: CGSize = CGSize(width: 280, height: 64)) {
        self.actionID = actionID
        self.buttonSize = size
        self.shadowNode = SKShapeNode(rectOf: size, cornerRadius: min(22, size.height * 0.34))
        self.backgroundNode = SKShapeNode(rectOf: size, cornerRadius: min(22, size.height * 0.34))
        self.accentNode = SKShapeNode(rectOf: CGSize(width: 6, height: max(22, size.height - 24)), cornerRadius: 3)
        self.iconPlateNode = SKShapeNode(rectOf: CGSize(width: min(48, size.height - 16), height: min(48, size.height - 16)), cornerRadius: min(16, size.height * 0.25))
        self.iconNode = SKLabelNode(fontNamed: GameConfig.titleFont)
        self.titleNode = SKLabelNode(fontNamed: GameConfig.titleFont)
        self.subtitleNode = SKLabelNode(fontNamed: GameConfig.coinFont)
        self.detailNode = SKLabelNode(fontNamed: GameConfig.coinFont)
        super.init()

        name = SceneIdentifier.button
        isUserInteractionEnabled = false

        shadowNode.fillColor = UIColor.black.withAlphaComponent(0.22)
        shadowNode.strokeColor = .clear
        shadowNode.position = CGPoint(x: 0, y: -4)
        addChild(shadowNode)

        backgroundNode.fillColor = fillColorValue
        backgroundNode.strokeColor = strokeColorValue
        backgroundNode.lineWidth = 2
        backgroundNode.glowWidth = 2
        addChild(backgroundNode)

        accentNode.fillColor = Palette.stroke.withAlphaComponent(0.9)
        accentNode.strokeColor = .clear
        addChild(accentNode)

        iconPlateNode.fillColor = strokeColorValue.withAlphaComponent(0.12)
        iconPlateNode.strokeColor = strokeColorValue.withAlphaComponent(0.45)
        iconPlateNode.lineWidth = 1.5
        addChild(iconPlateNode)

        iconNode.text = iconGlyph(for: actionID)
        iconNode.fontSize = size.height <= 52 ? 16 : 20
        iconNode.verticalAlignmentMode = .center
        iconNode.fontColor = strokeColorValue
        addChild(iconNode)

        titleNode.text = title
        titleNode.fontSize = size.width <= 100 ? 20 : 19
        titleNode.verticalAlignmentMode = .center
        titleNode.fontColor = Palette.textPrimary
        titleNode.numberOfLines = 2
        titleNode.lineBreakMode = .byTruncatingTail
        addChild(titleNode)

        subtitleNode.text = subtitle
        subtitleNode.fontSize = size.width <= 120 ? 10 : 11
        subtitleNode.verticalAlignmentMode = .top
        subtitleNode.fontColor = Palette.textSecondary
        subtitleNode.isHidden = subtitle == nil
        subtitleNode.numberOfLines = 2
        subtitleNode.lineBreakMode = .byWordWrapping
        addChild(subtitleNode)

        detailNode.text = size.width > 120 ? ">" : nil
        detailNode.fontSize = 10
        detailNode.verticalAlignmentMode = .center
        detailNode.fontColor = Palette.textSecondary.withAlphaComponent(0.9)
        detailNode.isHidden = subtitle == nil || size.width <= 120
        addChild(detailNode)

        updateLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func contains(_ point: CGPoint) -> Bool {
        calculateAccumulatedFrame().contains(point)
    }

    func updateSubtitle(_ text: String?) {
        subtitleNode.text = text
        subtitleNode.isHidden = text == nil
        detailNode.isHidden = text == nil || buttonSize.width <= 120
        updateLayout()
    }

    func updateTitle(_ text: String) {
        titleNode.text = text
        updateLayout()
    }

    func setVisualStyle(fillColor: UIColor, strokeColor: UIColor, titleColor: UIColor = Palette.textPrimary, subtitleColor: UIColor = Palette.textSecondary) {
        fillColorValue = fillColor
        strokeColorValue = strokeColor
        backgroundNode.fillColor = fillColor
        backgroundNode.strokeColor = strokeColor
        accentNode.fillColor = strokeColor.withAlphaComponent(0.92)
        iconPlateNode.fillColor = strokeColor.withAlphaComponent(0.12)
        iconPlateNode.strokeColor = strokeColor.withAlphaComponent(0.45)
        iconNode.fontColor = strokeColor
        titleNode.fontColor = titleColor
        subtitleNode.fontColor = subtitleColor
        detailNode.fontColor = subtitleColor
    }

    func setHighlighted(_ highlighted: Bool) {
        backgroundNode.fillColor = highlighted ? strokeColorValue.withAlphaComponent(0.24) : fillColorValue
        xScale = highlighted ? 0.98 : 1
        yScale = highlighted ? 0.98 : 1
    }

    private func updateLayout() {
        let isCompact = buttonSize.width <= 120 || subtitleNode.isHidden
        let iconWidth: CGFloat = isCompact ? 0 : 44
        let horizontalPadding: CGFloat = isCompact ? 10 : 22
        let trailingWidth: CGFloat = isCompact ? 0 : 46
        let labelWidth = max(40, buttonSize.width - horizontalPadding * 2 - iconWidth - trailingWidth)

        titleNode.preferredMaxLayoutWidth = labelWidth
        subtitleNode.preferredMaxLayoutWidth = labelWidth

        if isCompact {
            accentNode.isHidden = true
            iconPlateNode.isHidden = true
            iconNode.isHidden = true
            titleNode.horizontalAlignmentMode = .center
            subtitleNode.horizontalAlignmentMode = .center
            titleNode.position = CGPoint(x: 0, y: subtitleNode.isHidden ? 0 : 10)
            subtitleNode.position = CGPoint(x: 0, y: -8)
        } else {
            accentNode.isHidden = false
            iconPlateNode.isHidden = false
            iconNode.isHidden = false
            accentNode.position = CGPoint(x: -buttonSize.width / 2 + 16, y: 0)
            iconPlateNode.position = CGPoint(x: -buttonSize.width / 2 + 42, y: 0)
            iconNode.position = iconPlateNode.position
            titleNode.horizontalAlignmentMode = .left
            subtitleNode.horizontalAlignmentMode = .left
            let textX = -buttonSize.width / 2 + horizontalPadding + iconWidth + 8
            titleNode.position = CGPoint(x: textX, y: 12)
            subtitleNode.position = CGPoint(x: textX, y: 1)
        }

        detailNode.position = CGPoint(x: buttonSize.width / 2 - 22, y: 0)
    }

    private func iconGlyph(for actionID: String) -> String {
        switch actionID {
        case "play", "retry":
            return ">"
        case "store", "restore.purchases":
            return "$"
        case "settings":
            return "[]"
        case "characters":
            return "@"
        case "modes":
            return "#"
        case "back", "menu":
            return "<"
        case "pause":
            return "="
        case "resume":
            return ">"
        case "toggle.sound":
            return "S"
        case "toggle.haptics":
            return "~"
        case "secret.code":
            return "*"
        case "toggle.godMode":
            return "G"
        case "grant.coins":
            return "$"
        case "god.nextPhase":
            return ">>"
        case "god.endRun":
            return "X"
        case "reset.progress":
            return "!"
        case "attack":
            return "+"
        default:
            if actionID.hasPrefix("ability.") {
                return "^"
            }
            if actionID.hasPrefix("weapon.") {
                return "/"
            }
            return "·"
        }
    }
}
