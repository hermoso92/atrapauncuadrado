import Foundation

/// Tipos de entidad en el modo mundo (independientes del arcade `SquareKind`).
enum ArtificialWorldSquareKind: String, Codable, CaseIterable {
    case common
    case nutritious
    case hostile
    case rare
    case resource

    /// Daño por contacto hostil (0 si no aplica).
    var contactDamage: Double {
        switch self {
        case .hostile: 22
        default: 0
        }
    }

    var hungerRestore: Double {
        switch self {
        case .nutritious: 0.22
        case .common: 0.06
        case .resource: 0.12
        case .rare: 0.18
        case .hostile: 0
        }
    }

    var energyRestore: Double {
        switch self {
        case .nutritious: 0.12
        case .common: 0.04
        case .resource: 0.20
        case .rare: 0.25
        case .hostile: 0
        }
    }
}
