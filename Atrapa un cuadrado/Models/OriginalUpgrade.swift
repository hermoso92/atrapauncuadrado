import Foundation
import UIKit

enum OriginalUpgrade: String, CaseIterable, Codable, Hashable {
    case coinPouch
    case scoreCharm

    var title: String {
        switch self {
        case .coinPouch:
            "Bolsa retro"
        case .scoreCharm:
            "Amuleto arcade"
        }
    }

    var subtitle: String {
        switch self {
        case .coinPouch:
            "Cada captura suma 1 moneda extra."
        case .scoreCharm:
            "Cada captura suma 4 puntos extra."
        }
    }

    var price: Int {
        switch self {
        case .coinPouch:
            80
        case .scoreCharm:
            120
        }
    }

    var tint: UIColor {
        switch self {
        case .coinPouch:
            Palette.warning
        case .scoreCharm:
            Palette.success
        }
    }
}
