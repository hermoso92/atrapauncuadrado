import Foundation

/// Habilidades del modo mundo (separado del arcade `AbilityType`).
enum WorldAbility: String, CaseIterable, Codable {
    case returnToShelter
    case scan
    case sprint
    case wideCapture
    case autoGather
    case dash

    var displayTitle: String {
        switch self {
        case .returnToShelter: "Refugio"
        case .scan: "Escanear"
        case .sprint: "Sprint"
        case .wideCapture: "Captura+"
        case .autoGather: "Iman"
        case .dash: "Dash"
        }
    }

    var cooldownSeconds: TimeInterval {
        switch self {
        case .returnToShelter: 8
        case .scan: 10
        case .sprint: 6
        case .wideCapture: 7
        case .autoGather: 5
        case .dash: 4
        }
    }
}

extension ArtificialWorldSnapshot {
    var unlockedWorldAbilities: Set<WorldAbility> {
        get {
            Set(unlockedWorldAbilityRaws.compactMap(WorldAbility.init(rawValue:)))
        }
        set {
            unlockedWorldAbilityRaws = newValue.map(\.rawValue).sorted()
        }
    }

    func canUse(_ ability: WorldAbility) -> Bool {
        if unlockedWorldAbilityRaws.isEmpty {
            return true
        }
        return unlockedWorldAbilities.contains(ability)
    }
}
