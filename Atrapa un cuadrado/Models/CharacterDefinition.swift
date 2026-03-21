import UIKit

enum CharacterStyle: String, Codable {
    case circle
    case stickman
    case diamond
}

struct CharacterDefinition: Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let style: CharacterStyle
    let primaryHex: String
    let secondaryHex: String
    let speedMultiplier: CGFloat
    let magnetRangeMultiplier: CGFloat
    let price: Int
    let startsUnlocked: Bool

    var primaryColor: UIColor {
        UIColor(hex: primaryHex)
    }

    var secondaryColor: UIColor {
        UIColor(hex: secondaryHex)
    }
}

extension CharacterDefinition {
    static let classicCircle = CharacterDefinition(
        id: "classic-circle",
        title: "Circulo Clasico",
        subtitle: "Equilibrado y fiel al origen.",
        style: .circle,
        primaryHex: "#5CC9FF",
        secondaryHex: "#FFFFFF",
        speedMultiplier: 1,
        magnetRangeMultiplier: 1,
        price: 0,
        startsUnlocked: true
    )

    static let stickman = CharacterDefinition(
        id: "retro-stickman",
        title: "Stickman Retro",
        subtitle: "Ligero, agil y con mucha memoria.",
        style: .stickman,
        primaryHex: "#FFD447",
        secondaryHex: "#FFFFFF",
        speedMultiplier: 1.08,
        magnetRangeMultiplier: 0.92,
        price: 70,
        startsUnlocked: false
    )

    static let prism = CharacterDefinition(
        id: "neon-prism",
        title: "Prisma Neon",
        subtitle: "Magnetismo superior a cambio de cuerpo inestable.",
        style: .diamond,
        primaryHex: "#FF6A6A",
        secondaryHex: "#6CFFB3",
        speedMultiplier: 0.96,
        magnetRangeMultiplier: 1.18,
        price: 120,
        startsUnlocked: false
    )

    static let catalog: [CharacterDefinition] = [
        classicCircle,
        stickman,
        prism
    ]

    static func definition(for id: String) -> CharacterDefinition {
        catalog.first(where: { $0.id == id }) ?? classicCircle
    }

    var supportedAbilities: [AbilityType] {
        switch style {
        case .circle:
            return [.dash, .magnet, .pulse]
        case .stickman:
            return [.dash, .pulse, .overdrive]
        case .diamond:
            return [.shield, .magnet, .overdrive]
        }
    }

    var attackCooldownMultiplier: CGFloat {
        switch style {
        case .circle:
            return 0.82
        case .stickman:
            return 1
        case .diamond:
            return 0.92
        }
    }

    var projectilePierceBonus: Int {
        switch style {
        case .circle:
            return 0
        case .stickman:
            return 1
        case .diamond:
            return 0
        }
    }

    var projectileDamageMultiplier: CGFloat {
        switch style {
        case .circle:
            return 1
        case .stickman:
            return 0.95
        case .diamond:
            return 1.2
        }
    }

    var pulseRadiusMultiplier: CGFloat {
        switch style {
        case .circle:
            return 1
        case .stickman:
            return 0.95
        case .diamond:
            return 1.3
        }
    }

    var defaultWeapon: WeaponType {
        switch style {
        case .circle:
            return .blaster
        case .stickman:
            return .rail
        case .diamond:
            return .scatter
        }
    }
}
