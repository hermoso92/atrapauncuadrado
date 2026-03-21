import CoreGraphics
import UIKit

enum GameConfig {
    static let worldInset: CGFloat = 24
    static let playerBaseSpeed: CGFloat = 360
    static let playerRadius: CGFloat = 22
    static let playerMaxHealth: CGFloat = 100
    static let initialSpawnInterval: TimeInterval = 1.7
    static let initialSquares: Int = 5
    static let maxSquares: Int = 15
    static let difficultyStepInterval: TimeInterval = 18
    static let squareBaseSpeed: CGFloat = 90
    static let dashDuration: TimeInterval = 0.32
    static let dashCooldown: TimeInterval = 3.5
    static let magnetDuration: TimeInterval = 5
    static let magnetCooldown: TimeInterval = 12
    static let shieldDuration: TimeInterval = 3.5
    static let shieldCooldown: TimeInterval = 14
    static let pulseCooldown: TimeInterval = 8
    static let overdriveDuration: TimeInterval = 5.5
    static let overdriveCooldown: TimeInterval = 13
    static let damageFlashDuration: TimeInterval = 0.18
    static let touchDeadZone: CGFloat = 10
    static let touchSnapDistance: CGFloat = 110
    static let reticleRadius: CGFloat = 18
    static let joystickBaseRadius: CGFloat = 42
    static let joystickKnobRadius: CGFloat = 18
    static let joystickActivationPadding: CGFloat = 20
    static let pulseRadius: CGFloat = 122
    static let projectileLifetime: TimeInterval = 1.1
    static let coinFont = "AvenirNext-Bold"
    static let titleFont = "AvenirNext-Heavy"
}

enum Palette {
    static let background = UIColor(red: 0.04, green: 0.06, blue: 0.10, alpha: 1)
    static let panel = UIColor(red: 0.10, green: 0.13, blue: 0.18, alpha: 1)
    static let stroke = UIColor(red: 0.30, green: 0.75, blue: 1.00, alpha: 1)
    static let accent = UIColor(red: 0.98, green: 0.45, blue: 0.26, alpha: 1)
    static let success = UIColor(red: 0.32, green: 0.89, blue: 0.62, alpha: 1)
    static let warning = UIColor(red: 1.00, green: 0.78, blue: 0.24, alpha: 1)
    static let danger = UIColor(red: 1.00, green: 0.35, blue: 0.42, alpha: 1)
    static let textPrimary = UIColor(white: 0.96, alpha: 1)
    static let textSecondary = UIColor(white: 0.70, alpha: 1)
}

enum PhysicsMask {
    static let none: UInt32 = 0
    static let player: UInt32 = 1 << 0
    static let square: UInt32 = 1 << 1
    static let obstacle: UInt32 = 1 << 2
}

enum SceneIdentifier {
    static let button = "menu.button"
    static let pauseOverlay = "pause.overlay"
}

enum AbilityVisualState {
    case locked
    case ready
    case coolingDown
    case active
}
