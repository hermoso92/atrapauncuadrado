import Foundation

/// Última experiencia elegida por el jugador (hub, persistencia simple).
enum LaunchExperience: String, CaseIterable {
    case artificialWorld
    case arcadeHub
}

enum AppLaunchPreferences {
    private static let key = "atrapa.launch.lastExperience"

    static var lastExperience: LaunchExperience {
        get {
            guard let raw = UserDefaults.standard.string(forKey: key),
                  let value = LaunchExperience(rawValue: raw) else {
                return .arcadeHub
            }
            return value
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }
}
