import CoreGraphics
import Foundation

enum AbilityType: String, CaseIterable, Codable, Hashable {
    case dash
    case magnet
    case shield
    case pulse
    case overdrive

    var title: String {
        switch self {
        case .dash:
            "Dash"
        case .magnet:
            "Iman"
        case .shield:
            "Escudo"
        case .pulse:
            "Pulso"
        case .overdrive:
            "Over"
        }
    }

    var description: String {
        switch self {
        case .dash:
            "Acelera y atraviesa el caos."
        case .magnet:
            "Atrae cuadrados cercanos durante unos segundos."
        case .shield:
            "Bloquea dano durante una ventana corta."
        case .pulse:
            "Explota a tu alrededor y limpia presion cercana."
        case .overdrive:
            "Sube cadencia, velocidad y control por unos segundos."
        }
    }

    var price: Int {
        switch self {
        case .dash:
            0
        case .magnet:
            90
        case .shield:
            120
        case .pulse:
            160
        case .overdrive:
            220
        }
    }
}

enum WeaponType: String, CaseIterable, Codable, Hashable {
    case blaster
    case scatter
    case rail

    var title: String {
        switch self {
        case .blaster:
            "Blaster"
        case .scatter:
            "Scatter"
        case .rail:
            "Rail"
        }
    }

    var subtitle: String {
        switch self {
        case .blaster:
            "Disparo estable y fiable."
        case .scatter:
            "Abre abanico y limpia grupos."
        case .rail:
            "Tiro pesado que perfora objetivos."
        }
    }

    var price: Int {
        switch self {
        case .blaster:
            0
        case .scatter:
            180
        case .rail:
            260
        }
    }

    var damage: CGFloat {
        switch self {
        case .blaster:
            16
        case .scatter:
            11
        case .rail:
            24
        }
    }

    var projectileCount: Int {
        switch self {
        case .blaster:
            1
        case .scatter:
            3
        case .rail:
            1
        }
    }

    var spreadAngle: CGFloat {
        switch self {
        case .blaster:
            0
        case .scatter:
            .pi / 7
        case .rail:
            0
        }
    }

    var cooldown: TimeInterval {
        switch self {
        case .blaster:
            0.7
        case .scatter:
            1.1
        case .rail:
            1.35
        }
    }

    var projectileSpeed: CGFloat {
        switch self {
        case .blaster:
            520
        case .scatter:
            460
        case .rail:
            680
        }
    }

    var maxHits: Int {
        switch self {
        case .blaster:
            1
        case .scatter:
            1
        case .rail:
            3
        }
    }
}
