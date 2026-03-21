import Foundation
import UIKit

enum GameMode: String, CaseIterable, Codable {
    case original
    case evolution
    case ghost

    var title: String {
        switch self {
        case .original:
            "Clasico"
        case .evolution:
            "Arsenal"
        case .ghost:
            "Fantasma"
        }
    }

    var productTitle: String {
        switch self {
        case .original:
            "Modo Clasico"
        case .evolution:
            "Modo Arsenal"
        case .ghost:
            "Modo Fantasma"
        }
    }

    var accessLabel: String {
        switch self {
        case .original:
            "Gratis"
        case .evolution:
            "Premium o 1000 monedas"
        case .ghost:
            "Codigo amiguisimo"
        }
    }

    var premiumCoinCost: Int? {
        switch self {
        case .original:
            nil
        case .evolution:
            1_000
        case .ghost:
            nil
        }
    }

    var isPremium: Bool {
        self == .evolution || self == .ghost
    }

    var menuSubtitle: String {
        switch self {
        case .original:
            "Arcade puro: leer, capturar y sobrevivir."
        case .evolution:
            "Combate, builds, armas y personajes."
        case .ghost:
            "Modo oculto: raro, rapido y despiadado."
        }
    }

    var selectorBadge: String {
        switch self {
        case .original:
            "Arcade puro"
        case .evolution:
            "Build + combate"
        case .ghost:
            "Secreto extremo"
        }
    }

    var selectorHook: String {
        switch self {
        case .original:
            "La lectura mas limpia del juego. Sin ruido, sin trucos."
        case .evolution:
            "La capa moderna: eliges personaje, arma y habilidades."
        case .ghost:
            "Una version deformada del juego: mas presion, mas ritmo y mas riesgo."
        }
    }

    var lockedHint: String {
        switch self {
        case .original:
            "Siempre disponible."
        case .evolution:
            "Desbloquea con App Store o con 1000 monedas."
        case .ghost:
            "Desbloquea con el codigo secreto amiguisimo."
        }
    }

    var arenaTitle: String {
        switch self {
        case .original:
            "CLASICO"
        case .evolution:
            "ARSENAL"
        case .ghost:
            "FANTASMA"
        }
    }

    var arenaSubtitle: String {
        switch self {
        case .original:
            "Captura. Respira. Repite."
        case .evolution:
            "Arma. Esquiva. Escala."
        case .ghost:
            "Depura. Aguanta. No pestañees."
        }
    }

    var summaryAccent: UIColor {
        switch self {
        case .original:
            Palette.warning
        case .evolution:
            Palette.stroke
        case .ghost:
            UIColor(red: 0.56, green: 1.00, blue: 0.70, alpha: 1)
        }
    }
}
