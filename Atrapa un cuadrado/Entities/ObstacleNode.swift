import SpriteKit

final class ObstacleNode: SKShapeNode {
    let obstacleRect: CGRect

    init(rect: CGRect) {
        self.obstacleRect = rect
        super.init()

        path = CGPath(roundedRect: rect, cornerWidth: 16, cornerHeight: 16, transform: nil)
        fillColor = Palette.panel.withAlphaComponent(0.9)
        strokeColor = Palette.warning
        lineWidth = 2
        glowWidth = 1
        zPosition = 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
